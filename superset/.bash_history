ls -la /app/pythonpath_dev/
cat /app/pythonpath_dev/superset_init.py
exit
python --version
pip show superset
pip show PyMySQL
python -c "import pymysql; print(pymysql.VERSION); pymysql.install_as_MySQLdb(); import MySQLdb; print('Success')"
find /app -name "superset_config.py" -o -name "superset_init.py" 2>/dev/null
echo $PYTHONPATH
cat /app/pythonpath_dev/superset_init.py
cat /app/superset_home/superset_config.py | head -20
ps aux | grep superset
pgrep -f superset
netstat -tlnp | grep :8088
find /app -name "*.log" 2>/dev/null | head -5
pkill -f superset
python -c "
import sys
sys.path.insert(0, '/app/pythonpath_dev')
print('PYTHONPATH:', sys.path[:3])
try:
    import superset_init
    print('superset_init loaded successfully')
except Exception as e:
    print('Error loading superset_init:', e)
"
pgrep -f superset
ps aux | grep superset
pgrep -f superset
python -c "
import os
import subprocess
try:
    result = subprocess.run(['python', '-c', 'import superset'], capture_output=True, text=True)
    print('Superset import result:', result.returncode)
    if result.stderr:
        print('Stderr:', result.stderr)
except Exception as e:
    print('Error:', e)
"
sed -i '2i import pymysql; pymysql.install_as_MySQLdb()' /app/superset_home/superset_config.py
head -5 /app/superset_home/superset_config.py
python -c "
import pymysql
pymysql.install_as_MySQLdb()
from sqlalchemy import create_engine
try:
    engine = create_engine('mysql+pymysql://netflix_user:hotboyche10@mysql:3306/netflix_db')
    connection = engine.connect()
    print('Database connection successful!')
    connection.close()
except Exception as e:
    print('Database connection error:', e)
"
exit
python -c "
import sys
sys.path.insert(0, '/app/superset_home')
sys.path.insert(0, '/app/pythonpath_dev')
import superset_config
import MySQLdb
print('MySQLdb imported successfully via config!')
print('MySQLdb version:', MySQLdb.__version__ if hasattr(MySQLdb, '__version__') else 'No version info')
"
python -c "
import sys
sys.path.insert(0, '/app/superset_home')
import superset_config
try:
    from superset import db
    print('Superset db import successful')
except ImportError as e:
    print('Superset db import error:', e)
except Exception as e:
    print('Other error:', e)
"
exit
ping mysql -c 3
python -c "
import pymysql
try:
    connection = pymysql.connect(
        host='mysql',
        user='netflix_user', 
        password='hotboyche10',
        database='netflix_db'
    )
    print('MySQL connection successful!')
    connection.close()
except Exception as e:
    print('MySQL connection error:', e)
"
exit
sed -i 's/netflix_user:hotboyche10/netflix_user:netflix_password/g' /app/superset_home/superset_config.py
grep "SQLALCHEMY_DATABASE_URI" /app/superset_home/superset_config.py
python -c "
import pymysql
try:
    connection = pymysql.connect(
        host='mysql',
        user='netflix_user',
        password='netflix_password',
        database='netflix_db'
    )
    print('MySQL connection successful!')
    cursor = connection.cursor()
    cursor.execute('SELECT COUNT(*) FROM fact_show')
    result = cursor.fetchone()
    print('fact_show table has', result[0], 'rows')
    connection.close()
except Exception as e:
    print('MySQL connection error:', e)
"
python -c "
import pymysql
pymysql.install_as_MySQLdb()
from sqlalchemy import create_engine, text
try:
    engine = create_engine('mysql+pymysql://netflix_user:netflix_password@mysql:3306/netflix_db')
    with engine.connect() as connection:
        result = connection.execute(text('SELECT COUNT(*) FROM fact_show'))
        count = result.fetchone()[0]
        print('SQLAlchemy connection successful!')
        print('fact_show table has', count, 'rows')
except Exception as e:
    print('SQLAlchemy connection error:', e)
"
cat /app/superset_home/superset_config.py | head -10
exit
curl -I localhost:8088 2>/dev/null | head -1 || echo "Checking status..."
python -c "
import requests
try:
    response = requests.get('http://localhost:8088', timeout=5)
    print('Superset is running! Status code:', response.status_code)
except Exception as e:
    print('Superset check error:', e)
"
exit
python -c "
import sys
sys.path.insert(0, '/app/superset_home')
import superset_config
print('Config loaded successfully')
try:
    import MySQLdb
    print('MySQLdb available:', MySQLdb.__version__)
except Exception as e:
    print('MySQLdb error:', e)
"
echo $SUPERSET_CONFIG_PATH
export SUPERSET_CONFIG_PATH=/app/superset_home/superset_config.py
echo "Set SUPERSET_CONFIG_PATH to: $SUPERSET_CONFIG_PATH"
PYTHONPATH=/app/superset_home:/app/pythonpath_dev python -c "
import superset_config
import MySQLdb
print('MySQLdb working in Python path')
"
# Thêm vào đầu file superset_init.py
echo 'import pymysql; pymysql.install_as_MySQLdb()' > /tmp/import_line
cat /tmp/import_line /app/pythonpath_dev/superset_init.py > /tmp/new_init && mv /tmp/new_init /app/pythonpath_dev/superset_init.py
exit
python -c "
import subprocess
result = subprocess.run(['pgrep', '-f', 'gunicorn'], capture_output=True, text=True)
if result.stdout:
    print('Gunicorn processes:', result.stdout.strip())
else:
    print('No gunicorn processes found')
" 2>/dev/null || echo "pgrep not available"
python -c "
import os
import signal
import subprocess
try:
    result = subprocess.run(['ps', 'aux'], capture_output=True, text=True)
    lines = result.stdout.split('\n')
    for line in lines:
        if 'superset' in line or 'gunicorn' in line:
            print(line)
except:
    print('ps command not available')
"
exit
echo "SUPERSET_CONFIG_PATH: $SUPERSET_CONFIG_PATH"
echo "PYTHONPATH: $PYTHONPATH"
python -c "
import os, sys
print('SUPERSET_CONFIG_PATH:', os.environ.get('SUPERSET_CONFIG_PATH'))  
print('PYTHONPATH:', os.environ.get('PYTHONPATH'))

# Test import sequence
import superset_config  
import MySQLdb
print('MySQLdb version:', MySQLdb.__version__)

# Test Superset import với config
from superset.app import create_app
print('Superset app import successful!')
"
superset run --host=0.0.0.0 --port=8088 --with-threads &
sleep 5
echo "Superset started in background"
python -c "
import socket
for port in [8088, 8080, 3000]:
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    result = sock.connect_ex(('127.0.0.1', port))
    if result == 0:
        print(f'Port {port} is open')
    sock.close()
"
python -c "
from superset.app import create_app
app = create_app()
with app.app_context():
    from superset import db
    print('Database engine:', db.engine.url)
    print('MySQLdb integration successful!')
"
env | grep -i superset
env | grep -i database
env | grep -i sqlalchemy
export SUPERSET_DATABASE_URI="mysql+pymysql://netflix_user:netflix_password@mysql:3306/netflix_db"
echo "SUPERSET_DATABASE_URI: $SUPERSET_DATABASE_URI"
python -c "
from superset.app import create_app
app = create_app()
with app.app_context():
    from superset import db
    print('Database engine:', db.engine.url)
    # Test connection
    connection = db.engine.connect()
    print('MySQL connection successful!')
    connection.close()
"
pkill -f "superset run" 2>/dev/null || echo "No superset process to kill"
superset run --host=0.0.0.0 --port=8088 --with-threads &
sleep 10
echo "Superset restarted with MySQL!"
python -c "
import os
import signal
import subprocess
try:
    # Find và kill superset processes
    result = subprocess.run(['pgrep', '-f', 'superset'], capture_output=True, text=True)
    if result.stdout:
        pids = result.stdout.strip().split('\n')
        for pid in pids:
            if pid:
                os.kill(int(pid), signal.SIGTERM)
                print(f'Killed process {pid}')
except:
    print('Using fallback kill method')
    os.system('pkill -f superset')
    os.system('pkill -f gunicorn')
"
exit
echo "SUPERSET_DATABASE_URI: $SUPERSET_DATABASE_URI"
echo "SUPERSET_CONFIG_PATH: $SUPERSET_CONFIG_PATH"
echo "PYTHONPATH: $PYTHONPATH"
python -c "
import os
from superset.app import create_app
app = create_app()
with app.app_context():
    from superset import db
    print('Database engine:', db.engine.url)
    connection = db.engine.connect()
    print('MySQL connection successful!')
    connection.close()
"
superset run --host=0.0.0.0 --port=8088 --debug
python -c "
import subprocess
import time
try:
    # Kill any process using port 8088
    subprocess.run(['fuser', '-k', '8088/tcp'], stderr=subprocess.DEVNULL)
    print('Killed processes on port 8088')
    time.sleep(2)
except:
    print('fuser not available, trying alternative')
    
# Alternative method
try:
    result = subprocess.run(['lsof', '-ti:8088'], capture_output=True, text=True)
    if result.stdout:
        pids = result.stdout.strip().split()
kill
exit
python -c "
import socket
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
result = sock.connect_ex(('127.0.0.1', 8088))
if result == 0:
    print('Port 8088 still in use')
else:
    print('Port 8088 is free')
sock.close()
"
exit
pkill -f superset || echo "No superset processes"
pkill -f gunicorn || echo "No gunicorn processes" 
pkill -f flask || echo "No flask processes"
# Fix superset_config.py - hardcode MySQL connection
cat > /app/superset_home/superset_config.py << 'EOF'
# superset/superset_config.py
import pymysql; pymysql.install_as_MySQLdb()
import os

# Superset configuration  
SECRET_KEY = 'netflix_superset_secret_2024'

# Force MySQL database - không dùng environment variable
SQLALCHEMY_DATABASE_URI = 'mysql+pymysql://netflix_user:netflix_password@mysql:3306/netflix_db'

# Feature flags
FEATURE_FLAGS = {
    'DASHBOARD_NATIVE_FILTERS': True,
    'DASHBOARD_CROSS_FILTERS': True,
    'DASHBOARD_NATIVE_FILTERS_SET': True,
    'ENABLE_TEMPLATE_PROCESSING': True,
    'DYNAMIC_PLUGINS': True,
}
EOF

echo 'import pymysql; pymysql.install_as_MySQLdb()' > /app/pythonpath_dev/superset_init.py
unset SUPERSET_DATABASE_URI
export SUPERSET_CONFIG_PATH=/app/superset_home/superset_config.py
export PYTHONPATH=/app/superset_home:/app/pythonpath_dev
echo "=== superset_config.py ==="
cat /app/superset_home/superset_config.py
echo -e "\n=== superset_init.py ==="
cat /app/pythonpath_dev/superset_init.py
echo -e "\n=== Environment ==="
echo "SUPERSET_CONFIG_PATH: $SUPERSET_CONFIG_PATH"
echo "PYTHONPATH: $PYTHONPATH"
echo "SUPERSET_DATABASE_URI: $SUPERSET_DATABASE_URI"
python -c "
import sys
sys.path.insert(0, '/app/superset_home')
import superset_config
from superset.app import create_app
app = create_app()
with app.app_context():
    from superset import db
    print('Database engine:', db.engine.url)
    connection = db.engine.connect()
    print('MySQL connection successful!')
    connection.close()
"
superset run --host=0.0.0.0 --port=8088
superset run --host=0.0.0.0 --port=8090
exit
python -c "
try:
    import MySQLdb
    print('MySQLdb available')
except:
    print('MySQLdb not available')

try:
    import pymysql
    print('PyMySQL available')
except:
    print('PyMySQL not available')

try:
    from sqlalchemy.dialects import mysql
    print('SQLAlchemy MySQL dialect available')
except:
    print('SQLAlchemy MySQL dialect not available')
"
python -c "
from superset.db_engine_specs import load_engine_specs
specs = load_engine_specs()
mysql_specs = [spec for spec in specs if 'mysql' in spec.__name__.lower()]
print('MySQL engine specs:', [spec.__name__ for spec in mysql_specs])
"
# Install mysqlclient (native MySQLdb)
pip install mysqlclient
python -c "
import pymysql
pymysql.install_as_MySQLdb()
try:
    import MySQLdb
    print('MySQLdb now available:', MySQLdb.__version__)
except Exception as e:
    print('MySQLdb error:', e)
"
cat >> /app/superset_home/superset_config.py << 'EOF'

# Allow DML operations
PREVENT_UNSAFE_DB_CONNECTIONS = False
SQLLAB_ASYNC_TIME_LIMIT_SEC = 300
SQLLAB_TIMEOUT = 300
EOF

superset run --host=0.0.0.0 --port=8090
pkill -f "superset run"
exit
python /app/force_mysql_import.py
pip install mysqlclient
cat > /app/force_mysql_import.py << 'EOF'
import pymysql
pymysql.install_as_MySQLdb()

try:
    import MySQLdb
    print("MySQLdb successfully installed")
except ImportError as e:
    print(f"MySQLdb import failed: {e}")
EOF

python /app/force_mysql_import.py
echo 'import pymysql
pymysql.install_as_MySQLdb()

try:
    import MySQLdb
    print("MySQLdb successfully installed")
except ImportError as e:
    print(f"MySQLdb import failed: {e}")' > /app/force_mysql_import.py
chmod +x /app/force_mysql_import.py
python /app/force_mysql_import.py
python -c "
import pymysql
pymysql.install_as_MySQLdb()

try:
    import MySQLdb
    print('MySQLdb successfully installed')
    print('MySQLdb version:', MySQLdb.__version__)
except ImportError as e:
    print(f'MySQLdb import failed: {e}')
"
python -c "
import pymysql
pymysql.install_as_MySQLdb()
import MySQLdb
print('MySQLdb version:', MySQLdb.__version__)
"
python -c "
import pymysql
pymysql.install_as_MySQLdb()

try:
    import MySQLdb
    print('MySQLdb successfully installed')
    print('MySQLdb version:', MySQLdb.__version__)
except ImportError as e:
    print(f'MySQLdb import failed: {e}')
"
cat > /app/superset_home/superset_config.py << 'EOF'
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
EOF

cat /app/superset_home/superset_config.py
export SUPERSET_CONFIG_PATH=/app/superset_home/superset_config.py
export PYTHONPATH=/app/superset_home:/app/pythonpath_dev
unset SUPERSET_DATABASE_URI
echo "SUPERSET_CONFIG_PATH: $SUPERSET_CONFIG_PATH"
echo "PYTHONPATH: $PYTHONPATH"
echo "SUPERSET_DATABASE_URI: $SUPERSET_DATABASE_URI"
python -c "
from superset.app import create_app
app = create_app()
with app.app_context():
    from superset import db
    print('Database engine:', db.engine.url)
    connection = db.engine.connect()
    print('Connection successful')
    connection.close()
"
python -c "
import pymysql
pymysql.install_as_MySQLdb()
import MySQLdb
print('Pre-flight MySQLdb check:', MySQLdb.__version__)
" && superset run --host=0.0.0.0 --port=8090
exit
