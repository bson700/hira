--SYS 사용자가 실행

DROP USER c##hr CASCADE;
CREATE USER c##hr IDENTIFIED BY oracle
DEFAULT TABLESPACE users
TEMPORARY TABLESPACE temp;

GRANT connect, resource, dba TO c##hr;
