--View dataset

SELECT * 
FROM netflix_data;


-- 1. Looking for duplicates, using show_id (unique value for each row)
SELECT show_id, COUNT(*) as duplicate_count
FROM netflix_data
GROUP BY show_id
HAVING COUNT(*) > 1;
 -- No duplicates found
 
-- 2. Identifying any NULL values in all columns

SELECT COUNT(*) FILTER (WHERE show_id IS NULL) AS showid_nulls,
       COUNT(*) FILTER (WHERE type IS NULL) AS type_nulls,
       COUNT(*) FILTER (WHERE title IS NULL) AS title_nulls,
       COUNT(*) FILTER (WHERE director IS NULL) AS director_nulls,
	   COUNT(*) FILTER (WHERE starring IS NULL) AS starring_nulls,
       COUNT(*) FILTER (WHERE country IS NULL) AS country_nulls,
       COUNT(*) FILTER (WHERE date_added IS NULL) AS date_added_nulls,
       COUNT(*) FILTER (WHERE release_year IS NULL) AS release_year_nulls,
       COUNT(*) FILTER (WHERE rating IS NULL) AS rating_nulls,
       COUNT(*) FILTER (WHERE duration IS NULL) AS duration_nulls,
       COUNT(*) FILTER (WHERE listed_in IS NULL) AS listed_in_nulls
FROM netflix_data;

-- director_nulls: 1969
-- starring_nulls: 570
-- country_nulls: 476
-- date_added_nulls: 11
-- rating_nulls: 10

-- 3. Fill nulls with 'Not Available' using a CTE

WITH FilledNetflixData AS (
    SELECT
		show_id,
        title,
        COALESCE(director, 'Not Available') AS director,
        COALESCE(starring, 'Not Available') AS starring,
        COALESCE(country, 'Not Available') AS country,
        COALESCE(date_added, 'Not Available') AS date_added,
        COALESCE(rating, 'Not Available') AS rating
    FROM
        netflix_data
)
 
 -- Updating original table
UPDATE netflix_data AS nd
SET
    director = fnd.director,
    starring = fnd.starring,
    country = fnd.country,
    date_added = fnd.date_added,
    rating = fnd.rating
FROM FilledNetflixData AS fnd
WHERE nd.show_id = fnd.show_id;


-- 4. Changing Date Format 

UPDATE netflix_data
SET date_added = TO_CHAR(TO_DATE(date_added, 'Month DD, YYYY'), 'DD/MM/YYYY')
WHERE date_added IS NOT NULL AND date_added <> 'Not Available';

SELECT date_added 
FROM netflix_data;


-- 5. Drop unused columns

ALTER TABLE netflix_data
DROP COLUMN starring,
DROP COLUMN description;


-- 6. Breaking up Genres column (listed_in) into separate columns (1 genre per column)

SELECT
    SPLIT_PART(listed_in, ',', 1) AS genre,
    CASE WHEN LENGTH(listed_in) - LENGTH(REPLACE(listed_in, ',', '')) >= 1
         THEN NULLIF(SPLIT_PART(listed_in, ',', 2), '')
         ELSE NULL
    END AS genre2,
    CASE WHEN LENGTH(listed_in) - LENGTH(REPLACE(listed_in, ',', '')) >= 2
         THEN NULLIF(SPLIT_PART(listed_in, ',', 3), '')
         ELSE NULL
    END AS genre3,
    CASE WHEN LENGTH(listed_in) - LENGTH(REPLACE(listed_in, ',', '')) >= 3
         THEN NULLIF(SPLIT_PART(listed_in, ',', 4), '')
         ELSE NULL
    END AS genre4
FROM netflix_data;

-- Updating table to include new columns

ALTER TABLE netflix_data
ADD COLUMN genre VARCHAR(255),
ADD COLUMN genre2 VARCHAR(255);

-- Only adding the first 2 genres from the data (will likely only use the first value
-- but might be useful for further exploration). 
UPDATE netflix_data
SET genre = SPLIT_PART(listed_in, ',', 1),
	genre2 = CASE WHEN LENGTH(listed_in) - LENGTH(REPLACE(listed_in, ',', '')) >= 1
         THEN NULLIF(SPLIT_PART(listed_in, ',', 2), '')
         ELSE NULL
    END;
	

-- 7. Breaking up Country column into separate columns

SELECT
    SPLIT_PART(country, ',', 1) AS country1,
    CASE WHEN LENGTH(country) - LENGTH(REPLACE(country, ',', '')) >= 1
         THEN NULLIF(SPLIT_PART(country, ',', 2), '')
         ELSE NULL
    END AS country2,
    CASE WHEN LENGTH(country) - LENGTH(REPLACE(country, ',', '')) >= 2
         THEN NULLIF(SPLIT_PART(country, ',', 3), '')
         ELSE NULL
    END AS country3,
    CASE WHEN LENGTH(country) - LENGTH(REPLACE(country, ',', '')) >= 3
         THEN NULLIF(SPLIT_PART(country, ',', 4), '')
         ELSE NULL
    END AS country4
FROM netflix_data;


ALTER TABLE netflix_data
ADD COLUMN or_country VARCHAR(255);

-- Only keeping the first country (most entries only have one)
UPDATE netflix_data
SET or_country = SPLIT_PART(country, ',', 1)


ALTER TABLE netflix_data
DROP COLUMN country,
DROP COLUMN country_1,
DROP COLUMN country1;


ALTER TABLE netflix_data
RENAME COLUMN or_country TO country

-- 8. Looking for most common genre for TV & Movies by country

 -- Genre distribution by country 
SELECT 	country, genre, COUNT(*) as genre_count
FROM netflix_data
WHERE type = 'Movie'
GROUP BY country, genre
ORDER BY country, genre_count DESC;

 -- Only looking at most common movie genres for each country. 
WITH GenreCounts AS (
    SELECT country, genre, COUNT(*) AS genre_count,
           ROW_NUMBER() OVER (PARTITION BY country ORDER BY COUNT(*) DESC) AS rn
    FROM netflix_data
    WHERE type = 'Movie'
    GROUP BY country, genre
)
SELECT country, genre, genre_count
FROM GenreCounts
WHERE rn = 1
ORDER BY country, genre_count DESC;


-- Only looking at most common TV show genres for each country
WITH GenreCounts AS (
    SELECT country, genre, COUNT(*) AS genre_count,
           ROW_NUMBER() OVER (PARTITION BY country ORDER BY COUNT(*) DESC) AS rn
    FROM netflix_data
    WHERE type = 'TV Show'
    GROUP BY country, genre
)
SELECT country, genre, genre_count
FROM GenreCounts
WHERE rn = 1
ORDER BY country, genre_count DESC;



-- 9. Looking into distribution of movie genres by year

SELECT 	release_year, genre, COUNT(*) as genre_count
FROM netflix_data
WHERE type = 'Movie'
GROUP BY release_year, genre
ORDER BY release_year, genre_count DESC;

-- Creating decades groups to explore movie genre distribution by decade rather than years. 

WITH MovieDecades AS (
	SELECT 
		CASE
			WHEN release_year BETWEEN 1940 AND 1949 THEN 1940
			WHEN release_year BETWEEN 1950 AND 1959 THEN 1950
			WHEN release_year BETWEEN 1960 AND 1969 THEN 1960
			WHEN release_year BETWEEN 1970 AND 1979 THEN 1970
			WHEN release_year BETWEEN 1980 AND 1989 THEN 1980
			WHEN release_year BETWEEN 1990 AND 1999 THEN 1990
			WHEN release_year BETWEEN 2000 AND 2009 THEN 2000
			WHEN release_year BETWEEN 2010 AND 2019 THEN 2010	
			WHEN release_year BETWEEN 2020 AND 2023 THEN 2020
			ELSE 0
		END AS decade, 
		genre
	FROM netflix_data
	WHERE type = 'Movie'
)

SELECT decade, genre, COUNT (*) AS genre_count
FROM MovieDecades
GROUP BY decade, genre
ORDER BY decade, genre_count ASC;
			

-- 10. Looking into the most common TV Show genre for each decade. 

WITH TVShowDecades AS (
	SELECT 
		CASE
			WHEN release_year BETWEEN 1920 AND 1929 THEN 1920
			WHEN release_year BETWEEN 1940 AND 1949 THEN 1940
			WHEN release_year BETWEEN 1950 AND 1959 THEN 1950
			WHEN release_year BETWEEN 1960 AND 1969 THEN 1960
			WHEN release_year BETWEEN 1970 AND 1979 THEN 1970
			WHEN release_year BETWEEN 1980 AND 1989 THEN 1980
			WHEN release_year BETWEEN 1990 AND 1999 THEN 1990
			WHEN release_year BETWEEN 2000 AND 2009 THEN 2000
			WHEN release_year BETWEEN 2010 AND 2019 THEN 2010	
			WHEN release_year BETWEEN 2020 AND 2023 THEN 2020
			ELSE 0
		END AS decade, 		
		genre
	FROM netflix_data
	WHERE type = 'TV Show'
)

SELECT decade, genre, COUNT (*) AS genre_count
FROM TVShowDecades
GROUP BY decade, genre
HAVING COUNT (*) = (
	SELECT MAX (sub.genre_count)
	FROM (
		SELECT decade, genre, COUNT(*) AS genre_count
		FROM TVShowDecades
		GROUP BY decade, genre
	) AS sub
	WHERE sub.decade = TVShowDecades.decade
)
ORDER BY decade DESC;




