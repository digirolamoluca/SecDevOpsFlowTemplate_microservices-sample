#! /bin/bash
echo "Launching WPScan"
echo "ENDPOINT: $1"
echo "Report Path:"

wpscan --url $1 -o $2

echo "Terminate"
