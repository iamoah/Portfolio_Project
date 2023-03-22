use happy;

---Checking data type
sp_help superstore;

--- Checking to have an overview of the data and the ones that can be graphed
select * from superstore;
select distinct (Country) from superstore;
select distinct (Segment) from superstore;
select distinct (City) from superstore;
select distinct (market) from superstore;
select distinct (Sub_Category) from superstore;
select distinct (Order_Priority) from superstore;
select distinct (year_order) from superstore;

---Cleaning and preparing data for analysis

alter table superstore add year_order varchar(10);
update superstore set year_order = YEAR(Order_Date);

alter table superstore add month_order varchar(10);
update superstore set month_order = MONTH(Order_Date);



---Analysis 
---Sales Analysis 

---Which category of item gave more revenue  and profits accross all stores
select Sub_Category, sum (sales) Revenue, sum (Profit) prof
from superstore 
group by Sub_Category
order by 2 desc;

---which year gave the best revenue 
select year_order, sum (sales) Revenue
from superstore 
group by year_order
order by 2 desc;

---Best country for sales 
select Country, sum (sales) Revenue
from superstore 
group by Country
order by 2 desc;

---Find out if sales happend in each month in each year
select distinct month_order from superstore  where year_order IN ( 2011, 2012, 2013, 2014) 

---What was the best month for sales in each year? How much was earned that month? which month did we experience the most orders
select month_order, sum(sales) Revenue, count(*) Frequency
from superstore 
group by month_order
order by 2 desc;


--- Categories of orders in each category in each year and month.
DROP View IF EXISTS view1

create view view1
as 
select month_order, Sub_Category, year_order, sum(sales) Revenue, count(*) Frequency
from superstore 
group by month_order, Sub_Category, year_order;
GO

---which months and category of item gave the best revenue in 2014 since it had the best revenue
select distinct(Sub_Category), month_order, year_order, Revenue, Frequency from view1
where year_order = 2014
order by 4 desc

---RFM analysis to find out who is an old customer or a new customer
DROP TABLE IF EXISTS #temp_rfm
;with rfm_analysis as (
   Select Customer_Name,
		sum(sales) customer_sales,
		avg(sales) avg_sales,
		count(Quantity) Frequency,
		max(Order_Date) last_order_date,
		(select max(Order_Date) from superstore) max_order_date,
		DATEDIFF(DD,max(Order_Date), (select max(Order_Date) from superstore)) Recency
	from superstore
	group by Customer_Name
),
rfm_calc as
(

select * ,
NTILE(4) OVER (order by Recency) rfm_recency,
NTILE(4) OVER (order by Frequency) rfm_frequency,
NTILE(4) OVER (order by customer_sales) rfm_sales
from rfm_analysis
)
select *, rfm_recency + rfm_frequency + rfm_sales as rfm_total,
cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_sales as varchar) rfm_total_string
into #temp_rfm
from rfm_calc


select Customer_Name,rfm_recency,rfm_frequency,rfm_sales,
	case
		when rfm_total_string in (111, 112, 121, 122, 131, 123, 132,211,212,114,141) then 'lost customers'
		when rfm_total_string in (133, 134, 143, 244, 334, 343,344) then 'slipping away'
		when rfm_total_string in (221, 222, 223, 233, 322) then 'potential Churners'
		when rfm_total_string in (311,411,331) then 'new customers'
		when rfm_total_string in (323,333,321,422,332,432) then 'active customers'
		when rfm_total_string in (433,434,443,444) then 'loyal'
	end rfm_segment
from #temp_rfm rfm_analysis

---Which products are sold together


--- getting items that are shipped the data shows everything was shipped
alter table superstore add shipped varchar(10);
update superstore set shipped = 'order_ship'
where [Ship _Mode] = 'Same Day';

update superstore set shipped = 'order_ship'
where [Ship _Mode] = 'First Class';

update superstore set shipped = 'order_ship'
where [Ship _Mode] = 'Standard Class';

update superstore set shipped = 'order_ship'
where [Ship _Mode] = 'Second Class';

--- Which items where shipped together for quantities that are two or more 

select distinct Order_ID, stuff(
(select ',' + Product_ID from superstore p
where Order_ID IN(
select Order_ID
from (
Select Order_ID, count(*) rn
from superstore
Where shipped = 'order_ship'
group by Order_ID
) k
where rn = 2
) 
and p.Order_ID = s.Order_ID
for xml path ('')), 1, 1, '')
from superstore s
order by 2 desc


---how long does it take to ship orders 
DROP View IF EXISTS view2

create view view2
as 
select Sub_Category, Country, Segment, DATEDIFF(minute,Order_Date,Ship_Date) time_ship
from superstore
GO

---average delivery time accross products 

select distinct Sub_Category, avg(time_ship) avg_ship 
from view2 
group by Sub_Category
order by 2 asc;

