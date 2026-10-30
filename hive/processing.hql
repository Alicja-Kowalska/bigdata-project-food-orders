-- STEP 1: Environment Cleanup
DROP TABLE IF EXISTS mr_output;
DROP TABLE IF EXISTS restaurants;
DROP TABLE IF EXISTS hive_final_results;

-- STEP 2: Structure for MapReduce Results (Text file, tab-separated)
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

-- STEP 3: Structure for the Restaurant Dictionary (Text file, comma-separated)
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

-- STEP 4: Output Table - USING THE METHOD FROM THE TUTORIAL
CREATE EXTERNAL TABLE hive_final_results (
    country STRING,
    cuisine STRING,
    total_orders BIGINT,
    weighted_avg_price DOUBLE,
    cancelled_ratio DOUBLE,
    cuisine_rank INT,
    deviation_from_country_avg DOUBLE
)
STORED AS JSONFILE
LOCATION '${hiveconf:HIVE_OUTPUT_DIR}';

-- STEP 5: Data processing and writing
WITH JoinedData AS (
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
    SELECT 
        country,
        cuisine,
        SUM(orders_count) AS total_orders,
        SUM(orders_count * avg_total_price) / SUM(orders_count) AS weighted_avg_price,
        CAST(SUM(cancelled_count) AS DOUBLE) / SUM(orders_count) AS cancelled_ratio
    FROM JoinedData
    GROUP BY country, cuisine
)
INSERT OVERWRITE TABLE hive_final_results
SELECT 
    country,
    cuisine,
    total_orders,
    weighted_avg_price,
    cancelled_ratio,
    RANK() OVER (PARTITION BY country ORDER BY total_orders DESC) AS cuisine_rank,
    total_orders - AVG(total_orders) OVER (PARTITION BY country) AS deviation_from_country_avg
FROM AggregatedData;