import sqlite3

conn = sqlite3.connect('visitas_cauca.db')
cursor = conn.cursor()
cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
tables = [row[0] for row in cursor.fetchall()]
print("Tablas en la base de datos:")
for table in tables:
    print(f"  - {table}")

# Buscar tablas que contengan 'usuario' o 'user'
user_tables = [t for t in tables if 'usuario' in t.lower() or 'user' in t.lower()]
print(f"\nTablas relacionadas con usuarios: {user_tables}")

conn.close()
