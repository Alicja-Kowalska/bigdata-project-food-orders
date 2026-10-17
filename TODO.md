# Big Data Project Implementation Plan (Dataset 15)

## 1. Repository Setup & Structure
- [ ] Create directories: `mapreduce`, `hive`, `airflow/dags`.
- [ ] Create and populate the `.gitignore` file.
- [ ] Prepare `README.md` with architecture description and setup instructions.

## 2. Stage I: MapReduce (Hadoop Streaming - Python)
- [ ] **Implement `mapper.py`**
  - [ ] Read data from stdin, handling/ignoring the header row.
  - [ ] Extract `order_year` from `order_date`.
  - [ ] Convert formats and cast variable types.
  - [ ] Build a complex key: `restaurant_id`, `payment_type`, `order_year`.
  - [ ] Emit a tuple enabling aggregation (count, price, cancelled flag).
  - [ ] Verification: Script must operate in a streaming fashion (no lists/dicts in memory for the whole file).
- [ ] **Implement `combiner.py`** (Criteria M06, M07)
  - [ ] Perform partial aggregation receiving the stream from the mapper.
  - [ ] Calculate partial sums (order count, total prices, cancellations).
  - [ ] Verification: Returned format must be strictly identical to the mapper's output.
- [ ] **Implement `reducer.py`** (Criteria M08, M09, M10)
  - [ ] Read partial sums and perform final aggregation for groups.
  - [ ] Calculate target metrics: `orders_count`, `avg_total_price`, `cancelled_count`.
  - [ ] Format and emit the final output as plain text (e.g., tab-separated).
- [ ] **Implement `run_mr.sh` script** (Criteria M11, M12)
  - [ ] Handle 2 arguments: input directory and output directory.
  - [ ] Automated cleanup of the output directory before execution (`hadoop fs -rm -r -f ...`).
  - [ ] Execute `mapred streaming` passing python scripts via the `-files` option.

## 3. Stage II: Apache Hive
- [ ] **Implement `processing.hql` script**
  - [ ] Performance requirement: Use CTEs (`WITH` clauses) to avoid writing unnecessary intermediate tables to disk.
  - [ ] Use `DROP TABLE IF EXISTS` at the beginning for idempotence/repeatability.
  - [ ] Create 2 `EXTERNAL TABLE`s for the MapReduce output and the restaurant dataset.
  - [ ] Perform an optimal `JOIN` of both datasets on `restaurant_id`.
  - [ ] Set aggregation level to `country` and `cuisine`.
  - [ ] Calculate Hive metrics: total orders, *weighted average* price (based on MR data), and `cancelled_ratio`.
  - [ ] Alpha group calculation: Use `RANK() OVER` partitioned by country to create a ranking.
  - [ ] Alpha group calculation: Calculate deviation from the country average using `AVG() OVER`.
  - [ ] Output format: Export data to JSONL format (record-level JSON) using the SerDe mechanism (H15 requirement).
- [ ] **Implement `run_hive.sh` script**
  - [ ] Handle 3 arguments (MR output dir, DB4 input dir, Hive output dir).
  - [ ] Remove output directory before execution.
  - [ ] Execute HQL script using the `beeline` command.

## 4. Stage III: Orchestration (Apache Airflow)
- [ ] Configure the attached DAG in Airflow.
- [ ] Verify parameter passing in operators (`{{ params... }}`).
- [ ] Test pipeline execution, check repeatability (no file conflicts on the second run).
- [ ] Audit the `get_output` task logs for valid JSONL format.