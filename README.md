# Netflix ETL Pipeline with Airflow, MySQL, and Superset

![Airflow](https://img.shields.io/badge/Airflow-2.10-blue)
![MySQL](https://img.shields.io/badge/MySQL-8.0-orange)
![Superset](https://img.shields.io/badge/Apache%20Superset-2.1-brightgreen)
![Docker](https://img.shields.io/badge/Docker-Compose-blue)

## 📌 Introduction
This project implements an **ETL pipeline** to process the **Netflix Movies & TV Shows dataset**.  
The goal is to automate data extraction, transformation, loading into a **star schema** in MySQL, and visualize insights with Superset.  

Key technologies used:
- **Apache Airflow** – Workflow orchestration  
- **MySQL** – Data warehouse  
- **Docker Compose** – Containerized deployment  
- **Apache Superset** – Dashboard & visualization  

---

## ⚙️ System Architecture
- **Airflow** → Orchestrates and manages ETL tasks  
- **MySQL** → Stores processed data in a star schema  
- **Docker** → Ensures reproducible and isolated environments  
- **Superset** → Provides interactive dashboards  

### Pipeline Workflow
1. **Extract** → Load raw CSV (`netflix_titles.csv`) from `data/raw/`  
2. **Transform** → Clean & normalize into a star schema format  
3. **Load** → Insert transformed data into MySQL database  
4. **Visualize** → Explore insights with Superset dashboards  

---

## 🎯 Learning Objectives
This project was built to practice **Data Engineering skills**:
- Building ETL pipelines with Python & SQL  
- Workflow orchestration with Apache Airflow  
- Containerization with Docker Compose  
- Designing star schema data models in MySQL  
- Data visualization with Apache Superset  

---

## 📂 Project Structure
```
netflix-etl-pipeline/
├── docker-compose.yml          # Docker services (Airflow, MySQL, Superset, Redis, Flower)
├── .env                        # Environment variables
├── requirements.txt            # Python dependencies
├── Dockerfile.airflow          # Custom Airflow image
├── Dockerfile.superset         # Custom Superset image
├── airflow/
│   ├── dags/                   # ETL DAGs
│   │   ├── netflix_etl_dag.py
│   │   └── setup_connections.py
│   ├── logs/                   # Airflow logs
│   └── plugins/                # (optional custom operators/hooks)
├── configs/
│   ├── airflow.cfg
│   └── superset/superset_config.py
├── data/
│   ├── raw/
│   │   └── netflix_titles.csv  # Raw dataset
│   └── processed/              # Transformed CSVs for loading
└── dashboards/
    └── netflix_superset.json   # Exported Superset dashboard
```

---

## 🚀 How to Run

1. **Clone the repository**
   ```bash
   git clone https://github.com/<your-username>/netflix-etl-pipeline.git
   cd netflix-etl-pipeline
   ```

2. **Start all services**
   ```bash
   docker compose up -d --build
   ```
   This will start:  
   - Airflow (webserver, scheduler, worker, Redis, Flower, Postgres metadata DB)  
   - MySQL (data warehouse)  
   - Superset (visualization)  

3. **Initialize Airflow**
   ```bash
   docker exec -it airflow-webserver bash
   bash init_airflow.sh
   ```

4. **Initialize Superset**
   ```bash
   docker exec -it superset bash
   bash init_superset.sh
   ```

5. **Access the services**
   - Airflow → [http://localhost:8080](http://localhost:8080)  
   - Superset → [http://localhost:8088](http://localhost:8088)  
   - MySQL →  
     ```bash
     mysql -h localhost -P 3306 -u netflix_user -p
     ```

---

## ✅ Quick Test
1. Open Airflow UI → Trigger DAG `netflix_etl_dag`  
2. Check MySQL → Tables should be loaded into `netflix_db`  
3. Open Superset UI → Explore dashboard  

---

## 📊 Pipeline Diagram
```mermaid
flowchart LR
    A[Raw CSV: netflix_titles.csv] -->|Extract| B[Airflow DAG]
    B -->|Transform| C[Processed CSVs]
    C -->|Load| D[MySQL Database: Star Schema]
    D -->|Query| E[Superset Dashboard]
```

---

## 📊 Dashboards Preview
- **Content Growth Over Time**  
  ![Growth](dashbroads/content-growth-over-time-2025-09-07T17-29-34.974Z.jpg)

- **Distribution by Type**  
  ![Type](dashbroads/content-distribution-by-type-2025-09-07T17-29-44.282Z.jpg)

- **Top 15 Countries**  
  ![Countries](dashbroads/top-15-countries-by-content-volume-2025-09-07T17-29-53.079Z.jpg)

- **Ratings Distribution**  
  ![Ratings](dashbroads/content-ratings-distribution-2025-09-07T17-30-00.744Z.jpg)

- **Top Genres**  
  ![Genres](dashbroads/top-genres-performance-2025-09-07T17-30-06.903Z.jpg)

- **Duration & Seasons**  
  ![Duration](dashbroads/content-duration-and-season-analysis-2025-09-07T17-30-13.328Z.jpg)

- **Full Dashboard**  
  ![Dashboard](dashbroads/netflix-analytics-dashboard-2025-09-07T17-30-26.572Z.jpg)

---

## 🔮 Future Improvements
- Support **incremental load** instead of full refresh  
- Add **data quality checks** with Great Expectations  
- Build a **recommendation engine**  
- Enable **Superset authentication** (OAuth/LDAP)  

---

## 📚 Dataset
- Source: [Netflix Movies & TV Shows](https://www.kaggle.com/shivamb/netflix-shows)  

---

## 👨‍💻 Author
- [meep2k3](https://github.com/meep2k3)

## 📜 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
