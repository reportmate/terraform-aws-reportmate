from __future__ import annotations
import os, psycopg
from psycopg_pool import ConnectionPool  # psycopg comes with this sub-pkg

_pool: ConnectionPool | None = None


def get_pool() -> ConnectionPool:
    global _pool
    if _pool is None:
        dsn = os.environ["DATABASE_URL"]
        _pool = ConnectionPool(
            conninfo=dsn,
            min_size=1,
            max_size=6,
            open=False,           # lazy-open
        )
        _pool.open(wait=True)
    return _pool