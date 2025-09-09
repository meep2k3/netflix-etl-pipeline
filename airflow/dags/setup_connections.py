# airflow/dags/setup_connections.py
from airflow import settings
from airflow.models import Connection
from airflow.utils.db import provide_session

@provide_session
def create_netflix_connections(session=None):
    """Create Netflix project connections in Airflow"""
    
    # MySQL connection for Netflix database
    netflix_mysql = Connection(
        conn_id='netflix_mysql_conn',
        conn_type='mysql',
        host='mysql',
        login='netflix_user',
        password='netflix_password',
        schema='netflix_db',
        port=3306
    )
    
    # Check if connection exists
    existing_conn = session.query(Connection).filter(
        Connection.conn_id == netflix_mysql.conn_id
    ).first()
    
    if not existing_conn:
        session.add(netflix_mysql)
        session.commit()
        print(f"Created connection: {netflix_mysql.conn_id}")
    else:
        print(f"Connection already exists: {netflix_mysql.conn_id}")

if __name__ == "__main__":
    create_netflix_connections()