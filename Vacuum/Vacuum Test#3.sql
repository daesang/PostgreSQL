show autovacuum_vacuum_threshold
-- 50
show autovacuum_vacuum_scale_factor
--0.2

show autovacuum_naptime

/*
Therefore autovacuum_vacuuum_threshold says that we need 20% and that 20% must be at least 50 rows.
Otherwise, VACUUM won't kick in.

AutoVacuum은 (삭제된 행)/(전체행) 이 20%가 되어야 하고, 그 20%는 최소한 50줄 이여야 한다.

전체 행  : 100000
삭제 행 : 100000 * 0.15 = 15000


*/

한 테이블이 vacuum 작업 없이 계속 트랜잭션 작업을 할 수 있는 간격은 그 테이블의 마지막 vacuum 이후부터
20억 - vacuum_freeze_min_age 값만큼의 트랜잭션이다. 즉, 이 이상 트랜잭션이 발생했고, vacuum 작업이 없었다면,
자료를 잃게 된다. 물론 현실적으로 이런 사태는 일어나지 않는다. 왜냐하면, autovacuum 기능을 사용하지 않더라도,
autovacuum_freeze_max_age(200000000) 환경 설정 값으로 지정한 간격이 생기면,
강제로 서버는 자체적으로 vacuum 작업을 진행하기 때문이다

한 테이블에 대해 vacuum 작업을 한 번도 하지 않았더라도 autovacuum_freeze_max_age - vacuum_freeze_min_age 값 만큼의
트랜잭션이 발생했다면, autovacuum 작업이 자동으로 진행된다.
-- autovacuum 작업이 자동으로 진행된다.
한 테이블에 대해 vacuum 작업을 한 번도 하지 않았더라도
autovacuum_freeze_max_age - vacuum_freeze_min_age 값 만큼의 트랜잭션이 발생했다면, autovacuum 작업이 자동으로 진행된다.
200000000 - 50000000

autovacuum_freeze_max_age - vacuum_freeze_min_age = vacuum_freeze_table_age
200000000 - 50000000 = 150000000

vacuum_freeze_table_age(150000000) 설정에 대한 최대값은 autovacuum_freeze_max_age(200000000) * 0.95 이다.
SELECT 200000000 * 0.95;
--190000000

표준 VACUUM 작업은 마지막 vacuum 작업이 있은 뒤부터 변경된 데이터 페이지들에 대해서만 작업 대상으로 삼는다.
하지만, 다음 세가지 경우에는 테이블의 모든 페이지를 조사한다.

1. 이 relfrozenxid 값을 조사해서, 이 값의 나이가 vacuum_freeze_table_age 값 보다 크다
vacuum_freeze_table_age
150000000

2. VACUUM 명령어에서 FREEZE 옵션을 사용할 때도 모든 페이지를 조사한다.

3.더 이상 사용되지 않는 자료를 정리하는 작업이 모든 페이지에 걸쳐 있어야 하는 경우에도 같은 작업을 한다.

 작업이 끝난 뒤 해당 테이블의 age(relfrozenxid) 값은 vacuum_freeze_min_age(50000000) 약간 큰 값으로 보여진다.

만일, VACUUM 작업을 계속 주기적으로 했으나, 항상 변경된 페이지들만 조사하는 작업만 했다면,
age(relfrozenxid) 값이 autovacuum_freeze_max_age(200000000) 값만큼 이르렀을 때 autovacuum 데몬에 의해
강제로 테이블의 모든 페이지를 조사해서 트랜잭션 ID 겹침 오류를 방지한다.


--AutoVacuum
테이블의 나이(relfrozenxid 칼럼 값을 age() 함수로 조사한 값)가 autovacuum_freeze_max_age (200000000)
설정으로 지정한 트랜잭션 수 보다 많다면, 그 테이블은 무조건 vacuum 작업을 한다

테이블의 relfrozenxid 나이값이 vacuum_freeze_table_age(150000000) 설정값보다 크다면, 테이블의 모든 로우를 조사해서,
영구 보관용 XID로 바꾸고, relfrozenxid 값을 변경 한다. 그렇지 않은 경우는 마지막 vacuum 작업 뒤 변경된 자료 페이지만을 대상으로 작업한다.


--reltuples
select reltuples  from pg_class
where relname = 'employee'

ALTER TABLE employee SET (autovacuum_enabled = true);

SELECT *
FROM pg_settings
WHERE name LIKE '%log_autovacuum_min_duration%'


SELECT reloptions
FROM pg_class
WHERE relname = 'employee';


---
show  vacuum_freeze_table_age
--150000000

--AutoVacuum실행 조건 1
-- 테이블 의 relfrozenxid 값이 vacuum_freeze_table_age 트랜잭션 보다 오래되면,
--오래된 튜플을 동결시키고 relfrozenxid를 진행시키기 위해 공격적인 진공이 수행됩니다
--db의 relfrozenxid 값이 vacuum_freeze_table_age  값보다 크면
--Autovacumm  freeze 시킨다.
--#1
SELECT c.oid::regclass as table_name,
       greatest(age(c.relfrozenxid),age(t.relfrozenxid)) as age
FROM pg_class c
LEFT JOIN pg_class t ON c.reltoastrelid = t.oid
WHERE c.relkind IN ('r', 'm');

--#2
SELECT datname, age(datfrozenxid) FROM pg_database;


----------------

truncate table t_test;

---
drop table t_test;


CREATE TABLE t_test (
i1 int,
v1 char(1000)
);

--테이블 파일 경로 확인
SELECT pg_relation_filepath('t_test') --전체 경로
SELECT pg_relation_filenode('t_test') --최종파일
--base/12401/25760

insert into t_test
SELECT i,'abcd'
FROM generate_series(1, 250) a(i);
--13 MB

select 100000 - 84999

select count(*) from t_test;

DELETE from t_test
where i1  <= 100;

select dblink_connect('myconn', 'dbname=postgres port=5432 user=postgres password=0152');

select loop_insert_txid_bump_t(1, 50000);

SELECT pg_size_pretty(pg_relation_size('t_test'));
SELECT pg_relation_size('t_test'); --
--294912

select 16244736 - 14131200
2113536

--100개 , 16384

insert into t_test
SELECT i,'abcd'
FROM generate_series(1, 100) a(i);

select oid, relpages,relfilenode from pg_class where relname='t_test';
--1725

--AutoVacuum실행 조건2
https://www.postgresql.org/docs/9.6/static/routine-vacuuming.html

vacuum threshold = vacuum base threshold + vacuum scale factor * number of tuples

show autovacuum_vacuum_threshold
-- 50
show autovacuum_vacuum_scale_factor
--0.2

--행수
SELECT reltuples
FROM pg_class
WHERE relname = 't_test';

--삭제 행수가 이것보다 클경우 AutoVacuum에 포함된다.
SELECT   0.15 *  100000;

vacuum t_test;

--PG로그 자세히 기록
log_autovacuum_min_duration = 0
show log_autovacuum_min_duration -- -1 기본값

--autovacuum 모니터링
SELECT * FROM pg_stat_all_tables
WHERE RELNAME = 't_test'

show log_autovacuum_min_duration ;
set log_autovacuum_min_duration  "0"

pg_stat_all_tables.n_dead_tup >= threshold + pg_class.reltuples * scale_factor

show log_filename

select *
FROM pg_stat_user_tables s
INNER JOIN pg_class c ON s.relid = c.oid
INNER JOIN vacuum_settings v ON c.oid = v.oid
WHERE c.relname = 'employee'

and (v.autovacuum_vacuum_threshold + (v.autovacuum_vacuum_scale_factor::numeric * c.reltuples) < s.n_dead_tup)

select oid from pg_settings
where name IN( 'autovacuum_vacuum_threshold', 'autovacuum_vacuum_scale_factor')




--------------------------------------
drop table t_test;

cREATE TABLE t_test (id int) WITH (autovacuum_enabled = off);

INSERT INTO t_test
SELECT * FROM generate_series(1, 100000);

SELECT pg_size_pretty(pg_relation_size('t_test'));
--3544 kB

UPDATE t_test SET id = id + 1;

SELECT pg_size_pretty(pg_relation_size('t_test'));
--7080 kB

 VACUUM t_test;

 SELECT pg_size_pretty(pg_relation_size('t_test'));
-- 7080 kB

UPDATE t_test SET id = id + 1;

SELECT pg_size_pretty(pg_relation_size('t_test'));
--7080 kB

UPDATE t_test SET id = id + 1;

SELECT pg_size_pretty(pg_relation_size('t_test'));
--10 MB


VACUUM t_test;

UPDATE t_test SET id = id + 1;

VACUUM t_test;

SELECT pg_size_pretty(pg_relation_size('t_test'));
