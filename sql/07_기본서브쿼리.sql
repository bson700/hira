-- 07 기본 서브쿼리

-- Abel 보다 급여가 많은 직원을 알기 위해 다음 두 문장 필요

SELECT salary FROM employees
WHERE last_name = 'Abel';
/*
11000
*/
SELECT *
FROM employees
WHERE salary > 11000;

-- 서브쿼리를 사용하여 같은 결과를 얻을 수 있다.
-- 서브쿼리는 값 대신 쓰일 수 있다.
-- 주로 where 절에서 값 대신에 쓰인다.
-- having 절에도 쓸 수 있다.
-- select 절에도 쓸 수 있다.
-- from 절에도 올 수 있다. -> in-line view
-- order by 절에도 올 수 있다.
-- group by 절에는 올 수 없다.
SELECT *
FROM employees
WHERE salary > (SELECT salary FROM employees
                WHERE last_name = 'Abel');

-- Abel 과 같은 급여 조회. Abel 자신도 나옴.
SELECT *
FROM employees
WHERE salary = (SELECT salary FROM employees
                WHERE last_name = 'Abel');

-- Abel 과 같은 급여 조회. Abel 자신은 제외
SELECT *
FROM employees
WHERE salary = (SELECT salary FROM employees
                WHERE last_name = 'Abel')
AND last_name <> 'Abel';


-- 단일행 서브쿼리
-- job_id = ST_CLERK AND salary > 2600
SELECT last_name, job_id, salary
FROM employees
WHERE job_id = (SELECT job_id
                FROM employees
                WHERE employee_id = 141)
AND salary > (SELECT salary
              FROM employees
              WHERE employee_id = 143);


SELECT last_name, job_id, salary
FROM employees
WHERE salary = (SELECT MIN(salary)
                FROM employees);
/*
Olson	ST_CLERK	2100
*/

-- 회사의 평균 급여보다 급여가 많은 사람 조회
SELECT last_name, job_id, salary
FROM employees
WHERE salary > (SELECT AVG(salary)
                FROM employees);




-- 50번 부서의 최소 급여 보다 최소 급여가 많은 부서
SELECT department_id, MIN(salary)
FROM employees
GROUP BY department_id
HAVING MIN(salary) > (SELECT MIN(salary)
                      FROM employees
                      WHERE department_id = 50);

-- 다중행 서브쿼리
SELECT employee_id, last_name
FROM employees
WHERE salary = (SELECT MIN(salary)
                FROM employees
                GROUP BY department_id);
/*
ORA-01427: 단일 행 하위 질의에 2개 이상의 행이 리턴되었습니다.
*/

-- IN 사용
SELECT employee_id, last_name
FROM employees
WHERE salary IN (SELECT MIN(salary)
                 FROM employees
                 GROUP BY department_id);

-- 303번 사번 없다.
SELECT employee_id, last_name
FROM employees
WHERE salary IN (SELECT salary FROM employees WHERE employee_id = 303);

-- 303번 ID 가 없다.
SELECT employee_id, last_name
FROM employees
WHERE manager_id IN (SELECT manager_id FROM employees WHERE employee_id = 303);
/*
subquery 가 null 이면, manager_id is null 인게 있어도 결과가 안나온다.
개발할 때는 subquery 먼저 실행 후 결과를 확인하는 것 이 좋다.
*/

-- IT 부서 직원들의 급여. 
SELECT salary
FROM employees
WHERE job_id LIKE 'IT%';
/*
9000
6000
4800
4800
4200
*/

-- IT 직원보다 급여가 높은 사람. IT 부서는 제외
SELECT employee_id, last_name, salary, job_id
FROM employees
WHERE salary > (SELECT salary
                FROM employees
                WHERE job_id LIKE 'IT%')
AND job_id NOT LIKE 'IT%'; -- IT 부서는 제외


-- ANY 는 최소값인 4200보다 크면 됨.
SELECT employee_id, last_name, salary, job_id
FROM employees
WHERE salary > ANY (SELECT salary
                FROM employees
                WHERE job_id LIKE 'IT%')
AND job_id NOT LIKE 'IT%'; -- IT 부서는 제외

-- ALL 은 모두를 만족하므로, 최대값 9000보다 큼.
SELECT employee_id, last_name, salary, job_id
FROM employees
WHERE salary > ALL (SELECT salary
                FROM employees
                WHERE job_id LIKE 'IT%')
AND job_id NOT LIKE 'IT%'; -- IT 부서는 제외

-- 9000 보다 작은 거 출력
SELECT employee_id, last_name, salary, job_id
FROM employees
WHERE salary < ANY (SELECT salary
                FROM employees
                WHERE job_id LIKE 'IT%')
AND job_id NOT LIKE 'IT%'; -- IT 부서는 제외

-- 4200보다 작은 거 출력
SELECT employee_id, last_name, salary, job_id
FROM employees
WHERE salary < ALL (SELECT salary
                FROM employees
                WHERE job_id LIKE 'IT%')
AND job_id NOT LIKE 'IT%'; -- IT 부서는 제외

-- IN --> =ANY
-- NOT IN --> <>ALL


-- manager 급의 직원들을 보고 싶음.
SELECT emp.employee_id, emp.last_name
FROM employees emp
WHERE emp.employee_id IN (SELECT mgr.manager_id
                          FROM employees mgr);
                          
-- 부하직원들이 없는 사원 -> 말단직원
SELECT emp.employee_id, emp.last_name
FROM employees emp
WHERE emp.employee_id NOT IN (SELECT mgr.manager_id
                              FROM employees mgr);
/* 아무것도 안나옴
*/

-- 결과에 manager_id 가 NULL 인 사람은 안나온다.
SELECT emp.employee_id, emp.last_name, emp.manager_id
FROM employees emp
WHERE emp.manager_id IN (100, 101, NULL);

-- NOT IN 을 쓰면 아무것도 안나온다. ALL 의 개념이기 때문이다.
SELECT emp.employee_id, emp.last_name, emp.manager_id
FROM employees emp
WHERE emp.manager_id IN (100, 101, NULL);

-- 이거 실행하면 null 이 하나 뜬다.
SELECT mgr.manager_id FROM employees mgr;

-- NULL 빼면 된다.
SELECT emp.employee_id, emp.last_name, emp.manager_id
FROM employees emp
WHERE emp.manager_id IN (100, 101);


-- NOT IN 은 서브쿼리에 NULL 이 있으면, 전체 결과를 NULL 로 만든다.

-- DESC 명령에서 해당 컬럼에 NOT NULL 제약이 없으면
-- WHERE mgr.manager_id IS NOT NULL 조건을 추가해서
-- 데이터가 하나도 나오지 않는 현상을 피해야 한다.
SELECT emp.employee_id, emp.last_name
FROM employees emp
WHERE emp.employee_id NOT IN (SELECT mgr.manager_id
                              FROM employees mgr
                              WHERE mgr.manager_id IS NOT NULL);

-- 지금까지는 열 하나만 비교하는 서브쿼리를 함.
