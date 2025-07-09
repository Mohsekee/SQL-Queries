create database pagila

-- customers' full name
alter table customer add full_name Varchar (50);
Update customer set full_name = concat(first_name, ' ', last_name)

--1 fullname, email, city and country 
with 
	cte_cus_details as(
select 
	x.full_name, x.email, y.address_id, y.city_id
from customer as x	
	left join address as y on x.address_id = y.address_id
),
	cte_cus_deets as(
select 
	a.full_name,
	a.email, b.city, b.country_id
from cte_cus_details as a 
	left join city as b on a.city_id = b.city_id
)
select 
	c.full_name, 
	c.email, 
	c.city, 
	d.country from cte_cus_deets as c 
	left join country as d on c.country_id = d.country_id  

-- method 2
with 
	cte_customer as
(select address_id,full_name, email from customer),
	cte_address as
(select address_id, city_id from address),
	cte_city as 
(select country_id,city_id, city from city),
cte_country as 
(select country_id, country from country)
select full_name,email, city, country from cte_customer as a 
	join cte_address as b on a.address_id = b.address_id
	join cte_city as c on b.city_id = c.city_id
	join cte_country as d on c.country_id = d.country_id

--2 Title of each film rented by each customer, rental date and the staff member who handled the rental.

with 
	cte_film2 as (
select film_id, title from film),
	cte_customer2 as (
select customer_id, full_name as cust_name, store_id from customer),
	cte_staff2 as(
select staff_id, username as staff_name, store_id from staff),
	cte_rental2 as (
select rental_id, rental_date, inventory_id from rental),
	cte_payment2 as (
select customer_id, rental_id, staff_id from payment),
	cte_inventory2 as (
select inventory_id, film_id, store_id from inventory)
	select f.title, c.cust_name, b.rental_date, d.staff_name 
	from cte_payment2 as a 
	inner join cte_rental2 as b on a.rental_id = b.rental_id
	inner join cte_customer2 as c on c.customer_id = a.customer_id
	inner join cte_staff2 as d on d.staff_id = a.staff_id
	inner join cte_inventory2 AS e ON e.inventory_id = b.inventory_id
	inner join cte_film2 AS f ON f.film_id = e.film_id	

--3 Top 10 customers who have paid the most in total, their full name, email, and total amount paid.
with 
	cte_payments as
	(select customer_id, full_name as customer_name, email from customer),
	cte_total_amount as
	(select customer_id, sum(amount)as total_amount from payment 
	group by customer_id)
	select a.customer_name, a.email, b.total_amount from cte_payments as a
	inner join cte_total_amount as b on a.customer_id = b.customer_id
	order by total_amount desc
	limit 10

--4 five films that have generated the most revenue from rentals, the film title, total revenue, and total number of rentals.
with 
cte_total_revenue as(
select 
	rental_id, 
	sum(amount)as total_revenue from payment 
		group by rental_id
),
cte_tot_rev as (
	select 
	rental_id, 
	count(rental_id) as No_of_rentals, inventory_id from rental
		group by rental_id, inventory_id
),
cte_invtry as(
	select 
	film_id, 
	inventory_id from inventory
),
cte_film_rev as (
select film_id, title from film)
	select d.title, sum(a.total_revenue)as total_revenue,
	count(b.rental_id) as No_of_rentals from cte_total_revenue as a
	inner join cte_tot_rev as b on a.rental_id = b.rental_id
	inner join cte_invtry as c on c.inventory_id = b.inventory_id
	inner join cte_film_rev as d on d.film_id = c.film_id
	group by d.title
	order by total_revenue desc
	limit 5

--5 staff member who processed more than 300 rentals, total number of rentals processed, and the total amount collected.
with 
cte_ren_tals as(
	select
		count(rental_id) as No_of_rentals,
		staff_id
from rental
		group by staff_id),
cte_st_aff as(
	select
		staff_id,
		username as staff_name
	from staff),
cte_pay_ments as(
	select
		staff_id,
		sum(amount) as total_amount
	from payment
		group by staff_id)
	select 
		b.staff_name, 
		c.total_amount,
		a.No_of_rentals
	from cte_ren_tals as a 
inner join cte_st_aff as b on a.staff_id = b.staff_id
inner join cte_pay_ments as c on a.staff_id = c.staff_id
Where No_of_rentals > '300'

--6 All films that have never been rented.
select film_id, title 
	from film as f 
	where film_id not in 
(select 
	distinct(film_id) from inventory as i
join rental as r on i.inventory_id = r.inventory_id)


--7 Names of customers who have rented more films than the average customer
with
cte_customer as(
    select customer_id, full_name as customer_name 
    from customer
),
cte_rental as (
    select customer_id, count(rental_id) as total_rental 
    from rental
    group by customer_id
),
cte_joined as (
    select 
        c.customer_name,
        r.total_rental
    from cte_customer c
    join cte_rental r on c.customer_id = r.customer_id
)
select
    customer_name,
    total_rental
from cte_joined
where total_rental > (
    select avg(total_rental) from cte_joined
)
order by total_rental desc;

--8 all films whose rental rate is higher than the average rental rate of other films in the same category.
with
cte_film as(
	select film_id, title, rental_rate
	from film
),
cte_film_category as (
	select film_id, category_id 
	from film_category
),
cte_category as(
	select category_id, name as category_name
	from category
),
cte_joined as(
	select f.film_id, f.title, fc.category_id, f.rental_rate, c.category_name
	from cte_film as f 
	join cte_film_category as fc on fc.film_id = f.film_id
	join cte_category as c on c.category_id = fc.category_id
),
cte_avg_by_category as(
	select category_id, avg(rental_rate) as avg_rental_rate
	from cte_joined
	group by category_id
	)
select title, category_name, round(avg_rental_rate, 2) as avg_rental_r8
	from cte_joined as j
	join cte_avg_by_category as a on j.category_id = a.category_id 
	where j.rental_rate > a.avg_rental_rate
	order by j.category_name, j.rental_rate desc;

--9 For each city, rank customers by the number of rentals they’ve made. Include the city, customer name, rental count, and rank.
with 
cte_customer as (
	select customer_id, full_name as cust_name, address_id
	from customer
),
cte_payment as (
	select customer_id, count(rental_id) as total_rental
	from payment
	group by customer_id
),
cte_address as (
	select address_id, city_id 
	from address
),
cte_city as (
	select city_id, city from city)
select c.city, ct.cust_name, r.total_rental, 
	rank() over(partition by c.city order by r.total_rental) as rental_rank
	from cte_city as c 
	join cte_address as a on c.city_id = a.city_id
	join cte_customer as ct on ct.address_id = a.address_id
	join cte_payment as r on r.customer_id = ct.customer_id
order by c.city, rental_rank

--10 total revenue and a cumulative revenue total ordered by month for each month in 2007 (no 2005 records).
Select
	mon_th,
	TO_CHAR(TO_DATE(mon_th::text, 'MM'), 'Month') AS month, 
	total_revenue,
	sum(total_revenue) over(order by mon_th) as cum_total_rev
	from
(select 
	extract (month from payment_date) as mon_th,
	sum(amount) as total_revenue 
	from payment
	where extract (year from payment_date) = 2007
	group by mon_th) as monthly_revenue
	order by mon_th
	
--11 customers rented more than 40 films, along with the number of films rented and the total amount they paid
select  
	c.full_name as cust_name, 
	count (distinct f.film_id) as total_film, 
	sum(p.amount) as amount_paid
from customer as c 
	left join payment as p on p.customer_id = c.customer_id
	left join rental as r on r.rental_id = p.rental_id
	left join inventory as i on i.inventory_id = r.inventory_id
	left join film as f on f.film_id = i.film_id
group by c.full_name
	having count (distinct f.film_id) > 40
	order by amount_paid desc

--12 most rented film in each category, the category name, film title, and number of rentals.
with cte_film_category as (
    select fc.film_id, fc.category_id
    from film_category as fc
),
cte_category as (
    select category_id, name as category_name
    from category
),
cte_film as (
    select film_id, title
    from film
),
cte_rental_count as (
    select i.film_id, count(r.rental_id) as total_rentals
    from inventory as i
    join rental as r on r.inventory_id = i.inventory_id
    group by i.film_id
),
cte_joined as (
    select f.title, c.category_name, r.total_rentals,
           rank() over (partition by c.category_name order by r.total_rentals desc) as rank
    from cte_film as f
    join cte_film_category as fc on f.film_id = fc.film_id
    join cte_category as c on c.category_id = fc.category_id
    join cte_rental_count as r on r.film_id = f.film_id
)
select category_name, title, total_rentals
from cte_joined
where rank = 1;

-- 13 for each store, top 3 customers with the highest number of rentals. Include store ID, customer name, and rental count.
with
customer_cte as(
	select customer_id, full_name as cust_name, store_id 
	from customer 
),
rental_cte as(
	select customer_id, count(rental_id) as total_rental
	from rental
	group by customer_id
),
joined_cte as(
	select c.store_id, c.cust_name, total_rental, 
	rank () over (partition by c.store_id order by total_rental desc) as rank
	from customer_cte as c 
	join rental_cte as r on r.customer_id = c.customer_id
)
select
	store_id, cust_name, total_rental
	from joined_cte
	where rank <=3
	
--14 Find customers who did not make any rentals during the last 3 months of the dataset.
select customer_id, full_name 
from customer 
where customer_id not in (
    select distinct customer_id 
    from rental 
    where rental_date >= (select max(rental_date) - interval '3 month' from rental)
);

--15 Customers whose email addresses are invalid — specifically those missing '@' or ending in '.con' instead of '.com'.
select 
	customer_id, 
	full_name, 
	email
from customer
where email like '%con' 
or email not like '%@%'

--16 For each rental, calculate whether the film was returned late (more than 3 days after rental date), and count the number of late returns per customer
select 
	c.full_name as customer_name,
	count(r.rental_id) as no_of_late_returns
from rental as r
join customer as c on r.customer_id = c.customer_id
where r.return_date - r.rental_date > interval '3 day'
group by c.customer_id, c.full_name;

--17 The total number of rentals and revenue per category
select 
	cat.name as category_name,
	count(p.rental_id) as total_rental,
	sum(p.amount) as revenue 
from payment as p 
	join rental as r on r.rental_id = p.rental_id
	join inventory as i on i.inventory_id = r.inventory_id
	join film_category as fc on fc.film_id = i.film_id
	join category as cat on cat.category_id =fc.category_id
	group by cat.category_id
	order by total_rental desc

--18 List the top 5 categories based on total revenue generated from film rentals
select 
	cat.name as category_name,
	sum(p.amount) as revenue 
from payment as p 
	join rental as r on r.rental_id = p.rental_id
	join inventory as i on i.inventory_id = r.inventory_id
	join film_category as fc on fc.film_id = i.film_id
	join category as cat on cat.category_id =fc.category_id
	group by cat.category_id
	order by revenue desc
	limit 5
a1
--19 Find customers who have rented all films in the 'Comedy' category
with comedy_films as (
	select film_id 
	from film_category fc
	join category c on c.category_id = fc.category_id
	where c.name = 'Comedy'
),
customer_rentals as (
	select r.customer_id, c.full_name, count(distinct i.film_id) as rented_comedy
	from rental r
	join inventory i on i.inventory_id = r.inventory_id
	join customer c on c.customer_id = r.customer_id
	where i.film_id in (select film_id from comedy_films)
	group by r.customer_id, c.full_name
)
select full_name, rented_comedy
from customer_rentals
where rented_comedy = (select count(*) from comedy_films);

	
--20 For each film, show how many times it has been rented and the average rating given (based on the assumption that payment amount represents interest level).
select
	f.title,
	count(r.rental_id) as total_rental,
	round(Avg(p.amount), 2) as  interest_level
from film as f 
	join inventory as i on f.film_id = i.film_id
	join rental as r on r.inventory_id = i.inventory_id
	join payment as p on p.rental_id = r.rental_id
	group by f.film_id, f.title
	order by interest_level desc
