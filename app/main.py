from fastapi import FastAPI
from .database import Base, engine
from .routes import visitas
from fastapi.staticfiles import StaticFiles
app = FastAPI()


app.mount("/media", StaticFiles(directory="media"), name="media")

# Crear tablas en la base de datos
Base.metadata.create_all(bind=engine)

# Incluir rutas
app.include_router(visitas.router)
