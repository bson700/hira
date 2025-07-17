-- 09 분석함수

/*
Window 가 기간이라는 뜻도 있다. 일종의 범위를 의미한다. 즉, 범위 같은 개념으로 쓰인다.
오라클 10g 부터 나왔다.

DBMS 의 기능을 잘 활용하면 코딩을 줄일 수 있다.
*/

/*
생각보다 외래키 안씀. 에러나는 경우가 많음. 확장성 측면에서는 방해된다고도 함.
PK, UNIQUE, NOT NULL 은 DBMS 에서 많이 잡음.
FK 는 꼭 필요한 경우 제외하고 없앰.

사원정보 입력할 때 부서번호는 목록에서는 골라서 넣는 경우가 많다.
외래키를 넣는 곳은, 응용프로그램 에서 목록을 사용하여 제한하고, 외래키는 사용하지 않는
경우도 많다.
*/

-- RANK : 동률이 있으면 다음 등수를 스킵
SELECT job_id, last_name, salary,
       RANK( ) OVER (ORDER BY salary DESC) ALL_RANK
FROM employees;
/*
AD_PRES	King	24000	1
AD_VP	Yang	17000	2
AD_VP	Garcia	17000	2
SA_MAN	Singh	14000	4
SA_MAN	Partners	13500	5
MK_MAN	Martinez	13000	6
FI_MGR	Gruenberg	12008	7
AC_MGR	Higgins	12008	7
SA_MAN	Errazuriz	12000	9
SA_REP	Ozer	11500	10
(후략)
*/

-- 동률을 부여하지만 SKIP을 하지는 않는다. -> 3이 보인다.
SELECT job_id, last_name, salary,
       RANK( ) OVER (ORDER BY salary DESC) ALL_RANK,
       DENSE_RANK( ) OVER (ORDER BY salary DESC) DENSE_RANK
FROM employees;
/*
AD_PRES	King	24000	1	1
AD_VP	Yang	17000	2	2
AD_VP	Garcia	17000	2	2
SA_MAN	Singh	14000	4	3
SA_MAN	Partners	13500	5	4
MK_MAN	Martinez	13000	6	5
FI_MGR	Gruenberg	12008	7	6
AC_MGR	Higgins	12008	7	6
SA_MAN	Errazuriz	12000	9	7
SA_REP	Ozer	11500	10	8
(후략)
*/

-- ROW_NUMBER( ): 무조건 한 등수씩 다줌. 동률이어도 순위를 부여한다.
-- 같은 값 중 먼저 발견된 행에 앞번호를 준건지 확실치 않음. 순위가 뒤집힐 수 있다. 이경우는 사용 권장 안함.
SELECT job_id, last_name, salary,
       RANK( ) OVER (ORDER BY salary DESC) ALL_RANK,
       DENSE_RANK( ) OVER (ORDER BY salary DESC) DENSE_RANK,
       ROW_NUMBER( ) OVER (ORDER BY salary DESC) ROW_NUMBER
FROM employees;
/*
AD_PRES	King	24000	1	1	1
AD_VP	Yang	17000	2	2	2
AD_VP	Garcia	17000	2	2	3
SA_MAN	Singh	14000	4	3	4
SA_MAN	Partners	13500	5	4	5
MK_MAN	Martinez	13000	6	5	6
FI_MGR	Gruenberg	12008	7	6	7
AC_MGR	Higgins	12008	7	6	8
SA_MAN	Errazuriz	12000	9	7	9
SA_REP	Ozer	11500	10	8	10
(후략)
*/

-- 매니저가 같은 사람들(100)끼리 그룹에 대한 SUM(salary)를 옆에 표시해줌.
-- SUM 은 그룹함수인데 GROUP BY 와 함게 사용하나,
-- Windows SUM 은 GROUP BY 없이 사용 가능
-- 이런 기능을 위해 인라인 뷰를 사용했었었다.
SELECT manager_id, last_name, salary,
       SUM(salary) OVER (PARTITION BY manager_id) mgr_sum
FROM employees;

SELECT manager_id, last_name, salary,
       SUM(salary) OVER (PARTITION BY manager_id ORDER BY salary) mgr_sum
FROM employees;

-- 누적 데이터를 보여주고 있다. RANGE UNBOUNDED PRECEDING 가 있을 때와 없을 때의 차이를 모르게음.
SELECT manager_id, last_name, salary,
       SUM(salary) OVER (PARTITION BY manager_id ORDER BY salary RANGE UNBOUNDED PRECEDING) mgr_sum
FROM employees;

--> ??? RANGE UNBOUNDED PRECEDING 가 있을 때와 없을 때의 차이를 모르겠음.

SELECT job_id, last_name, salary,
       RANK( ) OVER (PARTITION BY job_id ORDER BY salary DESC) ALL_RANK
FROM employees;
/*
(생략)
MK_REP	Davis	6000	1
PR_REP	Brown	10000	1
PU_CLERK	Khoo	3100	1
PU_CLERK	Baida	2900	2
PU_CLERK	Tobias	2800	3
PU_CLERK	Himuro	2600	4
PU_CLERK	Colmenares	2500	5
PU_MAN	Li	11000	1
SA_MAN	Singh	14000	1
SA_MAN	Partners	13500	2
(후략)
*/

-- 오라클은 행단위 IO 가 아니라 BLOCK IO를 한다.

-- 전체 사원이 한 파티션. 단일 파티션으로 순위 계산.
SELECT department_id, employee_id, last_name, salary,
       RANK() OVER (ORDER BY salary DESC) AS rank
FROM employees;

-- 파티션이 나눠지고, 그 안에서 순위 계산.
SELECT department_id, employee_id, last_name, salary,
       RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rank
FROM employees;
/* 부서가 바뀔 때 마다 순위가 바뀌는 것을 확인할 수 있다.
10	200	Whalen	4400	1
20	201	Martinez	13000	1
20	202	Davis	6000	2
30	114	Li	11000	1
30	115	Khoo	3100	2
30	116	Baida	2900	3
30	117	Tobias	2800	4
30	118	Himuro	2600	5
30	119	Colmenares	2500	6
40	203	Jacobs	6500	1
50	121	Fripp	8200	1
(후략)
*/

-- 프레임 생략 시 파티션 전체의 합을 행마다 출력
SELECT manager_id, last_name, salary,
       SUM(salary) OVER (PARTITION BY manager_id) AS "MgrSum"
FROM employees;

-- 매니저 번호가 바뀌면 프레임이 바뀐다. 파티션이 끝날때 까지 프레임이 커진다.
SELECT manager_id, last_name, salary,
       SUM(salary) OVER (PARTITION BY manager_id ORDER BY salary
                         RANGE UNBOUNDED PRECEDING) AS "MgrSum"
FROM employees;

-- 파티션 내 현재 행 까지의 프레임에 대한 급여 총합 출력
-- 윈도우 프레임: 'RANGE [BETWEEN] UNBOUNDED PRECEDING [AND CURRENT ROW]'임.
SELECT manager_id, last_name, salary,
       SUM(salary) OVER (PARTITION BY manager_id ORDER BY salary
                         RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS "MgrSum"
FROM employees;
/*
(생략)
100	Zlotkey	10500	46900
100	Li	11000	68900
100	Cambrault	11000	68900
100	Errazuriz	12000	80900
(후략)
*/

-- 윈도우 프레임을 ROWS UNBOUNDED PRECEDING 로 한 경우 동률의 급여를 별도처리
SELECT manager_id, last_name, salary,
       SUM(salary) OVER (PARTITION BY manager_id ORDER BY salary
                         ROWS UNBOUNDED PRECEDING) AS "MgrSum"
FROM employees;
/*
100	Zlotkey	10500	46900
100	Li	11000	57900
100	Cambrault	11000	68900
100	Errazuriz	12000	80900
100	Martinez	13000	93900
*/

-- 현재 행 기준 앞, 뒤 1개씩 총 3개행의 급여 합
-- 첫번째 행은 앞이 없고, 맨 뒤의 행은 뒤가 없다.
SELECT manager_id, last_name, salary,
       SUM(salary) OVER (PARTITION BY manager_id ORDER BY salary
                         ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS "MgrSum"
FROM employees;

-- ㄱ뭏ㄷ 보다는 rows 를 많이 쓴다. 명확해서.

-- 프레임의 싸이즈가 값 기준이므로 프레임 사이즈가 고정적이지 않게 된다. 달라질 수 있다.
-- 현재 행의 --> 강사님 필기 참고할 것
-- 현재 6500이면, 5500 부터 7500 까지.
-- 레인지는 연속적인 값들(시계열), 로그로 찍히는 값들이 대상이 될 수 있으나, 급여와는 잘 맞지 않는다.
SELECT manager_id, last_name, salary,
       SUM(salary) OVER (PARTITION BY manager_id ORDER BY salary
                         RANGE BETWEEN 1000 PRECEDING AND 1000 FOLLOWING) AS "MgrSum"
FROM employees;
/*
100	Mourgos	5800	12300
100	Vollman	6500	12300
100	Kaufling	7900	24100
100	Weiss	8000	24100
100	Fripp	8200	24100
100	Zlotkey	10500	32500
100	Li	11000	44500
100	Cambrault	11000	44500
100	Errazuriz	12000	47000
100	Martinez	13000	52500
*/

-- 같은 부서 내 최소 급여, 최대 급여를 출력
SELECT department_id, last_name, salary,
       MIN(salary) OVER (PARTITION BY department_id) AS dept_min,
       MAX(salary) OVER (PARTITION BY department_id) AS dept_max
FROM employees;

-- 항상 현재행 까지
-- 부서별 파티션에서 급여로 정렬했을 때 현재 행까지에서의 최대, 최소 급여를 출력
-- 연속 데이터가 아닐 경우 ROWS 가 더 많이 쓰인다.
SELECT department_id, last_name, salary,
       MIN(salary) OVER (PARTITION BY department_id ORDER BY salary
       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS dept_min,
       MAX(salary) OVER (PARTITION BY department_id ORDER BY salary
       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS dept_max
FROM employees;
/*
10	Whalen	4400	4400	4400
20	Davis	6000	6000	6000
20	Martinez	13000	6000	13000
30	Colmenares	2500	2500	2500
30	Himuro	2600	2500	2600
30	Tobias	2800	2500	2800
30	Baida	2900	2500	2900
30	Khoo	3100	2500	3100
30	Li	11000	2500	11000
40	Jacobs	6500	6500	6500
50	Olson	2100	2100	2100
(후략)
*/

-- 위 코드를 변형해서 프레임을 고정 사이즈로


-- 이동 범위 내 ......


-- 현재 행 기준 앞, 뒤 한 행씩 3개의 행에 대한 평균급여 출력


-- 급여를 기준으로 정렬하고 현재 행 사원의 급여기준 -1000~+2000 사이의 급여를 받는 인원수를 출력


-- 현재 행까지의 같은 부서내 사원들에 대한 평균 급여를 표시
-- 윈도우 프레임이 없기 때문에 현재행까지의 누적 평균급여 출력
SELECT department_id, last_name, hire_date, salary,
       AVG(salary) OVER (PARTITION BY department_id ORDER BY hire_date) as dept_avg
FROM employees;
/*
(전략)
30	Khoo	13/05/18	3100	7050
30	Tobias	15/07/24	2800	5633.333333333333333333333333333333333333
30	Baida	15/12/24	2900	4950
(후략)
*/

SELECT department_id, last_name, hire_date, salary,
       ROUND(AVG(salary) OVER (PARTITION BY department_id ORDER BY hire_date), 0) as dept_avg
FROM employees;
/*
30	Khoo	13/05/18	3100	7050
30	Tobias	15/07/24	2800	5633
30	Baida	15/12/24	2900	4950
*/

SELECT department_id, last_name, hire_date, salary,
       ROUND(AVG(salary) OVER (PARTITION BY department_id ORDER BY hire_date), 0)
       블라블라 as dept_avg
FROM employees;

-- PARTITION BY 가 없으면 전체사원 기준
SELECT employee_id, last_name, hire_date, salary,
       COUNT(*) OVER (ORDER BY salary
       RANGE BETWEEN 1000 PRECEDING AND 2000 FOLLOWING) as emp_count
FROM employees;

-- 그룹 내 행 순서 : FIRST_VALUE, LAST_VALUE, LAG, LEAD : Oracle 에서만 지원

-- 부서별 최대 급여를 받는 직원의 이름이 함께 출력
SELECT department_id, last_name, salary,
       FIRST_VALUE(last_name) OVER (PARTITION BY department_id
       ORDER BY salary DESC ROWS UNBOUNDED PRECEDING) as DEPT_RICH
FROM employees;
/*
10	Whalen	4400	Whalen
20	Martinez	13000	Martinez
20	Davis	6000	Martinez
30	Li	11000	Li
30	Khoo	3100	Li
30	Baida	2900	Li
30	Tobias	2800	Li
30	Himuro	2600	Li
30	Colmenares	2500	Li
40	Jacobs	6500	Jacobs
(후략)
*/

-- 부서별 최소 급여를 받는 직원의 이름이 함께 출력
SELECT department_id, last_name, salary,
       FIRST_VALUE(last_name) OVER (PARTITION BY department_id
       ORDER BY salary ROWS UNBOUNDED PRECEDING) as DEPT_RICH
FROM employees;
/*
10	Whalen	4400	Whalen
20	Davis	6000	Davis
20	Martinez	13000	Davis
30	Colmenares	2500	Colmenares
30	Himuro	2600	Colmenares
30	Tobias	2800	Colmenares
30	Baida	2900	Colmenares
30	Khoo	3100	Colmenares
30	Li	11000	Colmenares
40	Jacobs	6500	Jacobs
*/

-- LAST_VALUE
SELECT department_id, last_name, salary,
       LAST_VALUE(last_name) OVER (PARTITION BY department_id
       ORDER BY salary DESC ROWS UNBOUNDED PRECEDING) as DEPT_RICH
FROM employees;
/*
10	Whalen	4400	Whalen
20	Martinez	13000	Martinez
20	Davis	6000	Davis
30	Li	11000	Li
30	Khoo	3100	Khoo
30	Baida	2900	Baida
30	Tobias	2800	Tobias
30	Himuro	2600	Himuro
30	Colmenares	2500	Colmenares
40	Jacobs	6500	Jacobs
(후략)
*/

-- 입사일 기준으로 정렬하여, 현재 행 사원의 입사일 직전에 입사한 직원의 입사일을 함께 표시
-- LAG(hire_date, 1) : 기본값 1
SELECT last_name, salary, hire_date,
       LAG(hire_date, 1) OVER (ORDER BY hire_date) as prev_hiredate
FROM employees ;
/* 앞의 행의 hire_date 가 현재 행에 함께 표시
Garcia	17000	11/01/13	
Gietz	8300	12/06/07	11/01/13
Brown	10000	12/06/07	12/06/07
Jacobs	6500	12/06/07	12/06/07
Higgins	12008	12/06/07	12/06/07
Faviet	9000	12/08/16	12/06/07
Gruenberg	12008	12/08/17	12/08/16
Li	11000	12/12/07	12/08/17
Kaufling	7900	13/05/01	12/12/07
Khoo	3100	13/05/18	13/05/01
*/

-- LAG 변형
SELECT last_name, salary, hire_date,
       LAG(hire_date, 2) OVER (ORDER BY hire_date) as prev_hiredate
FROM employees ;
/* 3번째 행의 결과에 첫번째 행의 hire_date가 같이 나옴
Garcia	17000	11/01/13	
Gietz	8300	12/06/07	
Brown	10000	12/06/07	11/01/13
Jacobs	6500	12/06/07	12/06/07
Higgins	12008	12/06/07	12/06/07
Faviet	9000	12/08/16	12/06/07
Gruenberg	12008	12/08/17	12/06/07
Li	11000	12/12/07	12/08/16
Kaufling	7900	13/05/01	12/08/17
Khoo	3100	13/05/18	12/12/07
*/

-- 입사일 순으로 정렬한 후 이전 입사지의 급여를 함께 출력
SELECT last_name, salary, hire_date,
       LAG(salary) OVER (ORDER BY hire_date) as prev_salary
FROM employees ;
/*
Garcia	17000	11/01/13	
Gietz	8300	12/06/07	17000
Brown	10000	12/06/07	8300
Jacobs	6500	12/06/07	10000
Higgins	12008	12/06/07	6500
Faviet	9000	12/08/16	12008
Gruenberg	12008	12/08/17	9000
Li	11000	12/12/07	12008
Kaufling	7900	13/05/01	11000
Khoo	3100	13/05/18	7900
*/

-- 부서별 급여 순으로 정렬하고, 이전 직원의 급여와 함께 출력
SELECT department_id, last_name, salary, hire_date,
       LAG(salary) OVER (PARTITION BY department_id ORDER BY salary) as prev_salary
FROM employees ;
/*
10	Whalen	4400	13/09/17	
20	Davis	6000	15/08/17	
20	Martinez	13000	14/02/17	6000
30	Colmenares	2500	17/08/10	
30	Himuro	2600	16/11/15	2500
30	Tobias	2800	15/07/24	2600
30	Baida	2900	15/12/24	2800
30	Khoo	3100	13/05/18	2900
30	Li	11000	12/12/07	3100
40	Jacobs	6500	12/06/07	
*/

-- (LAG활용) 전체 직원을 대상으로 급여 순으로 정렬한 후 급여간의 격차를 출력
-- 전체 직원을 대상 : PARTITION BY 안씀
SELECT department_id, last_name, salary, hire_date,
       LAG(salary) OVER (ORDER BY salary) as prev_salary,
       salary - LAG(salary) OVER (ORDER BY salary) as diff_sal
FROM employees ;
/*
50	Olson	2100	17/04/10		
50	Markle	2200	18/03/08	2100	100
50	Philtanker	2200	18/02/06	2200	0
50	Landry	2400	17/01/14	2200	200
50	Gee	2400	17/12/12	2400	0
30	Colmenares	2500	17/08/10	2400	100
50	Marlow	2500	15/02/16	2500	0
50	Patel	2500	16/04/06	2500	0
50	Vargas	2500	16/07/09	2500	0
50	Sullivan	2500	17/06/21	2500	0
(후략)
*/


-- LEAD 함수로 현재 행 사원입사일 다음의 입사일을 함께 출력
SELECT last_name, hire_date,
       LEAD(hire_date) OVER (ORDER BY hire_date) as "NEXTHIRED"
FROM employees;

-- 다음 입사일 까지의 일수
SELECT last_name, hire_date,
       LEAD(hire_date) OVER (ORDER BY hire_date) as "NEXTHIRED",
       TRUNC(LEAD(hire_date) OVER (ORDER BY hire_date) - hire_date) as interval
FROM employees;

-- LAG, LEAD 는 간격 계산에 많이 활용한다.

-- 3번째 인자: 기본값 --> 기본값을 주어서 이 값으로 대체시킬 수도 있다.
SELECT last_name, hire_date,
       LEAD(hire_date, 1, TO_DATE('2025/01/01', 'yyyy/mm/dd')) OVER (ORDER BY hire_date) as "NEXTHIRED"
FROM employees;
/*
Garcia	11/01/13	12/06/07	511
Gietz	12/06/07	12/06/07	0
Brown	12/06/07	12/06/07	0
Jacobs	12/06/07	12/06/07	0
Higgins	12/06/07	12/08/16	70
Faviet	12/08/16	12/08/17	1
Gruenberg	12/08/17	12/12/07	112
Li	12/12/07	13/05/01	145
Kaufling	13/05/01	13/05/18	17
Khoo	13/05/18	13/06/17	30
(후략)
*/

-- LAG, LEAD 는 이상탐지에도 사용한다.

-- 기본값 적용
SELECT last_name, hire_date,
       LEAD(hire_date, 1, TO_DATE('2025/01/01', 'yyyy/mm/dd')) OVER (ORDER BY hire_date) as "NEXTHIRED"
FROM employees;


-- 그룹 내 비율 함수 : RATIO_TO_REPORT, PERCENT_RANK, CUME_DIST, NTILE

-- RATIO_TO_REPORT 는 소수점이 많이 나온다

-- 전체 사원대상 전체 급여의 합에서 해당 급여가 차지하는 비율 출력
-- 샐러리의 총합에서 이 급여가 몇 퍼센트에 해당한다.
SELECT last_name, job_id, salary,
       ROUND(RATIO_TO_REPORT(salary) OVER (), 2) as R_R
FROM employees;
/*
King	AD_PRES	24000	0.03
Yang	AD_VP	17000	0.02
Garcia	AD_VP	17000	0.02
James	IT_PROG	9000	0.01
Miller	IT_PROG	6000	0.01
Williams	IT_PROG	4800	0.01
Jackson	IT_PROG	4800	0.01
Nguyen	IT_PROG	4200	0.01
Gruenberg	FI_MGR	12008	0.02
Faviet	FI_ACCOUNT	9000	0.01
(후략)
*/

SELECT last_name, job_id, salary,
       ROUND(RATIO_TO_REPORT(salary) OVER (), 2) as R_R
FROM employees
WHERE job_id LIKE 'IT%';
/* 9000 이라는 급여를 받는 사람은 전체 급여의 31%
James	IT_PROG	9000	0.31
Miller	IT_PROG	6000	0.21
Williams	IT_PROG	4800	0.17
Jackson	IT_PROG	4800	0.17
Nguyen	IT_PROG	4200	0.15
*/

SELECT last_name, job_id, salary,
       ROUND(RATIO_TO_REPORT(salary) OVER (), 2) * 100 || '%' as R_R
FROM employees
WHERE job_id LIKE 'IT%';
/* ROUND 를 했기 때문에, 더하면 정확하게 100%가 안 될 수 있다.
James	IT_PROG	9000	31%
Miller	IT_PROG	6000	21%
Williams	IT_PROG	4800	17%
Jackson	IT_PROG	4800	17%
Nguyen	IT_PROG	4200	15%
*/

-- 부서별 급여 분산 정도를 분석
SELECT department_id, last_name, salary,
       ROUND(RATIO_TO_REPORT(salary)
             OVER (PARTITION BY department_id), 2) AS ratio_by_dept
FROM employees;
/* 부서 내에서만 백분위를 구함
20	Davis	6000	0.32
30	Li	11000	0.44
30	Khoo	3100	0.12
30	Baida	2900	0.12
30	Tobias	2800	0.11
30	Himuro	2600	0.1
30	Colmenares	2500	0.1
40	Jacobs	6500	1
(후략)
*/

-- (활용) 각 업무 내에서 급여의 비중이 30%를 초과하는 직원의 사번, 이름, 업무ID, 급여를 출력
-- (힌트) window function은 where 절에 쓸 수 없으므로 인라인뷰로 작성
--> where 절에 조건을 지정하면 안된다. windows 함수는 where 절에 지정할 수 없다.
--    -> 이 select 문 자체를 뷰처름 쓰면 된다.
SELECT *
FROM (SELECT employee_id, last_name, job_id, salary,
             ROUND(RATIO_TO_REPORT(salary) OVER (PARTITION BY job_id), 2) AS ratio_by_job
      FROM employees)
WHERE ratio_by_job > 0.3;
/*
206	Gietz	AC_ACCOUNT	8300	1
205	Higgins	AC_MGR	12008	1
200	Whalen	AD_ASST	4400	1
100	King	AD_PRES	24000	1
102	Garcia	AD_VP	17000	0.5
101	Yang	AD_VP	17000	0.5
108	Gruenberg	FI_MGR	12008	1
203	Jacobs	HR_REP	6500	1
103	James	IT_PROG	9000	0.31
201	Martinez	MK_MAN	13000	1
*/

-- 부서별 현재 행의 사원급여가 순서상 몇번째인지 파악할 수 있는 값 출력
-- 급여가 순서상 부서 몇번째 정도에 위치했는지 보는
-- PARTITION BY department_id 을 없애면 전체 사원에서 순서상 몇번째인지 알 수 있음.
SELECT department_id, last_name, salary,
       PERCENT_RANK() OVER (PARTITION BY department_id
                            ORDER BY salary DESC) as P_R
FROM employees;
/* Li 는 상위 0 퍼센트, Colmenares 는 1 퍼센트
10	Whalen	4400	0
20	Martinez	13000	0
20	Davis	6000	1
30	Li	11000	0
30	Khoo	3100	0.2
30	Baida	2900	0.4
30	Tobias	2800	0.6
30	Himuro	2600	0.8
30	Colmenares	2500	1
40	Jacobs	6500	0
50	Fripp	8200	0
50	Weiss	8000	0.0227272727272727272727272727272727272727
50	Kaufling	7900	0.0454545454545454545454545454545454545455
*/

-- 전체 중에서 현재 행의 사원급여가 순서상 몇번째인지 파악할 수 있는 값 출력

SELECT department_id, last_name, salary,
       ROUND(PERCENT_RANK() OVER (ORDER BY salary DESC), 4) as P_R
FROM employees;
/*
90	King	24000	0
90	Yang	17000	0.0094
90	Garcia	17000	0.0094
80	Singh	14000	0.0283
80	Partners	13500	0.0377
20	Martinez	13000	0.0472
100	Gruenberg	12008	0.0566
110	Higgins	12008	0.0566
80	Errazuriz	12000	0.0755
80	Ozer	11500	0.0849
*/

-- 부서 내 소속사원들에서 현재 사원의 급여가 누적순서상 몇번째 인지를 출력
SELECT department_id, last_name, salary,
       ROUND(PERCENT_RANK() OVER (PARTITION BY department_id ORDER BY salary DESC), 4) as P_R,
       ROUND(CUME_DIST() OVER (PARTITION BY department_id ORDER BY salary DESC), 4) as C_D
FROM employees;
/*
10	Whalen	4400	0	1
20	Martinez	13000	0	0.5
20	Davis	6000	1	1
30	Li	11000	0	0.1667
30	Khoo	3100	0.2	0.3333
30	Baida	2900	0.4	0.5
30	Tobias	2800	0.6	0.6667
30	Himuro	2600	0.8	0.8333
30	Colmenares	2500	1	1
40	Jacobs	6500	0	1
*/

-- NTILE(n)로 파티션 또는 전체 데이트를 n등분
-- n등분의 결과를 보는 것
-- NTILE 도 PARTITION BY 쓸 수 있다.
-- 급여 순으로 10개의 그룹으로 나누겠다.
SELECT last_name, salary,
       NTILE(10) OVER (ORDER BY salary DESC) as QUAR_TILE
FROM employees;
/* 나머지 7명은 앞부분 부터 한명씩 더 넣음. --> ? 그럼 마지막 한명은 급여 순이 안될듯...?
King	24000	1
Yang	17000	1
Garcia	17000	1
Singh	14000	1
Partners	13500	1
Martinez	13000	1
Gruenberg	12008	1
Higgins	12008	1
Errazuriz	12000	1
Ozer	11500	1
(후략)
*/

-- LISTAGG PIVOT UNPIVOT

SELECT department_id, COUNT(*)
FROM employees
GROUP BY department_id;
/*
50	45
40	1
110	2
90	3
30	6
70	1
	1
10	1
20	2
60	5
(후략)
*/

-- 위 코드에서 해당 그룹에 해당하는 직원들을 알고 싶다. --> LISTAGG

-- 부서별 인원 수와 부서의 사원 이름을 이름 순으로 함께 출력
SELECT department_id, COUNT(*),
       LISTAGG(last_name, ',') WITHIN GROUP(ORDER BY last_name) AS ename
FROM employees
GROUP BY department_id
HAVING COUNT(*) <= 7;
/*
10	1	Whalen
20	2	Davis,Martinez
30	6	Baida,Colmenares,Himuro,Khoo,Li,Tobias
40	1	Jacobs
60	5	Jackson,James,Miller,Nguyen,Williams
70	1	Brown
90	3	Garcia,King,Yang
100	6	Chen,Faviet,Gruenberg,Popp,Sciarra,Urman
110	2	Gietz,Higgins
(null)	1	Grant
*/

-- PIVOT : 행열을 바꿔주는 것

-- 다 못침 : 강사님 스크립트 참고할 것
SELECT department_id, , COUNT(*)
FROM employees
GROUP BY department_id;

SELECT *
FROM (SELECT department_id, job_id, salary
      FROM employees
      WHERE department_id IN (50,60, 80))
PIVOT(MAX(salary) FOR department_id IN (50 AS d50, 60 AS d60, 80 AS d80));
/*
SH_CLERK	4200		
ST_CLERK	3600		
IT_PROG		9000	
SA_MAN			14000
ST_MAN	8200		
SA_REP			11500
*/

SELECT *
FROM (SELECT job_id, department_id, salary FROM employees
WHERE department_id IN (50,60, 80))
PIVOT (MAX(salary) FOR job_id IN ('IT_PROG','SA_MAN','SA_REP',
'ST_CLERK', 'ST_MAN'))
ORDER BY department_id;
/*
50	(null)	(null)	(null)	3600	8200
60	9000	(null)	(null)	(null)	(null)
80	(null)	14000	11500	(null)	(null)
*/
