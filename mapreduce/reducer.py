#!/usr/bin/env python3
import sys

# Initialize variables to keep track of the current key and global sums
current_key = None
total_count = 0
total_price = 0.0
total_cancelled = 0

# Process each line from standard input
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue

    # Parse the output from the Combiner
    # Format: restaurant_id,payment_type,order_year \t partial_count,partial_price,partial_cancelled
    try:
        key, value_str = line.split('\t', 1)
        count_str, price_str, cancelled_str = value_str.split(',')
        
        count = int(count_str)
        price = float(price_str)
        cancelled = int(cancelled_str)
    except ValueError:
        continue

    # Accumulate values for the same key
    if current_key == key:
        total_count += count
        total_price += price
        total_cancelled += cancelled
    else:
        # When the key changes, calculate final metrics and emit the result
        if current_key is not None:
            # Calculate the average total price
            avg_price = total_price / total_count
            
            # Split the complex key back into individual fields for a cleaner Hive table schema
            restaurant_id, payment_type, order_year = current_key.split(',')
            
            # Emit final row separated by tabs: 
            # restaurant_id | payment_type | order_year | orders_count | avg_total_price | cancelled_count
            print(f"{restaurant_id}\t{payment_type}\t{order_year}\t{total_count}\t{avg_price:.2f}\t{total_cancelled}")
        
        # Reset trackers for the new key
        current_key = key
        total_count = count
        total_price = price
        total_cancelled = cancelled

# Emit the final group's result after the loop finishes
if current_key is not None:
    avg_price = total_price / total_count
    restaurant_id, payment_type, order_year = current_key.split(',')
    print(f"{restaurant_id}\t{payment_type}\t{order_year}\t{total_count}\t{avg_price:.2f}\t{total_cancelled}")