use gdb023;

-- query 1
select distinct(market)
from dim_customer
where customer = 'Atliq Exclusive' and region = 'APAC'
;

-- query 2
with 
cte1 as 
(select count(distinct(product_code)) as unique_2020 from fact_sales_monthly where fiscal_year=2020),
cte2 as
(select count(distinct(product_code)) as unique_2021 from fact_sales_monthly where fiscal_year=2021)
select unique_2020 as unique_products_2020, unique_2021 as unique_products_2021, ((unique_2021-unique_2020)/unique_2021)*100
as percentage_chg 
from cte1 join cte2;

-- query3

select segment, count(distinct(product_code)) as product_count 
from dim_product 
group by segment
order by product_count desc;

select count(product_code) 
from dim_product
where segment='Notebook'
;

-- query 4
with 
cte2020 as 
(select count(distinct(fsm.product_code)) as product_count_2020, segment
from fact_sales_monthly fsm
join dim_product dp
on fsm.product_code = dp.product_code
where fiscal_year=2020
group by segment
),
cte2021 as
(select count(distinct(fsm.product_code)) as product_count_2021, segment
from fact_sales_monthly fsm
join dim_product dp
on fsm.product_code = dp.product_code
where fiscal_year=2021
group by segment)
select cte2020.segment, product_count_2020, product_count_2021, (product_count_2021-product_count_2020) as difference
from cte2020 join cte2021
where cte2020.segment= cte2021.segment
order by difference desc;


-- query 5
select * from fact_manufacturing_cost;

(select fmc.product_code, dp.product, manufacturing_cost
from fact_manufacturing_cost fmc
join dim_product dp
where fmc.product_code = dp.product_code
order by manufacturing_cost desc
limit 1)
union
(select fmc.product_code, dp.product, manufacturing_cost
from fact_manufacturing_cost fmc
join dim_product dp
where fmc.product_code = dp.product_code
order by manufacturing_cost asc
limit 1);

-- query 6

select customer, fpid.customer_code, pid
from 
(select customer_code, avg(pre_invoice_discount_pct) as pid, fiscal_year 
from fact_pre_invoice_deductions
where fiscal_year=2021
group by customer_code ) as fpid
join dim_customer dc
on dc.customer_code = fpid.customer_code
where market = 'India'
order by fpid.pid desc
limit 5;

-- query 7
select month(date) Month, year(date) Year,sum(gross_price*sold_quantity) as Gross_sales_amount
from fact_gross_price fgp
join fact_sales_monthly fsm
on fgp.product_code=fsm.product_code
join dim_customer dc
on fsm.customer_code = dc.customer_code
where dc.customer= 'Atliq Exclusive'
group by date
order by Gross_sales_amount desc;



-- query 8
select sum(sold_quantity) as total_sold_quantity, quarter(date) as Quarter
from fact_sales_monthly
group by fiscal_year,Quarter
order by total_sold_quantity desc
limit 1;


-- query 9

-- correct but without % contribution
select channel, sum(gross_price*sold_quantity) as gross_sales_mln
-- ,(sum(gross_price*sold_quantity)/channel)*100 over() percentage
from fact_gross_price fgp
join fact_sales_monthly fsm
on fgp.product_code = fsm.product_code
join dim_customer dc
on fsm.customer_code = dc.customer_code
where fsm.fiscal_year=2021
group by channel
order by gross_sales_mln desc

;
-- query 10
with cte1 as(
select product_code, sum(sold_quantity) as total_sold_quantity
from fact_sales_monthly
where fiscal_year=2021
group by  product_code),
top_3 as(
select dp.product_code,product, division, 
row_number() over(PARTITION BY division order by c.total_sold_quantity desc) as dr
from dim_product dp join cte1 c
on dp.product_code=c.product_code)
select * from cte1 join top_3
on cte1.product_code = top_3.product_code 
where top_3.dr<=3

