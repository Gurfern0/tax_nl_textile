-- Advanced Cohort Analysis and Customer Lifetime Value Calculation
-- This query demonstrates complex window functions, CTEs, and advanced aggregations

WITH customer_cohorts AS (
    -- Identify customer cohorts based on their first purchase
    SELECT 
        customer_id,
        DATE_TRUNC(order_date, MONTH) as cohort_month,
        DATE_TRUNC(first_order_date, MONTH) as first_purchase_month,
        -- Calculate cohort age in months
        DATE_DIFF(DATE_TRUNC(order_date, MONTH), 
                 DATE_TRUNC(first_order_date, MONTH), 
                 MONTH) as cohort_age
    FROM orders o
    JOIN customers c USING (customer_id)
    WHERE status = 'completed'
),

cohort_metrics AS (
    -- Calculate key metrics for each cohort
    SELECT 
        first_purchase_month,
        cohort_age,
        COUNT(DISTINCT customer_id) as active_customers,
        SUM(total_amount) as total_revenue,
        AVG(total_amount) as avg_order_value,
        -- Calculate retention rate
        COUNT(DISTINCT customer_id) / 
        FIRST_VALUE(COUNT(DISTINCT customer_id)) 
            OVER (PARTITION BY first_purchase_month 
                  ORDER BY cohort_age) as retention_rate
    FROM customer_cohorts cc
    JOIN orders o USING (customer_id)
    WHERE o.status = 'completed'
    GROUP BY 1, 2
),

customer_lifetime_value AS (
    -- Calculate customer lifetime value using RFM analysis
    SELECT 
        customer_id,
        COUNT(DISTINCT order_id) as frequency,
        SUM(total_amount) as monetary,
        DATE_DIFF(CURRENT_TIMESTAMP(), 
                 MAX(order_date), 
                 DAY) as recency,
        -- Calculate RFM score
        CASE 
            WHEN recency <= 30 THEN 5
            WHEN recency <= 60 THEN 4
            WHEN recency <= 90 THEN 3
            WHEN recency <= 180 THEN 2
            ELSE 1
        END as recency_score,
        CASE 
            WHEN frequency >= 10 THEN 5
            WHEN frequency >= 7 THEN 4
            WHEN frequency >= 5 THEN 3
            WHEN frequency >= 3 THEN 2
            ELSE 1
        END as frequency_score,
        CASE 
            WHEN monetary >= 1000 THEN 5
            WHEN monetary >= 500 THEN 4
            WHEN monetary >= 250 THEN 3
            WHEN monetary >= 100 THEN 2
            ELSE 1
        END as monetary_score
    FROM orders
    WHERE status = 'completed'
    GROUP BY 1
)

-- Final results combining cohort analysis and customer value
SELECT 
    cm.first_purchase_month,
    cm.cohort_age,
    cm.active_customers,
    cm.total_revenue,
    cm.avg_order_value,
    cm.retention_rate,
    -- Add customer value metrics
    AVG(clv.frequency) as avg_frequency,
    AVG(clv.monetary) as avg_lifetime_value,
    -- Calculate cohort health score
    (cm.retention_rate * 0.4 + 
     (cm.total_revenue / FIRST_VALUE(cm.total_revenue) 
      OVER (PARTITION BY cm.first_purchase_month 
            ORDER BY cm.cohort_age)) * 0.6) as cohort_health_score
FROM cohort_metrics cm
LEFT JOIN customer_lifetime_value clv 
    ON cm.first_purchase_month = DATE_TRUNC(clv.first_order_date, MONTH)
GROUP BY 1, 2, 3, 4, 5, 6
ORDER BY 1, 2;

-- Performance Notes:
-- 1. This query uses window functions efficiently for cohort calculations
-- 2. CTEs help break down complex logic into manageable steps
-- 3. The query benefits from partitioning on order_date and customer_id
-- 4. Consider materializing the customer_lifetime_value CTE for frequent access
-- 5. Indexes on customer_id and order_date will improve JOIN performance 