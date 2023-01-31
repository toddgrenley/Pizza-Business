-------------------------------------
-- PIZZA PARTY!!!
-------------------------------------
-- A new pizzeria needs some BI expertise to help keep track of business performance. From a database constructed of 10 tables, we'll query the information and 
-- ultimately pull together 3 dashboards: one each for Orders, Stock, and Staff. Each can be built with data from a single query, except for Stock, which will take two.
-- Let's begin with Orders.

-- Orders Query
-- We'll pull together all information pertaining to orders, including contents, prices, times, as well as delivery address and method. This info is located across
-- three tables, so we'll need to join the Orders table to the Item and Address tables.

SELECT O.order_id, I.item_price, O.quantity, I.item_cat, I.item_name, O.created_at, A.delivery_address1, A.delivery_address2, A.delivery_city, A.delivery_zipcode, O.delivery
FROM [Pizza Project]..Orders AS O
LEFT JOIN [Pizza Project]..Item AS I
	ON O.item_id = I.item_id
LEFT JOIN [Pizza Project]..Address AS A
	ON O.add_id = A.add_id

-- Stock Query #1
-- This is where it will get more complicated. In order to retrieve all information necessary for stock analysis, we'll have to pull together four total tables: the
-- Orders and Item tables from the last query, as well as the Recipe and Ingredient tables which further detail what goes into each item. On top of that, we'll need
-- to do several calculations to get an idea of the COGS (cost of goods sold) incurred by the business. Seeing as some of the calculations will have to be layered,
-- (subsequent calculations will depend on previous ones), we'll make use of subqueries to allow this to be done in a single overall query. And if that's not enough, 
-- we'll create a View out of it so it can be referenced in our second Stock query coming up. (Yes, it will further build off this one)

CREATE VIEW Stock1 
AS
SELECT s1.item_name, s1.ing_id, s1.ing_name, s1.ing_weight, s1.ing_price, s1.order_quantity, s1.recipe_quantity, s1.order_quantity*s1.recipe_quantity AS ordered_weight, s1.ing_price/s1.ing_weight AS unit_cost, (s1.order_quantity*s1.recipe_quantity)*(s1.ing_price/s1.ing_weight) AS ingredient_cost
FROM (
SELECT O.item_id, I.sku, I.item_name, R.ing_id, Ing.ing_name, R.quantity AS recipe_quantity, SUM(O.quantity) AS order_quantity, Ing.ing_weight, Ing. ing_price
FROM [Pizza Project]..Orders AS O
LEFT JOIN [Pizza Project]..Item AS I
	ON O.item_id = I.item_id
LEFT JOIN [Pizza Project]..Recipe AS R
	ON I.sku = R.recipe_id
LEFT JOIN [Pizza Project]..Ingredient AS Ing
	ON Ing.ing_id = R.ing_id
GROUP BY O.item_id, I.sku, I.item_name, R.ing_id, R.quantity, Ing.ing_name, Ing.ing_weight, Ing.ing_price
) s1

-- Stock Query #2
-- Whereas the previous query focused on pooling and calculating the necessary data to find COGS, this one will focus more on Inventory levels to give the pizzeria 
-- an idea of when they need to order more supplies. To do this, we'll use what the previous query achieved to further calculate Inventory totals (the previous one
-- broke everything down by item; here we want a simpler aggregation for Inventory tracking purposes). We'll then use yet another subquery to calculate how much of
-- each ingredient remains in Inventory.

SELECT s2.ing_name, s2.ordered_weight, CAST(Ing.ing_weight AS int)*Inv.quantity AS total_inv_weight, (CAST(Ing.ing_weight AS int)*Inv.quantity)-s2.ordered_weight AS remaining_weight
FROM 
(SELECT ing_id, ing_name, SUM(ordered_weight) AS ordered_weight
FROM Stock1
GROUP BY ing_name, ing_id) s2
LEFT JOIN [Pizza Project]..Inventory AS Inv
	ON Inv.item_id = s2.ing_id
LEFT JOIN [Pizza Project]..Ingredient AS Ing
	ON Ing.ing_id = s2.ing_id

-- Keep in mind, not everything needs to be pre-calculated here in our queries. Some aspects we will want, such as Percent Remaining, can be added when putting 
-- together our dashboards in our BI tool (in this case Tableau, though I may add Looker or Power BI as Tableau can trip over some of the simple stuff we need here).

-- Staff Query (the last one!)
-- This one is likely self-explanatory. This query will provide the data necessary to create a dashboard that monitors employee work hours over time as well as the
-- cost of paying staff, aka payroll, aka something the business would not be complete without.

SELECT R.date, S.first_name, S.last_name, S.hourly_rate, Sh.start_time, Sh.end_time,
	CAST(DATEDIFF(minute,Sh.start_time,Sh.end_time)AS float)/60 AS hours_in_shift,
	CAST(DATEDIFF(minute,Sh.start_time,Sh.end_time)AS float)/60*S.hourly_rate AS staff_cost
FROM [Pizza Project]..Rota AS R
LEFT JOIN [Pizza Project]..Staff AS S
	ON R.staff_id = S.staff_id
LEFT JOIN [Pizza Project]..Shift AS Sh
	ON R.shift_id = Sh.shift_id

-- That's it. Now we're ready to move on to the chosen BI tool for visualizing.