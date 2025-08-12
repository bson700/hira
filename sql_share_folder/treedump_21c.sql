set echo off
set verify off

conn SYS/oracle@LOCALHOST:1521/XEPDB1 as sysdba

column object_name format a30
column object_id new_value obj_id

SELECT object_name, object_id
FROM all_objects
WHERE object_name = UPPER('&index_name')
  AND owner       = 'SQLT01'
  AND data_object_id IS NOT NULL ;

set echo on
ALTER SESSION SET EVENTS 'IMMEDIATE TRACE NAME TREEDUMP LEVEL &obj_id ' ;
set echo off

set PAUSE ON
@@trace
