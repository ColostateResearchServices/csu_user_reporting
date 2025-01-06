#!/usr/bin/env python3

import argparse
import csv
from datetime import datetime, timedelta
import subprocess

def compute_su_usage(user, start_date, end_date):
    # Run sreport command to compute SU usage
    cmd = [
        "sreport", "-t", "hours", "-T", "billing", "-P", "cluster", 
        "AccountUtilizationByUser", f"start={start_date}", f"end={end_date}", 
        "tree", f"user={user}", "-p"
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    # Process output to extract SU usage
    output_lines = result.stdout.splitlines()
    su_usage = 0
    for line in output_lines[4:]:  # Skip the header
        fields = line.split('|')
        try:
            su_usage += float(fields[5].strip())
        except ValueError:
            pass
    return su_usage


def main():
    parser = argparse.ArgumentParser(description="Compute SU usage by specified users over a configurable period")
    parser.add_argument("user", nargs="?", help="The username to query SU usage")
    parser.add_argument("--days", type=int, default=30, help="Number of days from today backwards (default 30 days)")
    parser.add_argument("-s", "--start-date", help="Specify the start date for the report (format YYYY-MM-DD)")
    parser.add_argument("-e", "--end-date", help="Specify the end date for the report (format YYYY-MM-DD)")
    parser.add_argument("-i", "--input-csv", help="Specify input CSV file containing usernames")
    parser.add_argument("-o", "--output-csv", help="Specify output CSV file to write total SU usage")
    
    args = parser.parse_args()

    # Default start and end dates
    if not args.start_date:
        args.start_date = (datetime.now() - timedelta(days=args.days)).strftime("%Y-%m-%d")
    if not args.end_date:
        args.end_date = datetime.now().strftime("%Y-%m-%d")

    # Compute SU usage for single user or from CSV
    if args.input_csv:
        with open(args.input_csv, 'r') as csvfile:
            reader = csv.reader(csvfile)
            rows = list(reader)
            with open(args.output_csv, 'w', newline='') as output_csv:
                writer = csv.writer(output_csv)
                writer.writerow(["Username", "Total SUs"])
                for row in rows:
                    user = row[0]
                    su_usage = compute_su_usage(user, args.start_date, args.end_date)
                    writer.writerow([user, su_usage])
        print(f"Output written to {args.output_csv}")
    elif args.user:
        su_usage = compute_su_usage(args.user, args.start_date, args.end_date)
        print(f"{args.user},{su_usage}")
    else:
        parser.print_help()

    print("Processing complete.")

if __name__ == "__main__":
    main()
