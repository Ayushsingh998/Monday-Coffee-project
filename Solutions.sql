use sql_project_1 ;

-- Monday Coffee -- Data Analysis 

CREATE TABLE city
(
	city_id	INT PRIMARY KEY,
	city_name VARCHAR(15),	
	population	BIGINT,
	estimated_rent	FLOAT,
	city_rank INT
);

CREATE TABLE customers
(
	customer_id INT PRIMARY KEY,	
	customer_name VARCHAR(25),	
	city_id INT,
	CONSTRAINT fk_city FOREIGN KEY (city_id) REFERENCES city(city_id)
);
CREATE TABLE products
(
	product_id	INT PRIMARY KEY,
	product_name VARCHAR(35),	
	Price float
);
CREATE TABLE sales
(
	sale_id	INT PRIMARY KEY,
	sale_date	date,
	product_id	INT,
	customer_id	INT,
	total FLOAT,
	rating INT
);

-- importing the data 

select * from city;
select * from customers;
select * from products;
select * from sales;


-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT 
	city_name,
	ROUND((population * 0.25)/1000000, 2) as coffee_consumers_in_millions,
	city_rank
FROM city
ORDER BY 2 DESC;


-- -- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?


SELECT 
	SUM(total) as total_revenue
FROM sales
WHERE 
	sale_date >= '2023-10-01'
	AND
	sale_date >= '2024-01-01';


SELECT 
	ci.city_name,
	SUM(s.total) as total_revenue
FROM sales as s
JOIN customers as c ON s.customer_id = c.customer_id
JOIN city as ci  ON ci.city_id = c.city_id
WHERE 
	s.sale_date >= '2023-10-01'
	AND
	s.sale_date >= '2024-01-01'
GROUP BY 1
ORDER BY 2 DESC;

-- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?

SELECT 
	p.product_name,
	COUNT(s.sale_id) as total_orders
FROM products as p
LEFT JOIN
sales as s ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_orders DESC;

-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?

-- city abd total sale
-- no cx in each these city

SELECT 
	ci.city_name,
	SUM(s.total) as total_revenue,
	COUNT(DISTINCT s.customer_id) as total_cx,
	ROUND(SUM(s.total)/COUNT(DISTINCT s.customer_id),2) as avg_sale_pr_cx
	
FROM sales as s JOIN customers as c ON s.customer_id = c.customer_id
JOIN city as ci ON ci.city_id = c.city_id
GROUP BY ci.city_name
ORDER BY  total_cx DESC;

-- -- Q.5
-- City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)


with city_data as(
select 
city_name,
round(((population*0.25)/1000000),2) as coffee_customers_per_million
from city),
customer_data as (
select  
c2.city_name,
count(distinct s.customer_id) as current_cx
from sales s join customers c1 on s.customer_id = c1.customer_id
join city c2 on c1.city_id = c2.city_id
group by c2.city_name)

select 
d.city_name,
d.coffee_customers_per_million,
cd.current_cx
from city_data d join customer_data cd on d.city_name = cd.city_name ;



-- -- Q6
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

select * from 
( select 
  c2.city_name,
  p.product_name, 
  count(s.sale_id) as no_of_product,
  dense_rank()over(partition by c2.city_name order by count( s.sale_id) desc) as rnk
  from sales s join products p on s.product_id = p.product_id
  join customers c1 on s.customer_id =  c1.customer_id
  join city c2 on c1.city_id = c2.city_id 
  group by p.product_name,c2.city_name 
  order by rnk)x
where x.rnk <= 3;


-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

select  
c2.city_name,
count(distinct s.customer_id) as count_of_customers
from sales s join customers c1 on s.customer_id = c1.customer_id
join city c2 on c1.city_id = c2.city_id 
WHERE 
	s.product_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
group by c2.city_name;

-- -- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

with data as (
select 
c2.city_name,
sum(s.total) as total_per_city,
count(distinct s.customer_id ) as no_of_customers,
round((sum(total)/count(distinct s.customer_id)),2) as avg_sales_per_customers
from sales s join customers c1 on s.customer_id = c1.customer_id
join city c2 on c1.city_id = c2.city_id 
group by c2.city_name 
)

select 
c.city_name,
d.no_of_customers,
d.avg_sales_per_customers,
c.estimated_rent as total_rent,
round(c.estimated_rent/d.no_of_customers ,2) as avg_rent_per_customer
from city c join data d
on c.city_name = d.city_name 
order by avg_rent_per_customer desc; 



-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city


with monthly_sale as(
SELECT 
    c2.city_name,
    MONTH(s.sale_date) AS sale_month,
    YEAR(s.sale_date) AS sale_year,
    SUM(s.total) AS total_sale
FROM sales s 
JOIN customers c1 ON s.customer_id = c1.customer_id
JOIN city c2 ON c1.city_id = c2.city_id 
GROUP BY c2.city_name, MONTH(s.sale_date), YEAR(s.sale_date)
ORDER BY c2.city_name, sale_year, sale_month
)

select 
x.city_name ,
x.sale_month,
x.sale_year,
x.current_mon_sale,
x.last_month_sale,
round(((x.current_mon_sale-x.last_month_sale)/x.last_month_sale)*100,2) as growth_ratio
from(
select 
city_name ,
sale_month,
sale_year,
total_sale as current_mon_sale,
lag(total_sale,1)over(partition by city_name) as last_month_sale
from monthly_sale)x
where last_month_sale is not null ;


-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

with data as (
select 
c2.city_name,
sum(s.total) as total_per_city,
count(distinct s.customer_id ) as no_of_customers,
round((sum(total)/count(distinct s.customer_id)),2) as avg_sales_per_customers
from sales s join customers c1 on s.customer_id = c1.customer_id
join city c2 on c1.city_id = c2.city_id 
group by c2.city_name 
)

select 
c.city_name,
d.total_per_city as total_sales,
c.estimated_rent as total_rent,
c.population as total_population,
round(((c.population*0.25)/1000000),3) as coffee_consumption_in_million,
d.no_of_customers,
d.avg_sales_per_customers,
round(c.estimated_rent/d.no_of_customers ,2) as avg_rent_per_customer
from city c join data d
on c.city_name = d.city_name 
order by total_sales desc ; 

/*
-- Recomendation
City 1: Pune
	1.Average rent per customer is very low.
	2.Highest total revenue.
	3.Average sales per customer is also high.

City 2: Delhi
	1.Highest estimated coffee consumers at 7.7 million.
	2.Highest total number of customers, which is 68.
	3.Average rent per customer is 330 (still under 500).

City 3: Jaipur
	1.Highest number of customers, which is 69.
	2.Average rent per customer is very low at 156.
	3.Average sales per customer is better at 11.6k.

*/
