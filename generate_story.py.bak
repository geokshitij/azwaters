import json, os, shutil
ACCESS_TOKEN = 'pk.eyJ1Ijoia2RhaGFsIiwiYSI6ImNtZmcyM2QzejBvcHgydXB2eGUzbWpoeG4ifQ.kNzDDcHaMjIT43MMit5Rxg'
INPUT_JSON_PATH = 'data/story_content.json'
OUTPUT_DIR = 'output'
if os.path.exists(OUTPUT_DIR): shutil.rmtree(OUTPUT_DIR)
os.makedirs(os.path.join(OUTPUT_DIR, 'assets'))
with open(INPUT_JSON_PATH, 'r') as f: story_config = json.load(f)
story_config['accessToken'] = ACCESS_TOKEN
with open(os.path.join(OUTPUT_DIR, 'config.js'), 'w') as f: f.write(f"var config = {json.dumps(story_config, indent=4)};")
shutil.copy('index.html', os.path.join(OUTPUT_DIR, 'index.html'))
for item in os.listdir('assets'):
    s = os.path.join('assets', item)
    d = os.path.join(OUTPUT_DIR, 'assets', item)
    if os.path.isfile(s): shutil.copy2(s, d)
print("--> Python build script finished successfully.")
