--Hive语法学习(2)

--1.登录数据库操作
mysql -h localhost -u root -p


--2.表的操作
create databases cp character set UTF8; --使用UTF-8编码
use cp;

create table news(
	nid int primary key auto_increment,
	sid int unique,
	title varchar(50) not null,
	content text,
	constraint wid_fk foreign key(wid) references department(wid),
	index index_1 (nid ASC)
)engine=innodb;

--auto_increment: 自动增长方式进行
--engine=innodb：为默认的数据引擎，支持事物处理功能

desc news; --查看基本结构语句
show create table news\G --查看详细结构

drop table news; --删除表；如果有该表有字段作为其他表的外键时，需要在其他表中先删除外键，否则基于关联关系，删除报错
drop database cp; --删除数据库


--3.插入数据
insert into news (nid,sid,title,content) values (1,1,'小刁做扫除','举国喜庆十一'); --选择字段插入数据
insert into news values (2,3,'小刁做扫除','举国喜庆十一'); --默认插入所有字段数据
insert into news values (3,4,'小刁做扫除','举国喜庆十一');

insert into news values
	(1,1,'小刁做扫除','举国喜庆十一'),
	(2,3,'小刁做扫除','举国喜庆十一'),
	(3,4,'小刁做扫除','举国喜庆十一'); --同时插入多条记录

insert into news (nid,sid,title,content) values 
	(select nid,sid,title,content from employee where id>2001 and id<2050); --查询结果插入表


--4.更新数据
update news set name="zhangz",age=18 where d_id=1001;


--5.删除数据
delete from news where id=1001;
delete from news; --删除表news中所有数据


--6.更改表属性
alter table news rename to new; --修改表名为new
alter table news modify sid varchar(100); --修改字段sid的数据类型
alter table news modify title varchar(50) first; --移动title字段到第一位
alter table news modify title varchar(50) after content; --移动title字段到content之后
alter table news change sid ssid varchar(100); --修改字段sid的名字，也可以同时修改数据类型
alter table news add phone varchar(20) not null after title; --在title字段后面添加命名为phone的字段
alter table news add phone varchar(20) primary key first; --在第一个字段位置添加命名为phone的字段
alter table news add constraint phone_fk foreign key(phone); --添加外键
alter table news drop phone; --删除表中名为phone的字段
alter table news drop foreign key wid_fk; --删除外键wid_fk
alter table news engine="MyISAM"; --更改存储引擎为MyISAM，默认为InnoDB


--7.索引操作
--建立普通索引
create table index1(
	id int,
	name varchar(20),
	sex boolean,
	index(id)
)

--建立唯一索引
create table index1(
	id int,
	name varchar(20),
	sex boolean,
	unique index index_1 (id ASC)
)

--建立全文索引（仅限于MyISAM引擎、并且是char/varchar/text类型的字段）
create table index1(
	id int,
	name varchar(20),
	sex boolean,
	fulltext index index_2 (name ASC)
)

--建立单列索引
create table index1(
	id int,
	name varchar(20),
	sex boolean,
	index index_3 (name(10) ASC) --10<20,提高查询速度
)

--建立多列索引
create table index1(
	id int,
	name varchar(20),
	sex boolean,
	index index_4 (name,sex) --查询时，只有使用了多列索引中第一个字段name，索引才会被启用
)

--create 索引类型 index 索引名 on 表名 (字段名(字段长度) 正序|倒序);
create unique index index_1 on news (name(10) desc);

--alter语句创建索引
alter table news add unique index index_1 (name(10) asc);

--删除索引
drop index index_1 on news;


--8. 查询操作
select id,name,sex,score from news
	where name like "wang%"
	group by sex having sum(score) >10
	order by id asc;

select * from news where id in (1,3,5);
select * from news where id not in (1,3,5);
select * from news where age between 18 and 28;
select * from news where age not between 18 and 28;
select * from news where name like "aric%"; --以aric开头的
select * from news where name like "a_c";  --_仅代表一个字符
select * from news where name not like "aric%";
select * from news where sex is null;
select * from news where id=2 and age<26 and sex like "男";
select distinct id from news;
select * from news order by id asc, age desc;
select * from news group by sex;
select sex, group_concat(name) from news group by sex; --group_concat用于显示各个分组指定字段的所有元素
select sex, count(*) as A from news group by sex;

select sex, count(sex) from news 
	group by sex having count(sex)>2; --having表达式用于group by后面，用于对分组结果进行筛选

select * from news group by sex,id;

select sex,count(sex) from news 
	group by sex with rollup; --with rollup用于计算各个分组的计数

select last_insert_id(); --最后一次增长的ID
select * from news limit 0,3; --从第1条记录开始取3条记录(下标从0开始)，limit 初始位置,记录数
select * from news limit 2,4; --从第3条记录开始取4条记录

select news.name,employee.name,age,sex from news,employee 
	where news.id = employee.id
	and age>24;

select news.name,employee.name,age,sex,count(sex)
	from news
	left join employee 
	on news.id = employee.id
	where age>24
	and order by age asc;

select * from news
	where d_id in
		(select d_id from department);

select id,name,score from student
	where score>=
		(select score from scholarship
			where level=1); --in,>,<,=,<>

select * from employee
	where age>24 and exists
		(select d_name from department
			where d_id=1003); --not exists

select * from employee
	where age > any
		(select age from department 
			where sex='nan'); --any表示大于任何一个，即可返回结果

select * from employee
	where age > all
		(select age from department 
			where sex='nan'); --all表示大于所有值，才返回结果

select name from employee
	union all
	select d_name from department; --union会将结果去重复，union all不去重复

select * from employee e where e.sex='nan'; --为表取别名
select sex,count(sex) as sex_count from employee; --为字段取别名
select d.d_id as department_id,d.sex as sex_id from department d where d.d_id=1001;

select * from employee where name regexp '^L'; --正则表达式，以L开头
--$ 结尾
--. 任意一个字符
--[abcdefg]或[a-g]或[a-z0-9] 指定字符中任何一个
--[^abcdefg] 指定字符外的字符
--a|zz|cG 匹配任意一个
--+和* 匹配多个字符，*可以匹配0个字符，+匹配至少一个字符
--aa{3} aa出现3次
--aa{m,n} aa出现至少m次，至多n次

--eg.同时参加了计算机和英语考试的学生信息
select * from student where id =any(
	select stu_id from score where stu_id in(
		select stu_id from score where c_name="计算机")
	where c_name="英语"
);
--or
select * from student where id in (
	select stu_id from score where c_name="计算机" and stu_id in (
		select stu_id from score where c_name="英语"
	)
);



--9. 常用函数
--数值函数
abs
floor
ceiling
rand
sign(x) --signmod函数
truncate(x,y) --x小数保留y位
round
power
exp
mod(x,y) --x除以y后的余数
log
log10
count
sum
avg

--字符串函数
length
concat(s1,s2) --合并字符串 select concat(sid,number) from news;
insert(s1,x,len,s2) --s1(x,s1)被s2替换
upper
lower
left(s,n) --返回字符串s的前n个字符
right(s,n)
trim(s) --去掉字符串s开始和结尾处的空格
ltrim(s)
rtrim(s)
repeat(s)
regexp

--日期函数
curdate()
current_date()
current_time()
now()
localtime()
year(d) --返回d中的年份值
month(d)
dayname(d)
hour(t)
to_date()


--聚合函数
collect_set()
collect_list()



--10. 条件判断函数
if(expr,v1,v2) --expr条件成立，返回v1，否则返回v2，select id,grade,content (if grade>=60,'pass','fail') from news;
ifnull(v1,v2) --如果v1不为空，就返回v1值，否则返回v2值，select id,grade ifnull(grade,'no grade') from news;
case when expr1 then v1 
	when expr2 then v2 
	else v3 end

select id,grade case
	when grade>60 then 'good'
	when grade=60 then 'pass'
	else 'fail' end level from news; --level为good/pass/fail的列名

case expr when e1 then v1 
	when e2 then v2 
	else v3 end

select id,grade case grade
	when 90 then 'good'
	when 60 then 'pass'
	when 50 then 'fail'
	else 'no grade' end level from news;


select age, (case sex when 'male' then 0 when 'female' when 1 else 2 end) as sex, score from news;
select sex, (case when age<20 then 1 when 20<age<40 then 0 else 2 end), score from news;



--11. 循环
--1）while循环
create procedure sum1(a int)
begin
	declare sum int default 0;  -- default 是指定该变量的默认值
	declare i int default 1;
	while i<=a DO -- 循环开始
		set sum=sum+i;
		set i=i+1;
	end while; -- 循环结束
	select sum;  -- 输出结果
end
call sum1(100); -- 执行存储过程
drop procedure if exists sum1; -- 删除存储过程

--2) loop循环
create procedure sum2(a int)
begin
	declare sum int default 0;
	declare i int default 1;
	loop_name:loop -- 循环开始
		if i>a then 
			leave loop_name;  -- 判断条件成立则结束循环  好比java中的 boeak
		end if;
	set sum=sum+i;
	set i=i+1;
	end loop;  -- 循环结束
	select sum; -- 输出结果
end
call sum2(100); -- 执行存储过程
drop procedure if exists sum2; -- 删除存储过程

--3）repeat循环
create procedure sum3(a int)
begin
	declare sum int default 0;
	declare i int default 1;
	repeat -- 循环开始
		set sum=sum+i;
		set i=i+1;
	until i>a end repeat; -- 循环结束
	select sum; -- 输出结果
end
call sum3(100); -- 执行存储过程
drop procedure if exists sum3; -- 删除存储过程



--12. over函数
row_number() over()
--row_number() OVER (PARTITION BY COL1 ORDER BY COL2)
--SELECT *, row_Number() OVER (partition by COL1 ORDER BY COL2 desc) rank FROM employee
select user_id, item_id, t.row_num from
(select user_id, item_id, row_number() over (partition by user_id order by current_date desc) as row_num from table2) t
where t.row_num = 1

select * from (select stu_id, row_number() over(partition by class order by age desc) rank from student ) where rank<=3;

rank() over() --dense_rank() over 连续排名，与rank() over()类似
select stu_id, class, stu_score, rank() over(order by stu_score desc) as score_rank from student where class='mysql'; --查询mysql课程的学生分数排名
select stu_id, class, stu_score, rank() over(partition by class order by stu_score desc) as score_rank from student; --查询各学科分数的学生排名
select stu_id, class, stu_score, rank() over(partition by class order by stu_score desc) as score_rank from student where score_rank<=2; --查询各学科排名前2名的学生

select stu_id,class,sum(stu_score) from student group by class,stu_id; --查询各学生总分

select t.*, rank() over(order by t.sum_score desc) as total_rank from 
(select stu_id,class,sum(stu_score) as sum_score from student as s1
group by stu_id,class ) t
--根据总分查询学生排名(先计算总分、后排名)

sum() over()
count() over()


	
--13. Python与mysql交互(python script)

--1) mysql数据导入到python
import pandas
from sqlalchemy import creat_engine
engine = create_engine('mysql+mysqlconnector://root:@127.0.0.1:3306/cp') --"mysql+mysqlconnector://用户名:密码@IP地址:端口号/数据库名"
data = pandas.read_sql("select * from news;",con=engine)


--2)python数据导入到mysql
from pandas import DataFrame;
from sqlalchemy import create_engine
engine = create_engine('mysql+mysqlconnector://root:@127.0.0.1:3306/cp')
data = DataFrame({'age':[21,22,23],'name':['KEN','大数据分析实战','小蚊子']})
data.to_sql("testTable",index=False,con=engine,if_exists='append')






