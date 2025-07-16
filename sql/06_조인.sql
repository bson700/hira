-- 06 조인

-- 부서를 알고 싶으면?
SELECT employee_id, last_name, department_id
FROM employees
WHERE employee_id = 101;
/*
101	Yang	90
*/

-- 부서 테이블을 조회한다.
SELECT department_id, department_name
FROM departments
WHERE department_id = 90;
/*
90	Executive
*/

-- JOIN 으로 한번에 알 수 있다
SELECT employee_id, last_name, department_name
FROM employees JOIN departments
USING (department_id)
WHERE employee_id = 101;
/*
101	Yang	Executive
*/

-- JOIN 4개 이상은 잘 안한다. 검색 속도가 매우 느려진다.
-- 3개 조인하는 것을 3-way join 이라고 한다.

-- 관계형 DB는 필드값에 단일값만 허용. 리스트 지원 안함.

-- PK가 중복되는 컬럼은 다른 테이블을 만들어 내보낸다.

/*
'관심분야' 가 어러개 있을 수 있다.
PK 와 함께 다른 테이블로 내보낸다.

id  int
101 경제
101 ?리

id  id  int
1   101 경제
2   101 ?리

1정규형: 기본키를 중복하는 애가 없게 만든다.

데이터가 반복되면 ...
하나 수정하면 여러 부분 수정해야 할 수 있고, 정보의 불일치가 발생할 수 있다.
한 명밖에 없는 사원을 지우면 부서가 없어질 수 도 있다.
부서만 따로 만드는 것을 못한다. 빈 부서를 만들 수 없다. 사원번호가 PK 이므로.
반복되는 거 떼어낸다.

정규형은 중복을 제거해 나가는 과정이다.
JOIN 정규화 전의 모습을 보기 위한 것이다.

정규화가 잘 되었는지 검증하는 방법.
떼어 놓은 테이블끼리 조인해서 원래 테이블 모습으로 복원되었는지 본다.
정규화를 하더라도 INSERT, UPDATE, DELETE 에 이상이 생기면 안된다.

JOIN은 성능저하의 원인

JOIN 제거하려면 -> 테이블 다시 합친다.

*/

-- Natural Join : 동일한 이름을 가진 모든 열을 기준
SELECT employee_id, last_name, department_name
FROM employees NATURAL JOIN departments;

-- 두 테이블의 컬럼이름이 중복된다. : MANAGER_ID, DEPARTMENT_ID
-- 이 두개가 동시에 같은 것을 조인한다. 즉, 조인 키가 두개가 되었다.
-- 이 둘이 같지 않은 누락된 행들이 발생한다. 이러한 행들을 OUTER 라고 한다.
DESC employees
DESC departments

-- location_id 하나만 열 이름이 같다. -> 이경우 Natural join 사용 적당.
SELECT department_id, department_name, city
FROM departments NATURAL JOIN locations;

-- 부서번호가 (null)인 직원(OUTER)이 1건 나온다.
SELECT employee_id, last_name, department_name
FROM employees JOIN departments
USING (department_id);
/* 106건
200	Whalen	Administration
201	Martinez	Marketing
*/

/*
고객 테이블의 PK는 고객ID
주문 테이블에서는 주문고객 이라고 나올 수 있다.
고객.고객ID = 주문.주문고객

--> USING 절에서는 컬럼이름이 같아야 한다. USING에는 괄호가 있어야 한다.
--> ON 절을 사용하면 컬럼이름이 달라도 된다.
*/

-- ON 절 사용
-- 양쪽 조인 키 이름이 같으므로, '테이블 이름 접두어'를 사용해야 한다.
-- SELECT 절에도 테이블 이름 접두어를 사용해야 한다.
SELECT employee_id, last_name, employees.department_id, department_name
FROM employees JOIN departments
ON (employees.department_id = departments.department_id);

-- '테이블 이름 접두어' 를 모두 사용해도 된다.
SELECT employees.employee_id, employees.last_name,
       employees.department_id, departments.department_name
FROM employees JOIN departments
ON (employees.department_id = departments.department_id);ㅜ ㅜㅏ

-- Alias (별칭)을 사용 -> '별칭을 준다' 라고 한다.
-- 별칭을 쓰면, 이제 테이블 풀네임을 쓸 수 없다.
SELECT e.employee_id, e.last_name,
       e.department_id, d.department_name
FROM employees e JOIN departments d
ON (e.department_id = d.department_id);

-- USING 은 안되는 DBMS도 있다. ON은 모두 된다.

-- 3 way 조인
SELECT e.employee_id, e.last_name,
       e.department_id, d.department_name,
       l.city
FROM employees e JOIN departments d
ON (e.department_id = d.department_id)
JOIN locations l
ON (d.location_id = l.location_id);

-- DW 시스템의 경우에 4개 이상도 사용하긴 한다. --> Star Join 이라고도 한다.

SELECT e.employee_id, e.last_name,
       e.department_id, d.department_name,
       l.city
FROM employees e JOIN departments d
ON (e.department_id = d.department_id)
JOIN locations l
ON (d.location_id = l.location_id)
WHERE e.department_id = 50;

-- ON 절을 쓰는 조인 문장에서 WHERE 대신에 AND 도 가능
SELECT e.employee_id, e.last_name,
       e.department_id, d.department_name,
       l.city
FROM employees e JOIN departments d
ON (e.department_id = d.department_id)
JOIN locations l
ON (d.location_id = l.location_id)
AND e.department_id = 50;

/*
조인 유형

--테이블 수
-Join(2개)
-3 Way Join(3개)
-Self Join(1개)

--조인 연산
-등가 조인(Equi Join) " = "을 사용하는 조인
-비등가 조인(Non-Equi Join) : " = "을 사용하지 않는 조인

-- 아우터 행을 포함하는지 여부
-Inner Join : 조인 조건을 만족하는 행만 출력
-Outer Join : Inner Join 결과 + Outer 함께 출력
             (LEFT/RIGHT/FULL)
*/

-- self join은 하나의 테이블을 두번 읽는 방식이다.
-- 머리 속으로 매니저 테이블이 하나 있다고 생각하고 Join
-- selef join 은 USING 을 쓸 수 없다. 반드시 별칭을 써야 한다.
-- 조인이 가능한 열이 하나 있어야 한다.
SELECT e.employee_id, e.last_name, e.manager_id, m.last_name
FROM employees e JOIN employees m
ON (e.manager_id = m.manager_id);

-- SAL : salary
-- grade_level 을 결과를 눈으로 보고 찾아야 한다.
SELECT * 
FROM job_grades;
/*
GRADE_LEVEL LOWEST_SAL  HIGHEST_SAL
A	1000	2999
B	3000	5999
C	6000	9999
D	10000	14999
E	15000	24999
F	25000	40000
*/

-- grade_level 를 알고 싶다면 -> BETWEEN AND
SELECT e.employee_id, e.last_name, e.salary, j.grade_level
FROM employees e JOIN job_grades j
ON (e.salary BETWEEN j.lowest_sal AND j.highest_sal);

-- LEFT OUTER JOIN
SELECT e.employee_id, e.last_name, e.department_id, d.department_name
FROM employees e LEFT OUTER JOIN departments d
ON (e.department_id = d.department_id);

-- RIGHT OUTER JOIN
SELECT e.employee_id, e.last_name, e.department_id, d.department_name
FROM employees e RIGHT OUTER JOIN departments d
ON (e.department_id = d.department_id);

-- FULL OUTER JOIN
SELECT e.employee_id, e.last_name, e.department_id, d.department_name
FROM employees e FULL OUTER JOIN departments d
ON (e.department_id = d.department_id);

-- 아우터만 찾고 싶다. 부서가 없는 사원만 보고싶다. OUTER 조인의 결과에서 INNER 조인의 결과를 빼면된다.
SELECT e.employee_id, e.last_name, e.department_id, d.department_name
FROM employees e LEFT OUTER JOIN departments d
ON (e.department_id = d.department_id)
MINUS
SELECT e.employee_id, e.last_name, e.department_id, d.department_name
FROM employees e JOIN departments d
ON (e.department_id = d.department_id);
/*
178	Grant	(null)	(null)
*/

-- manager_id가 널인 사장은 안나옴. 아우터
SELECT e.employee_id, e.last_name, e.department_id, d.department_name
FROM employees e RIGHT OUTER JOIN departments d
ON (e.manager_id = d.manager_id);

SELECT e.employee_id, e.last_name, e.salary, j.grade_level
FROM employees e LEFT OUTER JOIN job_grades j
ON (e.salary BETWEEN j.lowest_sal AND j.highest_sal);

/*
USING 절을 아우터 조인 할 수 있나? 할수 있다.
*/

-- CROSS JOIN
-- Cartesian Product : 두 테이블에서 모든 데이터가 한번씩 만나봄. 모든 경우의 수.
--                     두 테이블의 행수의 곱만큼

-- 조인 조건이 부적합한 경우
-- 조인키 속성이 없어서
-- 내 의도와 상관없이 잘못되서 카테시안 곱이 된 경우임.
SELECT last_name, city
FROM employees NATURAL JOIN locations;

-- CROSS 조인을 일부러 하는 경우 -> 확률 찾으려고, 전체 경우의 수를 찾으려고
SELECT last_name, department_name
FROM employees CROSS JOIN departments;

/*
비표준 조인
- 표준 조인 전에 먼저 나온 조인
*/

SELECT e.employee_id, e.last_name, e.department_id, d.department_name
FROM employees e, departments d
WHERE e.department_id = d.department_id
AND e.salary > 10000;


SELECT e.employee_id, e.last_name, e.department_id, d.department_name
FROM employees e LEFT OUTER JOIN departments d
ON (e.department_id = d.department_id);
-- 위 표준 LEFT OUTER 조인을 비표준 조인으로 변경하면
SELECT e.employee_id, e.last_name, e.department_id, d.department_name
FROM employees e, departments d
WHERE e.department_id = d.department_id(+);

-- 비표준 조인은 FULL OUTER JOIN 은 안된다.
SELECT e.employee_id, e.last_name, e.department_id, d.department_name
FROM employees e, departments d
WHERE e.department_id(+) = d.department_id(+);
/*
ORA-01468: outer-join된 테이블은 1개만 지정할 수 있습니다
*/

SELECT e.employee_id, e.last_name, e.department_id, d.department_name
FROM employees e, departments d
WHERE e.department_id(+) = d.department_id
AND e.department_id = d.department_id(+);
/*
ORA-01416: 두 개의 테이블을 outer-join할 수 없습니다
*/

-- 이렇게 하면 된다.
SELECT e.employee_id, e.last_name, e.department_id, d.department_name
FROM employees e, departments d
WHERE e.department_id(+) = d.department_id
UNION
SELECT e.employee_id, e.last_name, e.department_id, d.department_name
FROM employees e, departments d
WHERE e.department_id = d.department_id(+);
