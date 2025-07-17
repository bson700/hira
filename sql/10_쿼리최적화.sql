/*
Instance
Memory
  SGA(System Global Area)
    Shared Pool
    DB Buffer Cache
    Redo log buffer
  Background Process

Database
DataFile     ?File    Redolog

User Process

-> 3가지 파일을 합친걸 Database 라고 한다.
DB 장애가 나면, 이 3개의 파일중 하나가 깨진 상태이다.
DB 복구시 이 파일들을 복구한다.

Oracle 에서는 메모리를 Area 라고 표시한다.
SGA와 Background Process를 합쳐서 Instance 라고 한다.


User Process 접속하면 서버 인스턴스에 서버 프로세스가 생성되고, 이를 (         )라고 한다.

SQL Processing
https://docs.oracle.com/en/database/oracle/oracle-database/19/tgsql/sql-processing.html#GUID-B3415175-41F2-4EBB-95CF-5F8B5C39E927

* SELECT 문의 처리과정
1. sql developer 는 SQL 명령문을 전달만 한다.
2. 서버 프로세스가 처리

* 서버 프로세스가 처리 과정
1. Parse (구문 분석) : 컴파일하고 실행할 수 있는 상태까지 만들어주는 작업
   가. Syntax 체크
   나. Semantic 체크 : DB 의 메타자료를 이용해서 권한이 있늕지, 객체의 존재 유무(테이블의 이름이 정확한지, 컬럼 이름이 정확한지) 체크
   다. 컴파일
   라. 컴파일된 코드로 실행계획을 만들고, 최적화를 수행 : 최적화된 실행계획을 만든다.
   마. 소스트리를 만든다. -> 명령어를 실행할 순서를 만든다.
   바. 실행계획은 경로를 만드는데, Index를 탈지, 어떤 경로로 접근하는 것이 가장 비용 효율적일지 결정.
   --> SQL원문, 컴파일된 코드, 실행계획, 소스트리와 같은 결과물이 만들어진다. 이 4가지가 SQL CURSOR 라는 정보이다. 이것이 SQL 실행세트이다.
   --> 같은 SQL은 똑같은 커서가 만들어질 확률이 높다.
   사. Shared Pool에 커서를 만들어 놓음. -> 재활용한다.
       동일한 명령문이 없어서 처음부터 파일 : 하드 파싱
       메모리에 있는 커서 활용 : 소프트 파싱
       명령문이 길면 커서도 크다.
   아. (버퍼캐시) select 문의 실행은 데이터의 읽기 작업이다.
       오라클은 설치하면 다섯번째 파일(USERS)이 우리가 쓰는 파일이다.
       버퍼캐시는 이 데이터 파일을 캐시하는 영역이다.
       여기에 한 블록(8K)이 통째로 올라온다.
       Physical Read : 데이터 파일에서 읽는 거.
       Logical Read : 버퍼캐시에서 읽는 거.
   --> 소프트 파싱, Logical Read 를 높이자.

2. Execution (실행)

3. Fetch (인출)
PGA(Private/Process/Program Global Area)
데이터가 많을때 네트워크로 전달할 때, ....
SELECT 만 Fetch 가 있다.
Insert/Update/Delete 는 없다. (Parse, Execution만 있다.).
Insert 후 입력이 잘 되었는지 확인하려면, Select 해야 보임.
I/U/D는 Redolog 버퍼에 기록했다가, Redolog 파일에 저장한다. 장애시 복구가 목적이다.
- 자동 리커버리: 메모리만 깨지고 디스크는 괜찮을 경우. 인스턴스에만 오류, 디스크 정상.
- 백업: 디스크가 망가질 경우.

성능 튜닝의 제일 처음 -> 메모리 튜닝(커서 재활용률, 버퍼캐시 재활용률)

Optimizer는 최적화를 담당하는 엔진
실행계획이 평소에는 안보임 
*/

show parameter optimizer_mode
/* 이 명령문은 관리자만 실행 가능하다.
매개변수 질의 표시를 실패했습니다. 
*/

/*
권한 변경
1. 관리자 DB로 이동
2. GRANT dba TO C##hr
3. 다시 인사관리 모드로 이동해서 실행
*/

show parameter optimizer_mode
/*
NAME           TYPE   VALUE    
-------------- ------ -------- 
optimizer_mode string ALL_ROWS 
*/

-- 통계: DB가 켜져있을 때 합산되다가, 전원 온/오프시 이전 통계를 버리고, 다시 0부터

-- System 통계(자동수집관리): 자동 관리한다. 10g 부터 만들어졌다. 10g 부터는 자동 수집되고 있다.
-- Object 통계 : 테이블과 인덱스에 대한 통계. 테이블과 인덱스를 객체라고 한다. 11g 부터는 object 통계도 자동.

-- 통계정보 모은걸 그래프로 뽑아주는 프로그램도 있다.
-- 스크립트 2개를 비교하는 프로그램도 있다.

-- AWR(Automatic Workload Repository) : 시스템 자동 통계 수집
--   -> 통계 수집하고, 레파지토리에 저장하고, 기울기가 틔는 이상 시간대에 대한 Advice를 해주기도 함.

/*
객체통계
옵티마이저의 비용 계산에는 system 통계보다 object 통계가 영향을 더 많이 미친다.
통계생성
- ANALYZE [TABLE|INDEX] table_name|index_name
[COMPUTE STATISTICS]
테이블 10개 인덱스 30개 있다면 ANALYZE 명령 40번 실행해야 함.
- DBMS_STATS 패키지 실행
통계확인
- user_tables, user_indexes 에서 확인
- 새로운 통계 생성 시 기존 통계 덮어씀. -> dictionary table 을 업데이트 하는 것이므로.
*/

show parameter optimizer_mode

SELECT table_name, num_rows, blocks, empty_blocks,
       TO_CHAR(last_analyzed, 'yyyy/mm/dd hh24:mi:ss') last_analyze_date
FROM user_tables;
/* last_analyze_date 보면, 어제밤 10시. 11g 부터는 object 통계도 자동.
REGIONS	5	5	0	2025/07/14 22:00:05
COUNTRIES	25			2025/07/14 22:00:05
LOCATIONS	23	5	0	2025/07/16 22:00:09
DEPARTMENTS	27	5	0	2025/07/16 22:00:09
JOBS	19	5	0	2025/07/14 22:00:05
EMPLOYEES	107	5	0	2025/07/15 22:00:09
JOB_HISTORY	10	5	0	2025/07/14 22:00:05
JOB_GRADES	6	5	0	2025/07/16 22:00:09
*/

CREATE TABLE emp
AS
SELECT * FROM employees;
/*
NAME           TYPE   VALUE    
-------------- ------ -------- 
optimizer_mode string ALL_ROWS 

Table EMP이(가) 생성되었습니다.
*/

SELECT table_name, num_rows, blocks, empty_blocks,
       TO_CHAR(last_analyzed, 'yyyy/mm/dd hh24:mi:ss') last_analyze_date
FROM user_tables;
/* EMP 테이블이 바로 들어간 걸 확인할 수 있다. 예전에는 당일 날 안 만들어졌음.
REGIONS	5	5	0	2025/07/14 22:00:05
COUNTRIES	25			2025/07/14 22:00:05
LOCATIONS	23	5	0	2025/07/16 22:00:09
DEPARTMENTS	27	5	0	2025/07/16 22:00:09
JOBS	19	5	0	2025/07/14 22:00:05
EMPLOYEES	107	5	0	2025/07/15 22:00:09
JOB_HISTORY	10	5	0	2025/07/14 22:00:05
JOB_GRADES	6	5	0	2025/07/16 22:00:09
EMP	107	5	0	2025/07/17 14:58:56
*/

DELETE FROM emp
WHERE department_id IN (50, 30); -- 2개 부서의 직원들 삭제
COMMIT;

SELECT table_name, num_rows, blocks, empty_blocks,
       TO_CHAR(last_analyzed, 'yyyy/mm/dd hh24:mi:ss') last_analyze_date
FROM user_tables;
/* 행을 삭제했는데도 EMP 테이블이 업데이트 되지 않음을 확인할 수 있다.
REGIONS	5	5	0	2025/07/14 22:00:05
COUNTRIES	25			2025/07/14 22:00:05
LOCATIONS	23	5	0	2025/07/16 22:00:09
DEPARTMENTS	27	5	0	2025/07/16 22:00:09
JOBS	19	5	0	2025/07/14 22:00:05
EMPLOYEES	107	5	0	2025/07/15 22:00:09
JOB_HISTORY	10	5	0	2025/07/14 22:00:05
JOB_GRADES	6	5	0	2025/07/16 22:00:09
EMP	107	5	0	2025/07/17 14:58:56
*/

/*
예전에는 통계 데이터가 자동 업데이트 안될때는 잘못된 통계 데이터를 사용하게 된다.
*/

-- 개별 테이블의 통계 낼때 예전에는 ANALYZE 많이 사용했다.

ANALYZE TABLE emp COMPUTE STATISTICS;

SELECT table_name, num_rows, blocks, empty_blocks,
       TO_CHAR(last_analyzed, 'yyyy/mm/dd hh24:mi:ss') last_analyze_date
FROM user_tables;
/* 행은 줄었는데, 블럭은 줄지 않음.
REGIONS	5	5	0	2025/07/14 22:00:05
COUNTRIES	25			2025/07/14 22:00:05
LOCATIONS	23	5	0	2025/07/16 22:00:09
DEPARTMENTS	27	5	0	2025/07/16 22:00:09
JOBS	19	5	0	2025/07/14 22:00:05
EMPLOYEES	107	5	0	2025/07/15 22:00:09
JOB_HISTORY	10	5	0	2025/07/14 22:00:05
JOB_GRADES	6	5	0	2025/07/16 22:00:09
EMP	56	5	3	2025/07/17 15:03:36
*/

/*
ANALYZE 명령문은 블럭(io의 최소단위)이 3개 비어있다는 것도 알려줌.
EMP	56	5	3	2025/07/17 15:03:36

dbms stats 는 사용중인 블록만 알려준다.
*/

/*
CREATE TABLE 하면 디스크 상의 블록을 8개 줌.
다쓰면, 블럭을 또 8개 줌.
--> 한 테이블의 정보가 한 블럭에 모으는 방향
데이터가 많이 들어오면
16개씩 줬다가
32개씩 줬다가 함
--> 데이터가 모이게 하는 방침
8개 블럭이 1 EXTENT
*/

ANALYZE TABLE emp DELETE STATISTICS

SELECT table_name, num_rows, blocks, empty_blocks,
       TO_CHAR(last_analyzed, 'yyyy/mm/dd hh24:mi:ss') last_analyze_date
FROM user_tables;
/*
REGIONS	5	5	0	2025/07/14 22:00:05
COUNTRIES	25			2025/07/14 22:00:05
LOCATIONS	23	5	0	2025/07/16 22:00:09
DEPARTMENTS	27	5	0	2025/07/16 22:00:09
JOBS	19	5	0	2025/07/14 22:00:05
EMPLOYEES	107	5	0	2025/07/15 22:00:09
JOB_HISTORY	10	5	0	2025/07/14 22:00:05
JOB_GRADES	6	5	0	2025/07/16 22:00:09
EMP	(null)	(null)	(null)	(null)
*/

-- 지정된 사용자의 모든 객체 통계를 삭제
exec DBMS_STATS.DELETE_SCHEMA_STATS('C##hr');

SELECT table_name, num_rows, blocks, empty_blocks,
       TO_CHAR(last_analyzed, 'yyyy/mm/dd hh24:mi:ss') last_analyze_date
FROM user_tables;
/*
REGIONS				
COUNTRIES				
LOCATIONS				
DEPARTMENTS				
JOBS				
EMPLOYEES				
JOB_HISTORY				
JOB_GRADES				
EMP				
*/

exec DBMS_STATS.GATHER_SCHEMA_STATS('C##hr');

SELECT table_name, num_rows, blocks, empty_blocks,
       TO_CHAR(last_analyzed, 'yyyy/mm/dd hh24:mi:ss') last_analyze_date
FROM user_tables;
/*
REGIONS	5	5	0	2025/07/17 15:10:16
COUNTRIES	25			2025/07/17 15:10:16
LOCATIONS	23	5	0	2025/07/17 15:10:16
DEPARTMENTS	27	5	0	2025/07/17 15:10:16
JOBS	19	5	0	2025/07/17 15:10:16
EMPLOYEES	107	5	0	2025/07/17 15:10:16
JOB_HISTORY	10	5	0	2025/07/17 15:10:16
JOB_GRADES	6	5	0	2025/07/17 15:10:16
EMP	56	5	0	2025/07/17 15:10:16
*/

/*
DBMS_ 는 오라클 설치시 오라클 기본제공 패키지이다.
*/

/*
DESC DBMS_STATS;
--> PROCEDURE
--> FUNCTION
*/

DESC DBMS_STATS;
/*
(전략)
PROCEDURE GATHER_SCHEMA_STATS
  Argument Name             Type                 In/Out Default?
  ------------------------- -------------------- ------ --------
  OWNNAME                   VARCHAR2             IN      
  ESTIMATE_PERCENT          NUMBER               IN     Y
  BLOCK_SAMPLE              PL/SQL BOOLEAN       IN     Y
  METHOD_OPT                VARCHAR2             IN     Y
  DEGREE                    NUMBER               IN     Y
  GRANULARITY               VARCHAR2             IN     Y
  CASCADE                   PL/SQL BOOLEAN       IN     Y
  STATTAB                   VARCHAR2             IN     Y
  STATID                    VARCHAR2             IN     Y
  OPTIONS                   VARCHAR2             IN     Y
  OBJLIST                   TABLE                OUT     
  STATOWN                   VARCHAR2             IN     Y
  NO_INVALIDATE             PL/SQL BOOLEAN       IN     Y
  GATHER_TEMP               PL/SQL BOOLEAN       IN     Y
  GATHER_FIXED              PL/SQL BOOLEAN       IN     Y
  STATTYPE                  VARCHAR2             IN     Y
  FORCE                     PL/SQL BOOLEAN       IN     Y
  OBJ_FILTER_LIST           TABLE                IN     Y

PROCEDURE GATHER_SCHEMA_STATS
  Argument Name             Type                 In/Out Default?
  ------------------------- -------------------- ------ --------
  OWNNAME                   VARCHAR2             IN      
  ESTIMATE_PERCENT          NUMBER               IN     Y
  BLOCK_SAMPLE              PL/SQL BOOLEAN       IN     Y
  METHOD_OPT                VARCHAR2             IN     Y
  DEGREE                    NUMBER               IN     Y
  GRANULARITY               VARCHAR2             IN     Y
  CASCADE                   PL/SQL BOOLEAN       IN     Y
  STATTAB                   VARCHAR2             IN     Y
  STATID                    VARCHAR2             IN     Y
  OPTIONS                   VARCHAR2             IN     Y
  STATOWN                   VARCHAR2             IN     Y
  NO_INVALIDATE             PL/SQL BOOLEAN       IN     Y
  GATHER_TEMP               PL/SQL BOOLEAN       IN     Y
  GATHER_FIXED              PL/SQL BOOLEAN       IN     Y
  STATTYPE                  VARCHAR2             IN     Y
  FORCE                     PL/SQL BOOLEAN       IN     Y
  OBJ_FILTER_LIST           TABLE                IN     Y
(후략)
*/

SELECT *
FROM emp
WHERE EMPLOYEE_ID = 102;
/*
102	Lex	Garcia	LGARCIA	1.515.555.0102	11/01/13	AD_VP	17000		100	90
*/

/*
실행계획
OPTIOINS FULL : 인덱스 만든적 없음. 풀 테이블 스캔.
COST 3 : 낮은게 자원을 덜씀
*/

-- 복제 --> 몇번 실행
INSERT INTO emp
SELECT * FROM emp;
/*
56개 행 이(가) 삽입되었습니다.


112개 행 이(가) 삽입되었습니다.


224개 행 이(가) 삽입되었습니다.


448개 행 이(가) 삽입되었습니다.


896개 행 이(가) 삽입되었습니다.


1,792개 행 이(가) 삽입되었습니다.


3,584개 행 이(가) 삽입되었습니다.


7,168개 행 이(가) 삽입되었습니다.


14,336개 행 이(가) 삽입되었습니다.


28,672개 행 이(가) 삽입되었습니다.


57,344개 행 이(가) 삽입되었습니다.


114,688개 행 이(가) 삽입되었습니다.
*/

UPDATE emp
SET employee_id = rownum;
COMMIT;

SELECT COUNT(*), MIN(employee_id), MAX(employee_id) FROM emp;
/*
229376	1	229376
*/

-- 아무거나 검색
SELECT * FROM emp WHERE employee_id = 34567;

SELECT table_name, num_rows, blocks, empty_blocks,
       TO_CHAR(last_analyzed, 'yyyy/mm/dd hh24:mi:ss') last_analyze_date
FROM user_tables;
/*
REGIONS	5	5	0	2025/07/17 15:10:16
COUNTRIES	25			2025/07/17 15:10:16
LOCATIONS	23	5	0	2025/07/17 15:10:16
DEPARTMENTS	27	5	0	2025/07/17 15:10:16
JOBS	19	5	0	2025/07/17 15:10:16
EMPLOYEES	107	5	0	2025/07/17 15:10:16
JOB_HISTORY	10	5	0	2025/07/17 15:10:16
JOB_GRADES	6	5	0	2025/07/17 15:10:16
EMP	56	5	0	2025/07/17 15:10:16
*/
/* 강사님 PC 데이터
EMP	114688	1255	25	2025/07/17 15:10:16
*/

-- 업데이트 안되어 있으면 ANALYZE ~~~ 로 수동으로 업데이트하면 된다.
-- 오라클 11버전 까지도 자동은 안되었음. 밤에 컴퓨터가 켜져 있어야 했음.

-- 아무거나 쿼리하고 코스트 확인
SELECT * FROM emp WHERE employee_id = 345;
/*
345	Louise	Doran	LDORAN	44.1632.960015	15/12/15	SA_REP	7500	0.3	146	80
*/
/*
강사님 PC 코스트 확인 하면 344
*/

CREATE INDEX emp_id_ix ON emp(employee_id);

SELECT * FROM emp WHERE employee_id = 345;
/*
계획이 코스트 2, INDEX로 바뀜. INDEX 를 추가하니 코스트가 100단위(344)에서 1단위로 줄음
ROWID를 제공해 주는 역할을 인덱스가 함. --> BY INDEX ROWID BATCHED
*/

-- 시스템을 튜닝 메모리 관리로 시작
-- SQL은 인덱스로 시작

exec DBMS_STATS.GATHER_SCHEMA_STATS('C##hr');

SELECT COUNT(*) FROM dba_tables;
/* 여기에는 dictionary 도 포함되어 있다.
2142
*/

-- dba 꺼는 너무 많기 때문에 where 절로 필터링해서 보기도 한다.

-- user 꺼만 보는 방법
SELECT table_name, num_rows, blocks, empty_blocks,
       TO_CHAR(last_analyzed, 'yyyy/mm/dd hh24:mi:ss') last_analyze_date
FROM dba_tables
WHERE OWNER = 'C##HR';
/*
REGIONS	5	5	0	2025/07/17 15:31:16
COUNTRIES	25			2025/07/17 15:31:14
LOCATIONS	23	5	0	2025/07/17 15:31:16
DEPARTMENTS	27	5	0	2025/07/17 15:31:15
JOBS	19	5	0	2025/07/17 15:31:16
EMPLOYEES	107	5	0	2025/07/17 15:31:16
JOB_HISTORY	10	5	0	2025/07/17 15:31:16
JOB_GRADES	6	5	0	2025/07/17 15:31:16
EMP	229376	2389	0	2025/07/17 15:31:15
*/


C:\Users\HIRA>sqlplus c##hr/oracle

SQL> EXPLAIN PLAN FOR
  2  SELECT * FROM EMP
  3  WHERE employee_id = 4567;

해석되었습니다.

SQL> set linesize 300
SQL> SELECT * FROM table(DBMS_XPLAN.DISPLAY);

PLAN_TABLE_OUTPUT
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Plan hash value: 3889782621

-------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name      | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |           |     1 |    70 |     2   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| EMP       |     1 |    70 |     2   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | EMP_ID_IX |     1 |       |     1   (0)| 00:00:01 |
-------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):

PLAN_TABLE_OUTPUT
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------

   2 - access("EMPLOYEE_ID"=4567)

14 행이 선택되었습니다.

SQL> show autotrace
autotrace OFF
SQL> set autotrace traceonly --> 켜긴 켜는데 추적만 하겠다. 이 기능은 sql developer 는 못쓴다.
SQL> SELECT * FROM emp WHERE employee_id = 2;


Execution Plan
----------------------------------------------------------
Plan hash value: 3889782621

-------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name      | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |           |     1 |    70 |     2   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| EMP       |     1 |    70 |     2   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | EMP_ID_IX |     1 |       |     1   (0)| 00:00:01 |
-------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("EMPLOYEE_ID"=2)


Statistics
----------------------------------------------------------
        159  recursive calls
          0  db block gets
        211  consistent gets --> 이게 높게 나오면 이건 버퍼캐시에서 읽었다.
          0  physical reads  --> 이게 높게 나오면 물리적인 IO를 했다.
          0  redo size
       1432  bytes sent via SQL*Net to client
        623  bytes received via SQL*Net from client
          2  SQL*Net roundtrips to/from client
         11  sorts (memory)
          0  sorts (disk)
          1  rows processed

SQL> SELECT * FROM emp WHERE employee_id = 89072
  2  ;


Execution Plan
----------------------------------------------------------
Plan hash value: 3889782621

-------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name      | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |           |     1 |    70 |     2   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| EMP       |     1 |    70 |     2   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | EMP_ID_IX |     1 |       |     1   (0)| 00:00:01 |
-------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("EMPLOYEE_ID"=89072)


Statistics
----------------------------------------------------------
          1  recursive calls
          0  db block gets
          4  consistent gets
          0  physical reads  --> 강사님 컴퓨터에서는 이게 1이었음. 물리 디스크에서도 읽었다.
          0  redo size
       1434  bytes sent via SQL*Net to client
        623  bytes received via SQL*Net from client
          2  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
          1  rows processed

SQL> set autotrace on
SQL> SELECT * FROM emp WHERE employee_id = 12345;

EMPLOYEE_ID FIRST_NAME                               LAST_NAME                                          EMAIL                                              PHONE_NUMBER
            HIRE_DAT JOB_ID                   SALARY COMMISSION_PCT MANAGER_ID DEPARTMENT_ID
----------- ---------------------------------------- -------------------------------------------------- -------------------------------------------------- ---------------------------------------- -------- -------------------- ---------- -------------- ---------- -------------
      12345 Harrison                                 Bloom                                              HBLOOM                                             44.1632.960024
            16/03/23 SA_REP                    10000             .2        148            80


Execution Plan
----------------------------------------------------------
Plan hash value: 3889782621

-------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name      | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |           |     1 |    70 |     2   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| EMP       |     1 |    70 |     2   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | EMP_ID_IX |     1 |       |     1   (0)| 00:00:01 |
-------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("EMPLOYEE_ID"=12345)


Statistics
----------------------------------------------------------
        127  recursive calls
          0  db block gets
        209  consistent gets
          0  physical reads
          0  redo size
       1442  bytes sent via SQL*Net to client
        623  bytes received via SQL*Net from client
          2  SQL*Net roundtrips to/from client
         11  sorts (memory)
          0  sorts (disk)
          1  rows processed

SQL>

/*
--> EXPLAIN PLAN FOR : 파싱만 함. 실행 안함. 파싱 과정에서 만들어진 플랜만 보기 위함.
--> AUTOTRACE : 실행과 계획을 보여줌.
--> 위 두 도구의 결과가 차이가 날 수 있다.

-- 11 버전 까지는 플랜 테이블을 만들기도 했다.

C:\app\HIRA\product\18.0.0\dbhomeXE\rdbms\admin
utlxplan.sql : 니가 만든 실행계획을 (   )에 심어놔라.
-- 12c(?) 부터는 플랜 테이블이 DB 안에 공용으로 하나 있다. 안 만들어도 된다.
*/

-- V$SQL_PLAN
-- 먼저, 
현재 메모리의 SQL 정보를 보여주는 DICTIONARY가 몇개 있다.

리커시브 SQL : select 권한을 볼때 오라클이 select 를 한다. 그래서, 우리가 실행한 것보다 더 많은 sql 이 있다.
그래서 튜닝할 때 먼저 메모리를 비우고 테스트한다.

alter system flush shared_pool;
/* 메모리 한번 씻음. / 버퍼 캐시도 지울 수 있다.(비우고, autotrace 에서 물리IO 확인할 때 유용하다고 함.)
System이(가) 변경되었습니다.
*/

SELECT employee_id, last_name, salary
FROM employees
WHERE employee_id = 108;
SELECT employee_id, last_name, salary
FROM employees
WHERE employee_id = 202;
SELECT employee_id, last_name, salary
FROM employees
WHERE employee_id = 108;
SELECT employee_id, last_name, salary
FROM employees
WHERE employee_id = 108;
SELECT employee_id, last_name, salary
FROM employees
WHERE employee_id = 108;
SELECT employee_id, last_name, salary
FROM employees
WHERE employee_id = 108;
SELECT employee_id, last_name, salary
FROM employees
WHERE employee_id = 108;
SELECT employee_id, last_name, salary
FROM employees
WHERE employee_id = 108;
SELECT employee_id, last_name, salary
FROM employees
WHERE employee_id = 108;
SELECT employee_id, last_name, salary
FROM employees
WHERE employee_id = 108;
SELECT employee_id, last_name, salary
FROM employees
WHERE employee_id = 108;
SELECT employee_id, last_name, salary
FROM employees
WHERE employee_id = 108;
SELECT employee_id, last_name, salary
FROM employees
where employee_id = 108;
SELECT employee_id, last_name, salary
FROM employees
WHERE EMPLOYEE_ID = 108;

-- 가장 기본적인 커서 공유를 모니터링하는 방법. 이 정보는 커서가 메모리에 있을때 보여주는 정보이다.
SELECT sql_text, executions FROM v$sql
WHERE sql_text LIKE 'SELECT employee_id%'
OR sql_text LIKE 'select employee_id%';
/* 커서는 4가지 세트이다. 커서에 저장되어 있는 텍스트는 다음과 같다. 조금이라도 다르면, 서로 다르게 파싱한다. 상수는 변수 처리하면 좋다. 코딩 표준을 만드는 것이 좋다.
SELECT employee_id, last_name, salary FROM employees WHERE employee_id = 202	1
SELECT employee_id, last_name, salary FROM employees WHERE employee_id = 108	11
SELECT employee_id, last_name, salary FROM employees WHERE EMPLOYEE_ID = 108	1
SELECT employee_id, last_name, salary FROM employees where employee_id = 108	1
*/

alter system flush shared_pool;

-- 이 정보는 커서가 메모리에 있을때 보여주는 정보이다. 사용 빈도가 낮은 애를 지운다.(LRU). 내가 보고 싶은 커서를 못 볼 수도 있다.
SELECT sql_text, executions FROM v$sql
WHERE sql_text LIKE 'SELECT employee_id%'
OR sql_text LIKE 'select employee_id%';
/*
*/

SELECT employee_id, last_name, first_name, department_name
FROM employees e JOIN departments d
ON e.department_id = d.department_id
AND last_name LIKE 'T%'
ORDER BY last_name;
/*
176	Taylor	Jonathon	Sales
180	Taylor	Winston	Shipping
117	Tobias	Sigal	Purchasing
150	Tucker	Sean	Sales
155	Tuvault	Oliver	Sales
*/

-- 메모리(쉐어드풀)의 주소: hash_value, address
-- 커서가 있는 메모리 주소 보는 방법
SELECT sql_text, hash_value, address
FROM v$sql
WHERE sql_text LIKE 'SELECT employee_id%';
/* hash_value: 117210874	address: 00007FFF6BE524A8
SELECT employee_id, last_name, first_name, department_name FROM employees e JOIN departments d ON e.department_id = d.department_id AND last_name LIKE 'T%' ORDER BY last_name	117210874	00007FFF6BE524A8
*/

SELECT id, lpad (' ', depth) || operation operation, options , object_name ,
optimizer, cost
FROM V$SQL_PLAN
WHERE hash_value = 117210874
AND address = '00007FFF6BE524A8'
START WITH id = 0
CONNECT BY
( prior id = parent_id
AND prior hash_value = hash_value
AND prior child_number = child_number
)
ORDER SIBLINGS BY id, position;
/* 이것도 실제 실행한 계획이다. 메모리에 커서가 있을 때만 유효. 실시간 정보. 약간 현황 같은 거임.
0	SELECT STATEMENT			ALL_ROWS	7
1	 SORT	ORDER BY			7
2	  MERGE JOIN				6
3	   TABLE ACCESS	BY INDEX ROWID	DEPARTMENTS		2
4	    INDEX	FULL SCAN	SYS_C007306		1
5	   SORT	JOIN			4
6	    TABLE ACCESS	FULL	EMPLOYEES		3
*/

DESC v$session;
/* BLOCKING: 락 때문에 차단되었다
이름                            널? 유형             
----------------------------- -- -------------- 
BLOCKING_SESSION_STATUS          VARCHAR2(11)   
BLOCKING_INSTANCE                NUMBER         
BLOCKING_SESSION                 NUMBER         
FINAL_BLOCKING_SESSION_STATUS    VARCHAR2(11)   
FINAL_BLOCKING_INSTANCE          NUMBER         
FINAL_BLOCKING_SESSION           NUMBER         
*/

HR(SQL DEVELOPER 1)               HR(SQL DEVELOPER 2)
서버에 동시 실행
update where employee_id = 101;
                                  update where employee_id = 103;
update where employee_id = 103;
/*
2번째 103을 기다림. 이걸 blocking session 이라고 하고, 2를 blocker 라고 한다.
오라클 동시 락 단위가 행이다.
만약, 2시간 후 2가 해제되었다면, 차단을 해결하고 나면 사라지고 없어짐.(?무슨말)
v$active_session_hisotory
시스템에서 배치잡 처리할 때 이런일 많이 일어난다.
보통 고객 등급 조정 작업이 매달 말일 일어남.
이벤트로 각 고객의 계정에 이벤트 계정 2000원 주는 작업하고 퇴근.
한쪽은 고객의 등급 조정하는 작업을 하고 퇴근.
일정시간 응답 없으면 타임아웃.
한 작업은 락 때문에 대기를 타다가 프로그램이 종료될 수 있다.
적립급 2000원 준다고 했는데, 왜 안줘요-?
락문제는 모니터링 할때 많이 쓰이기도 함.
*/

-- 애플리케이션 추적

-- 파라미터 확인
show parameter sql_trace;
/* 평소에는 꺼두는게 좋다. 이걸 켜놓으면, 우리가 입력한 SQL이 추적된다.
NAME      TYPE    VALUE 
--------- ------- ----- 
sql_trace boolean FALSE 
*/

-- 지금부터 활성화
alter system set ......;

-- 현재 세션에서만 활성화
alter session set sql_trace = true;
/*

Session이(가) 변경되었습니다.
*/

-- 추적 파일이 저장되는 경로에 추적 파일이 만들어진다.
select value from v$diag_info where name = 'Default Trace File';
/*
C:\APP\HIRA\PRODUCT\18.0.0\diag\rdbms\xe\xe\trace\xe_ora_9060.trc
*/

-- 다음 위치의 파일을 모두 지운다.
C:\APP\HIRA\PRODUCT\18.0.0\diag\rdbms\xe\xe\trace\

-- 파일이 많다. SQL 추적이 꺼져 있는 것이지, 시스템 추적은 켜져있다.

SELECT employee_id, last_name, first_name, department_name
FROM employees e JOIN departments d
ON e.department_id = d.department_id
AND last_name LIKE 'T%'
ORDER BY last_name;
/*
176	Taylor	Jonathon	Sales
180	Taylor	Winston	Shipping
117	Tobias	Sigal	Purchasing
150	Tucker	Sean	Sales
155	Tuvault	Oliver	Sales
*/

SELECT *
FROM emp
WHERE employee_id=1234;
/*
1234	Amit	Banda	ABANDA	44.1632.960022	18/04/21	SA_REP	6200	0.1	147	80
*/

select value from v$diag_info where name = 'Default Trace File';
/* 이 파일이 없음. 파일을 지우고 활성화 했어야 함.
C:\APP\HIRA\PRODUCT\18.0.0\diag\rdbms\xe\xe\trace\xe_ora_9060.trc
*/

-- 세션 바꾸자 : 인사관리 접속 해제 후 재접속. 다시

alter session set sql_trace = true;
/*
NAME      TYPE    VALUE 
--------- ------- ----- 
sql_trace boolean TRUE  

Session이(가) 변경되었습니다.
*/

select value from v$diag_info where name = 'Default Trace File';
/* 트레이스 파일이 생성된 것을 확인
C:\APP\HIRA\PRODUCT\18.0.0\diag\rdbms\xe\xe\trace\xe_ora_9524.trc
*/

SELECT employee_id, last_name, first_name, department_name
FROM employees e JOIN departments d
ON e.department_id = d.department_id
AND last_name LIKE 'T%'
ORDER BY last_name;

SELECT *
FROM emp
WHERE employee_id=1234;

-- 트레이스는 cmd 에서만 지원됨
C:\app\HIRA\product\18.0.0\diag\rdbms\xe\xe\trace>tkprof xe_ora_9524.trc sys=no waits=yes output=mytrc.txt

TKPROF: Release 18.0.0.0.0 - Development on 목 7월 17 17:39:20 2025

Copyright (c) 1982, 2019, Oracle and/or its affiliates.  All rights reserved.



C:\app\HIRA\product\18.0.0\diag\rdbms\xe\xe\trace>type mytrc.txt

TKPROF: Release 18.0.0.0.0 - Development on 목 7월 17 17:39:20 2025

Copyright (c) 1982, 2019, Oracle and/or its affiliates.  All rights reserved.

Trace file: xe_ora_9524.trc
Sort options: default

********************************************************************************
count    = number of times OCI procedure was executed
cpu      = cpu time in seconds executing
elapsed  = elapsed time in seconds executing
disk     = number of physical reads of buffers from disk
query    = number of buffers gotten for consistent read
current  = number of buffers gotten in current mode (usually for update)
rows     = number of rows processed by the fetch or execute call
********************************************************************************

SQL ID: 0gjpt6cdt5vxb Plan Hash: 1636480816

select value
from
 v$diag_info where name = 'Default Trace File'


call     count       cpu    elapsed       disk      query    current        rows
------- ------  -------- ---------- ---------- ---------- ----------  ----------
Parse        1      0.00       0.00          0          0          0           0
Execute      1      0.00       0.00          0          0          0           0
Fetch        1      0.01       0.01          0          0          0           1
------- ------  -------- ---------- ---------- ---------- ----------  ----------
total        3      0.01       0.01          0          0          0           1

Misses in library cache during parse: 0
Optimizer mode: ALL_ROWS
Parsing user id: 101
Number of plan statistics captured: 1

Rows (1st) Rows (avg) Rows (max)  Row Source Operation
---------- ---------- ----------  ---------------------------------------------------
         1          1          1  FIXED TABLE FULL X$DIAG_INFO (cr=0 pr=0 pw=0 time=15181 us starts=1 cost=0 size=57 card=1)

********************************************************************************

SELECT employee_id, last_name, first_name, department_name
FROM employees e JOIN departments d
ON e.department_id = d.department_id
AND last_name LIKE 'T%'
ORDER BY last_name

call     count       cpu    elapsed       disk      query    current        rows
------- ------  -------- ---------- ---------- ---------- ----------  ----------
Parse        1      0.01       0.02          0          0          0           0
Execute      1      0.00       0.00          0          0          0           0
Fetch        1      0.00       0.00          0          8          0           5
------- ------  -------- ---------- ---------- ---------- ----------  ----------
total        3      0.01       0.02          0          8          0           5

Misses in library cache during parse: 1
Optimizer mode: ALL_ROWS
Parsing user id: 101
Number of plan statistics captured: 1

Rows (1st) Rows (avg) Rows (max)  Row Source Operation
---------- ---------- ----------  ---------------------------------------------------
         5          5          5  SORT ORDER BY (cr=8 pr=0 pw=0 time=78 us starts=1 cost=7 size=185 card=5)
         5          5          5   MERGE JOIN  (cr=8 pr=0 pw=0 time=72 us starts=1 cost=6 size=185 card=5)
         9          9          9    TABLE ACCESS BY INDEX ROWID DEPARTMENTS (cr=2 pr=0 pw=0 time=22 us starts=1 cost=2 size=432 card=27)
         9          9          9     INDEX FULL SCAN SYS_C007306 (cr=1 pr=0 pw=0 time=15 us starts=1 cost=1 size=0 card=27)(object id 73576)
         5          5          5    SORT JOIN (cr=6 pr=0 pw=0 time=48 us starts=9 cost=4 size=105 card=5)
         5          5          5     TABLE ACCESS FULL EMPLOYEES (cr=6 pr=0 pw=0 time=36 us starts=1 cost=3 size=105 card=5)

********************************************************************************

SELECT *
FROM emp
WHERE employee_id=1234

call     count       cpu    elapsed       disk      query    current        rows
------- ------  -------- ---------- ---------- ---------- ----------  ----------
Parse        1      0.01       0.00          0          0          0           0
Execute      1      0.00       0.00          0          0          0           0
Fetch        1      0.00       0.00          0          3          0           1
------- ------  -------- ---------- ---------- ---------- ----------  ----------
total        3      0.01       0.00          0          3          0           1

Misses in library cache during parse: 1
Optimizer mode: ALL_ROWS
Parsing user id: 101
Number of plan statistics captured: 1

Rows (1st) Rows (avg) Rows (max)  Row Source Operation
---------- ---------- ----------  ---------------------------------------------------
         1          1          1  TABLE ACCESS BY INDEX ROWID BATCHED EMP (cr=3 pr=0 pw=0 time=16 us starts=1 cost=2 size=70 card=1)
         1          1          1   INDEX RANGE SCAN EMP_ID_IX (cr=2 pr=0 pw=0 time=12 us starts=1 cost=1 size=0 card=1)(object id 74125)




********************************************************************************

OVERALL TOTALS FOR ALL NON-RECURSIVE STATEMENTS

call     count       cpu    elapsed       disk      query    current        rows
------- ------  -------- ---------- ---------- ---------- ----------  ----------
Parse        3      0.03       0.03          0          0          0           0
Execute      3      0.00       0.00          0          0          0           0
Fetch        3      0.01       0.01          0         11          0           7
------- ------  -------- ---------- ---------- ---------- ----------  ----------
total        9      0.04       0.04          0         11          0           7

Misses in library cache during parse: 2


OVERALL TOTALS FOR ALL RECURSIVE STATEMENTS

call     count       cpu    elapsed       disk      query    current        rows
------- ------  -------- ---------- ---------- ---------- ----------  ----------
Parse        6      0.01       0.01          0          0          0           0
Execute    194      0.01       0.01          0          0          0           0
Fetch      312      0.01       0.00          0        650          0        1081
------- ------  -------- ---------- ---------- ---------- ----------  ----------
total      512      0.04       0.03          0        650          0        1081

Misses in library cache during parse: 3
Misses in library cache during execute: 3

    3  user  SQL statements in session.
   28  internal SQL statements in session.
   31  SQL statements in session.
********************************************************************************
Trace file: xe_ora_9524.trc
Trace file compatibility: 12.2.0.0
Sort options: default

       1  session in tracefile.
       3  user  SQL statements in trace file.
      28  internal SQL statements in trace file.
      31  SQL statements in trace file.
      31  unique SQL statements in trace file.
     899  lines in trace file.
     150  elapsed seconds in trace file.



C:\app\HIRA\product\18.0.0\diag\rdbms\xe\xe\trace>

-- tkprof xe_ora_9524.trc sys=no waits=yes output=mytrc.txt
-- sysno : 시스템 정보는 제거
