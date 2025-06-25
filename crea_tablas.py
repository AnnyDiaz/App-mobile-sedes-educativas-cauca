# crea_tablas.py

from app.database import engine, Base
from app import models

print("Creando las tablas...")
Base.metadata.create_all(bind=engine)
print("Listo.")
