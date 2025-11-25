#!/bin/bash

# Configuration
REPO_OWNER="superpeiss"
REPO_NAME="ios-app-fefcaf85-d1bf-459c-9fa6-507169eb877e"
TOKEN="YOUR_GITHUB_TOKEN_HERE"
RUN_ID="$1"

if [ -z "$RUN_ID" ]; then
    echo "Usage: $0 <run_id>"
    exit 1
fi

echo "Monitoring workflow run: $RUN_ID"
echo "========================================"

while true; do
    # Get run status
    response=$(curl -k -s -X GET \
        "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/actions/runs/$RUN_ID" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28")

    status=$(echo "$response" | grep -o '"status":"[^"]*"' | head -1 | cut -d'"' -f4)
    conclusion=$(echo "$response" | grep -o '"conclusion":"[^"]*"' | head -1 | cut -d'"' -f4)

    echo "Status: $status"

    if [ "$status" = "completed" ]; then
        echo "Conclusion: $conclusion"

        if [ "$conclusion" = "success" ]; then
            echo "✅ Build succeeded!"
            exit 0
        else
            echo "❌ Build failed!"

            # Try to download build log
            echo "Downloading build log..."
            curl -k -L -o build.log \
                "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/actions/runs/$RUN_ID/logs" \
                -H "Authorization: Bearer $TOKEN" \
                -H "Accept: application/vnd.github+json"

            exit 1
        fi
    fi

    sleep 10
done
