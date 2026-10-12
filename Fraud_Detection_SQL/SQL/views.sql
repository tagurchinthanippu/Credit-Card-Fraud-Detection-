-- =============================================================================
-- Reusable views for fraud analysis (run after schema.sql and seed.sql)
-- =============================================================================

-- 0. Base view: every transaction joined to its card, holder, merchant and
--    category. All other views and the notebooks build on this one.
CREATE OR REPLACE VIEW v_transaction_details AS
SELECT t.id          AS transaction_id,
       t.date,
       t.amount,
       t.card,
       ch.id         AS holder_id,
       ch.name       AS holder_name,
       m.id          AS merchant_id,
       m.name        AS merchant_name,
       mc.name       AS category
FROM transaction t
JOIN credit_card        cc ON cc.card = t.card
JOIN card_holder        ch ON ch.id   = cc.id_card_holder
JOIN merchant           m  ON m.id    = t.id_merchant
JOIN merchant_category  mc ON mc.id   = m.id_merchant_category;


-- 1. Top 100 highest transactions made between 07:00 and 09:00.
CREATE OR REPLACE VIEW v_early_hour_top100 AS
SELECT *
FROM v_transaction_details
WHERE date::time BETWEEN TIME '07:00' AND TIME '09:00'
ORDER BY amount DESC
LIMIT 100;


-- 2. Number of "micro" transactions (< $2.00) per card holder, with their share
--    of that holder's total activity. Card-testing fraud often starts with many
--    tiny charges that cardholders ignore.
CREATE OR REPLACE VIEW v_small_transactions_by_holder AS
SELECT holder_id,
       holder_name,
       COUNT(*) FILTER (WHERE amount < 2)                     AS small_tx_count,
       COUNT(*)                                               AS total_tx_count,
       ROUND(100.0 * COUNT(*) FILTER (WHERE amount < 2)
                   / COUNT(*), 1)                             AS small_tx_pct
FROM v_transaction_details
GROUP BY holder_id, holder_name
ORDER BY small_tx_count DESC, holder_id;


-- 3. Top five merchants by number of micro transactions (< $2.00).
--    Ten merchants tie at 5 micro transactions in this dataset, so the ranking
--    is made deterministic with documented tie-breaks: (1) more distinct cards
--    hit = more likely a compromised merchant rather than one unlucky customer,
--    then (2) merchant name.
CREATE OR REPLACE VIEW v_top5_merchants_small_tx AS
SELECT ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC,
                                   COUNT(DISTINCT card) DESC,
                                   merchant_name)   AS rank,
       merchant_id,
       merchant_name,
       category,
       COUNT(*)              AS small_tx_count,
       COUNT(DISTINCT card)  AS distinct_cards
FROM v_transaction_details
WHERE amount < 2
GROUP BY merchant_id, merchant_name, category
ORDER BY rank
LIMIT 5;
