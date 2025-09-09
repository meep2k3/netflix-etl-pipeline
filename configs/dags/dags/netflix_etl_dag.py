# airflow/dags/netflix_etl_dag.py - Fixed version
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.providers.mysql.operators.mysql import MySqlOperator
import sys
import os

# Thêm ETL modules vào Python path
sys.path.append('/opt/airflow/etl')

# Import ETL functions
from extract import extract
from transform import transform
from load import load

# Default arguments cho DAG
default_args = {
    'owner': 'data-engineer',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

# Định nghĩa DAG
dag = DAG(
    'netflix_etl_pipeline',
    default_args=default_args,
    description='Netflix ETL Pipeline - Extract, Transform, Load',
    schedule_interval='@daily',  # Chạy hàng ngày
    max_active_runs=1,
    catchup=False,
    tags=['netflix', 'etl', 'data-engineering'],
)

# Task functions
def extract_task(**context):
    """Extract Netflix data from CSV"""
    print("Starting Extract Task...")
    try:
        df = extract("/opt/airflow/data/netflix_titles.csv")
        
        # Log thông tin cơ bản
        print(f"Extracted {len(df)} records")
        print(f"Columns: {list(df.columns)}")
        print(f"Data types:\n{df.dtypes}")
        
        # Lưu extracted data để debug (optional)
        df.head(10).to_csv("/opt/airflow/data/sample_extracted.csv", index=False)
        
        # Push metadata to XCom
        context['task_instance'].xcom_push(key='records_count', value=len(df))
        context['task_instance'].xcom_push(key='columns', value=list(df.columns))
        
        return f"Successfully extracted {len(df)} records"
    except Exception as e:
        print(f"Extract task failed: {str(e)}")
        raise

def transform_task(**context):
    """Transform Netflix data"""
    print("Starting Transform Task...")
    try:
        # Get data from previous task
        records_count = context['task_instance'].xcom_pull(task_ids='extract', key='records_count')
        print(f"Processing {records_count} records from extract task")
        
        # Extract again (trong thực tế có thể cache data)
        df = extract("/opt/airflow/data/netflix_titles.csv")
        
        # Transform data
        output_files = transform(df, output_dir="/opt/airflow/data/processed")
        
        # Log transformation results
        print(f"Transform completed successfully!")
        print(f"Generated {len(output_files)} output files:")
        for file in output_files:
            if os.path.exists(file):
                file_size = os.path.getsize(file)
                print(f"  - {os.path.basename(file)}: {file_size} bytes")
        
        # Push results to XCom
        context['task_instance'].xcom_push(key='output_files', value=output_files)
        context['task_instance'].xcom_push(key='files_count', value=len(output_files))
        
        return f"Successfully transformed data into {len(output_files)} files"
    except Exception as e:
        print(f"Transform task failed: {str(e)}")
        raise

def load_task(**context):
    """Load transformed data to MySQL"""
    print("Starting Load Task...")
    try:
        # Get data from previous task
        files_count = context['task_instance'].xcom_pull(task_ids='transform', key='files_count')
        print(f"Loading {files_count} transformed files to MySQL")
        
        # Load data
        connection_string = "mysql+pymysql://netflix_user:netflix_password@mysql:3306/netflix_db"
        load(data_dir="/opt/airflow/data/processed", connection_string=connection_string)
        
        return "Successfully loaded all data to MySQL database"
    except Exception as e:
        print(f"Load task failed: {str(e)}")
        raise

def data_quality_check(**context):
    """Perform basic data quality checks"""
    print("Starting Data Quality Check...")
    
    try:
        from sqlalchemy import create_engine, text
        
        engine = create_engine("mysql+pymysql://netflix_user:netflix_password@mysql:3306/netflix_db")
        
        checks = []
        
        with engine.connect() as conn:
            # Check 1: Count records in fact table
            result = conn.execute(text("SELECT COUNT(*) as count FROM fact_show"))
            fact_count = result.fetchone()[0]
            checks.append(f"fact_show: {fact_count} records")
            
            # Check 2: Count unique directors
            result = conn.execute(text("SELECT COUNT(*) as count FROM dim_director"))
            director_count = result.fetchone()[0]
            checks.append(f"dim_director: {director_count} records")
            
            # Check 3: Count unique cast members
            result = conn.execute(text("SELECT COUNT(*) as count FROM dim_cast"))
            cast_count = result.fetchone()[0]
            checks.append(f"dim_cast: {cast_count} records")
            
            # Check 4: Count unique genres
            result = conn.execute(text("SELECT COUNT(*) as count FROM dim_genre"))
            genre_count = result.fetchone()[0]
            checks.append(f"dim_genre: {genre_count} records")
            
            # Check 5: Count unique countries
            result = conn.execute(text("SELECT COUNT(*) as count FROM dim_country"))
            country_count = result.fetchone()[0]
            checks.append(f"dim_country: {country_count} records")
            
            # Check 6: Verify bridge tables have data
            bridge_tables = ['bridge_show_director', 'bridge_show_cast', 'bridge_show_genre', 'bridge_show_country']
            for table in bridge_tables:
                result = conn.execute(text(f"SELECT COUNT(*) as count FROM {table}"))
                bridge_count = result.fetchone()[0]
                checks.append(f"{table}: {bridge_count} records")
        
        print("Data Quality Check Results:")
        for check in checks:
            print(f"  ✓ {check}")
        
        # Push results to XCom
        context['task_instance'].xcom_push(key='quality_checks', value=checks)
        
        return "Data quality checks passed successfully"
    except Exception as e:
        print(f"Data quality check failed: {str(e)}")
        raise

def cleanup_task(**context):
    """Clean up temporary files"""
    print("Starting Cleanup Task...")
    try:
        cleanup_paths = [
            "/opt/airflow/data/sample_extracted.csv"
        ]
        
        for path in cleanup_paths:
            if os.path.exists(path):
                os.remove(path)
                print(f"Removed file: {path}")
        
        return "Cleanup completed successfully"
    except Exception as e:
        print(f"Cleanup task failed: {str(e)}")
        return f"Cleanup completed with warnings: {str(e)}"

# Install packages task (chạy một lần để cài packages cần thiết)
install_packages = BashOperator(
    task_id='install_packages',
    bash_command='''
    pip install --no-cache-dir pymysql cryptography || true
    echo "Packages installation completed"
    ''',
    dag=dag,
)

# Định nghĩa tasks
extract_data = PythonOperator(
    task_id='extract',
    python_callable=extract_task,
    dag=dag,
)

transform_data = PythonOperator(
    task_id='transform',
    python_callable=transform_task,
    dag=dag,
)

load_data = PythonOperator(
    task_id='load',
    python_callable=load_task,
    dag=dag,
)

quality_check = PythonOperator(
    task_id='data_quality_check',
    python_callable=data_quality_check,
    dag=dag,
)

cleanup = PythonOperator(
    task_id='cleanup',
    python_callable=cleanup_task,
    dag=dag,
    trigger_rule='none_failed_min_one_success'
)

# Định nghĩa dependencies
install_packages >> extract_data >> transform_data >> load_data >> quality_check >> cleanup