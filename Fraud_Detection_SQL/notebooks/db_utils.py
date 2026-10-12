"""Shared database helpers for the fraud-detection notebooks.

The connection string is read from the DATABASE_URL environment variable (or a
`.env` file) so that credentials are never committed to the repository.

    DATABASE_URL=postgresql+psycopg2://USER:PASSWORD@localhost:5432/fraud_detection
"""
import os

import pandas as pd
from sqlalchemy import create_engine, text

try:  # optional: load variables from a local .env file if python-dotenv is installed
    from dotenv import load_dotenv

    load_dotenv()
except ImportError:  # pragma: no cover
    pass


def get_engine():
    """Create a SQLAlchemy engine from the DATABASE_URL environment variable."""
    url = os.getenv("DATABASE_URL")
    if not url:
        raise RuntimeError(
            "DATABASE_URL is not set. Copy .env.example to .env and fill in your "
            "PostgreSQL credentials (see README -> Getting started)."
        )
    return create_engine(url)


def load_transactions(engine=None, where=None, params=None):
    """Return every transaction (joined with holder, merchant and category).

    Reads from the `v_transaction_details` view defined in SQL/views.sql, indexed
    by transaction timestamp. `where` is an optional SQL condition that may use
    named parameters, e.g. where="holder_id = :holder", params={"holder": 25}.
    """
    engine = engine or get_engine()
    query = "SELECT * FROM v_transaction_details"
    if where:
        query += f" WHERE {where}"
    query += " ORDER BY date"
    df = pd.read_sql(text(query), engine, params=params, parse_dates=["date"])
    df["amount"] = df["amount"].astype(float)  # NUMERIC -> float for plotting/stats
    return df.set_index("date")
