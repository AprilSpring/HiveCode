-- Hive-sql learning

--1 显示表的分区
show partitions tablename; 

--2 创建表
CREATE
	TABLE login
	(
		Userid BIGINT,
		Ip STRING,
		time BIGINT
	)
	PARTITIONED BY
	(
		dt STRING
	)
	ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' STORED AS TEXTFILE;

--3 几种表的查询
--3.1 fdm拉链表
--拉链表获取最新数据
select * from fdm_xx_table_chain where dp='ACTIVE';

--还原拉链表2014-01-01线上数据
select * from fdm_xx_table_chain where start_date <= '2014-01-01' and end_date > '2014-01-01';
--提示：拉链表不建议使用dt分区。

--3.2 fdm增量表
--增量表获取2014-01-02当天数据
select * from fdm_xx_table where dt='2014-01-02';

--增量表获取2014-01-01到现在的数据
select * from fdm_xx_table where dt >= '2014-01-01';
--提示：fdm增量表通常是"dt + 日期字段"配合使用。

--3.3 gdm全量表
--全量表获取2014-01-01全量数据
select * from gdm_xx_table_da where dt='2014-01-02';

--全量表获取最新全量数据
select * from gdm_xx_table_da where dt = sysdate(-1);

--3.4 gdm增量表
--1) 以gdm_online_log为代表，数据按“昨日”增量加工(分区字段为dt)。加工方式同“fdm增量表加工方式”。
--增量表获取2014-01-01以后的数据
select * from gdm_xx_table where dt >= '2014-01-02';

--2) 以gdm_m04_ord_sum为代表，数据按“归档日期”增量加工(分区字段为dt、dp)。
--不同的gdm增量表有不同的归档原则（例如：订单gdm表根据订单数据，不定期进行归档；
--大部分gdm表按30/90/180天进行归档），所以在使用此类表的时候，一定要弄清楚表的归档原则。
--增量表获取2014-01-01用户下单的数据
select * from gdm_xx_table where dt >='2014-01-01' and 下单日期='2014-01-01';

--mapjoin
SELECT /*+ MAPJOIN(smalltable)*/  x.key, x.value
FROM smalltable JOIN bigtable ON smalltable.key = bigtable.key


/*=========================================================================*/
--eg1:统计[昨日][有效][订单数量]及[促销优惠金额]
select
	ord_dt
	count(sale_ord_id) as orders_count,
	sum(promotion_discount_amount) as promotion_discount_amount
from
	gdm.gdm_m04_ord_sum
where
	dp = 'ACTIVE' and
	valid_flag = 1 and
	ord_dt = sysdate(-1);

--eg2:统计[2014-06-01][有效][订单数量]及[促销优惠金额]
select
	ord_dt
	count(sale_ord_id) as orders_count,
	sum(promotion_discount_amount) as promotion_discount_amount
from
	gdm.gdm_m04_ord_sum
where
	dt >= '2014-06-01' and
	valid_flag = 1 and
	ord_dt = '2014-06-01';

--eg3:统计[昨日]按[一级分类]汇总[有效]订单[商品件数]
select
	item_first_cate_name，
	sum(sale_qtty) as sale_qtty
from
	gdm.gdm_m04_ord_det_sum
where
	dp = 'ACTIVE' and
	sale_ord_valid_flag = 1 and
	sale_ord_dt = sysdate(-1)
group by
	item_first_cate_name;


--想获取[2016-08-01]至[2016-10-31]号的下单情况
Select * from gdm.gdm_m04_ord_det_sum where  dt>='2016-08-01' and sale_ord_dt>='2016-08-01' and sale_ord_dt<='2016-10-31';

--获取[昨天]的下单情况
Select * from gdm.gdm_m04_ord_det_sum where dp='ACTIVE' and sale_ord_dt=sysdate(-1);

--查具体某个[订单]
Select * from gdm.gdm_m04_ord_det_sum where dt>='下单时间' and sale_ord_id='订单号' and sale_ord_dt='下单时间';
	
--[昨天][某个]商品的[销量]
Select sum(sale_qtty) from gdm.gdm_m04_ord_det_sum where dp='ACTIVE' and (item_sku_id='商品编号' or virtual_sku_id ='商品编号') and sale_ord_dt=sysdate(-1);


	
/*=========================================================================*/
--例子-1
select pur_bill_id 采购单号 , supp_brevity_cd 供应商简码 , create_tm 创建时间 , sku_id 商品sku , item_name 商品名称 , 
sum(uprc) 单价 , sum(original_price) 原价 , sum(mkt_prc) 市场价 , sum(into_wh_qtty) 实际入库数量, sum(originalnum) 原始下单数量 
from v_gdm_m04_pur_det_basic_sum_jd 
where dt=sysdate(-1) and substr(create_tm, 1, 10) >= '2013-01-01' 
and substr(create_tm, 1, 10) <= '2013-12-31' 
and supp_brevity_cd = 'hbssxxgl' 
and item_third_cate_cd = '870' 
group by pur_bill_id , supp_brevity_cd, create_tm , sku_id , item_name

--例子-2
select count(1) from 
	(SELECT count(1) FROM fdm.fdm_customer_userinfo_chain a 
		left outer join 
		(SELECT user_id FROM gdm.gdm_m04_ord_sum 
			where dt>='日期' 
			group by user_id) b 
		on a.user_id=b.user_id 
		where a.dp='ACTIVE' and b.user_id is null 
		group by a.user_id) c

--例子-3
select pin from fdm.fdm_customer_userinfo_chain where dp='ACTIVE' and user_level=50 and LIMIT 100000

--例子-4
select sale_ord_dt 下单日期, count(distinct sale_ord_id) 订单数, sum(Round(after_prefr_amount,2))订单金额 
from gdm.gdm_m04_ord_det_sum 
where sale_ord_dt >= '2013-01-01' 
and sale_ord_dt <= '2013-10-31' 
and dt > '2013-03-14' 
and item_second_cate_cd = '653' 
and ord_status_cd_1 = 1 
group by sale_ord_dt 
order by 下单日期 ASC

--例子-5
select user_log_acct from gdm_m01_userinfo_basic_sum 
where dt=sysdate(-1) and first_create_ord_tm >= '2014-07-01' 
group by user_log_acct

--例子-6
--内配提数实例
--提数实例：
--内配单号、内配箱子号、商品编号、wms接收时间、发货时间、上架时间
--create table inner_delv_det_6m as 
select t1.inner_delv_ob_id,t1.inner_delv_box_id,
       t1.item_sku_id,max(rt) as wms_rec_tm,
       max(sdt) as send_tm,sum(sq) as send_qty,
       max(it) as insp_tm,max(sht) as shelves_tm
  from   ---内配出宽表提取内配单和内配箱子出库数据
       (select inner_delv_ob_id,inner_delv_box_id,
               item_sku_id, max(wms_rec_tm) as rt,
               max(send_tm) as sdt,sum(send_qty) as sq
          from gdm.gdm_m08_ob_inner_delv_sum
         where dt >= '2013-06-01'
           and substr(create_tm, 1, 7) = '2013-06'
         group by inner_delv_ob_id, inner_delv_box_id, 
                  item_sku_id) t1
  left outer join --内配入宽表提取内配箱入库数据
                  (select inner_delv_box_id,item_sku_id,
                          max(shelves_tm) as sht,
                          max(insp_tm) as it
                     from gdm.gdm_m08_ib_inner_delv_sum
                    where dt >= '2013-06-01'
                    group by inner_delv_box_id,
                             item_sku_id) t2
--通过内配箱号和sku关联，注意入库验收和上架数量不能提取
    on t1.inner_delv_box_id = t2.inner_delv_box_id
   and t1.item_sku_id = t2.item_sku_id
 group by t1.inner_delv_ob_id, t1.inner_delv_box_id,
          t1.item_sku_id;


--例子-7
--优惠券数据提取
select
                a.create_time                 ,
                p.dim_item_fin_zero_cate_name,
                b.item_first_cate_name        ,
                b.item_second_cate_name       ,
                b.item_third_cate_name        ,
                b.purchaser_name              ,
                b.brandname                   ,
                a.jq_amount                   ,
                a.dq_amount                   ,
                a.jq_amount + a.dq_amount as hj_amount
        from
                (
                        select
                                wno                                      ,
                                substr(create_time, 1, 10) as create_time,
                                sum(
                                        case when voucher_type = 0 then
                                                        deduction_amount else 0.0 end)
                                as jq_amount,
                                sum(
                                        case when voucher_type = 1 then
                                                        deduction_amount else 0.0 end)
                                as dq_amount
                        from
                                fdm.fdm_fms_voucher_statistic_chain
                        where
                                start_date      <= substr(sysdate(                    - 1), 1, 10)
                                and end_date     > substr(sysdate(                    - 1), 1, 10)
                                and create_time >= concat(substr(month_add(sysdate(), -
                                1), 1, 8), '01')
                                and create_time < concat(substr(month_add(sysdate(), 0)
                                , 1, 8), '01')
                        group by
                                wno,
                                substr(create_time, 1, 10)
                )
                a
        left outer join
                (
                        select
                                item_sku_id          ,
                                item_first_cate_name ,
                                item_second_cate_name,
                                item_third_cate_cd   ,
                                item_third_cate_name ,
                                purchaser_name       ,
                                brandname
                        from
                                gdm.gdm_sku_basic_attrib_da
                        where
                                dt = substr(sysdate( - 1), 1, 10)
                )
                b
        on
                a.wno = b.item_sku_id
        left outer join
                (
                        select
                                item_fin_third_cate_id,
                                dim_item_fin_zero_cate_name
                        from
                                dim.dim_item_fin_cate_da
                        where
                                dt = substr(sysdate( - 1), 1, 10)
                )
                p
        on
                b.item_third_cate_cd = p.item_fin_third_cate_id

	
--例子-8
--2014年3月29日有效下单用户中用户级别为“铜牌会员”的用户数量
--认证考试1+下划线+个人邮箱前缀（例：认证考试1_yf-wangwei）
--共享人列表：你自己

select
	user_lv_cd,
	count(user_id) as user_lv_count
from
	exam_gdm_m04_ord_sum
where
	dt >= '2016-02-05'
	and ord_dt = '2016-02-05'
	and valid_flag = '1'
group by
	user_lv_cd;
	
--例子-9
--2014年3月29日的有效下单量、出库订单量、完成订单量
--ord_tm订购时间、out_wh_tm出库时间、ord_complete_tm订单完成时间、sale_ord_id销售订单编号
select
	count(if(to_date(ord_tm) = '2014-03-29', sale_ord_id, '')) as '有效下单量',
	count(if(to_date(out_wh_tm) = '2014-03-29', sale_ord_id, '')) as '出库订单量',
	count(if(to_date(ord_complete_tm) = '2014-03-29', sale_ord_id, '')) as '完成订单量'
from
	exam_gdm_m04_ord_sum
where
	dt >= '2014-03-29'
	and valid_flag = '1';

--例子-10
--商品分类表exam_proclass(id int, name string,fatherid int),其中fatherid 是id的父编号，fatherid为0时表示一级分类
--dim_class(first_id,first_name,second_id,second_name,third_id,third_name)
select
	t1.id first_id,
	t1.name first_name,
	t2.id second_id,
	t2.name second_name,
	t3.id third_id,
	t3.name third_name
from
	(
		select * from exam_proclass where father_id = 0
	)
	t1
join exam_proclass t2
on
	t1.id = t2.father_id
join exam_proclass t3
ON
	t2.id = t3.father_id;

--例子-11
--exam_dim(id int ,father_id int, name string)
--dim_area(province_id,province_name,city_id,city_name,county_id,county_name)
select
	t1.id province_id,
	t1.name province_name,
	t2.id city_id,
	t2.name city_name,
	t3.id county_id,
	t3.name county_name
from
	(
		select * from exam_dim where father_id = 0
	)
	t1
join exam_dim t2
on
	t1.id = t2.father_id
join exam_dim t3
on
	t2.id = t3.father_id;

--例子-12
select
	sum(coalesce(if(item_first_cate_cd = '9978', after_prefr_amount, 0), 0)) as phone_amount,
	sum(coalesce(if(item_first_cate_cd = '174'
	or item_first_cate_cd = '670', before_prefr_amount, 0), 0)) as compute_amount,
	sum(coalesce(if(item_first_cate_cd = '1315'
	and ord_status_cd_1 = 1, 1, 0), 0)) as clothing_ord_num
from
	exam_gdm_m04_ord_sum
WHERE
	dt >= '2016-06-18'
	and sale_ord_dt = '2016-06-18'
	and valid_flag = '1';

--例子-13
select
	t1.uprovince,
	t1.ucity,
	rank() over(partition by t1.uprovince order by t1.ord_count desc) as ord_rank
from
	(
		select
			uprovince,
			ucity,
			count(id) as ord_count
		from
			fdm.fdm_pek_orders_chain
		where
			start_date <= '2016-10-31'
			and end_date > '2016-10-31'
			and substr(createdate, 1, 10) = '2016-10-31'
			and yn = 1;
		
		group by uprovince,
		ucity
	)
	t1;

--例子-14
select
	pin,
	date1,
	joyval1,
	date2,
	joyval2
from
	(
		select
			pin,
			created as date1,
			joyval as joyval1
		from
			exam_fdm_db_userjoy_userjoy_chain
		where
			start_date >= sysdate()
	)

union all
	(
		select
			pin,
			created as date2,
			joyva as joyval2
		from
			exam_fdm_db_userjoy_userjoy_chain
		where
			start_date = '2015-01-01'
	);

	
--例子-15
SELECT
	COUNT(distinct user_id),
	sale_ord_id,
	user_actual_pay_amount,
	COUNT(parent_sale_ord_id)
FROM
	(
	(
		SELECT * FROM exam_gdm_m04_ord_sum WHERE dt >= '2016-03-12'
	)
	x
LEFT OUTER JOIN
	(
		SELECT
			*
		FROM
			exam_fdm_coupon_coupon_chain
		WHERE
			start_date <= '2016-03-12'
			and end_date > '2016-03-12'
			AND coupon_id = '31094989' valid_flag = '1'
	)
	y.order_id
ON
	x.sale_ord_id)
GROUP BY
	parent_sale_ord_id;



