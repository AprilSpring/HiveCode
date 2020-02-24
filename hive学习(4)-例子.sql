-- 例子

--数据表导入
hive> create table test_order_sample
(order_id string, seller_id string, price double, tag int, order_date string)
row format delimited fields terminated by ' ';

hive> load data
local inpath '/data/order_sample'
into table test_order_sample;


--例子1：统计出近一周每天成功支付的订单总数，gmv总额，平均客单价
select order_date, count(*), round(sum(price),2), round(avg(price),2)
from test_order_sample
where tag=1 and order_date >= date_sub(from_unixtime(unix_timestamp(),'yyyy-MM-dd'),7)
group by order_date
order by order_date desc;


--例子2：统计出近一周每天成功支付及支付失败各自的订单总数，gmv总额，平均客单价
select order_date, tag, count(*), round(sum(price),2), round(avg(price),2)
from test_order_sample
where order_date >= date_sub(from_unixtime(unix_timestamp(),'yyyy-MM-dd'),7)
group by order_date, tag
order by order_date desc;
--or
select order_date,
sum(if(tag=0,1,0)), sum(if(tag=0,price,0), avg(if(tag=0,price,0)),
sum(if(tag=1,1,0)), sum(if(tag=1,price,0), avg(if(tag=1,price,0)),
from test_order_sample
where order_date >= date_sub(from_unixtime(unix_timestamp(),'yyyy-MM-dd'),7)
group by order_date,
order by order_date desc;


--例子3：挑选出近一周gmv>1000并且订单量>2单的卖家ID及其订单
select seller_id, collect_set(order_id) as order_list
from test_order_sample
where tag=1 and order_date >= date_sub(from_unixtime(unix_timestamp(),'yyyy-MM-dd'),7)
group by seller_id
having sum(price) > 1000 and count(order_id) > 2;



