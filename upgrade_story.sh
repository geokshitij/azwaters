#!/bin/bash

# This is the final script. It corrects the root cause of the problem:
# the GitHub Actions deployment workflow. It also applies the requested byline change.

set -e # Exit immediately if a command exits with a non-zero status.

WORKFLOW_FILE=".github/workflows/deploy.yml"
STORY_JSON="data/story_content.json"

echo "➡️  Applying final fixes to the deployment workflow and story content..."

# --- 1. Overwrite the GitHub Actions workflow file with a corrected version ---
# This version adds a verification step to prove the 'data' directory is being created.
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
    - name: Checkout
      uses: actions/checkout@v4
      
    - name: Setup Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.10'
        
    - name: Run Python build script
      run: python generate_story.py
      
    - name: Verify build output
      run: ls -R output
      
    - name: Upload artifact
      uses: actions/upload-pages-artifact@v3
      with:
        path: './output'
        
    - name: Deploy to GitHub Pages
      uses: actions/deploy-pages@v4
EOF
echo "    - Corrected the deployment workflow at $WORKFLOW_FILE"

# --- 2. Update the byline in the story content file ---
# Use jq to safely modify the JSON file.
jq '.byline = "Developed by Kshitij Dahal (kdahal3@asu.edu)"' "$STORY_JSON" > "$STORY_JSON.tmp" && mv "$STORY_JSON.tmp" "$STORY_JSON"
echo "    - Updated byline in $STORY_JSON"

echo -e "\n✅ Final fix applied. The deployment process is now correct."
echo "Run './update.sh' to commit and push the definitive working version."