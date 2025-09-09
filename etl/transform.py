# etl/transform.py
import pandas as pd
import os

def transform(df: pd.DataFrame, output_dir: str = "/opt/airflow/data/processed"):
    """Transform Netflix data and create fact/dim tables"""
    print("Starting data transformation...")
    
    # Tạo thư mục output nếu chưa có
    os.makedirs(output_dir, exist_ok=True)
    
    # 1. Xử lý NaN cho director, country, cast, rating (Chuyển NaN thành "Unknown")
    df_filled = df.copy()
    df_filled[['director', 'cast', 'country', 'rating']] = df_filled[['director', 'cast', 'country', 'rating']].fillna('Unknown')

    # 2. Chuyển tên cột 
    df_filled = df_filled.rename(columns={
        'type': 'show_type',
        'description': 'show_description'
    })

    # 3. Chuẩn hóa nội dung trong từng cột
    # Chuẩn hóa cột director
    df_filled['director'] = df_filled['director'].str.strip().str.replace(r'\s+', ' ', regex=True).str.title()

    # Chuẩn hóa các cột ở dạng list
    def normalize_list_column(value, default="Unknown"):
        """Chuẩn hoá chuỗi dạng list (ngăn cách bởi dấu phẩy)"""
        if pd.isna(value) or value == default:
            return default
        items = [x.strip().title() for x in str(value).split(",") if x.strip()]
        return ", ".join(items)

    df_filled['cast'] = df_filled['cast'].apply(normalize_list_column)
    df_filled['country'] = df_filled['country'].apply(normalize_list_column)
    df_filled['listed_in'] = df_filled['listed_in'].apply(normalize_list_column)

    # Chuẩn hóa cột date_added (chuyển kiểu dữ liệu từ object -> datetime)
    df_filled['date_added'] = pd.to_datetime(df_filled['date_added'], errors='coerce')

    # Xử lý cột duration (tách ra thành duration_value và duration_unit)
    df_filled["duration"] = df_filled["duration"].fillna("0 Unknown") # Chuyển các giá trị NaN thành '0 Unknown'
    df_filled['duration_value'] = df_filled['duration'].str.extract(r'(\d+)')
    df_filled['duration_unit'] = df_filled['duration'].str.extract(r'([a-zA-Z]+)')
    df_filled['duration_value'] = df_filled['duration_value'].fillna(0).astype(int) # Chuyển NaN trong value (nếu có) -> 0
    df_filled['duration_unit'] = df_filled['duration_unit'].fillna('Unknown')
    df_filled.drop(columns=['duration'], inplace=True)

    # 4. Tách list, tạo các bảng dim, bridge, fact_show 
    def split_and_explode(df, col):
        return (
            df[['title', 'release_year', col]] 
            .assign(**{col: df[col].astype(str).str.split(', ')})
            .explode(col)
            .drop_duplicates()
        )
    
    # dim_tables
    dim_director = pd.DataFrame(df_filled['director'].astype(str).str.split(', ').explode().unique(), columns=['director_name'])
    dim_cast = pd.DataFrame(df_filled['cast'].astype(str).str.split(', ').explode().unique(), columns=['cast_name'])
    dim_genre = pd.DataFrame(df_filled['listed_in'].astype(str).str.split(', ').explode().unique(), columns=['genre_name'])
    dim_country = pd.DataFrame(df_filled['country'].astype(str).str.split(', ').explode().unique(), columns=['country_name'])

    # bridge tables 
    bridge_show_director = split_and_explode(df_filled, 'director')
    bridge_show_cast = split_and_explode(df_filled, 'cast')
    bridge_show_genre = split_and_explode(df_filled, 'listed_in')
    bridge_show_country = split_and_explode(df_filled, 'country')

    # fact show (loại bỏ các cột thừa)
    fact_show = df_filled.drop(columns=['show_id', 'director', 'cast', 'country', 'listed_in'])

    # 5. Lưu thành các file csv
    files_saved = []
    
    fact_show_path = os.path.join(output_dir, 'fact_show.csv')
    fact_show.to_csv(fact_show_path, index=False)
    files_saved.append(fact_show_path)

    dim_director_path = os.path.join(output_dir, 'dim_director.csv')
    dim_director.to_csv(dim_director_path, index=False)
    files_saved.append(dim_director_path)

    dim_cast_path = os.path.join(output_dir, 'dim_cast.csv')
    dim_cast.to_csv(dim_cast_path, index=False)
    files_saved.append(dim_cast_path)

    dim_genre_path = os.path.join(output_dir, 'dim_genre.csv')
    dim_genre.to_csv(dim_genre_path, index=False)
    files_saved.append(dim_genre_path)

    dim_country_path = os.path.join(output_dir, 'dim_country.csv')
    dim_country.to_csv(dim_country_path, index=False)
    files_saved.append(dim_country_path)

    bridge_show_cast_path = os.path.join(output_dir, 'bridge_show_cast.csv')
    bridge_show_cast.to_csv(bridge_show_cast_path, index=False)
    files_saved.append(bridge_show_cast_path)

    bridge_show_director_path = os.path.join(output_dir, 'bridge_show_director.csv')
    bridge_show_director.to_csv(bridge_show_director_path, index=False)
    files_saved.append(bridge_show_director_path)

    bridge_show_genre_path = os.path.join(output_dir, 'bridge_show_genre.csv')
    bridge_show_genre.to_csv(bridge_show_genre_path, index=False)
    files_saved.append(bridge_show_genre_path)

    bridge_show_country_path = os.path.join(output_dir, 'bridge_show_country.csv')
    bridge_show_country.to_csv(bridge_show_country_path, index=False)
    files_saved.append(bridge_show_country_path)

    print(f"Transform completed. Files saved: {len(files_saved)}")
    for file in files_saved:
        print(f"  - {file}")
    
    return files_saved

if __name__ == "__main__":
    from extract import extract
    df = extract()
    transform(df)