# Big Data Project Implementation Plan (Dataset 15)

## 1. Repository Setup & Structure
- [x] Create directories: `mapreduce`, `hive`, `airflow/dags`.
- [x] Create and populate the `.gitignore` file.
- [ ] Prepare `README.md` with architecture description and setup instructions.

## 2. Stage I: MapReduce (Hadoop Streaming - Python)
- [x] **Implement `mapper.py`**
  - [x] Read data from stdin, handling/ignoring the header row.
  - [x] Extract `order_year` from `order_date`.
  - [x] Convert formats and cast variable types.
  - [x] Build a complex key: `restaurant_id`, `payment_type`, `order_year`.
  - [x] Emit a tuple enabling aggregation (count, price, cancelled flag).
  - [x] Verification: Script must operate in a streaming fashion (no lists/dicts in memory for the whole file).
- [x] **Implement `combiner.py`** (Criteria M06, M07)
  - [x] Perform partial aggregation receiving the stream from the mapper.
  - [x] Calculate partial sums (order count, total prices, cancellations).
  - [x] Verification: Returned format must be strictly identical to the mapper's output.
- [x] **Implement `reducer.py`** (Criteria M08, M09, M10)
  - [x] Read partial sums and perform final aggregation for groups.
  - [x] Calculate target metrics: `orders_count`, `avg_total_price`, `cancelled_count`.
  - [x] Format and emit the final output as plain text (e.g., tab-separated).
- [x] **Implement `run_mr.sh` script** (Criteria M11, M12)
  - [x] Handle 2 arguments: input directory and output directory.
  - [x] Automated cleanup of the output directory before execution (`hadoop fs -rm -r -f ...`).
  - [x] Execute `mapred streaming` passing python scripts via the `-files` option.

## 3. Stage II: Apache Hive
- [x] **Implement `processing.hql` script**
  - [x] Performance requirement: Use CTEs (`WITH` clauses) to avoid writing unnecessary intermediate tables to disk.
  - [x] Use `DROP TABLE IF EXISTS` at the beginning for idempotence/repeatability.
  - [x] Create 2 `EXTERNAL TABLE`s for the MapReduce output and the restaurant dataset.
  - [x] Perform an optimal `JOIN` of both datasets on `restaurant_id`.
  - [x] Set aggregation level to `country` and `cuisine`.
  - [x] Calculate Hive metrics: total orders, *weighted average* price (based on MR data), and `cancelled_ratio`.
  - [x] Alpha group calculation: Use `RANK() OVER` partitioned by country to create a ranking.
  - [x] Alpha group calculation: Calculate deviation from the country average using `AVG() OVER`.
  - [x] Output format: Export data to JSONL format (record-level JSON) using the SerDe mechanism (H15 requirement).
- [x] **Implement `run_hive.sh` script**
  - [x] Handle 3 arguments (MR output dir, DB4 input dir, Hive output dir).
  - [x] Remove output directory before execution.
  - [x] Execute HQL script using the `beeline` command.

## 4. Stage III: Orchestration (Apache Airflow)
- [ ] Configure the attached DAG in Airflow.
- [ ] Verify parameter passing in operators (`{{ params... }}`).
- [ ] Test pipeline execution, check repeatability (no file conflicts on the second run).
- [ ] Audit the `get_output` task logs for valid JSONL format.