#!/bin/bash
echo "Initializing Superset MySQL fixes..."
python -c "import pymysql; pymysql.install_as_MySQLdb()"
export SUPERSET_CONFIG_PATH=/app/superset_home/superset_config.py
export PYTHONPATH=/app/superset_home:/app/pythonpath_dev
unset SUPERSET_DATABASE_URI
echo "MySQL fixes applied"