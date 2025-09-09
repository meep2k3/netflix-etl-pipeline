FROM python:3.12-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    default-libmysqlclient-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements and install Python packages
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy ETL scripts
COPY etl/ ./etl/
COPY data/ ./data/

# Set Python path
ENV PYTHONPATH=/app

# Default command
CMD ["python", "-c", "print('ETL Container Ready')"]