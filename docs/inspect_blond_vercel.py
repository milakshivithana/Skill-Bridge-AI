import urllib.request
import re

url = 'https://skill-bridge-blond.vercel.app'
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
html = urllib.request.urlopen(req).read().decode('utf-8')
print("HTML Title/Content:", html[:200])

js_files = re.findall(r'src="([^"]+\.js)"', html)
print("JS files:", js_files)

for js_file in js_files:
    full_js_url = url + js_file if js_file.startswith('/') else url + '/' + js_file
    print(f"Checking {full_js_url}...")
    js_content = urllib.request.urlopen(urllib.request.Request(full_js_url, headers={'User-Agent': 'Mozilla/5.0'})).read().decode('utf-8')
    matches = re.findall(r'https?://[^\s"\'`<>]+', js_content)
    for m in set(matches):
        if any(w in m.lower() for w in ['render', 'api', 'localhost', 'railway']):
            print("  Found API target:", m)
