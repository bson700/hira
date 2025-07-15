
SELECT MIN(salary), MAX(salary), AVG(salary), SUM(salary)
FROM employees;
2100	24000	6461.831775700934579439252336448598130841	691416

-- 사원 전체(테이블 전체)가 그룹
SELECT MIN(salary), MAX(salary), ROUND(AVG(salary)), SUM(salary)
FROM employees;
/*
2100	24000	6462	691416
*/

SELECT MIN(salary), MAX(salary), ROUND(AVG(salary)), SUM(salary)
FROM employees
WHERE department_id = 50;
/*
2100	8200	3476	156400
*/

SELECT MIN(first_name), MAX(first_name)
FROM employees;
/*
Adam	Winston
*/

SELECT MIN(hire_date), MAX(hire_date)
FROM employees;
/*
11/01/13	18/04/21
*/

-- GROUP 함수는 NULL 값을 빼고 계산
-- COUNT(DISTINCT department_id) : 부서의 개수
SELECT COUNT(*),
       COUNT(last_name),
       COUNT(commission_pct),
       COUNT(department_id),
       COUNT(DISTINCT department_id)
FROM employees;
/*
107	107	35	106	11
*/

/*
1 400
2 500
3 null
avg(sal) = (400 + 500) / 2 = 450
avg(nvl(sal, 0)) = (400 + 500 + 0) / 3 = 300
*/

SELECT AVG(commission_pct), AVG(NVL(commission_pct, 0)) FROM employees;
/*
0.2228571428571428571428571428571428571429	0.072897196261682242990654205607476635514
*/

-- 포인트가 null 인 사람도 평균에 포함시켜야 할까? 기업 입장임. 최근에는 null 안쓰고, 기본값 0 사용 추세.

SELECT SUM(salary), COUNT(*) FROM employees;
/*
691416	107
*/

SELECT department_id, SUM(salary), COUNT(*) FROM employees;
/*
ORA-00937: 단일 그룹의 그룹 함수가 아닙니다
*/

SELECT department_id, SUM(salary), COUNT(*) FROM employees
group by department_id;
/* 전체 결과임
50	156400	45
40	6500	1
110	20308	2
90	58000	3
30	24900	6
70	10000	1
(null)	7000	1
10	4400	1
20	19000	2
60	28800	5
100	51608	6
80	304500	34
*/

-- 예전 오라클은 group by 하면 정렬되었었다.
-- 데이터 양이 많아지면서 DBMS 에서 정렬 회피.
SELECT department_id, job_id, SUM(salary), COUNT(*)
FROM employees
GROUP BY department_id, job_id
ORDER BY 1, 2 DESC;

SELECT department_id, job_id, SUM(salary), COUNT(*)
FROM employees
WHERE department_id > 60
GROUP BY department_id, job_id
ORDER BY 1, 2 DESC;

-- COUNT(*) 가 1이 아닌 것을 보고 싶은데 에러남.
-- WHERE 절은 행을 선택 한다. 행을 셀렉션하지 않은 상태로 그룹함수를 쓸 수 없다.
SELECT department_id, job_id, SUM(salary), COUNT(*)
FROM employees
WHERE COUNT(*) <> 1
GROUP BY department_id, job_id
ORDER BY 1, 2 DESC;
/*
ORA-00934: 그룹 함수는 허가되지 않습니다
*/

-- 그래서 WEERE 절을 GROUP BY 절을 쓰면 에러.
-- WHERE 절은 행을 제한. GROUP을 제한할 때는 HAVING 사용
SELECT department_id, job_id, SUM(salary), COUNT(*) FROM employees
GROUP BY department_id, job_id
WHERE COUNT(*) <> 1
ORDER BY 1, 2 DESC;
/*
ORA-00933: SQL 명령어가 올바르게 종료되지 않았습니다
*/

-- WHERE 절은 행을 제한. GROUP을 제한할 때는 HAVING 사용
SELECT department_id, job_id, SUM(salary), COUNT(*)
FROM employees
GROUP BY department_id, job_id
HAVING COUNT(*) <> 1
ORDER BY 1, 2 DESC;
/*
30	PU_CLERK	13900	5
50	ST_MAN	36400	5
50	ST_CLERK	55700	20
50	SH_CLERK	64300	20
60	IT_PROG	28800	5
80	SA_REP	243500	29
80	SA_MAN	61000	5
90	AD_VP	34000	2
100	FI_ACCOUNT	39600	5
*/

SELECT department_id, job_id, SUM(salary), COUNT(*)
FROM employees
WHERE department_id > 50
GROUP BY department_id, job_id
HAVING COUNT(*) <> 1
ORDER BY 1, 2 DESC;
/*
60	IT_PROG	28800	5
80	SA_REP	243500	29
80	SA_MAN	61000	5
90	AD_VP	34000	2
100	FI_ACCOUNT	39600	5
*/

SELECT department_id, job_id, SUM(salary), COUNT(*)
FROM employees
GROUP BY department_id, job_id
ORDER BY 1, 2 DESC;
/*
10	AD_ASST	4400	1
20	MK_REP	6000	1
20	MK_MAN	13000	1
30	PU_MAN	11000	1
30	PU_CLERK	13900	5
40	HR_REP	6500	1
50	ST_MAN	36400	5
50	ST_CLERK	55700	20
50	SH_CLERK	64300	20
60	IT_PROG	28800	5
70	PR_REP	10000	1
80	SA_REP	243500	29
80	SA_MAN	61000	5
90	AD_VP	34000	2
90	AD_PRES	24000	1
100	FI_MGR	12008	1
100	FI_ACCOUNT	39600	5
110	AC_MGR	12008	1
110	AC_ACCOUNT	8300	1
(null)	SA_REP	7000	1
*/

SELECT department_id, SUM(salary), COUNT(*)
FROM employees
GROUP BY department_id
ORDER BY 1 DESC;
/*
	7000	1
110	20308	2
100	51608	6
90	58000	3
80	304500	34
70	10000	1
60	28800	5
50	156400	45
40	6500	1
30	24900	6
20	19000	2
10	4400	1
*/

SELECT SUM(salary), COUNT(*)
FROM employees;
691416	107

-- ROLLUP : 부서의 서브토탈 구하기
SELECT department_id, job_id, SUM(salary), COUNT(*)
FROM employees
GROUP BY ROLLUP(department_id, job_id)
ORDER BY 1, 2;
/*
10	AD_ASST	4400	1
10(null)	4400	1
20	MK_MAN	13000	1
20	MK_REP	6000	1
20(null)	19000	2
30	PU_CLERK	13900	5
30	PU_MAN	11000	1
30(null)	24900	6
40	HR_REP	6500	1
40(null)	6500	1
50	SH_CLERK	64300	20
50	ST_CLERK	55700	20
50	ST_MAN	36400	5
50(null)	156400	45
60	IT_PROG	28800	5
60(null)	28800	5
70	PR_REP	10000	1
70(null)	10000	1
80	SA_MAN	61000	5
80	SA_REP	243500	29
80(null)	304500	34
90	AD_PRES	24000	1
90	AD_VP	34000	2
90(null)	58000	3
100	FI_ACCOUNT	39600	5
100	FI_MGR	12008	1
100(null)	51608	6
110	AC_ACCOUNT	8300	1
110	AC_MGR	12008	1
110(null)	20308	2
	SA_REP	7000	1
(null)	7000	1
(null)	691416	107
*/

/*
GROUP BY ROLLUP (a, b, c)
(a, b, c)
(a, b)
(a)
() -> GROUP BY 안한 결과
*/

-- CUBE : 부서의 서브토탈 구하기
-- 컴럼 수의 제곱 만큼 결과가 만들어짐
SELECT department_id, job_id, SUM(salary), COUNT(*)
FROM employees
GROUP BY CUBE(department_id, job_id)
ORDER BY 1, 2;
/*
10	AD_ASST	4400	1
10		4400	1
20	MK_MAN	13000	1
20	MK_REP	6000	1
20		19000	2
30	PU_CLERK	13900	5
30	PU_MAN	11000	1
30		24900	6
40	HR_REP	6500	1
40		6500	1
50	SH_CLERK	64300	20
50	ST_CLERK	55700	20
50	ST_MAN	36400	5
50		156400	45
60	IT_PROG	28800	5
60		28800	5
70	PR_REP	10000	1
70		10000	1
80	SA_MAN	61000	5
80	SA_REP	243500	29
80		304500	34
90	AD_PRES	24000	1
90	AD_VP	34000	2
90		58000	3
100	FI_ACCOUNT	39600	5
100	FI_MGR	12008	1
100		51608	6
110	AC_ACCOUNT	8300	1
110	AC_MGR	12008	1
110		20308	2
	AC_ACCOUNT	8300	1
	AC_MGR	12008	1
	AD_ASST	4400	1
	AD_PRES	24000	1
	AD_VP	34000	2
	FI_ACCOUNT	39600	5
	FI_MGR	12008	1
	HR_REP	6500	1
	IT_PROG	28800	5
	MK_MAN	13000	1
	MK_REP	6000	1
	PR_REP	10000	1
	PU_CLERK	13900	5
	PU_MAN	11000	1
	SA_MAN	61000	5
	SA_REP	7000	1
	SA_REP	250500	30
	SH_CLERK	64300	20
	ST_CLERK	55700	20
	ST_MAN	36400	5
		7000	1
		691416	107
*/

/* 2^n 만큼 결과 출력. 2^3=8
GROUP BY CUBE (a, b, c) --> 8i 부터 나옴
a, b, c
a, b
a, c
b, c
a,
b,
c,
() -> GROUP BY 를 지정하지 않은 전체 토탈
*/

-- 마지막 () : total
SELECT department_id, manager_id, job_id, SUM(salary), COUNT(*)
FROM employees
GROUP BY GROUPING SETS ((department_id, manager_id), (manager_id, job_id), ())
ORDER BY 1, 2, 3;


/* null 의 의미
1. 데이터가 널이라서 만들어짐
2. 사용되지 않아서 널
--> 이 둘이 식별이 잘 안됨.
*/

SELECT department_id, job_id, SUM(salary), COUNT(*),
       GROUPING(department_id) GRP_deptid,
       GROUPING(job_id) GRP_jobid
FROM employees
GROUP BY ROLLUP(department_id, job_id)
ORDER BY 1, 2;
/*
10	AD_ASST	4400	1	0	0
10		4400	1	0	1
20	MK_MAN	13000	1	0	0
20	MK_REP	6000	1	0	0
20		19000	2	0	1
30	PU_CLERK	13900	5	0	0
30	PU_MAN	11000	1	0	0
30		24900	6	0	1
40	HR_REP	6500	1	0	0
40		6500	1	0	1
50	SH_CLERK	64300	20	0	0
50	ST_CLERK	55700	20	0	0
50	ST_MAN	36400	5	0	0
50		156400	45	0	1
60	IT_PROG	28800	5	0	0
60		28800	5	0	1
70	PR_REP	10000	1	0	0
70		10000	1	0	1
80	SA_MAN	61000	5	0	0
80	SA_REP	243500	29	0	0
80		304500	34	0	1
90	AD_PRES	24000	1	0	0
90	AD_VP	34000	2	0	0
90		58000	3	0	1
100	FI_ACCOUNT	39600	5	0	0
100	FI_MGR	12008	1	0	0
100		51608	6	0	1
110	AC_ACCOUNT	8300	1	0	0
110	AC_MGR	12008	1	0	0
110		20308	2	0	1
	SA_REP	7000	1	0	0
		7000	1	0	1
		691416	107	1	1
*/

-- 00, 01, 10, 11 --> 0, 1, 2, 3
-- 00: department_id, job_id 둘다 사용
SELECT department_id, job_id, SUM(salary), COUNT(*),
       GROUPING(department_id) GRP_deptid,
       GROUPING(job_id) GRP_jobid,
       GROUPING_ID(department_id, job_id) GRP
FROM employees
GROUP BY ROLLUP(department_id, job_id)
ORDER BY 1, 2;
/*
10	AD_ASST	4400	1	0	0	0
10		4400	1	0	1	1
20	MK_MAN	13000	1	0	0	0
20	MK_REP	6000	1	0	0	0
20		19000	2	0	1	1
30	PU_CLERK	13900	5	0	0	0
30	PU_MAN	11000	1	0	0	0
30		24900	6	0	1	1
40	HR_REP	6500	1	0	0	0
40		6500	1	0	1	1
50	SH_CLERK	64300	20	0	0	0
50	ST_CLERK	55700	20	0	0	0
50	ST_MAN	36400	5	0	0	0
50		156400	45	0	1	1
60	IT_PROG	28800	5	0	0	0
60		28800	5	0	1	1
70	PR_REP	10000	1	0	0	0
70		10000	1	0	1	1
80	SA_MAN	61000	5	0	0	0
80	SA_REP	243500	29	0	0	0
80		304500	34	0	1	1
90	AD_PRES	24000	1	0	0	0
90	AD_VP	34000	2	0	0	0
90		58000	3	0	1	1
100	FI_ACCOUNT	39600	5	0	0	0
100	FI_MGR	12008	1	0	0	0
100		51608	6	0	1	1
110	AC_ACCOUNT	8300	1	0	0	0
110	AC_MGR	12008	1	0	0	0
110		20308	2	0	1	1
	SA_REP	7000	1	0	0	0
		7000	1	0	1	1
		691416	107	1	1	3
*/

/*
https://github.com/my-ciel/SQL_Labs
https://bit.ly/3IpjPzL

오라클 10g 부터 정규표현식 함수 5개 추가
REGEXP_LIKE
REGEXP_REPLACE
REGEXP_INSTR
REGEXP_SUBSTR
REGEXP_COUNT

서울특별시 강남구
인천광역시 중구

김천시 동구
안동시 북구
순천시

구만 가져오고 싶을때 위치값을 지정하는 substr 가 안맞음.
비슷한 개념으로 INSTR 도 안맞음.

REGEXP_LIKE (first_name, '^Ste(v|ph)en$')
Ste로시작하고 en으로 끝나고, 중간에 v 나 ph 가 들어가는 문자열

REGEXP_LIKE (phone_number, '..\.....\.......')
. : 하나가 임의의 한문자를 대신한다.
\. : 진짜 점

[0-9] 범위 지정. 0~9 사이의 숫자
{2} 반복횟수. 2번
{2,} 반복횟수. 최소 2번, 2번 이상
{2,5} 반복횟수. 2번 이상 5번 이하
\d : digit. [0-9]와 같음

*/

--다음 예제는 'Steven' 또는 'Stephen' 의 문자열을 검색 합니다.

SELECT first_name, last_name 
FROM employees
WHERE REGEXP_LIKE (first_name, '^Ste(v|ph)en$') ;
/*
Steven	King
Steven	Markle
Stephen	Stiles
*/

-- \. : 문자, 숫자 모두 가능
SELECT first_name, phone_number
FROM employees
WHERE REGEXP_LIKE (phone_number, '..\.....\.......') ;
/*
John	44.1632.960000
Karen	44.1632.960001
(후략)
*/

--다음과 같이 각각의 자리마다 숫자가 반복 되는 회수를 지정할 수 있으며 원하는 문자열이 포함 된 것을 찾을 수 있습니다.
SELECT first_name, phone_number
FROM employees
WHERE REGEXP_LIKE (phone_number, '[0-9]{2}\.[0-9]{4}\.[0-9]{6}'); 

SELECT first_name, phone_number
FROM employees 
WHERE REGEXP_LIKE (phone_number, '\d{2}\.\d{4}\.\d{6}'); 

-- REPLACE
SELECT REPLACE('jack and jue', 'j', 'Bl') FROM dual;
/*
Black and Blue
*/

SELECT first_name, REPLACE(first_name, SUBSTR(first_name, 2, 2), '**')
FROM employees;
/*
Steven	S**ven
Neena	N**na
*/

--다음 예제는 3 자리로 표현 되는 전화 번호를 검색하여  3개의 그룹 문자를 표현하며 1번 그룹은 ( ) 로 감싸고 구분자는 "-" 사용하는 예제입니다.
SELECT first_name, phone_number, 
       REGEXP_REPLACE (phone_number, '(\d{2})\.(\d{4})\.(\d{6})','(\1)-\2-\3')   
       AS new_phone 
FROM employees ; 
/* 형식에 맞는 건 변환함
Peter	1.650.555.0144	1.650.555.0144
John	44.1632.960000	(44)-1632-960000
*/

--지정된 Class 가 알파벳이므로  주소에서 첫 번째 알파벳 문자의 위치를 검색 합니다.
-- 알파벳이 포함된 postal_code 를 사용하는 나라도 있다.
-- REGEXP_INSTR (street_address, '[[:alpha:]]' )
--     첫번째 알파벳이 나오는 위치를 반환. 숫자로만 이루어진 건 0을 반환.
-- INSTR 쓰면 a, b, c 모두 함수를 사용해야 한다. -> '[[:alpha:]] 를 사용하면 한번에 된다.
-- REGEXP_INSTR (postal_code, '[[:alpha:]]')
--    숫자로만 이루어지지 않은 우편번호 검색
SELECT location_id, city,
       street_address, REGEXP_INSTR (street_address, '[[:alpha:]]' ) addr , 
       postal_code, REGEXP_INSTR (postal_code, '[[:alpha:]]') pos 
FROM locations ;

/*
서울특별시 강남구 대치동
인천광역시 중구 운서동

김천시 동구
안동시 북구
순천시

주소에서 구만 추출: 처음 공백이 나오는 위치와 두번째 공백이 나오는 위치의 문자열을 가져와.

- 일반 사용 용도인 경우
- 분석용도인 경우: 시별, 구별, 동별 따로 필요한 경우가 있다.
*/

--다음 예제는 정규식을 사용하여 주소에서 두 번째 문자열인 (Road)을 추출합니다.
-- ' [^ ]+ '
-- [^ ] : 공백이 아닌(^)
-- + : 횟수. 한번 이상
-- 공백과 공백사이에 공백이 아닌 문자 1개 이상 가져옴.
SELECT location_id, street_address, 
       REGEXP_SUBSTR (street_address, ' [^ ]+ ') road 
FROM locations;
/*
1000	1297 Via Cola di Rie	 Via 
1100	93091 Calle della Testa	 Calle 
1200	2017 Shinjuku-ku	
1300	9450 Kamiya-cho	
*/

-- 정규표현식 함수도 일반함수와 중첩 가능하다
-- '\.(\d{3})\.' : .과 .사이에 3자리 숫자 가져와라.
-- 활용: 전화번호에서 지역번호 추출
--다음 예제는 지역번호를 뺀 국번만 추출합니다. 양쪽 끝의 '.' 문자를 없애기 위해 REPLACE 함수를 함께 사용합니다.
SELECT first_name, phone_number, 
       REGEXP_SUBSTR(phone_number,'\.(\d{3})\.'),
       REPLACE(REGEXP_SUBSTR(phone_number,'\.(\d{3})\.'),'.') code 
FROM employees ; 
/*
Steven	1.515.555.0100	.515.	515
Neena	1.515.555.0101	.515.	515
*/

--다음 예제는 이름(first_name)에서 ＇a＇ 가 발견 된 횟수를 검색 합니다.
SELECT employee_id, first_name,
       REGEXP_COUNT(first_name,'a') cnt 
FROM employees ; 
/*
100	Steven	0
101	Neena	1
*/

--다음은 특정 DNA 시퀀싱에서 'gtc'가 나오는 나오는 횟수를 반환합니다. 
SELECT 
   REGEXP_COUNT('ccacctttccctccactcctcacgttctcacctgtaaagcgtccctc
   cctcatccccatgcccccttaccctgcagggtagagtaggctagaaaccagagagctccaagc
   tccatctgtggagaggtgccatccttgggctgcagagagaggagaatttgccccaaagctgcc
   tgcagagcttcaccacccttagtctcacaaagccttgagttcatagcatttcttgagttttca
   ccctgcccagcaggacactgcagcacccaaagggcttcccaggagtagggttgccctcaagag
   gctcttgggtctgatggccacatcctggaattgttttcaagttgatggtcacagccctgaggc
   atgtaggggcgtggggatgcgctctgctctgctctcctctcctgaacccctgaaccctctggc
   taccccagagcacttagagccag', 
	'gtc') "Count"
FROM dual;
/*
4
*/


-- REGEXP_SUBSTR은 서브표현식 문자열의 해당 되는 부분을 추출할 수 있습니다. 다음을 실행하여 각 하위식을 식별할 수 있습니다.
-- i : case insensitive 의 약자. 여기에서는 숫자이므로 상관 없음
-- 일반적인 수식은 안에서 바깥으로, 정규표현식은 바깥에서 안으로.
-- 괄호가 한겹: 123, 45678 / 괄호가 중첩: 56, 78
SELECT REGEXP_SUBSTR ('0123456789', 
		'(123)(4(56)(78))', 1, 1, 'i', 1 ) "Exp1" , 
	 REGEXP_SUBSTR ('0123456789', 
		'(123)(4(56)(78))', 1, 1, 'i', 2 ) "Exp2" , 
	 REGEXP_SUBSTR ('0123456789', 
		'(123)(4(56)(78))', 1, 1, 'i', 3 ) "Exp3" , 
	 REGEXP_SUBSTR ('0123456789', 
		'(123)(4(56)(78))', 1, 1, 'i', 4 ) "Exp4"
FROM dual;
/*
123	45678	56	78
*/

--예제는 12345678 의 문자 패턴을 비교하면서 두 번째 하위식을 검색하며 45678 의 문자열이 시작되는 위치를 반환합니다.
-- 5번째 인자 : 지시한 그글자. 1 : 그 다음 글자
SELECT REGEXP_INSTR ('0123456789','(123)(4(56)(78))', 1, 1, 0, 'i', 2 )          
       AS "Position" 
FROM dual;
/*
5
*/

SELECT REGEXP_INSTR ('0123456789','(123)(4(56)(78))', 1, 1, 0, 'i', 3 )          
       AS "Position" 
FROM dual;
/*
6
*/

-- '(gtc(tcac)(aaag))' 중에 gtc 의 위치를 찾음
--DNA에서 특정 하위 패턴을 찾으려고 합니다. 예제에서는 첫번째 하위식 (gtc)의 위치가 반환됩니다.
SELECT 
   REGEXP_INSTR('ccacctttccctccactcctcacgttctcacctgtaaagcgtccctc
   cctcatccccatgcccccttaccctgcagggtagagtaggctagaaaccagagagctccaagc
   tccatctgtggagaggtgccatccttgggctgcagagagaggagaatttgccccaaagctgcc
   tgcagagcttcaccacccttagtctcacaaagccttgagttcatagcatttcttgagttttca
   ccctgcccagcaggacactgcagcacccaaagggcttcccaggagtagggttgccctcaagag
   gctcttgggtctgatggccacatcctggaattgttttcaagttgatggtcacagccctgaggc
   atgtaggggcgtggggatgcgctctgctctgctctcctctcctgaacccctgaaccctctggc
   taccccagagcacttagagccag', 
	'(gtc(tcac)(aaag))', 
	1, 1, 0, 'i', 
	1) "Position"
FROM dual;

