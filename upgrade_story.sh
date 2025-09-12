#!/bin/bash

# This is the definitive and final script to upgrade the project.
# It avoids all complex in-place editing by building a new index.html file from scratch.
# This is the most robust and reliable method.

set -e # Exit immediately if a command exits with a non-zero status.

INDEX_HTML="index.html"
NEW_INDEX_HTML="index.new.html"

echo "➡️  Starting the definitive build process for the final page..."

# Check if the file is in a clean state. If not, instruct the user.
if ! grep -q "// --- START: ADDED CODE FOR GIS DATA ---" "$INDEX_HTML"; then
    echo "❌ Error: index.html is not in the expected clean state."
    echo "Please run this command first to restore it:"
    echo "git checkout 36f4416 -- index.html"
    exit 1
fi

# --- 1. Define the complete, new block of code for all layers ---
CODE_BLOCK_FILE=$(mktemp)
cat > "$CODE_BLOCK_FILE" <<'EOF'
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

# --- 2. Find the line numbers for the old block we want to replace ---
START_LINE=$(grep -n "// --- START: ADDED CODE FOR GIS DATA ---" "$INDEX_HTML" | cut -d: -f1)
END_LINE=$(grep -n "// --- END: ADDED CODE FOR GIS DATA ---" "$INDEX_HTML" | cut -d: -f1)

# --- 3. Build the new file by stitching the pieces together ---
# Part 1: Everything BEFORE the old block
head -n $(($START_LINE - 1)) "$INDEX_HTML" > "$NEW_INDEX_HTML"

# Part 2: The NEW complete code block
cat "$CODE_BLOCK_FILE" >> "$NEW_INDEX_HTML"

# Part 3: Everything AFTER the old block
tail -n +$(($END_LINE + 1)) "$INDEX_HTML" >> "$NEW_INDEX_HTML"

# --- 4. Replace the old file with the new one and clean up ---
mv "$NEW_INDEX_HTML" "$INDEX_HTML"
rm "$CODE_BLOCK_FILE"

echo "    - Successfully rebuilt $INDEX_HTML with all new layers."
echo -e "\n✅ Final build complete. The project is now fully upgraded."
echo "Run './update.sh' to commit and push the final, working version."