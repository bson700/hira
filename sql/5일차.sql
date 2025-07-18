DROP TABLE emp PURGE;
DROP TABLE dept PURGE;

CREATE TABLE emp AS SELECT * FROM employees;
CREATE TABLE dept AS SELECT * FROM departments;

BEGIN
  FOR i IN 1..10 LOOP
  INSERT INTO emp
  SELECT * FROM emp;
  END LOOP;
  UPDATE emp 
  SET employee_id = rownum;
  UPDATE emp
  SET first_name = first_name ||
                 SUBSTR('abcdefghijklmnopqrstuvwxyz', TRUNC(DBMS_RANDOM.VALUE(1, 27)), 1),
      last_name  = last_name ||
                 SUBSTR('abcdefghijklmnopqrstuvwxyz', TRUNC(DBMS_RANDOM.VALUE(1, 27)), 1),
      email      = email ||
                 SUBSTR('ABCDEFGHIJKLMNOPQRSTUVWXYZ', TRUNC(DBMS_RANDOM.VALUE(1, 27)), 1);
  COMMIT;
  END;
/

SELECT COUNT(*), MIN(employee_id), MAX(employee_id) 
FROM emp;

/*
###################################################################################### 
# TEST 2 : Optimizer Mode와 실행계획 
###################################################################################### 
*/

show parameter optimizer_mode;
/*
NAME           TYPE   VALUE    
-------------- ------ -------- 
optimizer_mode string ALL_ROWS 
*/

ALTER SYSTEM FLUSH shared_pool;
/*
System이(가) 변경되었습니다.
*/

EXPLAIN PLAN FOR
SELECT *
FROM   emp e JOIN departments d
ON  (e.department_id = d.department_id)
AND e.email='SSTILESS' OR d.department_name='Treasury';
/*
설명되었습니다.
*/

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
/*
Plan hash value: 2219721203
 
--------------------------------------------------------------------------------------------------
| Id  | Operation                      | Name            | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT               |                 |   108 | 20412 |    10   (0)| 00:00:01 |
|   1 |  VIEW                          | VW_ORE_9CEC7F3F |   108 | 20412 |    10   (0)| 00:00:01 |
|   2 |   UNION-ALL                    |                 |       |       |            |          |
|   3 |    MERGE JOIN CARTESIAN        |                 |   107 |  9630 |     6   (0)| 00:00:01 |
|*  4 |     TABLE ACCESS FULL          | DEPARTMENTS     |     1 |    21 |     3   (0)| 00:00:01 |
|   5 |     BUFFER SORT                |                 |   107 |  7383 |     3   (0)| 00:00:01 |
|   6 |      TABLE ACCESS FULL         | EMP             |   107 |  7383 |     3   (0)| 00:00:01 |
|   7 |    NESTED LOOPS                |                 |     1 |    90 |     4   (0)| 00:00:01 |
|   8 |     NESTED LOOPS               |                 |     1 |    90 |     4   (0)| 00:00:01 |
|*  9 |      TABLE ACCESS FULL         | EMP             |     1 |    69 |     3   (0)| 00:00:01 |
|* 10 |      INDEX UNIQUE SCAN         | SYS_C007306     |     1 |       |     0   (0)| 00:00:01 |
|* 11 |     TABLE ACCESS BY INDEX ROWID| DEPARTMENTS     |     1 |    21 |     1   (0)| 00:00:01 |
--------------------------------------------------------------------------------------------------
 
Predicate Information (identified by operation id):
---------------------------------------------------
 
   4 - filter("D"."DEPARTMENT_NAME"='Treasury')
   9 - filter("E"."EMAIL"='SSTILESS')
  10 - access("E"."DEPARTMENT_ID"="D"."DEPARTMENT_ID")
  11 - filter(LNNVL("D"."DEPARTMENT_NAME"='Treasury'))
 
Note
-----
   - this is an adaptive plan
*/

ALTER SYSTEM SET optimizer_mode=first_rows_1;
/*
System이(가) 변경되었습니다.
*/

ALTER SYSTEM FLUSH shared_pool;
/*
System이(가) 변경되었습니다.
*/

EXPLAIN PLAN FOR
SELECT *
FROM   emp e JOIN departments d
ON  (e.department_id = d.department_id)
AND e.email='SSTILESS' OR d.department_name='Treasury';
/*
설명되었습니다.
*/

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
/*
Plan hash value: 376566315
 
----------------------------------------------------------------------------------
| Id  | Operation          | Name        | Rows  | Bytes | Cost (%CPU)| Time     |
----------------------------------------------------------------------------------
|   0 | SELECT STATEMENT   |             |    27 |  2430 |     4   (0)| 00:00:01 |
|   1 |  NESTED LOOPS      |             |    27 |  2430 |     4   (0)| 00:00:01 |
|   2 |   TABLE ACCESS FULL| DEPARTMENTS |    27 |   567 |     2   (0)| 00:00:01 |
|*  3 |   TABLE ACCESS FULL| EMP         |    27 |  1863 |     2   (0)| 00:00:01 |
----------------------------------------------------------------------------------
 
Predicate Information (identified by operation id):
---------------------------------------------------
 
   3 - filter("E"."DEPARTMENT_ID"="D"."DEPARTMENT_ID" AND 
              "E"."EMAIL"='SSTILESS' OR "D"."DEPARTMENT_NAME"='Treasury')
*/

/*
###################################################################################### 
# TEST 3 : 객체 통계 관리 TEST 
###################################################################################### 
*/

-- Optimizer Hints : PT54


---

-- dictionary 쿼리할 때 문자는 항상 대문자를 써야 한다. 대문자로 저장된다. 'EMP'
SELECT table_name, index_name
FROM user_indexes
WHERE table_name = 'EMP';
/* 0건
*/

CREATE INDEX EMP_EMAIL_IX ON emp(email);
/*
Index EMP_EMAIL_IX이(가) 생성되었습니다.
*/

EXPLAIN PLAN FOR
SELECT /*+ INDEX(e EMP_EMAIL_IX) */
       e.first_name, e.email
FROM emp e
WHERE e.email = 'SKINGG';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
/*
Plan hash value: 1651128111
 
----------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name         | Rows  | Bytes | Cost (%CPU)| Time     |
----------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |              |     1 |    15 |  1021   (1)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| EMP          |     1 |    15 |  1021   (1)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | EMP_EMAIL_IX |     1 |       |     3   (0)| 00:00:01 |
----------------------------------------------------------------------------------------------------
 
Predicate Information (identified by operation id):
---------------------------------------------------
 
   2 - access("E"."EMAIL"='SKINGG')
*/


-- emp의 department_id 에 인덱스가 없어서 USE_NL 힌트가 없어도 NL 조인을 사용함.
EXPLAIN PLAN FOR
SELECT /*+ USE_NL(e d) */
       e.employee_id, e.first_name, d.department_name
FROM   emp e
JOIN   departments d
ON     e.department_id = d.department_id;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
/*
Plan hash value: 59501456
 
--------------------------------------------------------------------------------------------
| Id  | Operation                    | Name        | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT             |             |     1 |    30 |     4   (0)| 00:00:01 |
|   1 |  NESTED LOOPS                |             |     1 |    30 |     4   (0)| 00:00:01 |
|   2 |   NESTED LOOPS               |             |     2 |    30 |     4   (0)| 00:00:01 |
|   3 |    TABLE ACCESS FULL         | EMP         |     2 |    28 |     2   (0)| 00:00:01 |
|*  4 |    INDEX UNIQUE SCAN         | SYS_C007306 |     1 |       |     0   (0)| 00:00:01 |
|   5 |   TABLE ACCESS BY INDEX ROWID| DEPARTMENTS |     1 |    16 |     1   (0)| 00:00:01 |
--------------------------------------------------------------------------------------------
 
Predicate Information (identified by operation id):
---------------------------------------------------
 
   4 - access("E"."DEPARTMENT_ID"="D"."DEPARTMENT_ID")
*/












