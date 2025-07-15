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
