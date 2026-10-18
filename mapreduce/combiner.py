#!/usr/bin/env python3
import sys

# Initialize variables to keep track of the current key and partial sums
# This pattern mirrors the stateful aggregation seen in typical MapReduce Combiners
current_key = None
current_count = 0
current_price_sum = 0.0
current_cancelled_sum = 0

# Process each line from standard input continuously
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue

    # Split the line into key and value based on the tab delimiter
    # Mapper output format: complex_key \t count,price,cancelled_flag
    try:
        key, value_str = line.split('\t', 1)
        count_str, price_str, cancelled_str = value_str.split(',')
        
        count = int(count_str)
        price = float(price_str)
        cancelled = int(cancelled_str)
    except ValueError:
        # Skip malformed lines to prevent pipeline crashes
        continue

    # If the key is the same as the previous one, accumulate the values
    if current_key == key:
        current_count += count
        current_price_sum += price
        current_cancelled_sum += cancelled
    else:
        # If the key changes and it's not the first line, emit the aggregated result for the previous key
        # The Combiner output format MUST perfectly match the Mapper output format
        if current_key is not None:
            print(f"{current_key}\t{current_count},{current_price_sum},{current_cancelled_sum}")
        
        # Reset the tracking variables for the new key
        current_key = key
        current_count = count
        current_price_sum = price
        current_cancelled_sum = cancelled

# Emit the final key's aggregated result after the loop finishes
if current_key is not None:
    print(f"{current_key}\t{current_count},{current_price_sum},{current_cancelled_sum}")