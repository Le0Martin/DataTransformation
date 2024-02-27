-- Table creation
CREATE TABLE marketing_campaign (
    id SERIAL,
    campaign_name VARCHAR(255),
    start_date DATE,
    end_date DATE,
    budget DECIMAL(10, 2),
    target_audience VARCHAR(255),
    advertising_channels VARCHAR(255), 
    campaign_type VARCHAR(255), 
    conversion_rate DECIMAL(5, 2),
    impressions BIGINT
);


-- Stored Procedure for data loading
CREATE OR REPLACE PROCEDURE insert_campaign_data()
LANGUAGE plpgsql
AS $$
DECLARE
    i INT := 1;
    random_target INT;
    random_conversion_rate DECIMAL(5, 2);
    random_impressions BIGINT;
    random_budget DECIMAL(10, 2);
    random_channel VARCHAR(255);
    random_campaign_type VARCHAR(255);
    random_start_date DATE;
    random_end_date DATE;
    random_public_target VARCHAR(255);
BEGIN
    LOOP
        EXIT WHEN i > 1000;
        
        -- Generate random values
        random_target := 1 + (i % 5);
        random_conversion_rate := ROUND((RANDOM() * 30)::numeric, 2);
        random_impressions := (1 + FLOOR(RANDOM() * 10)) * 1000000;

        -- Conditional values
        random_budget := CASE WHEN RANDOM() < 0.8 THEN ROUND((RANDOM() * 100000)::numeric, 2) ELSE NULL END;

        -- Advertising channels
        random_channel := CASE
            WHEN RANDOM() < 0.8 THEN
                CASE FLOOR(RANDOM() * 3)
                    WHEN 0 THEN 'Google'
                    WHEN 1 THEN 'Social Media'
                    ELSE 'News Websites'
                END
            ELSE NULL
        END;

        -- Campaign type
        random_campaign_type := CASE
            WHEN RANDOM() < 0.8 THEN
                CASE FLOOR(RANDOM() * 3)
                    WHEN 0 THEN 'Promotional'
                    WHEN 1 THEN 'Marketing'
                    ELSE 'Follower Growth'
                END
            ELSE NULL
        END;

        -- Set random dates from the last 4 years
        random_start_date := CURRENT_DATE - (1 + FLOOR(RANDOM() * 1460)) * INTERVAL '1 day';
        random_end_date := random_start_date + (1 + FLOOR(RANDOM() * 30)) * INTERVAL '1 day';

        -- Random target audience with possibility of "?"
        random_public_target := CASE WHEN RANDOM() < 0.2 THEN '?' ELSE 'Target Audience ' || random_target END;

        -- Insert record
        INSERT INTO marketing_campaign 
        (campaign_name, start_date, end_date, budget, target_audience, advertising_channels, campaign_type, conversion_rate, impressions)
        VALUES 
        ('Campaign ' || i, random_start_date, random_end_date, random_budget, random_public_target, random_channel, random_campaign_type, random_conversion_rate, random_impressions);

        i := i + 1;
    END LOOP;
END;
$$;

-- Execute the stored procedure
CALL insert_campaign_data();

-- Check the data
SELECT * FROM marketing_campaign;




-----------------------------------------------------------------------------------------------------------------
-- Checking ERRORS
-----------------------------------------------------------------------------------------------------------------

-- Identifying the total missing values in all columns.
SELECT
    COUNT(*) - COUNT(id) AS id_missing,
    COUNT(*) - COUNT(campaign_name) AS campaign_name_missing,
    COUNT(*) - COUNT(start_date) AS start_date_missing,
    COUNT(*) - COUNT(end_date) AS end_date_missing,
    COUNT(*) - COUNT(budget) AS budget_missing,
    COUNT(*) - COUNT(target_audience) AS target_audience_missing,
    COUNT(*) - COUNT(advertising_channels) AS advertising_channels_missing,
    COUNT(*) - COUNT(campaign_type) AS campaign_type_missing,
    COUNT(*) - COUNT(conversion_rate) AS conversion_rate_missing,
    COUNT(*) - COUNT(impressions) AS impressions_missing
FROM 
    marketing_campaign;
    
    
-- Identifying if there is any "?" character in any column.
SELECT *
FROM marketing_campaign
WHERE 
    campaign_name LIKE '%?%' OR
    CAST(start_date AS VARCHAR) LIKE '%?%' OR
    CAST(end_date AS VARCHAR) LIKE '%?%' OR
    CAST(budget AS VARCHAR) LIKE '%?%' OR
    target_audience LIKE '%?%' OR
    advertising_channels LIKE '%?%' OR
    campaign_type LIKE '%?%' OR
    CAST(conversion_rate AS VARCHAR) LIKE '%?%' OR
    CAST(impressions AS VARCHAR) LIKE '%?%';
    
    
-- Identifying duplicates (excluding the id column).
SELECT 
    campaign_name,
    start_date,
    end_date,
    budget,
    target_audience,
    advertising_channels,
    campaign_type,
    conversion_rate,
    impressions,
    COUNT(*) as duplicates
FROM 
    marketing_campaign
GROUP BY 
    campaign_name,
    start_date,
    end_date,
    budget,
    target_audience,
    advertising_channels,
    campaign_type,
    conversion_rate,
    impressions
HAVING 
    COUNT(*) > 1;
        

-- Identifying outliers in the 3 numeric columns using the following rules:
-- mean + 1.5 * standard_deviation
-- mean - 1.5 * standard_deviation
WITH stats AS (
    SELECT
        AVG(budget) AS avg_budget,
        STDDEV(budget) AS stddev_budget,
        AVG(conversion_rate) AS avg_conversion_rate,
        STDDEV(conversion_rate) AS stddev_conversion_rate,
        AVG(impressions) AS avg_impressions,
        STDDEV(impressions) AS stddev_impressions
    FROM
        marketing_campaign
)
SELECT
    id,
    campaign_name,
    start_date,
    end_date,
    budget,
    target_audience,
    advertising_channels,
    conversion_rate,
    impressions
FROM
    marketing_campaign,
    stats
WHERE
    budget < (avg_budget - 1.5 * stddev_budget) OR 
    budget > (avg_budget + 1.5 * stddev_budget) OR
    conversion_rate < (avg_conversion_rate - 1.5 * stddev_conversion_rate) OR 
    conversion_rate > (avg_conversion_rate + 1.5 * stddev_conversion_rate) OR
    impressions < (avg_impressions - 1.5 * stddev_impressions) OR 
    impressions > (avg_impressions + 1.5 * stddev_impressions);




-----------------------------------------------------------------------------------------------------------------
-- Checking the data and fixing the values
-----------------------------------------------------------------------------------------------------------------

-- Replacing the "?" character in the target_audience column with the value "Others".
SELECT DISTINCT target_audience
FROM marketing_campaign;

UPDATE marketing_campaign
SET target_audience = 'Others'
WHERE target_audience = '?';


-- Identifying the total number of records for each value in the advertising_channels column and
-- Updating the missing values with the mode of the advertising_channels column.
SELECT advertising_channels, COUNT(*) as total_records
FROM marketing_campaign
GROUP BY advertising_channels;

SELECT advertising_channels
FROM marketing_campaign
WHERE advertising_channels IS NOT NULL
GROUP BY advertising_channels
ORDER BY COUNT(*) DESC
LIMIT 1;

UPDATE marketing_campaign
SET advertising_channels = 'Social Media'
WHERE advertising_channels IS NULL;


-- Identifying the total number of records for each value in the campaign_type column.
SELECT campaign_type, COUNT(*) as total_records
FROM marketing_campaign
GROUP BY campaign_type;


-- Assuming that missing values in the campaign_type column are data collection errors.
-- Creating a Query that removes records where campaign_type has a null value.
DELETE FROM marketing_campaign
WHERE campaign_type IS NULL;


-- Identifying missing values in the budget column
SELECT *
FROM marketing_campaign
WHERE budget IS NULL;

-- Considering that a null budget for a target audience of "Others" is not relevant information.
-- Removing records if the budget column has a missing value and the target_audience column has the value "Others".

DELETE FROM marketing_campaign
WHERE budget IS NULL AND target_audience = 'Others';

SELECT *
FROM marketing_campaign
WHERE budget IS NULL;


-- Filling in missing values in the budget column with the average of the column,
-- but segmented by the advertising_channels column.
SELECT advertising_channels, AVG(budget) as avg_budget
FROM marketing_campaign
WHERE budget IS NOT NULL
GROUP BY advertising_channels;

UPDATE marketing_campaign AS c
SET budget = d.avg_budget
FROM (
    SELECT advertising_channels, AVG(budget) AS avg_budget
    FROM marketing_campaign
    WHERE budget IS NOT NULL
    GROUP BY advertising_channels
) AS d
WHERE c.advertising_channels = d.advertising_channels AND c.budget IS NULL;


-- Checking for missing values:
SELECT
    COUNT(*) - COUNT(id) AS id_missing,
    COUNT(*) - COUNT(campaign_name) AS campaign_name_missing,
    COUNT(*) - COUNT(start_date) AS start_date_missing,
    COUNT(*) - COUNT(end_date) AS end_date_missing,
    COUNT(*) - COUNT(budget) AS budget_missing,
    COUNT(*) - COUNT(target_audience) AS target_audience_missing,
    COUNT(*) - COUNT(advertising_channels) AS advertising_channels_missing,
    COUNT(*) - COUNT(campaign_type) AS campaign_type_missing,
    COUNT(*) - COUNT(conversion_rate) AS conversion_rate_missing,
    COUNT(*) - COUNT(impressions) AS impressions_missing
FROM 
    marketing_campaign;


-- Using an outlier treatment strategy to create a new column and fill it with True
-- if there is an outlier in the record and False otherwise.
ALTER TABLE marketing_campaign
ADD COLUMN has_outlier BOOLEAN DEFAULT FALSE;

-- Load the new column
WITH stats AS (
    SELECT
        AVG(budget) AS avg_budget,
        STDDEV(budget) AS stddev_budget,
        AVG(conversion_rate) AS avg_conversion_rate,
        STDDEV(conversion_rate) AS stddev_conversion_rate,
        AVG(impressions) AS avg_impressions,
        STDDEV(impressions) AS stddev_impressions
    FROM
        marketing_campaign
)
UPDATE marketing_campaign
SET has_outlier = TRUE
FROM stats
WHERE
    budget < (avg_budget - 1.5 * stddev_budget) OR 
    budget > (avg_budget + 1.5 * stddev_budget) OR
    conversion_rate < (avg_conversion_rate - 1.5 * stddev_conversion_rate) OR 
    conversion_rate > (avg_conversion_rate + 1.5 * stddev_conversion_rate) OR
    impressions < (avg_impressions - 1.5 * stddev_impressions) OR 
    impressions > (avg_impressions + 1.5 * stddev_impressions);

SELECT has_outlier, COUNT(*) AS count
FROM marketing_campaign
GROUP BY has_outlier;


-- Applying label encoding to the target_audience column and save the result in a new column
ALTER TABLE marketing_campaign
ADD COLUMN target_audience_encoded INT;

SELECT DISTINCT target_audience
FROM marketing_campaign;

-- Load the new column
UPDATE marketing_campaign
SET target_audience_encoded = 
    CASE target_audience
        WHEN 'Target Audience 1' THEN 1
        WHEN 'Target Audience 2' THEN 2
        WHEN 'Target Audience 3' THEN 3
        WHEN 'Target Audience 4' THEN 4
        WHEN 'Target Audience 5' THEN 5
        WHEN 'Others' THEN 0
        ELSE NULL
    END;


-- Applying label encoding to the advertising_channels column and save the result in a new column
ALTER TABLE marketing_campaign
ADD COLUMN advertising_channels_encoded INT;

SELECT advertising_channels, COUNT(*) as total_records
FROM marketing_campaign
GROUP BY advertising_channels;

-- Load the new column
UPDATE marketing_campaign
SET advertising_channels_encoded = 
    CASE advertising_channels
        WHEN 'Google' THEN 1
        WHEN 'Social Media' THEN 2
        WHEN 'News Websites' THEN 3
        ELSE NULL
    END;


-- Applying label encoding to the campaign_type column and save the result in a new column 
ALTER TABLE marketing_campaign
ADD COLUMN campaign_type_encoded INT;

SELECT campaign_type, COUNT(*) as total_records
FROM marketing_campaign
GROUP BY campaign_type;

-- Load the new column
UPDATE marketing_campaign
SET campaign_type_encoded = 
    CASE campaign_type
        WHEN 'Promotional' THEN 1
        WHEN 'Marketing' THEN 2
        WHEN 'Follower Growth' THEN 3
        ELSE NULL
    END;

SELECT * FROM marketing_campaign;


-- Droping the 3 original Columns
ALTER TABLE marketing_campaign
DROP COLUMN target_audience,
DROP COLUMN advertising_channels,
DROP COLUMN campaign_type;





-----------------------------------------------------------------------------------------------------------------
-- Summary Report with Quantitative Variables
-- Totals for the years 2022, 2023, and 2024 for the columns budget, conversion_rate, and impressions
-----------------------------------------------------------------------------------------------------------------
SELECT
    TO_CHAR(start_date, 'YYYY') AS year,
    SUM(budget) AS total_budget,
    SUM(conversion_rate) AS total_conversion_rate,
    SUM(impressions) AS total_impressions
FROM
    marketing_campaign
WHERE 
    EXTRACT(YEAR FROM start_date) IN (2022, 2023, 2024)
GROUP BY
    TO_CHAR(start_date, 'YYYY')
ORDER BY 
    TO_CHAR(start_date, 'YYYY') DESC;


-- Summary Report with Quantitative Variables and Pivot Table
SELECT
    'Total' as Total,
    SUM(CASE WHEN EXTRACT(YEAR FROM start_date) = 2022 THEN budget ELSE 0 END) AS "Budget_2022",
    SUM(CASE WHEN EXTRACT(YEAR FROM start_date) = 2022 THEN conversion_rate ELSE 0 END) AS "Conversion_Rate_2022",
    SUM(CASE WHEN EXTRACT(YEAR FROM start_date) = 2022 THEN impressions ELSE 0 END) AS "Impressions_2022",
    SUM(CASE WHEN EXTRACT(YEAR FROM start_date) = 2023 THEN budget ELSE 0 END) AS "Budget_2023",
    SUM(CASE WHEN EXTRACT(YEAR FROM start_date) = 2023 THEN conversion_rate ELSE 0 END) AS "Conversion_Rate_2023",
    SUM(CASE WHEN EXTRACT(YEAR FROM start_date) = 2023 THEN impressions ELSE 0 END) AS "Impressions_2023",
    SUM(CASE WHEN EXTRACT(YEAR FROM start_date) = 2024 THEN budget ELSE 0 END) AS "Budget_2024",
    SUM(CASE WHEN EXTRACT(YEAR FROM start_date) = 2024 THEN conversion_rate ELSE 0 END) AS "Conversion_Rate_2024",
    SUM(CASE WHEN EXTRACT(YEAR FROM start_date) = 2024 THEN impressions ELSE 0 END) AS "Impressions_2024"
FROM
    marketing_campaign;


-- Data Normalization with SQL using Min-Max normalization 
WITH min_max AS (
    SELECT
        MIN(budget) as min_budget,
        MAX(budget) as max_budget,
        MIN(conversion_rate) as min_conversion_rate,
        MAX(conversion_rate) as max_conversion_rate
    FROM
        marketing_campaign
)
SELECT
    id,
    campaign_name,
    start_date,
    end_date,
    ROUND((budget - min_budget) / (max_budget - min_budget),5) as normalized_budget,
    ROUND((conversion_rate - min_conversion_rate) / (max_conversion_rate - min_conversion_rate),5) as normalized_conversion_rate
FROM
    marketing_campaign, min_max;
