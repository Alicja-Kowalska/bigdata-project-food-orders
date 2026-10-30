#!/bin/bash

# Check if exactly three arguments are provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <mr_output_dir> <db4_input_dir> <hive_output_dir>"
    echo "Example: $0 /user/hadoop/output/mr_output /user/hadoop/input/datasource4 /user/hadoop/output/hive_output"
    exit 1
fi

MR_OUTPUT_DIR=$1
DB4_INPUT_DIR=$2
HIVE_OUTPUT_DIR=$3

echo "Starting Apache Hive processing pipeline..."
echo "MapReduce Output Directory (Input 1): $MR_OUTPUT_DIR"
echo "Restaurants Directory (Input 2): $DB4_INPUT_DIR"
echo "Hive Target Output Directory: $HIVE_OUTPUT_DIR"

# Ensure clean slate: Remove target directory if exists, then recreate it cleanly
hadoop fs -rm -r -f "$HIVE_OUTPUT_DIR"
hadoop fs -mkdir -p "$HIVE_OUTPUT_DIR"

# Execute the HQL script using beeline
beeline -u "jdbc:hive2://localhost:10000" \
    --hiveconf MR_OUTPUT_DIR="$MR_OUTPUT_DIR" \
    --hiveconf DB4_INPUT_DIR="$DB4_INPUT_DIR" \
    --hiveconf HIVE_OUTPUT_DIR="$HIVE_OUTPUT_DIR" \
    -f hive/processing.hql

# Check if the Hive job succeeded
if [ $? -eq 0 ]; then
    echo "Hive processing completed successfully! JSONL results are in $HIVE_OUTPUT_DIR"
else
    echo "Hive processing failed."
    exit 1
fi