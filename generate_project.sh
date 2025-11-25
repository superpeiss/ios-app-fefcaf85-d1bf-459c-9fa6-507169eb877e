#!/bin/bash

# Install XcodeGen if not present
if ! command -v xcodegen &> /dev/null; then
    echo "Installing XcodeGen..."
    brew install xcodegen
fi

# Generate Xcode project
echo "Generating Xcode project..."
cd "$(dirname "$0")"
xcodegen generate

echo "Project generation complete!"
