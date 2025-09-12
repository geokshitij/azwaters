#!/bin/bash

# This script fixes the "white screen" issue by restoring the last working
# index.html from its backup and then re-applying the necessary code
# modifications using a more robust method.

set -e # Exit immediately if a command exits with a non-zero status.

INDEX_HTML="index.html"
BACKUP_FILE="index.html.bak.final"
STORY_JSON="data/story_content.json"

echo "➡️  Starting the fix process..."

# --- 1. Restore from Backup ---
if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file '$BACKUP_FILE' not found. Cannot proceed."
    exit 1
fi

echo "    - Restoring $INDEX_HTML from backup..."
mv "$BACKUP_FILE" "$INDEX_HTML"
echo "    - Restore complete."

# --- 2. Re-apply the code modifications correctly ---
echo "➡️  Re-applying modifications to the restored $INDEX_HTML..."

# We will build a new index.html file piece by piece to avoid any command compatibility issues.
TEMP_INDEX_FILE=$(mktemp)

# Find the line number for the first insertion point
INSERT_LINE_1=$(grep -n "map.addSource('cap-canal'" "$INDEX_HTML" | cut -d: -f1)
# Find the line number for the second insertion point
INSERT_LINE_2=$(grep -n "// --- END: ADDED CODE FOR GIS DATA ---" "$INDEX_HTML" | cut -d: -f1)

# Write the part of the file before the first insertion
head -n $(($INSERT_LINE_1 - 1)) "$INDEX_HTML" > "$TEMP_INDEX_FILE"

# Append the Rivers code block
cat >> "$TEMP_INDEX_FILE" <<'EOF'
        // --- START: ADD RIVERS DATA ---
        map.addSource('az-rivers', {
            'type': 'geojson',
            'data': './data/AZ_rivers.geojson'
        });

        map.addLayer({
            'id': 'az-rivers-layer',
            'type': 'line',
            'source': 'az-rivers',
            'paint': {
                'line-color': '#00BFFF', // A deep sky blue
                'line-width': 1.5,
                'line-opacity': 0.6 // Slightly transparent to not overwhelm
            }
        }, 'cap-canal-layer'); // This places the rivers layer *before* the canal layer
        // --- END: ADD RIVERS DATA ---
EOF

# Write the middle part of the file
sed -n "$INSERT_LINE_1,${INSERT_LINE_2}p" "$INDEX_HTML" >> "$TEMP_INDEX_FILE"

# Append the Labels code block
cat >> "$TEMP_INDEX_FILE" <<'EOF'

        // --- START: ADD NEW LABEL LAYERS HERE ---
        // Add labels for the PUMPING stations
        map.addLayer({
            'id': 'cap-pumps-labels',
            'type': 'symbol',
            'source': 'cap-pumps',
            'layout': {
                'text-field': ['get', 'STRUCTURE'],
                'text-font': ['Open Sans Semibold', 'Arial Unicode MS Bold'],
                'text-size': 10,
                'text-offset': [0, 1.2],
                'text-anchor': 'top'
            },
            'paint': {
                'text-color': '#ffffff',
                'text-halo-color': '#000000',
                'text-halo-width': 1,
                'text-opacity': 0
            }
        });

        // Add labels for the RECHARGE sites
        map.addLayer({
            'id': 'cap-recharge-labels',
            'type': 'symbol',
            'source': 'cap-recharge',
            'layout': {
                'text-field': ['get', 'name'],
                'text-font': ['Open Sans Semibold', 'Arial Unicode MS Bold'],
                'text-size': 10,
                'text-offset': [0, 1.2],
                'text-anchor': 'top'
            },
            'paint': {
                'text-color': '#ffffff',
                'text-halo-color': '#000000',
                'text-halo-width': 1,
                'text-opacity': 0
            }
        });

        // Add a label for the CANAL line
        map.addLayer({
            'id': 'cap-canal-label',
            'type': 'symbol',
            'source': 'cap-canal',
            'layout': {
                'text-field': 'Central Arizona Project Canal',
                'symbol-placement': 'line-center',
                'text-font': ['Open Sans Italic', 'Arial Unicode MS Regular'],
                'text-size': 12
            },
            'paint': {
                'text-color': '#3399ff',
                'text-halo-color': 'rgba(255, 255, 255, 0.8)',
                'text-halo-width': 2,
                'text-opacity': 0
            }
        });
        // --- END: NEW LABEL LAYERS ---
EOF

# Write the rest of the file
tail -n +$(($INSERT_LINE_2 + 1)) "$INDEX_HTML" >> "$TEMP_INDEX_FILE"

# Replace the old file with the newly constructed one
mv "$TEMP_INDEX_FILE" "$INDEX_HTML"

echo "    - Successfully rebuilt index.html with all new layers."
echo -e "\n🎉 Fix complete! The white screen issue should be resolved."
echo "Run './update.sh' to commit and push the corrected files."
