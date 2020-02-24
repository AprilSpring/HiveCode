
Hive学习笔记

----------------------------我是分割线------------------------------

Hive基本语法


1. 选择语句
select  XXX  from  XXX  where  XXX  and  xxx; 


2. 快速创建自己的数据表
create table XXX as select XXX from XXXX where XXX and XXXX;

3. 关联语句
select  a.xx ,b.xx  from   XXX  a   join  XX  b  on （a. xx = b.xx）where  a.pt = ' ' and  a. OO = ' ' ;

4. 如何通过hive进行数据统计
select  xxxx , count( xx) as count  from  a  where  pt = ' '  group  by  xxxx   sort  by  count   desc ;

5. 创建带有分区的特定格式的表（可以根据时间不断向表格里添加数据）
CREATE EXTERNAL TABLE  ** (      -- **表示创建表的名字
seller_nick string ,                   
count string                      -- 定义表中的字段名，就是你想创建表的结构
) PARTITIONED BY ( ds string )     -- 时间分区ds
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','  
COLLECTION ITEMS TERMINATED BY '10'
STORED AS TEXTFILE;

6. 创建完成功后，需要向表中添加数据：
基本格式：insert overwrite table ** partition (ds = '**') 
             select  XX ,count(XXX) as  from  XXX   where  pt =' ';   --覆盖数据
或者  insert intotable **  partition（ds ='**'）
             select  XX ,count(XXX) as  from  XXX   where  pt =' ';   --追加数据

7. 举例子
--统计：乔阳 在７月１６日以后每天与多少个卖家发生了交易，并按照交易笔数对每天的卖家进行倒序排列。
CREATE EXTERNAL TABLE  buyer_qy  (    
seller_nick string ,                   
count string                    
) PARTITIONED BY ( ds string )    
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','  
COLLECTION ITEMS TERMINATED BY '10'
STORED AS TEXTFILE;    --我不会告诉你，我也是复制过来的
--表格创建一次就可以了，以后每天要运行的语句只有下面的这些咯！

insert overwrite table buyer_qy partition (ds = '20130716') 
           select  seller_nick , count (buyer_nick) as count  from r_gmv_alipay
where pt ='20130716000000' and  buyer_nick ='乔阳' 
group by seller_nick
sort by count desc ;
Tip：表格只要创建一次即可，每天通过insert语句不断向表格内填写数据就好啦，记得修改两个时间
 ① 填写表格时候的分区，即ds
 ② 获取数据表格的分区，即pt 

8. 多个条件匹配，要怎么写呢？
--验证8月1日和8月2日，昵称带有'乔阳'两个字的用户在掌上旺信或者湖畔上有登录过。
select  nick, loginfrom  from xuserloginsuccess2      
where ds ='20130801'and  ds  ='20130802'  --（两个并行的条件中间可以直接用and相连）
and （loginfrom ='zhangshangwangxin' or  loginfrom ='hupan'）;  --（两个选择条件中用or相连，必要时可以增加（
and nick like '%乔阳%';

9. 如何给特定的字段添加新的内容呢？
--要8月1日注册的用户在昵称后面统一添加cntaobao的标签。
select concat(nick,"cntaobao")  from  r_bmw_users_mv      -- contant(XXX,”**”)在筛选出来的每一个XXX字段后面增加**内容
where pt ='20130801000000'                          -- PT时间为年/月/日/小时/分钟/秒，所以需要在日期后面添加6个0
and user_regdate like '%2013-08-01%'                   -- like语句为模糊匹配，即字段含有'% ***%' ***内容就算命中
and suspended ='0';       

10. row_number函数
ROW_NUMBER() OVER(PARTITION BY COLUMN ORDER BY COLUMN)
--例如：求某一天内各个类目下成交件数前十的商品等。
select t.*, row_number() over(partition by t.category order by t.auction_count desc ) as rank from 
(select category, auction_id, count(user_id) as auction_count from xxx where ds ='xxxx' group by category, auction_id) t
where rank<=10;
## 备注
1) select * from (select stu_id, row_number() over(partition by class order by age desc) rank from student ) where rank <=3;
2) select t.* , rank() over(order by t.sum_score desc) as total_rank from 
(select stu_id, class, sum(stu_score) as sum_score from student as s1 group by stu_id, class) t

11. 条件判断
1）IF( Test Condition, True Value, False Value )
Example: IF(1=1, 'working', 'not working') returns 'working'

2）COALESCE( value1,value2,... ) --返回list中第一个不是null的值
Example: COALESCE(NULL,NULL,5,NULL,4)  -- 返回5

3）CASE Statement
Example:
CASE Fruit
WHEN 'APPLE' THEN 'The owner is APPLE'
WHEN 'ORANGE' THEN 'The owner is ORANGE'
ELSE 'It is another Fruit'
END

The other form of CASE is
CASE 
WHEN Fruit = 'APPLE' THEN 'The owner is APPLE'
WHEN Fruit = 'ORANGE' THEN 'The owner is ORANGE'
ELSE 'It is another Fruit'
END


----------------------------我是分割线------------------------------

Hive命令行执行语句

1. 非文件Hive查询
hive> select * from test limit 3;   --这个是注释符号
--or
hive -S -e "select * from test limit 3" > test.txt

2. 文件Hive查询
Eg,. /scripts/hive/test.hql
hive> source /scripts/hive/test.hql;
--or
hive -f /scripts/hive/test.hql

3. hive下执行Linux命令，加“!”
hive>! pwd;
--不支持管道和全局匹配


----------------------------我是分割线------------------------------
Hive优化 

1. 善用临时表
--如果某个表很大，可以先select部分字段成为临时表，再与其它表做join等连接操作，否则会由于大表扫描时间过长，拖长整个脚步时间。
CREATE TABLE temp_B AS SELECT id, price, feedback, type, attribute FROM B;

2. 一次执行多个COUNT
--如果我们要对多种条件进行COUNT，可以利用CASE语句进行，这样一条Hive QL就可以完成了。
SELECT COUNT(CASE WHEN type = 1 THEN 1 END), COUNT(CASE WHEN type = 2 THEN 1 END) FROM TABLE;

3. 导出表文件
首先需要用CREATE TABLE在HDFS上生成你所需要的表，当需要从HDFS上将表对应的文件导出到本地磁盘时有两种方式：

1）如果需要保持HDFS上的目录结构，原封不动地复制下来，采用下面的命令：
set hive.exec.compress.output='false';
INSERT OVERWRITE LOCAL DIRECTORY '/home/hesey/directory' select * from TABLE;
--这样下载下来的目录中会有很多由Reducer产生的part-*文件。

2）如果想把表的所有数据都下载到一个文件中，则采用下面的命令：
hadoop dfs -getmerge hdfs://hdpnn:9000/hesey/hive/TABLE /home/hesey/TABLE.txt
--这样所有文件会由Hadoop合并后下载到本地，最后就只有/home/hesey/TABLE.txt这一个文件。

4. UDF（user defined function）
1）如果是已经上传到Hive服务器的UDF，可以直接用
CREATE TEMPORARY FUNCTION dosomething AS 'net.hesey.udf.DoSomething';
--声明临时函数，然后在下面的Hive QL中就可以调用dosomething这个方法了。

2) 如果是自己编写的UDF，需要在声明临时函数前再加一行：
add jar /home/hesey/foo.jar
--这样就可以把自定义的UDF加载进来，然后和 1)一样声明临时函数就可以了。

5. JOIN的规则
--当Hive做JOIN运算时，JOIN前面的表会被放入内存，所以在做JOIN时，最好把小表放在前面，有利于提高性能并防止OOM。

6. 排序
--尽量采取分片排序，少用ORDER BY，尽量使用DISTRIBUTE BY和SORT BY：
SELECT user_id, amount FROM TABLE DISTRIBUTE BY user_id SORT BY user_id, amount
--这样最后排序的时候，相同的user_id和amount在同一个Reducer上被排序，不同的user_id可以同时分别在多个Reducer上排序，相比ORDER BY只能在一个Reducer上排序，速度有成倍的提升。

7. 
--统计每个action_type_id下有多少个不同的from_user_id：

--脚本1
select action_type_id
,count(distinct from_user_id) action_buyer_cnt
from tmp
group by action_type_id
--由于不同action_type_id，也就是key对应的数据量不同，即存在数据倾斜的现象，造成某个reduce过程耗时太长，影响整个运行时间。

--脚本2
select action_type_id
,count(*) as action_buyer_cnt
from 
(
​    select action_type_id
	,from_user_id
	from tmp
	group by action_type_id
	,from_user_id
)a
--由于按照action_type_id和from_user_id两个字段进行分组，使得数据分组相对均匀，避免某个reduce耗时过长的情况。



