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

-- ROW_NUMBER( ): 무조건 한 등수씩 다줌.
-- 같은 값 중 먼저 발견된 행에 앞번호를 준건지 확실치 않음. 이경우는 사용 권장 안함.
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