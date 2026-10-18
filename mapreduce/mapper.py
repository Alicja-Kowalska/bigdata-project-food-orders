#!/usr/bin/env python3
import sys

# Process each line from standard input continuously (streaming fashion)
for line in sys.stdin:
    # Remove leading and trailing whitespace
    line = line.strip()

    # Skip empty lines or the CSV header row (assuming header starts with 'order_id')
    if not line or line.startswith("order_id"):
        continue

    # Split the CSV line into individual columns based on the dataset schema
    # Expected: order_id, restaurant_id, order_date, items_count, total_price_usd, payment_type, status
    parts = line.split(',')

    # Ensure the row has exactly 7 columns to prevent IndexError on malformed lines
    if len(parts) == 7:
        try:
            # Extract relevant fields
            restaurant_id = parts[1].strip()
            order_date = parts[2].strip()
            # Cast price to float for aggregation
            total_price_usd = float(parts[4].strip())
            payment_type = parts[5].strip()
            status = parts[6].strip()

            # Extract the year from the datetime string (format: yyyy-MM-dd'T'HH:mm)
            # Slicing the first 4 characters is highly efficient
            order_year = order_date[:4]

            # Create a numeric flag for cancelled orders (1 if Cancelled, 0 otherwise)
            is_cancelled = 1 if status == 'Cancelled' else 0

            # Build the complex key required by the assignment
            complex_key = f"{restaurant_id},{payment_type},{order_year}"
            
            # Build the value tuple enabling Combiner/Reducer aggregation: (count, price, cancelled_flag)
            aggregation_value = f"1,{total_price_usd},{is_cancelled}"

            # Emit the key-value pair separated by a tab character (standard Hadoop Streaming delimiter)
            print(f"{complex_key}\t{aggregation_value}")

        except ValueError:
            # Silently skip the row if float casting fails (data quality protection)
            continue