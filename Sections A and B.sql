--Section A: Customer Journey
----------------------------------------------------------------------------------------------------------------------

SELECT 
    CUSTOMER_ID,
    S.PLAN_ID,
    P.PLAN_NAME AS "Plan",
    P.PRICE,
    START_DATE
FROM SUBSCRIPTIONS AS S
INNER JOIN PLANS AS P
    ON S.PLAN_ID = P.PLAN_ID
;

----------------------------------------------------------------------------------------------------------------------
--Section B 
-- 1. How many customers has Foodie-Fi ever had?
SELECT 
    COUNT(DISTINCT CUSTOMER_ID) AS "Number of Customers"
FROM SUBSCRIPTIONS
;

--2. What is the monthly distribution of trial plan start_date values for our dataset? - use the start of the month as the group by value
SELECT 
    DATE_TRUNC('MONTH', START_DATE) AS "Date",
    COUNT(CUSTOMER_ID) AS "Number of Trials"
FROM SUBSCRIPTIONS
WHERE 
    PLAN_ID = 0
GROUP BY
    "Date"
;

--3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT
    P.PLAN_NAME,
    COUNT(P.PLAN_NAME) AS "Number of Events"
FROM PLANS AS P
INNER JOIN SUBSCRIPTIONS AS S
    ON P.PLAN_ID = S.PLAN_ID
WHERE 
    YEAR(S.START_DATE) > 2020
GROUP BY 
    P.PLAN_NAME
;
    
--4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
--Churned Customers - CTE
WITH CHURNED_CUSTOMERS_CTE AS(
SELECT
    COUNT(DISTINCT CUSTOMER_ID) AS "Number of Churned Customers",
    1 AS "Record ID"
FROM SUBSCRIPTIONS
WHERE PLAN_ID = 4
),

--Total Customers - CTE
TOTAL_CUSTOMERS_CTE AS(
SELECT 
    COUNT(DISTINCT CUSTOMER_ID) AS "Total Number of Customers",
    1 AS "Record ID"
FROM SUBSCRIPTIONS
)
SELECT
    CC."Number of Churned Customers",
    TC."Total Number of Customers",
    ROUND(("Number of Churned Customers"/"Total Number of Customers")*100,1) AS "% of Customers who have Churned"
FROM CHURNED_CUSTOMERS_CTE AS CC
JOIN TOTAL_CUSTOMERS_CTE AS TC
    ON CC."Record ID" = TC."Record ID"
;

--^^ This is the CTE way which is quite inefficient. The following below is the sub-query way
--Sub-query way
SELECT
    COUNT(DISTINCT CUSTOMER_ID) AS "Number of Churned Customers",
    (SELECT
        COUNT(DISTINCT CUSTOMER_ID)
    FROM SUBSCRIPTIONS
    ) AS "Total Number of Customers",
    ROUND(("Number of Churned Customers"/"Total Number of Customers")*100, 1) AS "% of Customers who have Churned"
FROM SUBSCRIPTIONS
WHERE PLAN_ID = 4
;

--5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
WITH CUSTOMER_ROW_NUMBER_CTE AS(
SELECT
    S.CUSTOMER_ID,
    S.PLAN_ID,
    P.PLAN_NAME,
    S.START_DATE,
    ROW_NUMBER() OVER(PARTITION BY CUSTOMER_ID ORDER BY START_DATE ASC) AS "Row Number"
FROM SUBSCRIPTIONS AS S
JOIN PLANS AS P
    ON S.PLAN_ID = P.PLAN_ID
)
SELECT
    COUNT(CUSTOMER_ID) AS "Number of Customers Churned after Trial",
    ROUND(("Number of Customers Churned after Trial"/(SELECT COUNT(DISTINCT CUSTOMER_ID) FROM SUBSCRIPTIONS))*100) AS "% of Customers Churned after Trial"
FROM CUSTOMER_ROW_NUMBER_CTE
WHERE 
    "Row Number" = 2
    AND PLAN_ID = 4
;

--6. What is the number and percentage of customer plans after their initial free trial?
WITH CTE AS (
SELECT
    S.CUSTOMER_ID,
    P.PLAN_NAME,
    ROW_NUMBER() OVER(PARTITION BY CUSTOMER_ID ORDER BY START_DATE ASC) AS "Row Number"
FROM SUBSCRIPTIONS AS S
JOIN PLANS AS P
    ON S.PLAN_ID = P.PLAN_ID
)
SELECT
    PLAN_NAME,
    COUNT(CUSTOMER_ID) AS "Number of Customers",
    ROUND("Number of Customers"/(SELECT COUNT(DISTINCT CUSTOMER_ID) FROM SUBSCRIPTIONS)*100,1)
        AS "% of Customer Plans"
FROM CTE
WHERE "Row Number" = 2
GROUP BY 
    PLAN_NAME
;

--7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
WITH CTE AS(
SELECT
    S.CUSTOMER_ID,
    P.PLAN_NAME,
    START_DATE,
    ROW_NUMBER() OVER(PARTITION BY CUSTOMER_ID ORDER BY START_DATE DESC) AS "Row Number"
FROM SUBSCRIPTIONS AS S
JOIN PLANS AS P
    ON S.PLAN_ID = P.PLAN_ID
WHERE START_DATE <= '2020-12-31'
)
SELECT
    PLAN_NAME,
    COUNT(CUSTOMER_ID) AS "Number of Customers",
    ROUND(("Number of Customers"/(SELECT COUNT(DISTINCT CUSTOMER_ID) FROM SUBSCRIPTIONS))*100,1)
        AS "% of Customers"
FROM CTE
WHERE "Row Number" = 1
GROUP BY 
    PLAN_NAME
ORDER BY 
    "% of Customers" DESC
;

--8. How many customers have upgraded to an annual plan in 2020?
SELECT
    COUNT(DISTINCT CUSTOMER_ID) "Annual Customers in 2020"
FROM SUBSCRIPTIONS AS S
JOIN PLANS AS P
    ON S.PLAN_ID = P.PLAN_ID
WHERE P.PLAN_ID IN (3)
    AND YEAR(S.START_DATE) = 2020
;

--9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
-- First attempt (Long and inefficient) - No need for the second CTE
WITH CTE AS(
SELECT
    S.CUSTOMER_ID,
    P.PLAN_ID,
    P.PLAN_NAME,
    S.START_DATE
FROM SUBSCRIPTIONS AS S
JOIN PLANS AS P
    ON S.PLAN_ID = P.PLAN_ID
),

CTE2 AS(
SELECT
    A.CUSTOMER_ID,
    A.PLAN_NAME,
    A.START_DATE AS "Trial Date Signup",
    B.PLAN_NAME,
    B.START_DATE AS "Annual Date Signup",
    DATEDIFF(day, "Trial Date Signup", "Annual Date Signup")
        AS "Days Difference"
FROM CTE AS A
JOIN CTE AS B
    ON A.CUSTOMER_ID = B.CUSTOMER_ID
    AND A.PLAN_ID = 0
    AND B.PLAN_ID = 3
)
SELECT
ROUND(AVG("Days Difference"),1) AS "Average Days to get Annual"
FROM CTE2
;

--1 CTE method
WITH CTE AS(
SELECT
    A.CUSTOMER_ID,
    A.PLAN_ID,
    A.START_DATE AS "Trial Date Signup",
    B.PLAN_ID,
    B.START_DATE AS "Annual Date Signup",
    DATEDIFF(day, "Trial Date Signup", "Annual Date Signup")
        AS "Difference"
FROM SUBSCRIPTIONS AS A
JOIN SUBSCRIPTIONS AS B
    ON A.CUSTOMER_ID = B.CUSTOMER_ID
    AND A.PLAN_ID = 0
    AND B.PLAN_ID = 3
)
SELECT
    ROUND(AVG("Difference"),1) AS "Average Days to get Annual"
FROM CTE
;

--10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
WITH CTE AS(
SELECT
    A.CUSTOMER_ID,
    A.PLAN_ID,
    A.START_DATE AS "Trial Date Signup",
    B.PLAN_ID,
    B.START_DATE AS "Annual Date Signup",
    DATEDIFF(day, "Trial Date Signup", "Annual Date Signup")
        AS "Days to Upgrade to Annual"
FROM SUBSCRIPTIONS AS A
JOIN SUBSCRIPTIONS AS B
    ON A.CUSTOMER_ID = B.CUSTOMER_ID
    AND A.PLAN_ID = 0
    AND B.PLAN_ID = 3
)
SELECT 
    CASE 
        WHEN TO_VARCHAR("Days to Upgrade to Annual") <= 30 THEN '0-30'
        WHEN TO_VARCHAR("Days to Upgrade to Annual") >= 31 AND TO_VARCHAR("Days to Upgrade to Annual") <= 60 THEN '31-60'
        WHEN TO_VARCHAR("Days to Upgrade to Annual") >= 61 AND TO_VARCHAR("Days to Upgrade to Annual") <= 90 THEN '60-90'
        ELSE '91+'
    END AS "Days Difference Group",
    COUNT(CUSTOMER_ID)
FROM CTE
GROUP BY
    "Days Difference Group"
ORDER BY 
    "Days Difference Group" ASC
;

--How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
SELECT
    A.CUSTOMER_ID,
    A.PLAN_ID,
    A.START_DATE AS "Initial Pro monthly date",
    B.PLAN_ID,
    B.START_DATE AS "Basic Monthly Switch"
FROM SUBSCRIPTIONS AS A
JOIN SUBSCRIPTIONS AS B
    ON A.CUSTOMER_ID = B.CUSTOMER_ID
    AND A.PLAN_ID = 2
    AND B.PLAN_ID = 1
;
-- No one downgraded
    
    





