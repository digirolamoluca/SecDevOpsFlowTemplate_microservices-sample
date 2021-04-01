#! /bin/bash

echo "Lauching Owasp Zap Scanning"
echo "ENDPOINT: $1"
echo "Report path: $2"

TIMESTAMP=`date +%Y-%m-%d_%H-%M-%S`

echo "SESSION: $TIMESTAMP "

/usr/share/zaproxy/zap.sh -cmd -quickurl $1 -newsession $TIMESTAMP &> /dev/null

echo "Exporting report"

/usr/share/zaproxy/zap.sh -cmd -session $TIMESTAMP -last_scan_report $2 &> /dev/null

echo "Complete"
