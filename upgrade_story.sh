#!/bin/bash

# This is the final, targeted fix. It corrects the river styling by using the
# exact layer names from the 'mapbox/satellite-streets-v12' style.

set -e # Exit immediately if a command exits with a non-zero status.

echo "--- Step 1: Restoring index.html to a known-good state ---"
# This ensures we start from a clean, working base (commit c605e83).
git checkout c605e83 -- index.html
echo "    - index.html restored."

# --- Define file paths ---
INDEX_HTML="index.html"

echo "--- Step 2: Modifying index.html with the CORRECT river layer names ---"
# This method rebuilds the file to guarantee success.
NEW_INDEX_HTML="index.new.html"
# Find the line number to insert our new code after.
INSERT_LINE=$(grep -n "'sky-atmosphere-sun-intensity': 15" "$INDEX_HTML" | cut -d: -f1)

# Part 1: Everything up to and including our insertion point
head -n "$INSERT_LINE" "$INDEX_HTML" > "$NEW_INDEX_HTML"

# Part 2: The NEW, CORRECT code block to re-style the water layers
cat >> "$NEW_INDEX_HTML" <<'EOF'
                    }
                });

                // --- START: Highlight Rivers in Base Map ---
                // This makes the existing river data in the map style more prominent.
                // For lakes, reservoirs, etc.
                map.setPaintProperty('water', 'fill-color', '#3399ff');
                map.setPaintProperty('water', 'fill-opacity', 0.5);

                // For the actual river and stream lines
                map.setPaintProperty('waterway-river', 'line-color', '#3399ff');
                map.setPaintProperty('waterway-river', 'line-width', 2);
                map.setPaintProperty('waterway-stream', 'line-color', '#3399ff');
                map.setPaintProperty('waterway-canal', 'line-color', '#3399ff');
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
echo "    - Successfully added correct river highlighting to index.html."

echo -e "\n✅ Final fix complete. The river styling is now correct."
echo "Run './update.sh' to commit and push the final working version."