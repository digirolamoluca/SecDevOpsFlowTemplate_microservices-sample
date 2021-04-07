#! /bin/bash
echo "Launching WPScan"
echo "ENDPOINT: $1"
echo "REPORT:"

wpscan --url $1 -o $2

echo "Terminate"
