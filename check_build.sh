#!/bin/bash

# Simple script to check workflow status and provide useful info

REPO="superpeiss/ios-app-fefcaf85-d1bf-459c-9fa6-507169eb877e"
TOKEN="YOUR_GITHUB_TOKEN_HERE"

echo "======================================"
echo "GitHub Actions Build Status"
echo "======================================"
echo ""

# Get latest run
response=$(curl -k -s "https://api.github.com/repos/$REPO/actions/runs?per_page=1" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Accept: application/vnd.github+json")

run_id=$(echo "$response" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
status=$(echo "$response" | grep -o '"status":"[^"]*"' | head -1 | cut -d'"' -f4)
conclusion=$(echo "$response" | grep -o '"conclusion":"[^"]*"' | head -1 | cut -d'"' -f4)
sha=$(echo "$response" | grep -o '"head_sha":"[^"]*"' | head -1 | cut -d'"' -f4)

echo "Latest Run ID: $run_id"
echo "Status: $status"
echo "Conclusion: $conclusion"
echo "Commit SHA: $sha"
echo ""
echo "View full logs at:"
echo "https://github.com/$REPO/actions/runs/$run_id"
echo ""

if [ "$conclusion" = "failure" ]; then
    echo "Build FAILED - Please check the logs at the URL above"
    echo ""
    echo "Common issues to check:"
    echo "1. Swift compilation errors"
    echo "2. Missing imports or dependencies"
    echo "3. SwiftUI syntax errors"
    echo "4. Code signing issues (should be disabled)"
    exit 1
elif [ "$conclusion" = "success" ]; then
    echo "✅ Build SUCCEEDED!"
    exit 0
else
    echo "Build is still in progress..."
fi
