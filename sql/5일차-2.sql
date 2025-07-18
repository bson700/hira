/*
제약조건
Primary Key : Not Null + Unique
Foreign Key : 특정 PK 를 참조하는 키 (Reference Key 라고도 함)
Not Null
Unique: 중복 허용 불가. NULL 생성 가능. NULL 끼리도 같다고 판단할 수 없다.
Check: ID열의 길이는 4~8자 등. -> App에서 가능하고, 다른 DBMS에 없다.
*/

/*
자식이 있는 부모테이블의 행을 삭제하면, 자식이 있어서 못한다고 함.
부서가 없는 직원이 생길 수 있다.
*/

/*
PK 나 Unique 제약조건이 걸려있는 컬럼에는 인덱스가 자동으로 만들어진다.
*/

-- 5일차-1.sql 에서 테이블 준비
-- Lab11.txt 실습

-- CONSTRAINT_TYPE : P R U C
-- P PK
-- R FK; Reference Key
-- U UK: Unique 제약조건
-- C ??, NN -> NN은 체크가 안된다.
SELECT table_name, constraint_name, constraint_type
FROM user_constraints
WHERE table_name='EMP';
/*
EMP	SYS_C007611	C
EMP	SYS_C007612	C
EMP	SYS_C007613	C
EMP	SYS_C007614	C
*/

-- 인덱스에는 NONUNIQUE, UNIQUE 가 있다.
-- 비고유 인덱스 : 중복 데이터를 저장할 수 있는 인덱스
SELECT table_name, index_name, uniqueness
FROM user_indexes
WHERE table_name='EMP';
/*
EMP	EMP_EMAIL_IX	NONUNIQUE
*/

ALTER TABLE EMP
ADD CONSTRAINT emp_id_pk PRIMARY KEY (employee_id);
/*
Table EMP이(가) 변경되었습니다.
*/

-- 기본키열은 자동으로 인덱스가 만들어진다.
SELECT table_name, constraint_name, constraint_type
FROM user_constraints
WHERE table_name='EMP';
/*
EMP	SYS_C007611	C
EMP	SYS_C007612	C
EMP	SYS_C007613	C
EMP	SYS_C007614	C
EMP	EMP_ID_PK	P
*/

SELECT table_name, index_name, uniqueness
FROM user_indexes
WHERE table_name='EMP';
/*
EMP	EMP_EMAIL_IX	NONUNIQUE
EMP	EMP_ID_PK	UNIQUE
*/

DROP INDEX emp_email_ix;
/*
Index EMP_EMAIL_IX이(가) 삭제되었습니다.
*/

-- 이 경우에는 제약조건이 삭제되면 삭제된다.
DROP INDEX emp_id_pk;
/*
오류 보고 -
ORA-02429: 고유/기본 키 적용을 위한 인덱스를 삭제할 수 없습니다.

https://docs.oracle.com/error-help/db/ora-02429/02429. 00000 -  "cannot drop index used for enforcement of unique/primary key"
*Cause:    user attempted to drop an index that is being used as the
           enforcement mechanism for unique or primary key.
*Action:   drop the constraint instead of the index.
*/

-- dlal dlseprtmrk dlTsms 열에는 인덱스를 추가로 못 만든다
CREATE INDEX emp_id_ix ON emp(employee_id);
/*
오류 보고 -
ORA-01408: 열 목록에는 이미 인덱스가 작성되어 있습니다

https://docs.oracle.com/error-help/db/ora-01408/01408. 00000 -  "such column list already indexed"
*Cause:    A CREATE INDEX statement specified a column that was
           already indexed. A single column may be indexed only once.
           Additional indexes may be created on the column if it was used
           as a portion of a concatenated index, that was, if the index
           consists of multiple columns.
*Action:   Do not attempt to re-index the column, as it is
           unnecessary. To create a concatenated key, specify one or more
           additional columns in the CREATE INDEX statement.

*/

-- 다른 애랑 섞으니까 인덱스 만들 수 있다. -> 조합 인덱스
-- employee_id 에 인덱스가 2개가 되었다. -> 이때 HINT 로 어느 인덱스를 사용할 지 지정할 수 있다.
CREATE INDEX emp_id_ix ON emp(employee_id, last_name);
/*
Index EMP_ID_IX이(가) 생성되었습니다.
*/

-- DML 성능은 인덱스가 많을 수록 안 좋다.
-- 데이터가 변경되면 인덱스에도 반영해야 한다.

-- DML과 SELECT 문장의 균형을 생각해서 인덱스를 만들어라. -> 애매하게 제한
-- 풀테이블 스캔을 한달에 한번 하는데(쿼리 자체를 한달에 한번 하는데), 인덱스를 만들지 고민할 수 있다.

-- 접속하는 DBMS의 버전확인
SELECT * FROM v$version;
/*
Oracle Database 18c Express Edition Release 18.0.0.0.0 - Production	"Oracle Database 18c Express Edition Release 18.0.0.0.0 - Production
Version 18.4.0.0.0"	Oracle Database 18c Express Edition Release 18.0.0.0.0 - Production	0
*/

-- 내가 접속한 DB 에서 사용가능한 추가 옵션 확인
-- ORACLE_DATA_VAULT FALSE : 오라클 낮은 에디션에서는 사용할 수 없음.
-- Real Application Clusters FALSE : 우리 DBMS 에서 구현 불가.
-- RAC : DB 파일은 1개. 서버 프로세스는 여러개

-- 트리
-- Deep
-- BLevel : 예전에는 BLevel 이 4가 되면 인덱스 새로 만들 것 권장. 루트가 레벨 0, 처음 만들면 2
   --> 요즘 오라클은 자동으로

-- 인덱스 명: 테이블 이름의 약어_키컬럼의 약어_ix 또는 idx

-- BLevel 확인
SELECT table_name, index_name, uniqueness, blevel
FROM user_indexes
WHERE table_name='EMP';
/*
EMP	EMP_ID_IX	NONUNIQUE	1
EMP	EMP_ID_PK	UNIQUE	1
*/

DROP INDEX emp_id_ix;

SELECT table_name, index_name, uniqueness, blevel
FROM user_indexes
WHERE table_name='EMP';
/*
EMP	EMP_ID_PK	UNIQUE	1
*/

---

-- 교안 178 페이지

-- ROWID

-- where last_name = 'king'
-- -> (해결) where lower(last_name) = 'king'

-- 인덱스 컬럼에, 함수를 쓰거나, 수식을 쓰면 인덱스 사용 안함.
-- -> (해결) 함수 기반 인덱스 -> 계산을 해서 인덱스를 생성. 계산된 결과를 인덱스로 만듬.

-- 메모리 초기화
ALTER SYSTEM FLUSH shared_pool;
/*
System이(가) 변경되었습니다.
*/
ALTER SYSTEM FLUSH buffer_cache;
/*
System이(가) 변경되었습니다.
*/

SELECT table_name, num_rows FROM user_tables;
/* 오전에 만든 EMP의 개수가 반영되지 않았다.
REGIONS	5
COUNTRIES	25
LOCATIONS	23
DEPARTMENTS	27
JOBS	19
EMPLOYEES	107
JOB_HISTORY	10
JOB_GRADES	6
DEPT	27
EMP	107
*/

exec DBMS_STATS.GATHER_SCHEMA_STATS('c##hr');

SELECT table_name, num_rows FROM user_tables;
/* 오전에 만든 EMP의 개수가 반영되었다.
COUNTRIES	25
LOCATIONS	23
DEPARTMENTS	27
REGIONS	5
JOBS	19
EMPLOYEES	107
JOB_HISTORY	10
JOB_GRADES	6
EMP	109568
DEPT	27
*/

EXPLAIN PLAN FOR
SELECT employee_id, last_name, salary
FROM emp
WHERE last_name = 'Harriss';
/*
설명되었습니다.
*/

SELECT * FROM table(dbms_xplan.display);
/*
Plan hash value: 3956160932
 
--------------------------------------------------------------------------
| Id  | Operation         | Name | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |      |     2 |    34 |    17   (0)| 00:00:01 |
|*  1 |  TABLE ACCESS FULL| EMP  |     2 |    34 |    17   (0)| 00:00:01 |
--------------------------------------------------------------------------
 
Predicate Information (identified by operation id):
---------------------------------------------------
 
   1 - filter("LAST_NAME"='Harriss')
*/

CREATE INDEX emp_lnam_ix ON emp(last_name);

ALTER SYSTEM FLUSH shared_pool;
ALTER SYSTEM FLUSH buffer_cache;

EXPLAIN PLAN FOR
SELECT employee_id, last_name, salary
FROM emp
WHERE last_name = 'Harriss';
/*
설명되었습니다.
*/

SELECT * FROM table(dbms_xplan.display);
/* INDEX RANGE SCAN을 한다. 여기서 언은 ROWID 로 TABLE ACCESS 함.
Plan hash value: 1952665554
 
---------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name        | Rows  | Bytes | Cost (%CPU)| Time     |
---------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |             |     2 |    34 |     4   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| EMP         |     2 |    34 |     4   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | EMP_LNAM_IX |    41 |       |     1   (0)| 00:00:01 |
---------------------------------------------------------------------------------------------------
 
Predicate Information (identified by operation id):
---------------------------------------------------
 
   2 - access("LAST_NAME"='Harriss')
*/

ALTER SYSTEM FLUSH shared_pool;
ALTER SYSTEM FLUSH buffer_cache;

EXPLAIN PLAN FOR
SELECT employee_id, last_name, salary
FROM emp
WHERE LOWER(last_name) = 'harriss';
/*
설명되었습니다.
*/

SELECT * FROM table(dbms_xplan.display);
/* 풀 테이블 액세스
Plan hash value: 3956160932
 
--------------------------------------------------------------------------
| Id  | Operation         | Name | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |      |     1 |    17 |     2   (0)| 00:00:01 |
|*  1 |  TABLE ACCESS FULL| EMP  |     1 |    17 |     2   (0)| 00:00:01 |
--------------------------------------------------------------------------
 
Predicate Information (identified by operation id):
---------------------------------------------------
 
   1 - filter(LOWER("LAST_NAME")='harriss')
*/


-- 조합인덱스: 컬럼을 2개 이상 조합하는 인덱스

ALTER SYSTEM FLUSH shared_pool;
ALTER SYSTEM FLUSH buffer_cache;

CREATE INDEX emp_name_ix ON emp(first_name, last_name);

EXPLAIN PLAN FOR
SELECT * FROM emp
WHERE first_name='Jackk' AND last_name = 'Harriss';
SELECT * FROM table(dbms_xplan.display);

EXPLAIN PLAN FOR
SELECT * FROM emp
WHERE last_name='Harriss';
SELECT * FROM table(dbms_xplan.display);
/* 조합 인덱스 안써도 되는데 EMP_LNAM_IX 씀
Plan hash value: 1952665554
 
---------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name        | Rows  | Bytes | Cost (%CPU)| Time     |
---------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |             |     2 |   146 |     4   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| EMP         |     2 |   146 |     4   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | EMP_LNAM_IX |    41 |       |     1   (0)| 00:00:01 |
---------------------------------------------------------------------------------------------------
 
Predicate Information (identified by operation id):
---------------------------------------------------
 
   2 - access("LAST_NAME"='Harriss')
*/

DROP INDEX emp_lnam_ix;

CREATE INDEX emp_name_ix ON emp(last_name, first_name); -- 맨 뒤에 COMPRESS

DROP INDEX emp_name_ix;

---

ALTER SYSTEM FLUSH shared_pool;
ALTER SYSTEM FLUSH buffer_cache;

EXPLAIN PLAN FOR
SELECT * FROM emp
WHERE first_name='Jackk';

SELECT * FROM table(dbms_xplan.display);
-- 후행열만 검색하면 인덱스 스킵 스캔이 나와야 하는데 안나왔음.

---

CREATE INDEX emp_fullname_ix ON employees(last_name, first_name);

ALTER SYSTEM FLUSH shared_pool;
ALTER SYSTEM FLUSH buffer_cache;

EXPLAIN PLAN FOR
SELECT * FROM employees
WHERE first_name='Yang';

SELECT * FROM table(dbms_xplan.display);
/* INDEX SKIP SCAN : 앞에 있는 열 건너뛰고 후행 열에서 찾아보겠다. 조합인덱스에서만 나타날 수 있다.
Plan hash value: 3835763075
 
-------------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name            | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |                 |     1 |    69 |     2   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| EMPLOYEES       |     1 |    69 |     2   (0)| 00:00:01 |
|*  2 |   INDEX SKIP SCAN                   | EMP_FULLNAME_IX |     1 |       |     1   (0)| 00:00:01 |
-------------------------------------------------------------------------------------------------------
 
Predicate Information (identified by operation id):
---------------------------------------------------
 
   2 - access("FIRST_NAME"='Yang')
       filter("FIRST_NAME"='Yang')
*/

---

DROP INDEX emp_name_ix;
DROP INDEX emp_fullname_ix;

-- 컬럼에 대한 통계
SELECT table_name, column_name, num_distinct
FROM user_tab_col_statistics
WHERE table_name IN ('EMP', 'EMPLOYEES')
AND column_name = 'LAST_NAME';
/*
EMP	LAST_NAME	2652
EMPLOYEES	LAST_NAME	102
*/


-- 인덱스 스킵 스캔: 김에 길동 찾아보고, 이에 길동 찾아보고, ...
-- num_distinct 가 높은 값은 스킵 스캔이 안 일어남.
-- 앞이 작으면 스킵 스캔이 잘 일어남. 예) 남자중에 길동, 여자중에 길동

---

-- 함수 기반 인덱스

ALTER SYSTEM FLUSH shared_pool;
ALTER SYSTEM FLUSH buffer_cache;

CREATE INDEX emp_sal_ix ON emp(salary);

EXPLAIN PLAN FOR
SELECT employee_id, last_name, salary
FROM emp
WHERE salary > 6000;

SELECT * FROM table(dbms_xplan.display);
/*
Plan hash value: 2221402278
 
--------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name       | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |            |     2 |    34 |     3   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| EMP        |     2 |    34 |     3   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | EMP_SAL_IX |       |       |     2   (0)| 00:00:01 |
--------------------------------------------------------------------------------------------------
 
Predicate Information (identified by operation id):
---------------------------------------------------
 
   2 - access("SALARY">6000)
*/

DROP INDEX emp_sal_ix;
CREATE INDEX emp_sal_ix ON emp(salary*12);

ALTER SYSTEM FLUSH shared_pool;
ALTER SYSTEM FLUSH buffer_cache;

EXPLAIN PLAN FOR
SELECT employee_id, last_name, salary
FROM emp
WHERE salary * 12 < 100000;

SELECT * FROM table(dbms_xplan.display);
/* emp_sal_ix 사용하고 있음
Plan hash value: 2221402278
 
--------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name       | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |            |     2 |    60 |     3   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| EMP        |     2 |    60 |     3   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | EMP_SAL_IX |       |       |     2   (0)| 00:00:01 |
--------------------------------------------------------------------------------------------------
 
Predicate Information (identified by operation id):
---------------------------------------------------
 
   2 - access("SALARY"*12<100000)
*/

-- 비트맵 인덱스 : 0 또는 1로만 나타내는 인덱스

-- 컬럼 gender 추가
ALTER TABLE emp ADD gender CHAR(1);
/*
Table EMP이(가) 변경되었습니다.
*/

UPDATE emp
SET gender = CASE
               WHEN DBMS_RANDOM.VALUE < 0.5 THEN 'F'
               ELSE 'M'
             END;
/*
109,568개 행 이(가) 업데이트되었습니다.
*/

COMMIT;
/*
커밋 완료.
*/

SELECT DISTINCT gender FROM emp;
/*
M
F
*/

CREATE INDEX emp_gender_ix ON emp(gender);
/*
Index EMP_GENDER_IX이(가) 생성되었습니다.
*/

exec dbms_stats.gather_schema_stats('c##hr');
/*
PL/SQL 프로시저가 성공적으로 완료되었습니다.
*/

ALTER SYSTEM FLUSH shared_pool;
ALTER SYSTEM FLUSH buffer_cache;

EXPLAIN PLAN FOR
SELECT * FROM emp
WHERE gender='F';

SELECT * FROM table(dbms_xplan.display);
/* 버전이 높아지면서 COST 가 좋게 나옴
Plan hash value: 2221402278
 
--------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name       | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |            |     2 |    60 |     3   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| EMP        |     2 |    60 |     3   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | EMP_SAL_IX |       |       |     2   (0)| 00:00:01 |
--------------------------------------------------------------------------------------------------
 
Predicate Information (identified by operation id):
---------------------------------------------------
 
   2 - access("SALARY"*12<100000)
*/

EXPLAIN PLAN FOR
SELECT gender, COUNT(*)
FROM emp
GROUP BY gender;

SELECT * FROM table(dbms_xplan.display);
/* 그룹연산 하니 높게 나옴
Plan hash value: 4067220884
 
---------------------------------------------------------------------------
| Id  | Operation          | Name | Rows  | Bytes | Cost (%CPU)| Time     |
---------------------------------------------------------------------------
|   0 | SELECT STATEMENT   |      |     2 |     4 |   319   (4)| 00:00:01 |
|   1 |  HASH GROUP BY     |      |     2 |     4 |   319   (4)| 00:00:01 |
|   2 |   TABLE ACCESS FULL| EMP  |   109K|   214K|   312   (2)| 00:00:01 |
---------------------------------------------------------------------------
*/

-- 오라클에서 테이블을 분석하면, 관련 인덱스도 분석하는데, 인덱스만 따로 분석할 수도 있다.

ANALYZE INDEX emp_gender_ix COMPUTE STATISTICS;
SELECT blevel, leaf_blocks, distinct_keys, clustering_factor
FROM user_indexes
WHERE index_name = 'EMP_GENDER_IX'; -- 대문자로 검색해야 한다.
/* 지금은 B 트리 인덱스
1	199	2	2218
*/

DROP INDEX emp_gender_ix;

CREATE BITMAP INDEX emp_gender_ix ON emp(gender);

ALTER SYSTEM FLUSH shared_pool;
ALTER SYSTEM FLUSH buffer_cache;

EXPLAIN PLAN FOR
SELECT * FROM emp
WHERE gender='F';

SELECT * FROM table(dbms_xplan.display);
/* CONVERSION TO ROWIDS: 테이블 액세스 할려면 .. / 인덱스의 ROWID 순으로 저장하고 있다. / ROWID 범위를 저장하고 있다.
Plan hash value: 3630208881
 
-----------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name          | Rows  | Bytes | Cost (%CPU)| Time     |
-----------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |               |     1 |    77 |     4   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| EMP           |     1 |    77 |     4   (0)| 00:00:01 |
|   2 |   BITMAP CONVERSION TO ROWIDS       |               |       |       |            |          |
|*  3 |    BITMAP INDEX SINGLE VALUE        | EMP_GENDER_IX |       |       |            |          |
-----------------------------------------------------------------------------------------------------
 
Predicate Information (identified by operation id):
---------------------------------------------------
 
   3 - access("GENDER"='F')
*/

EXPLAIN PLAN FOR
SELECT gender, COUNT(*)
FROM emp
GROUP BY gender;

SELECT * FROM table(dbms_xplan.display);
/* BITMAP INDEX FAST FULL SCAN 발생. 테이블 접근 이력이 없다.
Plan hash value: 2091464919
 
-----------------------------------------------------------------------------------------------
| Id  | Operation                     | Name          | Rows  | Bytes | Cost (%CPU)| Time     |
-----------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT              |               |     2 |     4 |    12  (59)| 00:00:01 |
|   1 |  HASH GROUP BY                |               |     2 |     4 |    12  (59)| 00:00:01 |
|   2 |   BITMAP CONVERSION COUNT     |               |   109K|   214K|     5   (0)| 00:00:01 |
|   3 |    BITMAP INDEX FAST FULL SCAN| EMP_GENDER_IX |       |       |            |          |
-----------------------------------------------------------------------------------------------
*/

ANALYZE INDEX emp_gender_ix COMPUTE STATISTICS;
SELECT blevel, leaf_blocks, distinct_keys, clustering_factor
FROM user_indexes
WHERE index_name = 'EMP_GENDER_IX'; -- 대문자로 검색해야 한다.
/* 비트맵은 2개로 끝남. (비트맵 인덱스 아닌 경우 위의 결과 1	199	2	2218)
1	5	2	10
*/

-- clustering_factor : 인덱스로 만들었을때 얼마나 성능이 좋을까. 낮을수록 인덱스 성능이 좋다.
--                     테이블로 갔을때 분포가 심한지 아닌지 나타냄. 비트맵 인덱스 아닌 경우는 이 값이 큼.


---

CREATE TABLE bigemp
AS
SELECT * FROM emp;
/*
Table BIGEMP이(가) 생성되었습니다.
*/

ANALYZE TABLE bigemp COMPUTE STATISTICS;
/*
Table BIGEMP이(가) 분석되었습니다.
*/

SELECT table_name, num_rows, blocks, empty_blocks
FROM user_tables;
/* 1232 (HWM High Water Mark) 쓰는 블럭, 48 비어있는 블럭. 오라클은 풀테이블스캔하면 1232 블럭까지만 읽음.
   지금은 괜찮은데 삭제가 많이 일어나면...
REGIONS	5	5	0
COUNTRIES	25		
LOCATIONS	23	5	0
DEPARTMENTS	27	5	0
JOBS	19	5	0
EMPLOYEES	107	5	0
JOB_HISTORY	10	5	0
JOB_GRADES	6	5	0
DEPT	27	4	0
EMP	109568	1129	0
BIGEMP	109568	1232	48
*/

DELETE FROM bigemp
WHERE department_id IN (30, 50, 80);
/*
87,040개 행 이(가) 삭제되었습니다.
*/

COMMIT;
/*
커밋 완료.
*/

SELECT table_name, num_rows, blocks, empty_blocks
FROM user_tables;
/* BIGEMP 값들이 그대로...
COUNTRIES	25		
LOCATIONS	23	5	0
DEPARTMENTS	27	5	0
REGIONS	5	5	0
JOBS	19	5	0
EMPLOYEES	107	5	0
JOB_HISTORY	10	5	0
JOB_GRADES	6	5	0
EMP	109568	1129	0
DEPT	27	4	0
BIGEMP	109568	1232	48
*/

ANALYZE TABLE bigemp COMPUTE STATISTICS;
/*
Table BIGEMP이(가) 분석되었습니다.
*/

SELECT table_name, num_rows, blocks, empty_blocks
FROM user_tables;
/* table_name만 변했다. 1232에는 빈블록이 많을 것이다.
BIGEMP	22528	1232	48
COUNTRIES	25		
DEPARTMENTS	27	5	0
DEPT	27	4	0
EMP	109568	1129	0
EMPLOYEES	107	5	0
JOBS	19	5	0
JOB_GRADES	6	5	0
JOB_HISTORY	10	5	0
LOCATIONS	23	5	0
REGIONS	5	5	0
*/

-- DML 이 많이 발생하는 작업들은 가끔씩 이걸 해줘야 함.
ALTER TABLE bigemp ENABLE ROW MOVEMENT; -- 행 이동 활성화. (행고정이면 rowid 가 안바뀜)
ALTER TABLE bigemp SHRINK SPACE;
ALTER TABLE bigemp DISABLE ROW MOVEMENT;

ANALYZE TABLE bigemp COMPUTE STATISTICS;
/*
Table BIGEMP이(가) 분석되었습니다.
*/

SELECT table_name, num_rows, blocks, empty_blocks
FROM user_tables;
/* 블럭수(blocks)가 줄은 걸 확인할 수 있다. 빈 블록이 지워진 것이다.
   문제는 행이 이동되어 rowid 도 변경되었다. 그래서 인덱스도 rebuild 해줘야 한다.
REGIONS	5	5	0
COUNTRIES	25		
LOCATIONS	23	5	0
DEPARTMENTS	27	5	0
JOBS	19	5	0
EMPLOYEES	107	5	0
JOB_HISTORY	10	5	0
JOB_GRADES	6	5	0
DEPT	27	4	0
EMP	109568	1129	0
BIGEMP	22528	250	14
*/

---

-- 교재 p193

DROP TABLE bigemp PURGE;
/*
Table BIGEMP이(가) 삭제되었습니다.
*/


