-- =============================================================================
-- Fraud Detection | PostgreSQL schema
-- Originally exported from QuickDBD, then hardened: re-runnable, exact money
-- type, explicit constraints and indexes for the join/filter patterns used in
-- the analysis.
-- Run order: schema.sql -> seed.sql -> views.sql
-- =============================================================================

DROP TABLE IF EXISTS transaction       CASCADE;
DROP TABLE IF EXISTS credit_card       CASCADE;
DROP TABLE IF EXISTS merchant          CASCADE;
DROP TABLE IF EXISTS merchant_category CASCADE;
DROP TABLE IF EXISTS card_holder       CASCADE;

-- Card holder -----------------------------------------------------------------
CREATE TABLE card_holder (
    id    SERIAL       PRIMARY KEY,
    name  VARCHAR(50)  NOT NULL
);

-- Credit card -----------------------------------------------------------------
-- `card` is VARCHAR (not INT): card numbers are identifiers, not quantities, and
-- can exceed the INT range.
CREATE TABLE credit_card (
    card            VARCHAR(20) PRIMARY KEY,
    id_card_holder  INT         NOT NULL REFERENCES card_holder (id)
);

-- Merchant category -----------------------------------------------------------
CREATE TABLE merchant_category (
    id    SERIAL       PRIMARY KEY,
    name  VARCHAR(50)  NOT NULL UNIQUE
);

-- Merchant --------------------------------------------------------------------
CREATE TABLE merchant (
    id                   SERIAL        PRIMARY KEY,
    name                 VARCHAR(255)  NOT NULL,
    id_merchant_category INT           NOT NULL REFERENCES merchant_category (id)
);

-- Transaction -----------------------------------------------------------------
-- NUMERIC(10,2) instead of FLOAT: monetary amounts must not carry binary
-- floating-point rounding error.
CREATE TABLE transaction (
    id           INT            PRIMARY KEY,
    date         TIMESTAMP      NOT NULL,
    amount       NUMERIC(10, 2) NOT NULL CHECK (amount > 0),
    card         VARCHAR(20)    NOT NULL REFERENCES credit_card (card),
    id_merchant  INT            NOT NULL REFERENCES merchant (id)
);

-- Indexes on foreign keys and the columns the analysis filters on --------------
CREATE INDEX idx_credit_card_holder   ON credit_card (id_card_holder);
CREATE INDEX idx_merchant_category    ON merchant (id_merchant_category);
CREATE INDEX idx_transaction_card     ON transaction (card);
CREATE INDEX idx_transaction_merchant ON transaction (id_merchant);
CREATE INDEX idx_transaction_date     ON transaction (date);
