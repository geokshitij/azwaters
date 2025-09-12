#!/bin/bash

# V2 - A more robust version of the upgrade script using sed.
# This script automates adding GIS data layers to the Mapbox storytelling project.

set -e # Exit immediately if a command exits with a non-zero status.

# --- 1. Dependency Check ---
if ! command -v jq &> /dev/null
then
    echo "Error: 'jq' is not installed. It is required to safely edit the JSON config."
    echo "Please install it to continue."
    echo "On macOS: brew install jq"
    echo "On Debian/Ubuntu: sudo apt-get install jq"
    exit 1
fi
echo "✅ Dependency 'jq' is installed."

# --- File Paths ---
INDEX_HTML="index.html"
STORY_JSON="data/story_content.json"
BUILD_SCRIPT="generate_story.py"

# --- 2. Modify index.html to add map layers ---
echo "➡️  Processing $INDEX_HTML..."

if grep -q "'id': 'cap-canal-layer'" "$INDEX_HTML"; then
    echo "☑️  $INDEX_HTML already contains GIS layers. Skipping."
else
    cp "$INDEX_HTML" "$INDEX_HTML.bak"
    echo "    - Created backup: $INDEX_HTML.bak"

    # Define the JS code to insert into a temporary file
    JS_CODE_FILE=$(mktemp)
    cat > "$JS_CODE_FILE" <<'EOF'
        // --- START: ADDED CODE FOR GIS DATA ---
        // Add sources for CAP data
        map.addSource('cap-canal', {
            'type': 'geojson',
            'data': './data/CAP_Canal.geojson'
        });

        map.addSource('cap-pumps', {
            'type': 'geojson',
            'data': './data/CAP_pumps.geojson'
        });

        map.addSource('cap-recharge', {
            'type': 'geojson',
            'data': './data/CAP_recharge.geojson'
        });

        // Add layers for the CAP data
        // Set initial opacity to 0 to hide them
        map.addLayer({
            'id': 'cap-canal-layer',
            'type': 'line',
            'source': 'cap-canal',
            'paint': {
                'line-color': '#3399ff', // A bright blue
                'line-width': 2.5,
                'line-opacity': 0
            }
        });

        map.addLayer({
            'id': 'cap-pumps-layer',
            'type': 'circle',
            'source': 'cap-pumps',
            'paint': {
                'circle-radius': 6,
                'circle-color': '#ff4500', // Orangey-red
                'circle-stroke-color': 'white',
                'circle-stroke-width': 1,
                'circle-opacity': 0
            }
        });

        map.addLayer({
            'id': 'cap-recharge-layer',
            'type': 'circle',
            'source': 'cap-recharge',
            'paint': {
                'circle-radius': 6,
                'circle-color': '#33cc33', // A bright green
                'circle-stroke-color': 'white',
                'circle-stroke-width': 1,
                'circle-opacity': 0
            }
        });
        // --- END: ADDED CODE FOR GIS DATA ---
EOF

    # Use sed to read the contents of the temp file and insert it before the target line
    sed -i.bak2 "/setup the instance, pass callback functions/ r $JS_CODE_FILE" "$INDEX_HTML"
    rm "$JS_CODE_FILE" # Clean up temp file
    rm "$INDEX_HTML.bak2" # Clean up sed backup

    echo "    - Injected map layer definitions into $INDEX_HTML."
fi

# --- 3. Modify data/story_content.json to control layers ---
echo "➡️  Processing $STORY_JSON..."

if jq -e '.chapters[] | select(.id == "cap-title") | .onChapterEnter[0].layer == "cap-canal-layer"' "$STORY_JSON" > /dev/null; then
    echo "☑️  $STORY_JSON already contains layer controls. Skipping."
else
    cp "$STORY_JSON" "$STORY_JSON.bak"
    echo "    - Created backup: $STORY_JSON.bak"

    jq '
    .chapters |= map(
        (.onChapterEnter = if .onChapterEnter then .onChapterEnter else [] end) |
        (.onChapterExit = if .onChapterExit then .onChapterExit else [] end) |
        if .id == "cap-title" or .id == "cap-source" or .id == "cap-flyover" then
            .onChapterEnter = [
                {"layer": "cap-canal-layer", "opacity": 0.85},
                {"layer": "cap-pumps-layer", "opacity": 1},
                {"layer": "cap-recharge-layer", "opacity": 1}
            ]
        else . end |
        if .id == "srp-title" then
            .onChapterEnter = [
                {"layer": "cap-canal-layer", "opacity": 0},
                {"layer": "cap-pumps-layer", "opacity": 0},
                {"layer": "cap-recharge-layer", "opacity": 0}
            ]
        else . end |
        if .id == "cap-title" then
            .description = "<h3>A 336-mile aqueduct defying gravity to deliver Colorado River water across the state.</h3><p>The blue line represents the CAP canal, orange dots are pumping plants, and green dots are recharge facilities.</p>"
        else . end
    )
    ' "$STORY_JSON.bak" > "$STORY_JSON"

    echo "    - Added onChapterEnter/Exit layer controls to $STORY_JSON."
fi

# --- 4. Modify generate_story.py to copy the data directory ---
echo "➡️  Processing $BUILD_SCRIPT..."

if grep -q "shutil.copytree('data'" "$BUILD_SCRIPT"; then
    echo "☑️  $BUILD_SCRIPT already copies the data directory. Skipping."
else
    cp "$BUILD_SCRIPT" "$BUILD_SCRIPT.bak"
    echo "    - Created backup: $BUILD_SCRIPT.bak"

cat > "$BUILD_SCRIPT" <<'EOF'
import json, os, shutil
ACCESS_TOKEN = 'pk.eyJ1Ijoia2RhaGFsIiwiYSI6ImNtZmcyM2QzejBvcHgydXB2eGUzbWpoeG4ifQ.kNzDDcHaMjIT43MMit5Rxg'
INPUT_JSON_PATH = 'data/story_content.json'
OUTPUT_DIR = 'output'
if os.path.exists(OUTPUT_DIR): shutil.rmtree(OUTPUT_DIR)
os.makedirs(OUTPUT_DIR)

with open(INPUT_JSON_PATH, 'r') as f: story_config = json.load(f)
story_config['accessToken'] = ACCESS_TOKEN

with open(os.path.join(OUTPUT_DIR, 'config.js'), 'w') as f: f.write(f"var config = {json.dumps(story_config, indent=4)};")

shutil.copy('index.html', os.path.join(OUTPUT_DIR, 'index.html'))

# Copy assets and data directories to the output folder
if os.path.exists('assets'):
    shutil.copytree('assets', os.path.join(OUTPUT_DIR, 'assets'), dirs_exist_ok=True)
if os.path.exists('data'):
    shutil.copytree('data', os.path.join(OUTPUT_DIR, 'data'), dirs_exist_ok=True)

print("--> Python build script finished successfully.")
EOF
    echo "    - Updated $BUILD_SCRIPT to copy the 'data' directory."
fi

echo -e "\n🎉 All files updated successfully! Your story is now enhanced with GIS data."
echo "Run './update.sh' to commit and push the changes."