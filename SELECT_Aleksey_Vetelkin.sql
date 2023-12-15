-- 1
-- Which staff members made the highest revenue for each store
-- and deserve a bonus for the year 2017?

-- 1.1 
-- implemented using cte and window functions
with RankedRevenue as (
    select s.store_id, s.staff_id, s.first_name || ' ' || s.last_name as staff_name, 
	    sum(p.amount) as total_revenue,
        rank() over (partition by s.store_id order by sum(p.amount) desc) as revenue_rank
    from staff s
    join payment p on s.staff_id = p.staff_id
    where extract(year from p.payment_date) = 2017
    group by s.store_id, s.staff_id
)
select store_id, staff_id, staff_name, total_revenue
from RankedRevenue
where revenue_rank = 1;


-- 1.2
-- implemented using subquery and 'ROW_NUMBER()'
select store_id, staff_id, staff_name, total_revenue
from (
    select s.store_id, s.staff_id, s.first_name || ' ' || s.last_name as staff_name,
        sum(p.amount) as total_revenue,
        row_number() over (partition by s.store_id order by sum(p.amount) desc) as row_num
    from staff s
    join payment p on s.staff_id = p.staff_id
    where extract(year from p.payment_date) = 2017
    group by s.store_id, s.staff_id
) ranked_revenue
where row_num = 1;

-- 2
-- Which five movies were rented more than the others,
-- and what is the expected age of the audience for these movies?

-- 2.1
-- implemented using only joins
select f.title, f.rating, count(*) as rental_count
from film f
join inventory i on i.film_id = f.film_id
join rental r on r.inventory_id = i.inventory_id
group by f.film_id, f.title, f.rating
order by rental_count desc
limit 5;

-- 2.2 
-- implemented using cte
with MovieRentalCounts as (
    select f.title, f.rating, count(*) as rental_count
    from film f
    join inventory i on i.film_id = f.film_id
    join rental r on i.inventory_id = r.inventory_id
    group by f.film_id, f.title, f.rating
)
select c.title, c.rating, c.rental_count
from MovieRentalCounts c
order by c.rental_count desc
limit 5;

-- 3
-- Which actors/actresses didn't act for a longer period of time than the others?

-- 3.1
-- implemented using cte and left join 
-- to take in a count cases when actor didn't play in any film
-- also using 'COALESCE' to handle situations with actors not playing anywhere
with ActorActivity as (
    select a.actor_id, a.first_name || ' ' || a.last_name as actor_name,
    	coalesce(max(f.release_year), -1) as latest_release_year
    from actor a
    left join film_actor fa on a.actor_id = fa.actor_id
    left join film f on fa.film_id = f.film_id
    group by a.actor_id, actor_name
)
select actor_id, actor_name,
	extract(year from current_date) - latest_release_year as years_without_acting
from ActorActivity
order by years_without_acting desc;

-- 3.2
-- implemented using subquery (where we find out when the actor played last time) 
-- and left join to take in a count cases when actor didn't play in any film
-- also using 'COALESCE' to handle situations with actors not playing anywhere
select a.actor_id, a.first_name || ' ' || a.last_name as actor_name,
    coalesce(extract(year from current_date) - max(actors_last_release.release_year), -1) as years_without_acting
from actor a
left join (
    select fa.actor_id, max(f.release_year) as release_year
    from film_actor fa
    left join film f on fa.film_id = f.film_id
    group by fa.actor_id
) actors_last_release on a.actor_id = actors_last_release.actor_id
group by a.actor_id, actor_name
order by years_without_acting desc;