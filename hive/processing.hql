-- STEP 1: Environment Cleanup (Idempotency)
DROP TABLE IF EXISTS mr_output;
DROP TABLE IF EXISTS restaurants;

-- STEP 2: Structure for MapReduce Results
CREATE EXTERNAL TABLE mr_output (
    restaurant_id STRING,
    payment_type STRING,
    order_year STRING,
    orders_count INT,
    avg_total_price DOUBLE,
    cancelled_count INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '${hiveconf:MR_OUTPUT_DIR}';

-- STEP 3: Structure for the Restaurant Dictionary (datasource4)
CREATE EXTERNAL TABLE restaurants (
    restaurant_id STRING,
    name STRING,
    city STRING,
    country STRING,
    cuisine STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '${hiveconf:DB4_INPUT_DIR}'
TBLPROPERTIES ("skip.header.line.count"="1");

-- STEP 4: Advanced Analytical Query with CTE placed at the beginning
WITH JoinedData AS (
    -- Perform JOIN on restaurant_id
    SELECT 
        r.country,
        r.cuisine,
        m.orders_count,
        m.avg_total_price,
        m.cancelled_count
    FROM mr_output m
    JOIN restaurants r ON m.restaurant_id = r.restaurant_id
),
AggregatedData AS (
    -- Group by country and cuisine to calculate Hive metrics
    SELECT 
        country,
        cuisine,
        SUM(orders_count) AS total_orders,
        -- Calculate weighted average price
        SUM(orders_count * avg_total_price) / SUM(orders_count) AS weighted_avg_price,
        -- Calculate cancelled ratio
        CAST(SUM(cancelled_count) AS DOUBLE) / SUM(orders_count) AS cancelled_ratio
    FROM JoinedData
    GROUP BY country, cuisine
)
INSERT OVERWRITE DIRECTORY '${hiveconf:HIVE_OUTPUT_DIR}'
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.JsonSerDe'
STORED AS TEXTFILE
SELECT 
    country,
    cuisine,
    total_orders,
    weighted_avg_price,
    cancelled_ratio,
    cuisine_rank,
    deviation_from_country_avg
FROM (
    SELECT 
        country,
        cuisine,
        total_orders,
        weighted_avg_price,
        cancelled_ratio,
        RANK() OVER (PARTITION BY country ORDER BY total_orders DESC) AS cuisine_rank,
        total_orders - AVG(total_orders) OVER (PARTITION BY country) AS deviation_from_country_avg
    FROM AggregatedData
) FinalSelect;