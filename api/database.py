import os
import psycopg2
from psycopg2.extras import RealDictCursor
from contextlib import contextmanager
from dotenv import load_dotenv

load_dotenv()


def get_connection():
    return psycopg2.connect(
        host=os.getenv("DB_HOST"),
        database=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD")
    )


@contextmanager
def get_cursor():
    conn = get_connection()
    # RealDictCursor returns rows as dicts: row["rule_name"] instead of row[0]
    cursor = conn.cursor(cursor_factory=RealDictCursor)

    try:
        yield cursor
    finally:
        cursor.close()
        conn.close()
