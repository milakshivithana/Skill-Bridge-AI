import urllib.request
import re

req = urllib.request.Request('https://skill-bridge-eight.vercel.app', headers={'User-Agent': 'Mozilla/5.0'})
html = urllib.request.urlopen(req).read().decode('utf-8')
print("HTML:", html[:300])
js_files = re.findall(r'src="([^"]+\.js)"', html)
print("JS files:", js_files)
for js_file in js_files:
    if js_file.startswith('/'):
        url = 'https://skill-bridge-eight.vercel.app' + js_file
    else:
        url = 'https://skill-bridge-eight.vercel.app/' + js_file
    js_content = urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})).read().decode('utf-8')
    matches = re.findall(r'http[^\s"\'`<>]+', js_content)
    print(f"URLs in {js_file}:")
    for m in matches:
        if any(w in m.lower() for w in ['api', 'render', 'localhost', '5264']):
            print("  *", m)
