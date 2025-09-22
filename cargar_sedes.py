import csv
from app.database import SessionLocal, engine
from app.models import SedeEducativa
from app.database import Base

# Asegúrate de que las tablas existen
Base.metadata.create_all(bind=engine)

db = SessionLocal()

with open('sedes.csv', mode='r', encoding='utf-8') as file:
    reader = csv.DictReader(file)
    for row in reader:
        sede = SedeEducativa(
            due=row['due'],
            institucion=row['institucion'],
            sede=row['sede'],
            municipio=row['municipio'],
            dane=row['dane'],
            lat=float(row['lat']),
            lon=float(row['lon'])
        )
        db.add(sede)

db.commit()
db.close()

print("✅ Sedes educativas cargadas correctamente.")
