#!/bin/bash

# This is the definitive upgrade script. It assumes index.html is in a clean,
# working state and replaces the old map layer definitions with the new,
# complete ones (including rivers and labels).

set -e # Exit immediately if a command exits with a non-zero status.

INDEX_HTML="index.html"

echo "➡️  Starting the final upgrade process for $INDEX_HTML..."

# Check if the work is already done.
if grep -q "'id': 'az-rivers-layer'" "$INDEX_HTML"; then
    echo "✅  The final layers already exist in $INDEX_HTML. No action needed."
    exit 0
fi

# --- Create a temporary file with the NEW, COMPLETE code block ---
COMPLETE_CODE_BLOCK=$(mktemp)
cat > "$COMPLETE_CODE_BLOCK" <<'EOF'
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

# Find the start and end lines of the OLD code block to be replaced.
START_LINE=$(grep -n "// --- START: ADDED CODE FOR GIS DATA ---" "$INDEX_HTML" | cut -d: -f1)
END_LINE=$(grep -n "// --- END: ADDED CODE FOR GIS DATA ---" "$INDEX_HTML" | cut -d: -f1)

# Use sed to delete the old block and replace it with the contents of our new file.
# This is a robust way to do a block replacement.
sed -i.bak -e "${START_LINE},${END_LINE}d" -e "${START_LINE}r $COMPLETE_CODE_BLOCK" "$INDEX_HTML"

# Clean up
rm "$COMPLETE_CODE_BLOCK"
rm "$INDEX_HTML.bak"

echo "    - Successfully replaced old layer definitions with the complete new set."
echo -e "\n✅ Final upgrade complete. The project is now fully functional with all features."
echo "Run './update.sh' to commit and push."