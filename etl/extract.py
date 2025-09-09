# etl/extract.py
import pandas as pd
import os

def extract(path: str = None) -> pd.DataFrame:
    """Extract Netflix data from CSV file"""
    if path is None:
        # Default path trong container
        path = "/opt/airflow/data/netflix_titles.csv"
    
    if not os.path.exists(path):
        raise FileNotFoundError(f"Netflix CSV file not found at {path}")
    
    print(f"Extracting data from {path}")
    df = pd.read_csv(path)
    print(f"Extracted {len(df)} records")
    return df

if __name__ == "__main__":
    df = extract()
    print(f"Shape: {df.shape}")
    print(f"Columns: {list(df.columns)}")