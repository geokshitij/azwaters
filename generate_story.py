import json, os, shutil
ACCESS_TOKEN = 'pk.eyJ1Ijoia2RhaGFsIiwiYSI6ImNtZmcyM2QzejBvcHgydXB2eGUzbWpoeG4ifQ.kNzDDcHaMjIT43MMit5Rxg'
INPUT_JSON_PATH = 'data/story_content.json'
OUTPUT_DIR = 'output'

# Clean and create the output directory
if os.path.exists(OUTPUT_DIR):
    shutil.rmtree(OUTPUT_DIR)
os.makedirs(OUTPUT_DIR)

# Load the story configuration
with open(INPUT_JSON_PATH, 'r') as f:
    story_config = json.load(f)
story_config['accessToken'] = ACCESS_TOKEN

# Write the new config.js file
with open(os.path.join(OUTPUT_DIR, 'config.js'), 'w') as f:
    f.write(f"var config = {json.dumps(story_config, indent=4)};")

# Copy the main HTML file
shutil.copy('index.html', os.path.join(OUTPUT_DIR, 'index.html'))

# --- START: CORRECTED SECTION ---
# Copy the entire 'assets' and 'data' directories to the output folder
# This ensures all images and GeoJSON files are included in the deployment.
if os.path.exists('assets'):
    shutil.copytree('assets', os.path.join(OUTPUT_DIR, 'assets'))
if os.path.exists('data'):
    shutil.copytree('data', os.path.join(OUTPUT_DIR, 'data'))
# --- END: CORRECTED SECTION ---

print("--> Python build script finished successfully.")
