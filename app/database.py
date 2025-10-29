from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
import os
from dotenv import load_dotenv

# Cargar las variables del archivo .env
load_dotenv()

# Obtener la URL de conexión a la base de datos
DATABASE_URL = os.getenv("DATABASE_URL")

# Si no se especifica DATABASE_URL, usar SQLite por defecto
if DATABASE_URL is None:
    DATABASE_URL = "sqlite:///./visitas_cauca.db"

# Crear el motor de la base de datos
# Para SQLite, habilitar las foreign keys
connect_args = {}
if "sqlite" in DATABASE_URL:
    connect_args = {"check_same_thread": False}

engine = create_engine(DATABASE_URL, connect_args=connect_args)

# Crear la sesión de conexión
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base para los modelos
Base = declarative_base()
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()