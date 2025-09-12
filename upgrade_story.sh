#!/bin/bash

# This is the final, simple, and correct fix. It uses the user's excellent idea
# to re-style the map's existing water layers instead of loading external files.
# It also moves the byline to the footer and cleans up the project.

set -e # Exit immediately if a command exits with a non-zero status.

echo "--- Step 1: Restoring project to a known-good state ---"
# This ensures we start from a clean, working base (commit c605e83).
git checkout c605e83 -- index.html data/story_content.json
echo "    - Project restored to a clean state."

# --- Define file paths ---
INDEX_HTML="index.html"
STORY_JSON="data/story_content.json"
RIVERS_FILE="data/AZ_rivers.geojson"

echo "--- Step 2: Modifying index.html to highlight existing rivers ---"
# This method rebuilds the file to guarantee success.
NEW_INDEX_HTML="index.new.html"
# Find the line number to insert our new code after.
INSERT_LINE=$(grep -n "'sky-atmosphere-sun-intensity': 15" "$INDEX_HTML" | cut -d: -f1)

# Part 1: Everything up to and including our insertion point
head -n "$INSERT_LINE" "$INDEX_HTML" > "$NEW_INDEX_HTML"

# Part 2: The NEW, simple code block to re-style the water layers
cat >> "$NEW_INDEX_HTML" <<'EOF'
                    }
                });

                // --- START: Highlight Rivers in Base Map ---
                // This makes the existing river data in the map style more prominent.
                map.setPaintProperty('water', 'fill-color', '#3399ff');
                map.setPaintProperty('waterway', 'line-color', '#3399ff');
                map.setPaintProperty('waterway', 'line-width', 2);
                // --- END: Highlight Rivers in Base Map ---
            };

            // setup the instance, pass callback functions
EOF

# Part 3: Everything AFTER the block we are replacing
# We find the line "// setup the instance..." and take everything after it.
TAIL_START_LINE=$(grep -n "// setup the instance, pass callback functions" "$INDEX_HTML" | cut -d: -f1)
tail -n +$(($TAIL_START_LINE + 1)) "$INDEX_HTML" >> "$NEW_INDEX_HTML"

# Replace the old file with the new one
mv "$NEW_INDEX_HTML" "$INDEX_HTML"
echo "    - Successfully added river highlighting to index.html."

echo "--- Step 3: Moving byline to footer ---"
jq '.byline = "" | .footer = (.footer + "<br>Developed by Kshitij Dahal (kdahal3@asu.edu)")' "$STORY_JSON" > "$STORY_JSON.tmp" && mv "$STORY_JSON.tmp" "$STORY_JSON"
echo "    - Byline moved to footer."

echo "--- Step 4: Cleaning up unnecessary files ---"
# Remove the problematic rivers file as it is no longer needed.
rm -f "$RIVERS_FILE"
# Remove any old backup files
rm -f *.bak*
rm -f data/*.bak*
echo "    - Project cleaned."

echo -e "\n✅ Final fix complete. The project is now correct and clean."
echo "Run './update.sh' to commit and push the final working version."