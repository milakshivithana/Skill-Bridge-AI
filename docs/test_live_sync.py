import urllib.request
import json
import psycopg2
import time

# 1. Register a test user via the Render API
email = f"test_live_{int(time.time())}@skillbridge.lk"
payload = {
    "fullName": "Live Test Candidate",
    "email": email,
    "password": "Password123!",
    "role": "Candidate"
}

data = json.dumps(payload).encode('utf-8')
req = urllib.request.Request(
    'https://skillbridge-g6r6.onrender.com/api/auth/register',
    data=data,
    headers={'Content-Type': 'application/json', 'User-Agent': 'Mozilla/5.0'}
)

print(f"Sending registration to Render API for {email}...")
try:
    res = urllib.request.urlopen(req)
    res_data = json.loads(res.read().decode('utf-8'))
    print("Render API responded:", res_data)
except Exception as e:
    print("API Error:", e)

# 2. Check directly in Railway PostgreSQL
conn = psycopg2.connect("postgresql://postgres:zLNVfXXkjnmfPyENNZkrWHpLSyNJANvL@ballast.proxy.rlwy.net:57408/railway")
cur = conn.cursor()
cur.execute('SELECT "Id", "FullName", "Email", "Role" FROM "Users" ORDER BY "Id";')
rows = cur.fetchall()
print(f"\n--- Current Users in Railway PostgreSQL ({len(rows)} total) ---")
found = False
for r in rows:
    print(f"ID={r[0]} | {r[1]} | {r[2]} | {r[3]}")
    if r[2] == email:
        found = True

conn.close()

if found:
    print(f"\n>>> SUCCESS! {email} was successfully saved directly into Railway PostgreSQL! <<<")
else:
    print(f"\n>>> NOTICE: {email} was returned by Render, but NOT found in Railway. Render is still using InMemory fallback. <<<")
