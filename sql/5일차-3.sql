-- Lab_12.txt

-- 1. EMP 테이블의 인덱스화된 열을 조회합니다.
SELECT i.index_name, c.column_name, c.column_position
FROM user_indexes i JOIN user_ind_columns c
USING (table_name)
WHERE table_name = 'EMP';
/*
EMP_SAL_IX	SYS_NC00012$	1
EMP_SAL_IX	GENDER	1
EMP_SAL_IX	EMPLOYEE_ID	1
EMP_ID_PK	SYS_NC00012$	1
EMP_ID_PK	GENDER	1
EMP_ID_PK	EMPLOYEE_ID	1
EMP_GENDER_IX	SYS_NC00012$	1
EMP_GENDER_IX	GENDER	1
EMP_GENDER_IX	EMPLOYEE_ID	1
*/

-- column_position : 조합 인덱스를 만들 때, 앞에께 1, 뒤에께 2

-- 2. department_id 열에 인덱스를 생성합니다.
SELECT distinct department_id FROM emp;
/* 테이블의 행수에 비하면, 중복도가 높고, 카디널리티가 낮다.
50
40
110
90
30
70

10
20
60
100
80
*/
CREATE INDEX emp_deptid_ix ON emp(department_id);
/*
Index EMP_DEPTID_IX이(가) 생성되었습니다.
*/

-- 3. 다음 두 쿼리의 실행계획을 확인합니다.
EXPLAIN PLAN FOR
SELECT * FROM emp
WHERE department_id = 30;
SELECT * FROM table(dbms_xplan.display);
/*
Plan hash value: 4049360392
 
-----------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name          | Rows  | Bytes | Cost (%CPU)| Time     |
-----------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |               |     1 |    77 |     2   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| EMP           |     1 |    77 |     2   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | EMP_DEPTID_IX |       |       |     1   (0)| 00:00:01 |
-----------------------------------------------------------------------------------------------------
 
Predicate Information (identified by operation id):
---------------------------------------------------
 
   2 - access("DEPARTMENT_ID"=30)
*/

EXPLAIN PLAN FOR
SELECT * FROM emp
WHERE department_id != 30;
SELECT * FROM table(dbms_xplan.display);
/*
Plan hash value: 3956160932
 
--------------------------------------------------------------------------
| Id  | Operation         | Name | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |      |     1 |    77 |     2   (0)| 00:00:01 |
|*  1 |  TABLE ACCESS FULL| EMP  |     1 |    77 |     2   (0)| 00:00:01 |
--------------------------------------------------------------------------
 
Predicate Information (identified by operation id):
---------------------------------------------------
 
   1 - filter("DEPARTMENT_ID"<>30)
*/


-- department_id!=30 ==> 30 이거나 (null)
-- 인덱스에는 null 이 없으므로 null 을 찾기위해 풀테이블스캔

DROP INDEX emp_deptid_ix;
/*
Index EMP_DEPTID_IX이(가) 삭제되었습니다.
*/

-- 인덱스 확인
SELECT i.index_name, c.column_name, c.column_position, i.uniqueness
FROM user_indexes i JOIN user_ind_columns c
USING (table_name)
WHERE table_name = 'EMP';
/*
EMP_SAL_IX	SYS_NC00012$	1	NONUNIQUE
EMP_SAL_IX	GENDER	1	NONUNIQUE
EMP_SAL_IX	EMPLOYEE_ID	1	NONUNIQUE
EMP_ID_PK	SYS_NC00012$	1	UNIQUE
EMP_ID_PK	GENDER	1	UNIQUE
EMP_ID_PK	EMPLOYEE_ID	1	UNIQUE
EMP_GENDER_IX	SYS_NC00012$	1	NONUNIQUE
EMP_GENDER_IX	GENDER	1	NONUNIQUE
EMP_GENDER_IX	EMPLOYEE_ID	1	NONUNIQUE
*/

SELECT constraint_name
FROM user_constraints
WHERE table_name = 'EMP';
/*
SYS_C007611
SYS_C007612
SYS_C007613
SYS_C007614
EMP_ID_PK
*/

--# TEST 2 : INDEX UNIQUE SCAN과 INDEX RANGE SCAN

-- UNIQUE 인덱스일 겨우 사용하는 연산에 따라서 플랜이 어떻게 달라지는가를 보기 위한 코드

EXPLAIN PLAN FOR
SELECT employee_id, first_name, salary FROM emp
WHERE employee_id = 103; -- 값을 찍을 때. 동등 연산일때. 유니크 스캔.
SELECT * FROM table(dbms_xplan.display);
/*
Plan hash value: 1252232671
 
-----------------------------------------------------------------------------------------
| Id  | Operation                   | Name      | Rows  | Bytes | Cost (%CPU)| Time     |
-----------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT            |           |     1 |    17 |     2   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID| EMP       |     1 |    17 |     2   (0)| 00:00:01 |
|*  2 |   INDEX UNIQUE SCAN         | EMP_ID_PK |     1 |       |     1   (0)| 00:00:01 |
-----------------------------------------------------------------------------------------
 
Predicate Information (identified by operation id):
---------------------------------------------------
 
   2 - access("EMPLOYEE_ID"=103)
*/

EXPLAIN PLAN FOR
SELECT employee_id, first_name, salary FROM emp
WHERE employee_id BETWEEN 100 AND 120; -- 범위는 레인지스캔
SELECT * FROM table(dbms_xplan.display);
/*
Plan hash value: 1991476412
 
-------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name      | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |           |     4 |    68 |     3   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| EMP       |     4 |    68 |     3   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | EMP_ID_PK |    22 |       |     2   (0)| 00:00:01 |
-------------------------------------------------------------------------------------------------
 
Predicate Information (identified by operation id):
---------------------------------------------------
 
   2 - access("EMPLOYEE_ID">=100 AND "EMPLOYEE_ID"<=120)
*/

EXPLAIN PLAN FOR
SELECT employee_id, first_name, salary FROM emp
WHERE employee_id IN (555, 666, 777); -- IN도 = 이므로 UNIQUE SCAN
SELECT * FROM table(dbms_xplan.display);
/*
Plan hash value: 1991476412
 
-------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name      | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |           |     4 |    68 |     3   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| EMP       |     4 |    68 |     3   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | EMP_ID_PK |    22 |       |     2   (0)| 00:00:01 |
-------------------------------------------------------------------------------------------------
 
Predicate Information (identified by operation id):
---------------------------------------------------
 
   2 - access("EMPLOYEE_ID">=100 AND "EMPLOYEE_ID"<=120)
*/

-- 제약조건을 지워야 인덱스를 지울 수 있다.
ALTER TABLE emp DROP PRIMARY KEY;
/*
Table EMP이(가) 변경되었습니다.
*/

-- PK 를 지우니 인덱스가 지워짐.
SELECT i.index_name, c.column_name, c.column_position, i.uniqueness
FROM user_indexes i JOIN user_ind_columns c
USING (table_name)
WHERE table_name = 'EMP';
/*
EMP_SAL_IX	GENDER	1	NONUNIQUE
EMP_SAL_IX	SYS_NC00012$	1	NONUNIQUE
EMP_GENDER_IX	GENDER	1	NONUNIQUE
EMP_GENDER_IX	SYS_NC00012$	1	NONUNIQUE
*/

CREATE INDEX emp_id_ix ON emp(employee_id);
/*
Index EMP_ID_IX이(가) 생성되었습니다.
*/

-- 인덱스 정보 조회
SELECT i.index_name, c.column_name, c.column_position, i.uniqueness
FROM user_indexes i JOIN user_ind_columns c
USING (table_name)
WHERE table_name = 'EMP';
/* 인덱스가 기본적으로 NONUNIQUE 로 만들어짐을 확인
EMP_SAL_IX	SYS_NC00012$	1	NONUNIQUE
EMP_SAL_IX	GENDER	1	NONUNIQUE
EMP_SAL_IX	EMPLOYEE_ID	1	NONUNIQUE
EMP_ID_IX	SYS_NC00012$	1	NONUNIQUE
EMP_ID_IX	GENDER	1	NONUNIQUE
EMP_ID_IX	EMPLOYEE_ID	1	NONUNIQUE
EMP_GENDER_IX	SYS_NC00012$	1	NONUNIQUE
EMP_GENDER_IX	GENDER	1	NONUNIQUE
EMP_GENDER_IX	EMPLOYEE_ID	1	NONUNIQUE
*/

-- NONUNIQUE일 때 플랜 확인: NONUNIQUE 인덱스는 무조건 RANGE SCAN을 한다.
EXPLAIN PLAN FOR
SELECT employee_id, first_name, salary FROM emp
WHERE employee_id = 103; -- 값을 찍을 때. 동등 연산일때. 유니크 스캔.
SELECT * FROM table(dbms_xplan.display);

EXPLAIN PLAN FOR
SELECT employee_id, first_name, salary FROM emp
WHERE employee_id BETWEEN 100 AND 120; -- 범위는 레인지스캔
SELECT * FROM table(dbms_xplan.display);

EXPLAIN PLAN FOR
SELECT employee_id, first_name, salary FROM emp
WHERE employee_id IN (555, 666, 777); -- IN도 = 이므로 UNIQUE SCAN
SELECT * FROM table(dbms_xplan.display);
/*
Plan hash value: 3469614518
 
--------------------------------------------------------------------------------------------------
| Id  | Operation                            | Name      | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                     |           |     3 |    51 |     3   (0)| 00:00:01 |
|   1 |  INLIST ITERATOR                     |           |       |       |            |          |
|   2 |   TABLE ACCESS BY INDEX ROWID BATCHED| EMP       |     3 |    51 |     3   (0)| 00:00:01 |
|*  3 |    INDEX RANGE SCAN                  | EMP_ID_IX |     3 |       |     2   (0)| 00:00:01 |
--------------------------------------------------------------------------------------------------
 
Predicate Information (identified by operation id):
---------------------------------------------------
 
   3 - access("EMPLOYEE_ID"=555 OR "EMPLOYEE_ID"=666 OR "EMPLOYEE_ID"=777)
*/

-- 제약조건 만들기
ALTER TABLE emp
ADD CONSTRAINT emp_pk PRIMARY KEY(employee_id);
/*
Table EMP이(가) 변경되었습니다.
*/

SELECT i.index_name, c.column_name, c.column_position, i.uniqueness
FROM user_indexes i JOIN user_ind_columns c
USING (table_name)
WHERE table_name = 'EMP';
/*
EMP_SAL_IX	SYS_NC00012$	1	NONUNIQUE
EMP_SAL_IX	GENDER	1	NONUNIQUE
EMP_SAL_IX	EMPLOYEE_ID	1	NONUNIQUE
EMP_ID_IX	SYS_NC00012$	1	NONUNIQUE
EMP_ID_IX	GENDER	1	NONUNIQUE
EMP_ID_IX	EMPLOYEE_ID	1	NONUNIQUE
EMP_GENDER_IX	SYS_NC00012$	1	NONUNIQUE
EMP_GENDER_IX	GENDER	1	NONUNIQUE
EMP_GENDER_IX	EMPLOYEE_ID	1	NONUNIQUE
*/

-- 하나의 열에는 인덱스가 중복 생성되지 않았다.
-- 기본키 만들면 인덱스가 만들어져야 하는데,
-- 이미 사람이 만들어 놓은 인덱스가 있으므로 이를 사용한다.
-- 오라클이 자동으로 만든 인덱스가 아니므로 PK를 삭제해도 인덱스가 삭제되지 않는다.
-- 그러므로,
-- 인덱스를 먼저 만들고, 키를 지정하면, 인덱스가 유지된다.

-- ##############################################################

-- 앞의 상황 클리어하고 실습
ALTER TABLE emp DROP PRIMARY KEY;
DROP INDEX EMP_SAL_IX;
DROP INDEX EMP_ID_IX;
DROP INDEX EMP_GENDER_IX;

-- 인덱스 확인
SELECT i.index_name, c.column_name, c.column_position, i.uniqueness
FROM user_indexes i JOIN user_ind_columns c
USING (table_name)
WHERE table_name = 'EMP';
/* 0건
*/

ALTER TABLE emp
ADD CONSTRAINT emp_id_pk PRIMARY KEY(employee_id);

-- 인덱스 확인
SELECT i.index_name, c.column_name, c.column_position, i.uniqueness
FROM user_indexes i JOIN user_ind_columns c
USING (table_name)
WHERE table_name = 'EMP';
/*
EMP_ID_PK	EMPLOYEE_ID	1	UNIQUE
*/

-- 1. 다음 명령은 INDEX FULL SCAN이 발생합니다. 
EXPLAIN PLAN FOR
SELECT * FROM emp
ORDER BY employee_id;
SELECT * FROM table(dbms_xplan.display);
/* -- 인덱스가 만들어져 있는 컬럼을 ORDER BY 하면, INDEX FULL SCAN 이 뜬다. 정렬에 장점이 있다.
Plan hash value: 1408607684
 
-----------------------------------------------------------------------------------------
| Id  | Operation                   | Name      | Rows  | Bytes | Cost (%CPU)| Time     |
-----------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT            |           |     1 |    77 |     3   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID| EMP       |   109K|  8239K|     3   (0)| 00:00:01 |
|   2 |   INDEX FULL SCAN           | EMP_ID_PK |     1 |       |     2   (0)| 00:00:01 |
-----------------------------------------------------------------------------------------
*/

-- 2. 다음 명령은 INDEX FAST FULL SCAN이 발생합니다. 
EXPLAIN PLAN FOR
SELECT first_name, last_name from emp;
SELECT * FROM table(dbms_xplan.display);
/*
Plan hash value: 3956160932
 
--------------------------------------------------------------------------
| Id  | Operation         | Name | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |      |     1 |    16 |     2   (0)| 00:00:01 |
|   1 |  TABLE ACCESS FULL| EMP  |     1 |    16 |     2   (0)| 00:00:01 |
--------------------------------------------------------------------------
*/

CREATE INDEX emp_name_ix on emp(first_name, last_name);
EXPLAIN PLAN FOR
SELECT first_name, last_name from emp;
SELECT * FROM table(dbms_xplan.display);
/* 조합 인덱스: 인덱스된 열만 SELECT 할때는 인덱스만 읽고 끝냄.
Plan hash value: 1847877723
 
------------------------------------------------------------------------------------
| Id  | Operation            | Name        | Rows  | Bytes | Cost (%CPU)| Time     |
------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT     |             |     1 |    16 |     2   (0)| 00:00:01 |
|   1 |  INDEX FAST FULL SCAN| EMP_NAME_IX |     1 |    16 |     2   (0)| 00:00:01 |
------------------------------------------------------------------------------------
*/

-- 인덱스 확인
SELECT i.index_name, c.column_name, c.column_position, i.uniqueness
FROM user_indexes i JOIN user_ind_columns c
USING (table_name)
WHERE table_name = 'EMP';
/*
EMP_ID_PK	EMPLOYEE_ID	1	UNIQUE
EMP_ID_PK	LAST_NAME	2	UNIQUE
EMP_ID_PK	FIRST_NAME	1	UNIQUE
EMP_NAME_IX	EMPLOYEE_ID	1	NONUNIQUE
EMP_NAME_IX	LAST_NAME	2	NONUNIQUE
EMP_NAME_IX	FIRST_NAME	1	NONUNIQUE
*/



