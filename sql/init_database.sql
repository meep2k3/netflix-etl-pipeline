-- sql/init_database.sql
-- Khởi tạo database schema cho Netflix ETL Pipeline

USE netflix_db;

-- ========================
-- FACT TABLE
-- ========================
CREATE TABLE IF NOT EXISTS fact_show (
    show_id INT AUTO_INCREMENT PRIMARY KEY,
    show_type VARCHAR(50),
    title VARCHAR(255) NOT NULL,
    show_description TEXT,
    release_year INT,
    date_added DATE,
    rating VARCHAR(50),
    duration_value INT,
    duration_unit VARCHAR(50),
    INDEX idx_title_year (title, release_year),
    INDEX idx_release_year (release_year),
    INDEX idx_show_type (show_type),
    INDEX idx_rating (rating)
);

-- ========================
-- DIMENSION TABLES
-- ========================

CREATE TABLE IF NOT EXISTS dim_director (
    director_id INT AUTO_INCREMENT PRIMARY KEY,
    director_name VARCHAR(255) NOT NULL,
    UNIQUE KEY uq_director_name (director_name)
);

CREATE TABLE IF NOT EXISTS dim_cast (
    cast_id INT AUTO_INCREMENT PRIMARY KEY,
    cast_name VARCHAR(255) NOT NULL,
    UNIQUE KEY uq_cast_name (cast_name)
);

CREATE TABLE IF NOT EXISTS dim_genre (
    genre_id INT AUTO_INCREMENT PRIMARY KEY,
    genre_name VARCHAR(255) NOT NULL,
    UNIQUE KEY uq_genre_name (genre_name)
);

CREATE TABLE IF NOT EXISTS dim_country (
    country_id INT AUTO_INCREMENT PRIMARY KEY,
    country_name VARCHAR(255) NOT NULL,
    UNIQUE KEY uq_country_name (country_name)
);

-- ========================
-- BRIDGE TABLES
-- ========================

CREATE TABLE IF NOT EXISTS bridge_show_director (
    show_id INT NOT NULL,
    director_id INT NOT NULL,
    PRIMARY KEY (show_id, director_id),
    FOREIGN KEY (show_id) REFERENCES fact_show(show_id) ON DELETE CASCADE,
    FOREIGN KEY (director_id) REFERENCES dim_director(director_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS bridge_show_cast (
    show_id INT NOT NULL,
    cast_id INT NOT NULL,
    PRIMARY KEY (show_id, cast_id),
    FOREIGN KEY (show_id) REFERENCES fact_show(show_id) ON DELETE CASCADE,
    FOREIGN KEY (cast_id) REFERENCES dim_cast(cast_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS bridge_show_genre (
    show_id INT NOT NULL,
    genre_id INT NOT NULL,
    PRIMARY KEY (show_id, genre_id),
    FOREIGN KEY (show_id) REFERENCES fact_show(show_id) ON DELETE CASCADE,
    FOREIGN KEY (genre_id) REFERENCES dim_genre(genre_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS bridge_show_country (
    show_id INT NOT NULL,
    country_id INT NOT NULL,
    PRIMARY KEY (show_id, country_id),
    FOREIGN KEY (show_id) REFERENCES fact_show(show_id) ON DELETE CASCADE,
    FOREIGN KEY (country_id) REFERENCES dim_country(country_id) ON DELETE CASCADE
);

-- ========================
-- CREATE VIEWS FOR ANALYSIS
-- ========================

-- View: Shows with all dimensions
CREATE OR REPLACE VIEW vw_netflix_complete AS
SELECT 
    f.show_id,
    f.title,
    f.show_type,
    f.release_year,
    f.date_added,
    f.rating,
    f.duration_value,
    f.duration_unit,
    GROUP_CONCAT(DISTINCT d.director_name ORDER BY d.director_name SEPARATOR ', ') as directors,
    GROUP_CONCAT(DISTINCT c.cast_name ORDER BY c.cast_name SEPARATOR ', ') as cast_members,
    GROUP_CONCAT(DISTINCT g.genre_name ORDER BY g.genre_name SEPARATOR ', ') as genres,
    GROUP_CONCAT(DISTINCT co.country_name ORDER BY co.country_name SEPARATOR ', ') as countries
FROM fact_show f
LEFT JOIN bridge_show_director bd ON f.show_id = bd.show_id
LEFT JOIN dim_director d ON bd.director_id = d.director_id
LEFT JOIN bridge_show_cast bc ON f.show_id = bc.show_id
LEFT JOIN dim_cast c ON bc.cast_id = c.cast_id
LEFT JOIN bridge_show_genre bg ON f.show_id = bg.show_id
LEFT JOIN dim_genre g ON bg.genre_id = g.genre_id
LEFT JOIN bridge_show_country bco ON f.show_id = bco.show_id
LEFT JOIN dim_country co ON bco.country_id = co.country_id
GROUP BY f.show_id, f.title, f.show_type, f.release_year, f.date_added, f.rating, f.duration_value, f.duration_unit;

-- View: Content statistics by year
CREATE OR REPLACE VIEW vw_content_by_year AS
SELECT 
    release_year,
    COUNT(*) as total_content,
    SUM(CASE WHEN show_type = 'Movie' THEN 1 ELSE 0 END) as movies,
    SUM(CASE WHEN show_type = 'TV Show' THEN 1 ELSE 0 END) as tv_shows
FROM fact_show
WHERE release_year IS NOT NULL
GROUP BY release_year
ORDER BY release_year DESC;

-- View: Top genres
CREATE OR REPLACE VIEW vw_top_genres AS
SELECT 
    g.genre_name,
    COUNT(*) as content_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fact_show), 2) as percentage
FROM dim_genre g
JOIN bridge_show_genre bg ON g.genre_id = bg.genre_id
JOIN fact_show f ON bg.show_id = f.show_id
GROUP BY g.genre_id, g.genre_name
ORDER BY content_count DESC;

-- View: Top countries
CREATE OR REPLACE VIEW vw_top_countries AS
SELECT 
    co.country_name,
    COUNT(*) as content_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fact_show), 2) as percentage
FROM dim_country co
JOIN bridge_show_country bco ON co.country_id = bco.country_id
JOIN fact_show f ON bco.show_id = f.show_id
GROUP BY co.country_id, co.country_name
ORDER BY content_count DESC;

-- Tạo user cho các services
CREATE USER IF NOT EXISTS 'netflix_user'@'%' IDENTIFIED BY 'netflix_password';
GRANT ALL PRIVILEGES ON netflix_db.* TO 'netflix_user'@'%';
FLUSH PRIVILEGES;

-- Insert sample data check
INSERT INTO dim_director (director_name) VALUES ('System Test') ON DUPLICATE KEY UPDATE director_name = director_name;
INSERT INTO dim_cast (cast_name) VALUES ('System Test') ON DUPLICATE KEY UPDATE cast_name = cast_name;
INSERT INTO dim_genre (genre_name) VALUES ('System Test') ON DUPLICATE KEY UPDATE genre_name = genre_name;
INSERT INTO dim_country (country_name) VALUES ('System Test') ON DUPLICATE KEY UPDATE country_name = country_name;

SELECT 'Netflix Database initialized successfully!' as status;