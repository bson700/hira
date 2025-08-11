CREATE SEQUENCE member_id_seq;
create table member 
(member_id number,
age number(2));

insert into member(member_id, age)
select member_id_seq.nextval, dbms_random.value(1,19) from dual
connect by level <=50;
insert into member(member_id, age)
select member_id_seq.nextval, dbms_random.value(20,29) from dual
connect by level <=270;
insert into member(member_id, age)
select member_id_seq.nextval, dbms_random.value(30,39) from dual
connect by level <=330;
insert into member(member_id, age)
select member_id_seq.nextval, dbms_random.value(41,49) from dual
connect by level <=200;
insert into member(member_id, age)
select member_id_seq.nextval, dbms_random.value(50,59) from dual
connect by level <=50;
insert into member(member_id, age)
select member_id_seq.nextval, 40 from dual
connect by level <=1000;
COMMIT;