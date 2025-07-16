/*
관계형은 계층형 데이터 표현에는 약하다
Windows 탐색기와 같은 데이터 표현에 좋다
오라클은 이를 표현할 수 있는 쿼리를 만들었다.
이를 '계층 쿼리'라고 한다.

예) 사장 > 부장 > 과장 -> 계층
*/

/*
UNION ALL 합집합을 하면서 교집합을 제거하지 않는 UNION

select 문장 하나의 결과가 1집합.
그러므로, 집합 연산은 2개의 select 문이 있어야 한다.

JOB_HISTORY 테이블
*/

SELECT employee_id FROM employees
UNION
SELECT employee_id FROM job_history;
/* 107개 나옴 : employees 107개 UNION job_history 10개 => 107개(중복제거)
100
101
(후략)
*/

-- UNION 1번째 컬럼 기준으로 정렬됨.
-- ORDER BY 절을 쓴다면 어디에?
SELECT employee_id, job_id FROM employees
UNION
SELECT employee_id, job_id FROM job_history;
/* 107개 나옴 : employees 107개 UNION job_history 10개
               => 115개(중복이 덜 되었다, 사번은 같지만, 잡ID는 다른 경우가 있다)
ORA-01789: 질의 블록은 부정확한 수의 결과 열을 가지고 있습니다.
*/

-- UNION 수행시 1번째 컬럼 정렬, ORDER By 에서 1번째 컬럼 또 정렬 => 안 좋음
SELECT employee_id, job_id FROM employees
UNION
SELECT employee_id, job_id FROM job_history
ORDER BY 1;

-- 첫번째 SELECT 문의 별칭이 헤드로 선택된다.
SELECT employee_id 사원번호, job_id FROM employees
UNION
SELECT employee_id, job_id 업무코드 FROM job_history;
/*
사원번호    JOB_ID
100	AD_PRES
101	AC_ACCOUNT
*/

-- 컬럼 개수만 맞추고 데이터 타입이 안맞을 경우 --> 오류 --> 데이터 타입이 같아야 한다.
-- ORA-01790: 대응하는 식과 같은 데이터 유형이어야 합니다
SELECT employee_id 사원번호, salary FROM employees
UNION
SELECT employee_id, job_id FROM job_history;

-- 집합 연산의 문법적 설명
-- 1.
-- 2.
-- 3. 

-- 이 업무를 하다가 옮겼다가 다시 이 업무로 돌아간 사람
SELECT employee_id, job_id FROM employees
INTERSECT
SELECT employee_id, job_id FROM job_history;
/*
176	SA_REP
200	AD_ASST
*/

-- 입사 후 부서 이동이 없었던 사람
SELECT employee_id FROM employees
MINUS
SELECT employee_id FROM job_history;
/* 100건
(생략)
*/

-- 퇴사한 직원: 현재에는 사번이 없는데 job_history에 사번이 있는 경우
SELECT employee_id FROM job_history
MINUS
SELECT employee_id FROM employees;
/* 0건
*/

-- 중복을 제거하지 않고 합친 것. 중복을 제거하지 않으려고 하다보니 정렬도 불필요.
-- 결과 데이터가 정렬되지 않음.
SELECT employee_id FROM employees
UNION ALL
SELECT employee_id FROM job_history;

-- JOIN, 정렬 등 사용하여 메모리 많이 먹거나 성능 저하 -> TOP SQL -> SQL 튜닝

-- 어차피 중복이 없다면 UNION, UNION ALL 어느걸 써도 결과가 같다.
-- 이 경우 UNION ALL 사용.

-- 임의로 데이터 개수와 타입을 맞추는 방법
SELECT employee_id, job_id, 1111 FROM job_history
UNION ALL
SELECT employee_id, job_id, salary FROM employees;
/* 117건
200	AC_ACCOUNT	1111
100	AD_PRES	24000
*/

-- 컬럼 개수는 맞는 데 위는 날짜, 아래는 숫자
SELECT department_id, hire_date FROM employees
UNION
SELECT department_id, location_id FROM departments;
/*
ORA-01790: 대응하는 식과 같은 데이터 유형이어야 합니다
*/

-- 컬럼개수와 데이터 타입 맞추기
SELECT department_id, hire_date, TO_NUMBER(null) location_id FROM employees
UNION
SELECT department_id, TO_DATE(null), location_id FROM departments;


-- 사원테이블 전체의 평균 급여를 정수로 출력 (전체 사원의 평균 급여)
SELECT TRUNC(AVG(salary)) FROM employees;

-- 부서별 평균 급여를 정수로 출력
SELECT department_id, TRUNC(AVG(salary)) FROM employees GROUP BY department_id;

-- 부서별 업무별 평균 급여를 정수로 출력
SELECT department_id, job_id, TRUNC(AVG(salary)) FROM employees GROUP BY department_id, job_id;

-- 위 3개의 문장으로 ROLLUP 동작 구현 (성능은 ROLLUP 이 좋음)
SELECT department_id, job_id, TRUNC(AVG(salary)) FROM employees GROUP BY department_id, job_id
UNION ALL
SELECT department_id, TO_CHAR(null), TRUNC(AVG(salary)) FROM employees GROUP BY department_id
UNION ALL
SELECT TO_NUMBER(null), TO_CHAR(null), TRUNC(AVG(salary)) FROM employees
ORDER BY 1, 2;


SELECT employee_id, last_name, manager_id
FROM employees
START WITH employee_id = 100
CONNECT BY PRIOR employee_id = manager_id;
/*
100	King	
101	Yang	100
108	Gruenberg	101
109	Faviet	108
110	Chen	108
111	Sciarra	108
112	Urman	108
113	Popp	108
200	Whalen	101
203	Jacobs	101
204	Brown	101
205	Higgins	101
206	Gietz	205
102	Garcia	100
103	James	102
104	Miller	103
(후략)
*/

/*
START WITH : 검색을 시작할 위치. 트리를 검색하는 시작점을 결정. 트리의 루트로 사용될.
CONNECT BY : 검색의 방향 결정: 탑다운, 바텀업

탑다운 : 자신의 이전(PRIOR) 행이 상사
*/

-- 2025-07-16

-- King 이 2개 나온다 -> START WITH 를 잘 지정해야 한다.
SELECT employee_id, first_name, last_name, manager_id
FROM employees
START WITH last_name = 'King'
CONNECT BY PRIOR employee_id = manager_id ;

-- employee_id 는 PK
SELECT employee_id, first_name, last_name, manager_id
FROM employees
START WITH employee_id = 100
CONNECT BY PRIOR employee_id = manager_id ;

-- manager_id 가 없는 사람을 사장으로 하겠다.
SELECT employee_id, first_name, last_name, manager_id
FROM employees
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id ;

-- BOTTOM-UP
-- 이전 행의 매니저 번호가 현재 행의 사원 번호
SELECT employee_id, first_name, last_name, manager_id
FROM employees
START WITH employee_id = 143
CONNECT BY employee_id = PRIOR manager_id ;
/*
143	Randall	Matos	124
124	Kevin	Mourgos	100
100	Steven	King	
*/

/*
Level 의사열(Pseudo Column)
오라클이 내부적으로 구현해 놓은 보이지 않는 컬럼으로 SELECT 절에 쓰면 나타남. DESC 명령에서는 안나옴.

rounum : 오라클이 행을 배치해준 순서
rowid : 실제 행의 위치를 나타내는 값
level --> 계층쿼리에서만 사용 가능
*/

SELECT employee_id, last_name, rowid FROM employees;

/*
ROWID
000000FFFBBBBBBRRR
객체번호, 파일번호, 블록 ID, 행번호

data dictionary = catalog

파일번호: UNDOTBS01.DBF 파일의 번호

DB블록 한블록당 8K



*/

-- OBJECT_ID 확인
DESC user_objects
/*
이름                널? 유형            
----------------- -- ------------- 
OBJECT_NAME          VARCHAR2(128) 
SUBOBJECT_NAME       VARCHAR2(128) 
OBJECT_ID            NUMBER        
DATA_OBJECT_ID       NUMBER        
OBJECT_TYPE          VARCHAR2(23)  
CREATED              DATE          
LAST_DDL_TIME        DATE          
TIMESTAMP            VARCHAR2(19)  
STATUS               VARCHAR2(7)   
TEMPORARY            VARCHAR2(1)   
GENERATED            VARCHAR2(1)   
SECONDARY            VARCHAR2(1)   
NAMESPACE            NUMBER        
EDITION_NAME         VARCHAR2(128) 
SHARING              VARCHAR2(18)  
EDITIONABLE          VARCHAR2(1)   
ORACLE_MAINTAINED    VARCHAR2(1)   
APPLICATION          VARCHAR2(1)   
DEFAULT_COLLATION    VARCHAR2(100) 
DUPLICATED           VARCHAR2(1)   
SHARDED              VARCHAR2(1)   
CREATED_APPID        NUMBER        
CREATED_VSNID        NUMBER        
MODIFIED_APPID       NUMBER        
MODIFIED_VSNID       NUMBER        
*/

-- EMPLOYEES 테이블의 OBJECT_ID 확인
SELECT object_id, object_name FROM user_objects;
/*
73569	REGIONS
73570	REG_ID_PK
73571	COUNTRIES
73572	COUNTRY_C_ID_PK
73573	LOCATIONS
73574	SYS_C007304
73575	DEPARTMENTS
73576	SYS_C007306
73577	JOBS
73578	SYS_C007308
73579	EMPLOYEES
73580	EMP_EMPID_PK
73581	EMP_EMAIL_UK
73582	JOB_HISTORY
73583	JHIST_EMP_ID_ST_DATE_PK
73584	JOB_GRADES
*/

/*
C:\app\HIRA\product\18.0.0\oradata\XE\*.DBF 가 데이터 파일
SYSAUX01.DBF -> 시스템꺼
SYSTEM01.DBF -> 시스템꺼
TEMP01.DBF -> 시스템꺼
UNDOTBS01.DBF -> 내꺼
*/

/*
DB블록 한블록당 8K
블록번호가 같은 건 한 블록에 있음
*/

DESC DEPARTMENTS
/*
이름              널?       유형           
--------------- -------- ------------ 
DEPARTMENT_ID   NOT NULL NUMBER(4)    
DEPARTMENT_NAME NOT NULL VARCHAR2(30) 
MANAGER_ID               NUMBER(6)    
LOCATION_ID              NUMBER(4)    
*/

-- 행을 액세스하는 가정 빠른 방법
SELECT employee_id, last_name, rowid FROM employees WHERE rowid = 'AAAR9rAAHAAAADOAAA';

SELECT 'DEPT' , department_id, department_name, rowid FROM departments
UNION ALL
SELECT 'EMP', employee_id, last_name, rowid FROM employees
ORDER BY ROWID;

-- level 1 밑에 2, 2 밑에 3, ...
-- level 은 계층 쿼리에서만 유효
SELECT employee_id, first_name, last_name, manager_id, level
FROM employees
START WITH employee_id = 100
CONNECT BY PRIOR employee_id = manager_id ;

SELECT employee_id, first_name, last_name, manager_id, level
FROM employees
START WITH employee_id = 100
CONNECT BY PRIOR employee_id = manager_id ;

-- 레벨이 낮아질 수록 2칸씩 들여쓰기
SELECT LPAD(last_name, LENGTH(last_name)+(LEVEL*2)-2,'_') AS org_chart
FROM employees
START WITH employee_id = 100
CONNECT BY PRIOR employee_id=manager_id;

-- SYS_CONNECT_BY_PATH : 경로를 보여줌
-- CONNECT_BY_ROOT : 루트가 뭔지 표시해줌

-- FROM 절 아래에 WHERE 절을 써서 특정 사원에 대한 정보를 제외
SELECT LPAD(last_name, LENGTH(last_name)+(LEVEL*2)-2,'_') AS org_chart
FROM employees
WHERE employee_id <> 101
START WITH employee_id = 100
CONNECT BY PRIOR employee_id=manager_id;

SELECT LPAD(last_name, LENGTH(last_name)+(LEVEL*2)-2,'_') AS org_chart
FROM employees
START WITH employee_id = 100
CONNECT BY PRIOR employee_id=manager_id
AND employee_id <> 101;