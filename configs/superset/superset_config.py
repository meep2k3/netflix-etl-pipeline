import pymysql; pymysql.install_as_MySQLdb()
import os

SECRET_KEY = 'netflix_superset_secret_2024'
SQLALCHEMY_DATABASE_URI = 'mysql+pymysql://netflix_user:netflix_password@mysql:3306/netflix_db'

# Fix DDL/DML permissions
PREVENT_UNSAFE_DB_CONNECTIONS = False
SQLLAB_ASYNC_TIME_LIMIT_SEC = 300
SQLLAB_TIMEOUT = 300

FEATURE_FLAGS = {
    'DASHBOARD_NATIVE_FILTERS': True,
    'DASHBOARD_CROSS_FILTERS': True,
    'DASHBOARD_NATIVE_FILTERS_SET': True,
    'ENABLE_TEMPLATE_PROCESSING': True,
    'DYNAMIC_PLUGINS': True,
}
