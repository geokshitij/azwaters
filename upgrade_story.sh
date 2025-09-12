#!/bin/bash

# This script fixes the river display issue by removing an incorrect block of code
# from index.html that tries to load a non-existent GeoJSON file.
# This allows the correct, pre-existing code that styles the base map's
# water layers to function as intended.

set -e # Exit immediately if a command exits with a non-zero status.

INDEX_FILE="index.html"
TEMP_FILE="index.html.temp"
START_MARKER="// --- START: ADD RIVERS DATA ---"
END_MARKER="// --- END: ADD RIVERS DATA ---"

echo "➡️  Starting the fix to correctly display rivers..."

# --- 1. Check if the incorrect block exists ---
if ! grep -q "$START_MARKER" "$INDEX_FILE"; then
    echo "✅ The incorrect river data block was not found."
    echo "It appears this fix has already been applied. No changes needed."
    exit 0
fi

echo "    - Found the incorrect river data block. Proceeding with removal."

# --- 2. Find the line numbers of the block to remove ---
START_LINE=$(grep -n "$START_MARKER" "$INDEX_FILE" | cut -d: -f1)
END_LINE=$(grep -n "$END_MARKER" "$INDEX_FILE" | cut -d: -f1)

if [ -z "$START_LINE" ] || [ -z "$END_LINE" ]; then
    echo "Error: Could not find the start or end markers for the block to remove."
    exit 1
fi

echo "    - The block to be removed is between lines $START_LINE and $END_LINE."

# --- 3. Rebuild the file without the incorrect block ---
# Copy everything BEFORE the start marker to a new temp file
head -n $(($START_LINE - 1)) "$INDEX_FILE" > "$TEMP_FILE"

# Append everything AFTER the end marker to the new temp file
tail -n +$(($END_LINE + 1)) "$INDEX_FILE" >> "$TEMP_FILE"

echo "    - A corrected version of index.html has been created."

# --- 4. Replace the old file with the new, corrected one ---
mv "$TEMP_FILE" "$INDEX_FILE"
echo "    - The original index.html has been replaced."

echo -e "\n🎉 Fix complete! The incorrect code has been removed."
echo "The map will now correctly highlight the rivers from the base map style."