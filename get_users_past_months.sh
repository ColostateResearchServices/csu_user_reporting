#!/bin/bash

# Get the current date
current_date=$(date +%Y-%m-%d)

# Parse the number of months from the argument
num_months=$1

# Create a CSV file and write the header
echo "User,Account" > csu_users.csv

# Loop through each past month
for ((i = 0; i < num_months; i++)); do
    # Calculate the start and end dates for the current month
    start_date=$(date -d "$current_date - $i months" +%Y-%m-01)
    end_date=$(date -d "$start_date + 1 month - 1 day" +%Y-%m-%d)

    # Run the command for the current month and append the output to the CSV file
    sacct --allusers --starttime="$start_date"T00:00:00 --endtime="$end_date"T23:59:59 -X -p --format=user | grep -i colostate | uniq >> output.csv
done
