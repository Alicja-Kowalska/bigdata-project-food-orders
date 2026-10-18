#!/bin/bash

# Check if exactly two arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <input_dir> <output_dir>"
    echo "Example: $0 /user/student/input/datasource1 /user/student/output/mr_output"
    exit 1
fi

INPUT_DIR=$1
OUTPUT_DIR=$2

echo "Starting Hadoop Streaming MapReduce process..."
echo "Input directory: $INPUT_DIR"
echo "Output directory: $OUTPUT_DIR"

# Automated cleanup: Remove the output directory if it already exists
# This fulfills the idempotency requirement (Criteria M11/M12)
hadoop fs -rm -r -f "$OUTPUT_DIR"

# Execute the MapReduce job using the mapred streaming utility
# The -files option distributes the local Python scripts to all cluster nodes
mapred streaming \
    -files mapreduce/mapper.py,mapreduce/combiner.py,mapreduce/reducer.py \
    -mapper "python3 mapper.py" \
    -combiner "python3 combiner.py" \
    -reducer "python3 reducer.py" \
    -input "$INPUT_DIR" \
    -output "$OUTPUT_DIR"

# Check if the MapReduce job succeeded
if [ $? -eq 0 ]; then
    echo "MapReduce job completed successfully!"
else
    echo "MapReduce job failed."
    exit 1
fi