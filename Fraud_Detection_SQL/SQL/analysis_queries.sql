-- =============================================================================
-- Fraud analysis queries (run after views.sql)
-- =============================================================================

-- Q1. Top 100 transactions between 07:00 and 09:00 ----------------------------
SELECT * FROM v_early_hour_top100;

-- Which categories dominate that window when only large charges (> $100) are kept?
SELECT category,
       COUNT(*)    AS tx_count,
       SUM(amount) AS total_amount,
       MAX(amount) AS largest
FROM v_transaction_details
WHERE date::time BETWEEN TIME '07:00' AND TIME '09:00'
  AND amount > 100
GROUP BY category
ORDER BY tx_count DESC;


-- Q2. Micro transactions (< $2) per card holder -------------------------------
SELECT * FROM v_small_transactions_by_holder;


-- Q3. Top five merchants targeted with micro transactions ---------------------
SELECT * FROM v_top5_merchants_small_tx;


-- Q4. Statistical outliers, entirely in SQL -----------------------------------
-- 4a. Three-standard-deviation rule (population std. dev.)
WITH stats AS (
    SELECT AVG(amount) AS mu, STDDEV_POP(amount) AS sigma
    FROM transaction
)
SELECT d.*
FROM v_transaction_details d, stats s
WHERE d.amount > s.mu + 3 * s.sigma
   OR d.amount < s.mu - 3 * s.sigma
ORDER BY d.amount DESC;

-- 4b. Interquartile-range rule (1.5 x IQR)
WITH q AS (
    SELECT percentile_cont(0.25) WITHIN GROUP (ORDER BY amount) AS q1,
           percentile_cont(0.75) WITHIN GROUP (ORDER BY amount) AS q3
    FROM transaction
)
SELECT d.*
FROM v_transaction_details d, q
WHERE d.amount > q.q3 + 1.5 * (q.q3 - q.q1)
   OR d.amount < q.q1 - 1.5 * (q.q3 - q.q1)
ORDER BY d.amount DESC;


-- Q5. Card holder 25: unusually large charges in Jan-Jun 2018 -----------------
SELECT transaction_id, date, amount, category, merchant_name
FROM v_transaction_details
WHERE holder_id = 25
  AND date >= DATE '2018-01-01' AND date < DATE '2018-07-01'
  AND amount > 100
ORDER BY amount DESC;
