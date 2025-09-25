# etl/load.py
import pandas as pd
from sqlalchemy import create_engine, text
import os

def load(
    data_dir: str = "/opt/airflow/data/processed",
    connection_string: str = "mysql+pymysql://netflix_user:netflix_password@netflix_mysql:3306/netflix_db",
):
    """Load transformed data into MySQL database"""
    print("Starting data loading...")

    # Tạo engine object
    engine = create_engine(connection_string)

    # --- Đọc file ---
    fact_show = pd.read_csv(os.path.join(data_dir, "fact_show.csv"))
    dim_director = pd.read_csv(os.path.join(data_dir, "dim_director.csv"))
    dim_cast = pd.read_csv(os.path.join(data_dir, "dim_cast.csv"))
    dim_genre = pd.read_csv(os.path.join(data_dir, "dim_genre.csv"))
    dim_country = pd.read_csv(os.path.join(data_dir, "dim_country.csv"))
    bridge_show_cast = pd.read_csv(os.path.join(data_dir, "bridge_show_cast.csv"))
    bridge_show_director = pd.read_csv(os.path.join(data_dir, "bridge_show_director.csv"))
    bridge_show_genre = pd.read_csv(os.path.join(data_dir, "bridge_show_genre.csv"))
    bridge_show_country = pd.read_csv(os.path.join(data_dir, "bridge_show_country.csv"))

    # --- Load fact_show ---
    # CLEAR TABLE
    with engine.begin() as conn:
        conn.execute(text("DELETE FROM dim_director"))
        conn.execute(text("DELETE FROM dim_cast"))
        conn.execute(text("DELETE FROM dim_country"))
        conn.execute(text("DELETE FROM dim_genre"))
        conn.execute(text("DELETE FROM bridge_show_director"))
        conn.execute(text("DELETE FROM bridge_show_cast"))
        conn.execute(text("DELETE FROM bridge_show_country"))
        conn.execute(text("DELETE FROM bridge_show_genre"))
        conn.execute(text("DELETE FROM fact_show"))
        print("Cleared existing data from fact_show")
        
    # Load fresh data
    print("Loading fact_show table...")
    try:
        fact_show.to_sql(
            name="fact_show",
            con=engine,
            if_exists="append",
            index=False,
            method="multi"
        )
        print(f"Loaded {len(fact_show)} records to fact_show")
    except Exception as e:
        print(f"Error with engine, trying connection string: {e}")
        fact_show.to_sql(
            name="fact_show",
            con=connection_string,
            if_exists="append",
            index=False,
            method="multi"
        )
        print(f"Loaded {len(fact_show)} records to fact_show (using connection string)")

    # --- Hàm insert dim ---
    def insert_dim(table_name, col_name, df):
        unique_values = df[col_name].dropna().unique()
        print(f"{table_name}: {len(unique_values)} unique values are going to insert")
        values = [{"val": v} for v in df[col_name].dropna().unique()]
        if values:
            with engine.begin() as conn:
                result = conn.execute(
                    text(f"INSERT IGNORE INTO {table_name} ({col_name}) VALUES (:val)"),
                    values,
                )
                print(f"Inserted {result.rowcount} records to {table_name}")

    print("Loading dimension tables...")
    insert_dim("dim_director", "director_name", dim_director)
    insert_dim("dim_cast", "cast_name", dim_cast)
    insert_dim("dim_country", "country_name", dim_country)
    insert_dim("dim_genre", "genre_name", dim_genre)

    # --- Load bridge ---
    print("Loading bridge tables...")
    with engine.begin() as conn:
        # Helper function
        def safe_insert(description, query, values):
            if not values:
                print(f"No values to insert for {description}")
                return
            result = None
            try:
                result = conn.execute(text(query), values)
            except Exception as e:
                print(f"Load task failed for {description}: {e}")
            if result is not None:
                print(f"Inserted {result.rowcount} records to {description}")

        # Map director
        director_values = [
            {"title": row["title"], "year": row["release_year"], "name": row["director"]}
            for _, row in bridge_show_director.iterrows()
        ]
        safe_insert(
            "bridge_show_director",
            """
            INSERT IGNORE INTO bridge_show_director (show_id, director_id)
            SELECT f.show_id, d.director_id
            FROM fact_show f
            JOIN dim_director d ON d.director_name = :name
            WHERE f.title = :title AND f.release_year = :year
            """,
            director_values
        )

        # Map cast
        cast_values = [
            {"title": row["title"], "year": row["release_year"], "name": row["cast"]}
            for _, row in bridge_show_cast.iterrows()
        ]
        safe_insert(
            "bridge_show_cast",
            """
            INSERT IGNORE INTO bridge_show_cast (show_id, cast_id)
            SELECT f.show_id, c.cast_id
            FROM fact_show f
            JOIN dim_cast c ON c.cast_name = :name
            WHERE f.title = :title AND f.release_year = :year
            """,
            cast_values
        )

        # Map country
        country_values = [
            {"title": row["title"], "year": row["release_year"], "name": row["country"]}
            for _, row in bridge_show_country.iterrows()
        ]
        safe_insert(
            "bridge_show_country",
            """
            INSERT IGNORE INTO bridge_show_country (show_id, country_id)
            SELECT f.show_id, c.country_id
            FROM fact_show f
            JOIN dim_country c ON c.country_name = :name
            WHERE f.title = :title AND f.release_year = :year
            """,
            country_values
        )

        # Map genre
        genre_values = [
            {"title": row["title"], "year": row["release_year"], "name": row["listed_in"]}
            for _, row in bridge_show_genre.iterrows()
        ]
        safe_insert(
            "bridge_show_genre",
            """
            INSERT IGNORE INTO bridge_show_genre (show_id, genre_id)
            SELECT f.show_id, g.genre_id
            FROM fact_show f
            JOIN dim_genre g ON g.genre_name = :name
            WHERE f.title = :title AND f.release_year = :year
            """,
            genre_values
        )

    print("Load completed successfully!")

if __name__ == "__main__":
    load()
