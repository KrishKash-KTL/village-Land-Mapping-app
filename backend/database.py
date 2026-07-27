"""
database.py - Database configuration and models for Village Land Mapping
PostgreSQL + PostGIS ke liye SQLAlchemy setup
"""

import os
from sqlalchemy import create_engine, Column, Integer, String, Float, DateTime, func
from sqlalchemy.orm import DeclarativeBase, sessionmaker
from geoalchemy2 import Geometry
from datetime import datetime

# Database connection - portable PostgreSQL on port 5433
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://postgres@localhost:5433/village_mapping"
)

engine = create_engine(DATABASE_URL, echo=False)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class Base(DeclarativeBase):
    pass


class Field(Base):
    """
    Ek khet/plot ka record.
    Stores name, owner, khasra number, GPS boundary polygon, and calculated dimensions.
    """
    __tablename__ = "fields"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    name = Column(String(200), nullable=False)
    owner_name = Column(String(200), nullable=False)
    khasra_number = Column(String(100), nullable=True)

    # PostGIS Polygon geometry in WGS84 (standard GPS coordinates)
    boundary = Column(Geometry("POLYGON", srid=4326), nullable=False)

    # Calculated dimensions
    area_sqm = Column(Float, nullable=True)      # Square meters
    area_bigha = Column(Float, nullable=True)    # Bigha (UP/Bihar standard: 1 bigha = 2529.3 sqm)
    area_acre = Column(Float, nullable=True)     # Acres (1 acre = 4046.86 sqm)
    perimeter_m = Column(Float, nullable=True)  # Perimeter in meters

    created_at = Column(DateTime, default=datetime.utcnow)


def get_db():
    """FastAPI dependency to get DB session."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def create_tables():
    """
    Creates all tables. Also enables PostGIS extension if not already enabled.
    """
    # Enable PostGIS extension
    with engine.connect() as conn:
        conn.execute(
            __import__("sqlalchemy").text("CREATE EXTENSION IF NOT EXISTS postgis;")
        )
        conn.commit()

    Base.metadata.create_all(bind=engine)
    print("✅ Database tables created successfully.")


def ensure_database_exists():
    """
    Creates the 'village_mapping' database if it does not exist.
    Connects to the default 'postgres' database first.
    """
    import psycopg2
    from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT

    try:
        conn = psycopg2.connect(
            host="localhost",
            port=5433,
            user="postgres",
            dbname="postgres"
        )
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cur = conn.cursor()
        cur.execute("SELECT 1 FROM pg_database WHERE datname = 'village_mapping'")
        if not cur.fetchone():
            cur.execute("CREATE DATABASE village_mapping")
            print("✅ Database 'village_mapping' created.")
        else:
            print("✅ Database 'village_mapping' already exists.")
        cur.close()
        conn.close()
    except Exception as e:
        print(f"⚠️  Could not ensure database exists: {e}")
        print("   Make sure PostgreSQL is running (run start-postgres.bat first)")
