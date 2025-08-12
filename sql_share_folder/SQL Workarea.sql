-----------------------------------------------------------------------------------
-- -- T1 테이블을 검색해보고 예제처럼 검색되는 데이터가 없다면, 아래 명령문을 이용하여 테이블을 생성 후 실습을 진행합니다.  
-----------------------------------------------------------------------------------

DROP TABLE t1 PURGE ; 

CREATE TABLE t1
AS
SELECT dbms_random.string('a',100) AS c1
  FROM dual
CONNECT BY level <= 500000 ;

ALTER TABLE t1 ADD (c2 VARCHAR2(5)) ; 

UPDATE t1 
SET c2 = SUBSTR(c1,1,5); 
COMMIT ; 

ALTER SYSTEM FLUSH SHARED_POOL ; 

-- Optimal 
ALTER SESSION SET workarea_size_policy = manual ;
ALTER SESSION SET sort_area_size = 1024000000 ;
SET AUTOTRACE TRACEONLY 
SELECT /*+ pga0 */ * FROM t1 ORDER BY 1 ; 
SET AUTOTRACE OFF 

SELECT x.*
FROM v$sql s
    ,TABLE(DBMS_XPLAN.DISPLAY_CURSOR(s.sql_id,s.child_number,'ALLSTATS LAST')) x
WHERE sql_text LIKE 'SELECT /*+ pga0%';
----------------------------------------------------------------------------------------------------------------
| Id  | Operation          | Name | Starts | E-Rows | A-Rows |   A-Time   | Buffers |  OMem |  1Mem | Used-Mem |
----------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT   |      |      1 |        |    500K|00:00:00.23 |    9853 |       |       |          |
|   1 |  SORT ORDER BY     |      |      1 |    483K|    500K|00:00:00.23 |    9853 |    67M|  2855K|   60M (0)|
|   2 |   TABLE ACCESS FULL| T1   |      1 |    483K|    500K|00:00:00.03 |    9853 |       |       |          |
----------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------

-- One Pass 
ALTER SESSION SET workarea_size_policy = manual ;
ALTER SESSION SET sort_area_size = 10485760 ; 
SET AUTOTRACE TRACEONLY 
SELECT /*+ pga1 */ * FROM t1 ORDER BY 1 ; 
SET AUTOTRACE OFF 

SELECT x.*
FROM v$sql s
    ,TABLE(DBMS_XPLAN.DISPLAY_CURSOR(s.sql_id,s.child_number,'ALLSTATS LAST')) x
WHERE sql_text LIKE 'SELECT /*+ pga1%';

--------------------------------------------------------------------------------------------------------------------------------------------
| Id  | Operation          | Name | Starts | E-Rows | A-Rows |   A-Time   | Buffers | Reads  | Writes |  OMem |  1Mem | Used-Mem | Used-Tmp|
--------------------------------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT   |      |      1 |        |    500K|00:00:00.26 |    7371 |   7147 |   7147 |       |       |          |         |
|   1 |  SORT ORDER BY     |      |      1 |    483K|    500K|00:00:00.26 |    7371 |   7147 |   7147 |    62M|  2754K|    9M (1)|   57344 |
|   2 |   TABLE ACCESS FULL| T1   |      1 |    483K|    500K|00:00:00.03 |    7363 |      0 |      0 |       |       |          |         |
--------------------------------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------
-- Multi Pass 

ALTER SESSION SET workarea_size_policy = manual ;
ALTER SESSION SET sort_area_size = 32768 ; 
SET AUTOTRACE TRACEONLY 
SELECT /*+ pgaM */ * FROM t1 ORDER BY 1 ; 
SET AUTOTRACE OFF 

SELECT x.*
FROM v$sql s
    ,TABLE(DBMS_XPLAN.DISPLAY_CURSOR(s.sql_id,s.child_number,'ALLSTATS LAST')) x
WHERE sql_text LIKE 'SELECT /*+ pgaM%';

--------------------------------------------------------------------------------------------------------------------------------------------
| Id  | Operation          | Name | Starts | E-Rows | A-Rows |   A-Time   | Buffers | Reads  | Writes |  OMem |  1Mem | Used-Mem | Used-Tmp|
--------------------------------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT   |      |      1 |        |    500K|00:00:07.12 |   14557 |  80389 |  80391 |       |       |          |         |
|   1 |  SORT ORDER BY     |      |      1 |    483K|    500K|00:00:07.12 |   14557 |  80389 |  80391 |    69M|  2880K|41984  (19|     113K|
|   2 |   TABLE ACCESS FULL| T1   |      1 |    483K|    500K|00:00:00.03 |    7363 |      0 |      0 |       |       |          |         |
--------------------------------------------------------------------------------------------------------------------------------------------
 
-----------------------------------------------------------------------
-- PGA �ڵ� ���� (pga_aggregate_target ���)

ALTER SESSION SET workarea_size_policy = AUTO ;
ALTER SESSION SET sort_area_size = 32768 ;
SET AUTOTRACE TRACEONLY
SELECT /*+ pgaA */ * FROM t1 ORDER BY 1 ; 
SET AUTOTRACE OFF 

SELECT x.*
FROM v$sql s
    ,TABLE(DBMS_XPLAN.DISPLAY_CURSOR(s.sql_id,s.child_number,'ALLSTATS LAST')) x
WHERE sql_text LIKE 'SELECT /*+ pgaA%';

----------------------------------------------------------------------------------------------------------------
| Id  | Operation          | Name | Starts | E-Rows | A-Rows |   A-Time   | Buffers |  OMem |  1Mem | Used-Mem |
----------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT   |      |      1 |        |    500K|00:00:00.22 |    7363 |       |       |          |
|   1 |  SORT ORDER BY     |      |      1 |    483K|    500K|00:00:00.22 |    7363 |    67M|  2855K|   60M (0)|
|   2 |   TABLE ACCESS FULL| T1   |      1 |    483K|    500K|00:00:00.03 |    7363 |       |       |          |
----------------------------------------------------------------------------------------------------------------

----------------------------------------------
-- HASH, SORT 확인 (hash - join/non eq에서는 sort, sort - order  ===> hash가 더빠름)
-- SORT 10M 

ALTER SESSION SET "_smm_max_size" = 10240 ;
SET AUTOTRACE TRACEONLY 
SELECT /*+ workarea10_sort */ c2, MAX(c1) 
  FROM t1 
 GROUP BY c2
 ORDER BY c2 ; 
SET AUTOTRACE OFF 
SELECT x.*
FROM v$sql s
    ,TABLE(DBMS_XPLAN.DISPLAY_CURSOR(s.sql_id,s.child_number,'ALLSTATS LAST')) x
WHERE sql_text LIKE 'SELECT /*+ workarea10_sort%';
--------------------------------------------------------------------------------------------------------------------------------------------
| Id  | Operation          | Name | Starts | E-Rows | A-Rows |   A-Time   | Buffers | Reads  | Writes |  OMem |  1Mem | Used-Mem | Used-Tmp|
--------------------------------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT   |      |      1 |        |    499K|00:00:00.40 |    7379 |   7625 |   7625 |       |       |          |         |
|   1 |  SORT GROUP BY     |      |      1 |    483K|    499K|00:00:00.40 |    7379 |   7625 |   7625 |    66M|  2837K|    9M (1)|   61440 |
|   2 |   TABLE ACCESS FULL| T1   |      1 |    483K|    500K|00:00:00.03 |    7363 |      0 |      0 |       |       |          |         |
--------------------------------------------------------------------------------------------------------------------------------------------
 
-----------------------------------------------------------------------
-- SORT 30M 

ALTER SESSION SET "_smm_max_size" = 30240 ;
SET AUTOTRACE TRACEONLY
SELECT /*+ workarea30_sort */ c2, MAX(c1) 
  FROM t1 
 GROUP BY c2
 ORDER BY c2 ; 
SET AUTOTRACE OFF 
SELECT x.*
FROM v$sql s
    ,TABLE(DBMS_XPLAN.DISPLAY_CURSOR(s.sql_id,s.child_number,'ALLSTATS LAST')) x
WHERE sql_text LIKE 'SELECT /*+ workarea30_sort%';
--------------------------------------------------------------------------------------------------------------------------------------------
| Id  | Operation          | Name | Starts | E-Rows | A-Rows |   A-Time   | Buffers | Reads  | Writes |  OMem |  1Mem | Used-Mem | Used-Tmp|
--------------------------------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT   |      |      1 |        |    499K|00:00:00.43 |    7377 |   7623 |   7623 |       |       |          |         |
|   1 |  SORT GROUP BY     |      |      1 |    483K|    499K|00:00:00.43 |    7377 |   7623 |   7623 |    66M|  2837K|   25M (1)|   61440 |
|   2 |   TABLE ACCESS FULL| T1   |      1 |    483K|    500K|00:00:00.04 |    7363 |      0 |      0 |       |       |          |         |
--------------------------------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------
-- HASH 10M 

ALTER SESSION SET "_smm_max_size" = 10240 ;
SET AUTOTRACE TRACEONLY
SELECT /*+ workarea10_hash */ c2, MAX(c1) 
  FROM t1 
 GROUP BY c2 ; 
SET AUTOTRACE OFF 
SELECT x.*
FROM v$sql s
    ,TABLE(DBMS_XPLAN.DISPLAY_CURSOR(s.sql_id,s.child_number,'ALLSTATS LAST')) x
WHERE sql_text LIKE 'SELECT /*+ workarea10_hash%';
--------------------------------------------------------------------------------------------------------------------------------------------
| Id  | Operation          | Name | Starts | E-Rows | A-Rows |   A-Time   | Buffers | Reads  | Writes |  OMem |  1Mem | Used-Mem | Used-Tmp|
--------------------------------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT   |      |      1 |        |    499K|00:00:00.29 |    7363 |   7860 |   7860 |       |       |          |         |
|   1 |  HASH GROUP BY     |      |      1 |    483K|    499K|00:00:00.29 |    7363 |   7860 |   7860 |    71M|  7219K|   10M (1)|   67584 |
|   2 |   TABLE ACCESS FULL| T1   |      1 |    483K|    500K|00:00:00.03 |    7363 |      0 |      0 |       |       |          |         |
--------------------------------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------
-- HASH 30M 

ALTER SESSION SET "_smm_max_size" = 30240 ;
SET AUTOTRACE TRACEONLY
SELECT /*+ workarea30_hash */ c2, MAX(c1) 
  FROM t1 
 GROUP BY c2 ; 
SET AUTOTRACE OFF 
SELECT x.*
FROM v$sql s
    ,TABLE(DBMS_XPLAN.DISPLAY_CURSOR(s.sql_id,s.child_number,'ALLSTATS LAST')) x
WHERE sql_text LIKE 'SELECT /*+ workarea30_hash%';
--------------------------------------------------------------------------------------------------------------------------------------------
| Id  | Operation          | Name | Starts | E-Rows | A-Rows |   A-Time   | Buffers | Reads  | Writes |  OMem |  1Mem | Used-Mem | Used-Tmp|
--------------------------------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT   |      |      1 |        |    499K|00:00:00.25 |    7363 |   8246 |   8246 |       |       |          |         |
|   1 |  HASH GROUP BY     |      |      1 |    483K|    499K|00:00:00.25 |    7363 |   8246 |   8246 |    87M|  7219K|   30M (1)|   68608 |
|   2 |   TABLE ACCESS FULL| T1   |      1 |    483K|    500K|00:00:00.03 |    7363 |      0 |      0 |       |       |          |         |
--------------------------------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------

DROP TABLE t1 PURGE ; 