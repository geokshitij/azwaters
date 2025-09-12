#!/bin/bash

# This is a complete and robust script to enhance the storytelling map.
# It is idempotent, meaning it is safe to run multiple times.
#
# It performs the following automated tasks:
# 1. Downloads Arizona Major Rivers GeoJSON data if it doesn't exist.
# 2. Modifies index.html to add a layer for the rivers.
# 3. Modifies index.html to add symbol layers for labeling the CAP canal, pumps, and recharge sites.
# 4. Modifies data/story_content.json to control the visibility of the new labels.

set -e # Exit immediately if a command exits with a non-zero status.

# --- 0. Configuration ---
RIVERS_URL="https://services1.arcgis.com/Ezk9fcjSUkeadg6u/arcgis/rest/services/Major_Rivers/FeatureServer/0/query?outFields=*&where=1%3D1&f=geojson"
RIVERS_FILE="data/AZ_rivers.geojson"
INDEX_HTML="index.html"
STORY_JSON="data/story_content.json"

# --- 1. Dependency Checks ---
if ! command -v jq &> /dev/null; then
    echo "Error: 'jq' is not installed. It is required to safely edit JSON."
    echo "On macOS: brew install jq"
    exit 1
fi
if ! command -v curl &> /dev/null; then
    echo "Error: 'curl' is not installed. It is required to download data."
    exit 1
fi
echo "✅ Dependencies 'jq' and 'curl' are installed."

# --- 2. Download River Data ---
echo "➡️  Processing River Data..."
if [ -f "$RIVERS_FILE" ]; then
    echo "☑️  $RIVERS_FILE already exists. Skipping download."
else
    echo "    - Downloading Arizona Major Rivers data..."
    curl -s -L "$RIVERS_URL" -o "$RIVERS_FILE"
    if [ $? -eq 0 ] && [ -s "$RIVERS_FILE" ]; then
        echo "    - Successfully saved to $RIVERS_FILE."
    else
        echo "    - Error: Failed to download or save river data. Aborting."
        rm -f "$RIVERS_FILE" # Clean up empty file on failure
        exit 1
    fi
fi

# --- 3. Modify index.html to add all new layers ---
echo "➡️  Processing $INDEX_HTML..."

if grep -q "'id': 'cap-canal-label'" "$INDEX_HTML"; then
    echo "☑️  $INDEX_HTML already contains label and river layers. Skipping."
else
    cp "$INDEX_HTML" "$INDEX_HTML.bak.final"
    echo "    - Created backup: $INDEX_HTML.bak.final"

    # Create temporary files for the code blocks to ensure portability
    RIVERS_CODE_FILE=$(mktemp)
    LABELS_CODE_FILE=$(mktemp)

    # --- Populate Rivers Layer Block ---
    cat > "$RIVERS_CODE_FILE" <<'EOF'
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

    # --- Populate Labels Layer Block ---
    cat > "$LABELS_CODE_FILE" <<'EOF'

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

    # Use sed to insert the contents of the temp files. This is the most reliable method.
    # First, insert the rivers code.
    sed -i.bak "/map.addSource('cap-canal'/ r $RIVERS_CODE_FILE" "$INDEX_HTML"
    # Then, insert the labels code.
    sed -i.bak "/\/\/ --- END: ADDED CODE FOR GIS DATA ---/ r $LABELS_CODE_FILE" "$INDEX_HTML"

    # Clean up temporary files
    rm "$RIVERS_CODE_FILE" "$LABELS_CODE_FILE"
    rm "$INDEX_HTML.bak" # sed creates this backup, we remove it for cleanliness

    echo "    - Injected river and label layer definitions into $INDEX_HTML."
fi

# --- 4. Modify data/story_content.json to control labels ---
echo "➡️  Processing $STORY_JSON..."

if jq -e '.chapters[] | select(.id == "cap-title") | .onChapterEnter[] | select(.layer == "cap-canal-label")' "$STORY_JSON" > /dev/null; then
    echo "☑️  $STORY_JSON already contains label controls. Skipping."
else
    cp "$STORY_JSON" "$STORY_JSON.bak.final"
    echo "    - Created backup: $STORY_JSON.bak.final"

    jq '
    .chapters |= map(
        # Add label controls to SHOW on CAP chapters
        if .id == "cap-title" or .id == "cap-source" or .id == "cap-flyover" then
            .onChapterEnter += [
                {"layer": "cap-canal-label", "opacity": 1},
                {"layer": "cap-pumps-labels", "opacity": 1},
                {"layer": "cap-recharge-labels", "opacity": 1}
            ]
        else . end |

        # Add label controls to HIDE when leaving CAP section
        if .id == "srp-title" then
            .onChapterEnter += [
                {"layer": "cap-canal-label", "opacity": 0},
                {"layer": "cap-pumps-labels", "opacity": 0},
                {"layer": "cap-recharge-labels", "opacity": 0}
            ]
        else . end
    )
    ' "$STORY_JSON.bak.final" > "$STORY_JSON"

    echo "    - Added label visibility controls to $STORY_JSON."
fi

echo -e "\n🎉 All files updated successfully! Your story is now polished with labels and river context."
echo "Run './update.sh' to commit and push the changes."