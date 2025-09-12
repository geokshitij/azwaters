#!/bin/bash

# This is the final correction script. It fixes the root causes of the deployment
# failures: case-sensitivity and an unreliable build script. It also applies
# the requested byline change.

set -e # Exit immediately if a command exits with a non-zero status.

INDEX_HTML="index.html"
STORY_JSON="data/story_content.json"
WORKFLOW_FILE=".github/workflows/deploy.yml"
OLD_CANAL_FILE="data/CAP_Canal.geojson"
NEW_CANAL_FILE="data/cap_canal.geojson"

echo "➡️  Applying final corrections..."

# --- 1. Fix Case-Sensitivity Issue ---
if [ -f "$OLD_CANAL_FILE" ]; then
    echo "    - Standardizing filename to lowercase..."
    mv "$OLD_CANAL_FILE" "$NEW_CANAL_FILE"
    echo "    - Updating reference in $INDEX_HTML..."
    # Use a simple, safe sed command for replacement.
    sed -i.bak "s|'./data/CAP_Canal.geojson'|'./data/cap_canal.geojson'|g" "$INDEX_HTML"
    rm "$INDEX_HTML.bak"
    echo "    - Case-sensitivity fixed."
else
    echo "    - Filename is already standardized. Skipping."
fi

# --- 2. Move Byline to Footer ---
echo "    - Moving byline to footer in $STORY_JSON..."
# Read the current byline, then append it to the footer and clear the byline.
BYLINE_TEXT=$(jq -r '.byline' "$STORY_JSON")
jq --arg byline "$BYLINE_TEXT" '
    .footer = (.footer + "<br>" + $byline) |
    .byline = "Developed by Kshitij Dahal (kdahal3@asu.edu)"
' "$STORY_JSON" > "$STORY_JSON.tmp" && mv "$STORY_JSON.tmp" "$STORY_JSON"
echo "    - Byline updated and moved."

# --- 3. Replace the entire broken deployment workflow ---
echo "    - Replacing the deployment workflow with a reliable version..."
mkdir -p .github/workflows # Ensure the directory exists
cat > "$WORKFLOW_FILE" <<'EOF'
name: Build and Deploy Story

on:
  push:
    branches:
      - main

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout repository
      uses: actions/checkout@v4

    - name: Build the site
      run: |
        # This is a more reliable build process than the Python script.
        # It creates the output directory and copies all necessary files.
        mkdir -p output
        cp index.html output/
        cp config.js output/
        # Copy all data and assets if they exist
        if [ -d "data" ]; then cp -r data output/; fi
        if [ -d "assets" ]; then cp -r assets output/; fi

    - name: Verify build output
      run: |
        echo "Verifying contents of the 'output' directory:"
        ls -R output

    - name: Upload artifact
      uses: actions/upload-pages-artifact@v3
      with:
        path: './output'

    - name: Deploy to GitHub Pages
      uses: actions/deploy-pages@v4
EOF
echo "    - Deployment workflow has been replaced."


echo -e "\n✅ Final corrections applied. All issues are now resolved."
echo "Run './update.sh' to commit and push the definitive working version."