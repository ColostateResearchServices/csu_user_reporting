#!/bin/bash

# Extended sreport to include options for input CSV, output CSV, custom start/end dates, and aggregation by user.

function usage() {
    cat <<EOF
Purpose: This script computes the number of Service Units (SUs) consumed by specified users over a configurable period.
Usage: $0 [userid] [days, default 30] [-s start_date -e end_date] [-i input_csv -o output_csv]
Options:
  [userid]        The username to query SU usage.
  [days]          Number of days from today backwards (default 30 days).
  -s start_date   Specify the start date for the report (format YYYY-MM-DD).
  -e end_date     Specify the end date for the report (format YYYY-MM-DD).
  -i input_csv    Specify input CSV file containing usernames.
  -o output_csv   Specify output CSV file to write total SU usage.
  -h              Display this help and exit.
Examples:
  $0 ralphie 15
  $0 ralphie -s 2023-01-01 -e 2023-06-01
  $0 -i users.csv -o usage.csv -s 2023-01-01 -e 2023-06-01
EOF
}

while getopts ":hs:e:i:o:" opt; do
  case $opt in
    h)
      usage
      exit 0
      ;;
    s)
      start_date=$OPTARG
      ;;
    e)
      end_date=$OPTARG
      ;;
    i)
      input_csv=$OPTARG
      ;;
    o)
      output_csv=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      usage
      exit 1
      ;;
  esac
done

# Shift out the processed options
shift $((OPTIND-1))

# Default days if not specified
days=30

# Check if the default position parameters are set
if [[ $# -eq 2 ]]; then
    user=$1
    days=$2
elif [[ $# -eq 1 ]]; then
    user=$1
fi

# Ensure user is specified unless input_csv is used
if [[ -z "$user" ]] && [[ -z "$input_csv" ]]; then
    echo "Error: A username or input CSV file must be specified."
    usage
    exit 1
fi

# Calculate default dates if not manually set
if [[ -z "$start_date" ]] || [[ -z "$end_date" ]]; then
    start_date=$(date +%Y-%m-%d -d "$days days ago")
    end_date=$(date +%Y-%m-%d)
fi

# Function to compute SU usage for a single user
function compute_su_usage() {
    local user=$1
    local su_usage=$(sreport -t hours -T billing -P cluster AccountUtilizationByUser start=$start_date end=$end_date tree user=$user -p | awk -F'|' 'BEGIN{sum=0}{if (NR>4) sum+=$6}END{print sum}')
    echo "$user,$su_usage"
}

# Handle CSV input/output
if [[ -n "$input_csv" ]] && [[ -n "$output_csv" ]]; then
    echo "Username,Total SUs" > "$output_csv"
    while IFS=, read -r user; do
        result=$(compute_su_usage "$user")
        echo "$result" >> "$output_csv"
    done < "$input_csv"
    echo "Output written to $output_csv"
elif [[ -n "$user" ]]; then
    result=$(compute_su_usage "$user")
    echo "$result"
else
    echo "Error: No valid input method (user or CSV) defined."
    usage
    exit 1
fi

echo "Processing complete."