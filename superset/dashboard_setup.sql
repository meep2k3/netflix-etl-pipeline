-- superset/dashboard_setup.sql
-- Sample queries for Superset dashboards

-- Query 1: Content Distribution by Type
SELECT 
    show_type,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fact_show), 2) as percentage
FROM fact_show
GROUP BY show_type;

-- Query 2: Content by Release Year
SELECT 
    release_year,
    COUNT(*) as total_content,
    SUM(CASE WHEN show_type = 'Movie' THEN 1 ELSE 0 END) as movies,
    SUM(CASE WHEN show_type = 'TV Show' THEN 1 ELSE 0 END) as tv_shows
FROM fact_show
WHERE release_year >= 2000
GROUP BY release_year
ORDER BY release_year;

-- Query 3: Top 15 Genres
SELECT 
    g.genre_name,
    COUNT(*) as content_count
FROM dim_genre g
JOIN bridge_show_genre bg ON g.genre_id = bg.genre_id
JOIN fact_show f ON bg.show_id = f.show_id
GROUP BY g.genre_id, g.genre_name
ORDER BY content_count DESC
LIMIT 15;

-- Query 4: Top 10 Countries by Content
SELECT 
    co.country_name,
    COUNT(*) as content_count
FROM dim_country co
JOIN bridge_show_country bco ON co.country_id = bco.country_id
JOIN fact_show f ON bco.show_id = f.show_id
WHERE co.country_name != 'Unknown'
GROUP BY co.country_id, co.country_name
ORDER BY content_count DESC
LIMIT 10;

-- Query 5: Content Added Over Time
SELECT 
    DATE_FORMAT(date_added, '%Y-%m') as month_year,
    COUNT(*) as content_added,
    show_type
FROM fact_show
WHERE date_added IS NOT NULL
  AND date_added >= '2015-01-01'
GROUP BY DATE_FORMAT(date_added, '%Y-%m'), show_type
ORDER BY month_year;

-- Query 6: Average Movie Duration by Rating
SELECT 
    rating,
    AVG(duration_value) as avg_duration,
    COUNT(*) as count
FROM fact_show
WHERE show_type = 'Movie' 
  AND duration_unit = 'min'
  AND rating != 'Unknown'
GROUP BY rating
ORDER BY avg_duration DESC;

-- Query 7: Top Directors by Number of Titles
SELECT 
    d.director_name,
    COUNT(*) as titles_count,
    GROUP_CONCAT(DISTINCT f.show_type) as content_types
FROM dim_director d
JOIN bridge_show_director bd ON d.director_id = bd.director_id
JOIN fact_show f ON bd.show_id = f.show_id
WHERE d.director_name != 'Unknown'
GROUP BY d.director_id, d.director_name
HAVING titles_count >= 3
ORDER BY titles_count DESC
LIMIT 20;

-- Query 8: Content Rating Distribution
SELECT 
    rating,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fact_show WHERE rating != 'Unknown'), 2) as percentage
FROM fact_show
WHERE rating != 'Unknown'
GROUP BY rating
ORDER BY count DESC;