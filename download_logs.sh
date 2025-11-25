#!/bin/bash

# Download build logs and extract key errors
RUN_ID="$1"
TOKEN="YOUR_GITHUB_TOKEN_HERE"
REPO="superpeiss/ios-app-fefcaf85-d1bf-459c-9fa6-507169eb877e"

if [ -z "$RUN_ID" ]; then
    echo "Usage: $0 <run_id>"
    exit 1
fi

# Get the run's logs URL
echo "Fetching logs for run $RUN_ID..."

curl -k -L -s "https://api.github.com/repos/$REPO/actions/runs/$RUN_ID/logs" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Accept: application/vnd.github+json" \
    -o /tmp/logs_${RUN_ID}.zip

echo "Logs saved to /tmp/logs_${RUN_ID}.zip"
echo ""
echo "To extract, you can use:"
echo "  jar xf /tmp/logs_${RUN_ID}.zip"
echo "  or manually download from:"
echo "  https://github.com/$REPO/actions/runs/$RUN_ID"
