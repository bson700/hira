-- 08 고급 서브쿼리

-- 지금까지는 열 하나만 비교하는 서브쿼리를 함.
-- 지금부터는 다중열 서브쿼리

SELECT employee_id, manager_id, department_id
FROM employees
WHERE (manager_id, department_id) IN (SELECT manager_id, department_id
                                      FROM employees
                                      WHERE first_name = 'John')
AND first_name <> 'John';
/* 15건. (108, 100) 쌍이 같은거 나옴.
*/


SELECT manager_id, department_id
FROM employees
WHERE first_name = 'John';
/*
108	100
123	50
100	80
*/

-- 비쌍비고
-- manager_id 만 먼저 IN 으로 비교하고
-- 그런 후, department_id IN으로 비교하고
--
SELECT employee_id, manager_id, department_id
FROM employees
WHERE manager_id IN (SELECT manager_id
                     FROM employees
                     WHERE first_name = 'John')
AND department_id IN (SELECT department_id
                     FROM employees
                     WHERE first_name = 'John')
AND first_name <> 'John';
/* 20건 : 5건이 더 나옴
*/
--> 연산자 우선순위때문에 100 50 이 없는데도 가져옴
--> 그러므로, 여러개의 컬럼을 비교할 때는, 앞의 쌍비교 방식을 사용해야 한다.

-- 스칼라 서브쿼리 : select 절에 컬럼값 대신 사용하는 서브쿼리
SELECT employee_id, last_name,
       CASE WHEN department_id = (SELECT department_id
                                  FROM departments
                                  WHERE location_id = 1800)
            THEN 'Canada'
            ELSE 'USA'
       END AS location
FROM employees;

SELECT d.department_id, d.department_name,
       (SELECT MAX(salary)
        FROM employees
        WHERE department_id = d.department_id) AS 최고급여
FROM departments d;

-- 각 부서의 평균 급여를 구한 후, 그 중 하나보다 크면 된다.
-- 내가 속한 부서와는 관련 없다.
SELECT employee_id, last_name, salary, department_id
FROM employees
WHERE salary > ANY (SELECT AVG(salary)
                    FROM employees
                    GROUP BY department_id);

-- 같은 걸 찾는 거지, 소속 부서의 최소값과 비교하는 것은 아니다.
SELECT employee_id, last_name, salary, department_id
FROM employees
WHERE salary IN (SELECT MIN(salary)
                 FROM employees
                 GROUP BY department_id);

-- 부서별 최소급여 명단을 구하고 싶으면,

SELECT employee_id, last_name, salary, department_id
FROM employees
WHERE salary = (SELECT MIN(salary)
                FROM employees
                WHERE department_id = 50);

-- 50 이 계속 바뀌어야 한다.

-- main query 건수 만큼 서브쿼리가 실행되므로, 쓰지 않는 것이 좋다.
SELECT employee_id, last_name, salary, department_id
FROM employees o
WHERE salary = (SELECT MIN(salary)
                FROM employees
                WHERE department_id = o.department_id);

SELECT * FROM employees;

-- 자신의 소속 부서의 평균 급여보다 많은 급여를 받는 사원을 모두 찾습니다.
SELECT last_name, salary, department_id
FROM employees outer
WHERE salary > (SELECT AVG(salary)
                FROM employees
                WHERE department_id = outer.department_id) ;


-- EXISTS : 조건에 맞는 행이 발견될 때 까지만 하고 멈춤

-- 그냥 한번 쿼리
SELECT employee_id, last_name, manager_id
FROM employees;
/*
199번은 Manager 아님
200번은 Manager 아님
201번은 Manager임
*/

-- 매니저인 직원 반환
-- X가 있는 행을 가져옴.
SELECT employee_id, last_name, job_id, department_id
FROM employees outer
WHERE EXISTS ( SELECT 'X'
               FROM employees
               WHERE manager_id = outer.employee_id);

-- 매니저가 아닌 직원 반환
-- 연산방식은 EXISTS 와 같음. X가 없는 행을 가져옴.
SELECT employee_id, last_name, job_id, department_id
FROM employees outer
WHERE NOT EXISTS ( SELECT 'X'
                   FROM employees
                   WHERE manager_id = outer.employee_id);

-- 인라인뷰: FROM 절에 테이블 대신 사용하는 쿼리
-- 뷰: SELECT 문장에 이름 붙여준 거

SELECT department_id, COUNT(*), SUM(salary), TRUNC(AVG(salary))
FROM employees
GROUP BY department_id;

-- 위의 식을 뷰로
-- 뷰로 만들 때는 별칭을 꼭 줘야 한다.: emps, sumsal, avgsal
CREATE OR REPLACE VIEW emp_list_vu
AS
SELECT department_id, COUNT(*) emps, SUM(salary) sumsal, TRUNC(AVG(salary)) avgsal
FROM employees
GROUP BY department_id;

SELECT * FROM emp_list_vu;
/*
emp_list_vu 의 정의를 data dictionary 에서 찾음
dd 에는 select 문이 있음.
그 select 문을 실행
*/

SELECT view_name, text FROM user_views;

-- 내부적으로 view 로 정의된 문장에 where 절이 추가됨.
SELECT * FROM emp_list_vu
WHERE department_id > 50;

-- view 로 만들어 놓으면 쿼리가 심플해짐
-- 데이터 보안에 좋음. view 를 통해 볼수 없는 데이터는 접근 불가.
-- view는 테이블을 보는 방법만 변경.

-- view 를 많이 정의해 놓으면 스키마가 커진다.

-- view 에도 권한을 따로 따로 지정해 줘야 한다.

-- view 삭제
DROP VIEW emp_list_vu;


-- 소속 부서 평균 월급보다 큰
SELECT e.employee_id, e.last_name, e.salary, l.avgsal
FROM employees e
JOIN (SELECT department_id, COUNT(*) emps, SUM(salary) sumsal, TRUNC(AVG(salary)) avgsal
      FROM employees
      GROUP BY department_id) l
ON (e.department_id = l.department_id)
WHERE e.salary > l.avgsal;
-- 인라인뷰는 FROM 절에서 한번만 실행.
-- 명령문이 실행되는 동안에는 오라클 메모리에 유지. 명령문 종료되면 없어짐. -> 인라인 뷰

-- 4개 조인하는 방법 : 2개 조인 + 2개 조인 => 2개 조인(결국 4개 조인)

-- 인라인뷰는 상호관련 서브쿼리를 대체하여 사용할 수도 있다.

-- Top-N은 중간을 못구한다. 최상위, 최하위를 구할 수 있다.
-- Top-N 분석이라면 서브쿼리 속에 ORDER BY 가 나옴.
-- 행을 패치하는 순서를 알려주는 rownum
-- Top-N 에는 rownum 과 order by 를 사용한다.

SELECT ROWNUM as RANK, employee_id, last_name, salary
FROM (SELECT employee_id, last_name, salary FROM employees
      ORDER BY salary DESC)
WHERE rownum <= 3;
/*
1	100	King	24000
2	101	Yang	17000
3	102	Garcia	17000
*/

SELECT ROWNUM as RANK, employee_id, last_name, salary
FROM (SELECT employee_id, last_name, salary FROM employees
      ORDER BY salary)
WHERE rownum <= 3;
/*
1	132	Olson	2100
2	128	Markle	2200
3	136	Philtanker	2200
*/

-- 또다른 예) 교재 124p

-- 다음은 EMPLOYEES 테이블에서 최상위 소득자 세 명의 이름 및 급여를 순위와 함께 표시합니다.
SELECT ROWNUM as RANK, last_name, salary
FROM (SELECT last_name,salary FROM employees
      ORDER BY salary DESC)
      WHERE ROWNUM <= 3;

-- 다음 예제는 인라인 뷰를 사용하여 회사의 최장기 근무 사원 네 명을 표시합니다.
SELECT ROWNUM as SENIOR,E.last_name, E.hire_date
FROM (SELECT last_name,hire_date FROM employees
      ORDER BY hire_date)E
      WHERE rownum <= 4;

-- 데이터가 메모리가 있는 거
-- 미리 상단에 정리
WITH dept_costsAS (SELECT d.department_name, SUM(e.salary) AS dept_total
                   FROM employees e JOIN departments d
                   ON (e.department_id = d.department_id)
                   GROUP BY d.department_name),
     avg_cost AS (SELECT SUM(dept_total)/COUNT(*) AS dept_avg
                   FROM dept_costs)
SELECT *
FROM dept_costs
WHERE dept_total > (SELECT dept_avg
                    FROM avg_cost)
ORDER BY department_name;
