import psycopg2

conn = psycopg2.connect("postgresql://postgres:zLNVfXXkjnmfPyENNZkrWHpLSyNJANvL@ballast.proxy.rlwy.net:57408/railway")
cur = conn.cursor()

cur.execute('SELECT "Id", "FullName", "Email", "Role", "CreatedAt" FROM "Users" ORDER BY "Id";')
rows = cur.fetchall()
print(f"Total Users in Railway: {len(rows)}")
for r in rows:
    print(f"ID={r[0]} | Name={r[1]} | Email={r[2]} | Role={r[3]} | CreatedAt={r[4]}")

conn.close()
