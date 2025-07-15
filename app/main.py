from fastapi import FastAPI
from app import models
from app.database import engine
from app.routes import auth, usuarios, visitas
from app.routes import dashboard
models.Base.metadata.create_all(bind=engine)

app = FastAPI()

app.include_router(auth.router)  
app.include_router(usuarios.router)
app.include_router(visitas.router)
app.include_router(dashboard.router) 
