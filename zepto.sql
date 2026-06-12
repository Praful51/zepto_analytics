create database zepto;
use zepto;

rename table zepto_v2 to zepto;

-- Data exploration

select count(*) from zepto;
describe zepto;
select * from zepto;

-- Missing values

select * from zepto 
where Category is null
or
name is null
or
mrp is null
or
discountPercent is null
or
availableQuantity is null
or
discountedSellingPrice is null
or
weightInGms is null
or
outOfStock is null
or
quantity is null;

# 

# Products in stock vs out of stock

select outOfStock,count(*) from zepto
group by outOfStock;

# Product names present multiple times

select name, count(*) as 'Number_of_Times'
from zepto
group by name
having count(*)>1
order by count(*) desc;

# Data cleaning

select * from zepto 
where mrp=0 or discountedSellingPrice=0;

SET SQL_SAFE_UPDATES = 0;

DELETE FROM zepto
WHERE mrp = 0;

SET SQL_SAFE_UPDATES = 1;

select * from zepto;

# convert paise to rupees

SET SQL_SAFE_UPDATES = 0;
 update zepto
 set mrp=mrp/100.0,
 discountedSellingPrice=discountedSellingPrice/100.0;
 SET SQL_SAFE_UPDATES = 1;


# Analysis
select * from zepto;

#1 What are the products with high mrp but out of stock

with price_group as (
select distinct name, mrp, outofstock, ntile(4) over (order by mrp desc) as quartile
from zepto)
select name, mrp,outofstock
from price_group
where quartile=1 and outofstock='True';

#2 Calculate estimated revenue for each category

select category, sum(discountedsellingprice*quantity) as revenue
from zepto
group by category                 
order by revenue desc;


#3 Identify the top 5 categories offering the highest average discount percentage

select category, avg(discountpercent) as avg_disc
from zepto
group by category
order by avg_disc desc
limit 5;

#4 Find the price per gram for products above 100g and sort by best value

select distinct category,name,weightInGms, discountedSellingPrice,round(discountedsellingprice/weightingms,2) as price_per_gm
from zepto
where weightingms>100
order by price_per_gm desc;


#5 What is the total inventory weight per category
select * from zepto;

select category, sum(weightingms*availablequantity) as total_inventory_weight
from zepto
group by category
order by total_inventory_Weight desc;

#6 Find the top 10 products contributing the most to total revenue.

select name,sum(discountedsellingprice*quantity) as total_revenue 
from zepto
where outofstock=False
group by name
order by total_revenue desc limit 10;

#7 Find categories where inventory quantity is high but estimated revenue contribution is low.

with highinv_lowrev as (
select category, sum(availablequantity) as inventory, sum(discountedsellingprice*quantity) as revenue
from zepto
group by category),
categories as (
select *,ntile(4) over (Order by inventory desc) as inv_rnk,
ntile(4) over (order by revenue asc) as rev_rnk
from highinv_lowrev)

select category,inventory, revenue 
from categories
where inv_rnk=1 and rev_rnk=1;

#8 Find products where discount percentage is high but available quantity is also high.

with highdisc_highquant_category as (
select category,name,discountpercent,availablequantity, ntile(4) over (order by discountpercent desc) as disc_rnk,
ntile(4) over (order by availablequantity desc) as quan_rnk
from zepto)

select category,name,discountpercent,availablequantity
from  highdisc_highquant_category 
where disc_rnk=1 and quan_rnk=1;

#9 Calculate out-of-stock percentage by category.

select category, sum(case when outofstock='TRUE' then 1 else 0 end) as total_outofstock,
round(sum(case when outofstock='TRUE' then 1 else 0 end) * 100.0/ count(*),2) as outofstock_percent
FROM zepto
group by category
order by outofstock_percent desc;

#10 Which categories are suffering from poor product availability

select * from zepto;

select category,count(*) as total_products,
sum(case when outofstock='TRUE' then 1 else 0 end) as outofstock_prod,
round(sum(case when outofstock='TRUE' then 1 else 0 end)*100/count(*),2) as stockout_percent
from zepto
group by category
order by stockout_percent desc;

