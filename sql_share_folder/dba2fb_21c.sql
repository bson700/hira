SET feedback OFF
SET serveroutput ON

conn SYS/oracle@LOCALHOST:1521/XEPDB AS sysdba
ALTER SYSTEM FLUSH BUFFER_CACHE ;

DECLARE
  l_dba   NUMBER := to_number('&dba','XXXXXXXX') ;
  l_file  NUMBER := dbms_utility.data_block_address_file(l_dba) ;
  l_block NUMBER := dbms_utility.data_block_address_block(l_dba) ;
BEGIN
  dbms_output.put_line('alter system dump datafile '||l_file||' block '||l_block||';') ;
  EXECUTE immediate 'alter system dump datafile '||l_file||' block '||l_block ;
END;
/

SET feedback ON
@@trace
