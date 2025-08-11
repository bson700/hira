DROP INDEX emp_email_ix;
EXPLAIN PLAN FOR
SELECT first_name, email, salary
FROM employees
WHERE email='SKING';
SELECT * FROM table(dbms_xplan.display);
EXPLAIN PLAN FOR
SELECT /*+ INDEX(employees emp_email_ix) */ first_name, email, salary
FROM employees
WHERE email='SKING';
SELECT * FROM table(dbms_xplan.display);
CREATE INDEX emp_email_ix ON employees(email);
EXPLAIN PLAN FOR
SELECT /*+ INDEX(employees emp_email_ix) */ first_name, email, salary
FROM employees
WHERE email='SKING';
SELECT * FROM table(dbms_xplan.display);

EXPLAIN PLAN FOR
SELECT /*+ USE_NL(e d) */ e.employee_id, e.first_name, d.department_name
FROM employees e JOIN departments d 
ON e.department_id = d.department_id;
SELECT * FROM table(dbms_xplan.display);

EXPLAIN PLAN FOR
SELECT /*+ FULL(e) */ e.employee_id, e.last_name, e.salary
FROM employees e
WHERE e.salary > 10000;
SELECT * FROM table(dbms_xplan.display);

show parameter optimizer_mode
EXPLAIN PLAN FOR
SELECT /*+ ALL_ROWS */ employee_id, hire_date, manager_id, department_id
FROM employees
WHERE department_id > 50;
SELECT * FROM table(dbms_xplan.display);

--힌트변경 /*+ FIRST_ROWS(3) */

EXPLAIN PLAN FOR
SELECT /*+ RULE */ employee_id, hire_date, manager_id, department_id
FROM employees
WHERE department_id > 50;
SELECT * FROM table(dbms_xplan.display);
