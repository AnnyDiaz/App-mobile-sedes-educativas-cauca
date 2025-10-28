# app/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from dotenv import load_dotenv
import os
from app import models
from app.database import engine
from app.routes import visitas, sedes, dashboard, auth, visitas_completas, usuarios, reportes, instituciones, municipios, visitas_programadas, items_pae, visitas_asignadas, notificaciones, supervisor, admin_basic

# Cargar variables de entorno
load_dotenv()

# 1. Configurar Rate Limiter
limiter = Limiter(key_func=get_remote_address)

# 2. Crear la instancia de la aplicación
app = FastAPI(
    title="API de Seguimiento de Sedes Educativas",
    description="API para gestionar las visitas a las sedes educativas del Cauca.",
    version="1.0.0"
)

# 3. Configurar Rate Limiting
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# 4. Añadir el Middleware de CORS con configuración segura
# IMPORTANTE: El middleware CORS debe estar ANTES de cualquier otro middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Para desarrollo, permite todos los orígenes (incluyendo http://localhost:*)
    allow_credentials=True,
    allow_methods=["*"],  # Permite todos los métodos HTTP (GET, POST, PUT, DELETE, OPTIONS, PATCH)
    allow_headers=["*"],  # Permite todos los headers
    expose_headers=["*"],  # Expone todos los headers en la respuesta
    max_age=3600,  # Cache preflight por 1 hora
)

# 3. Crear las tablas de la base de datos
models.Base.metadata.create_all(bind=engine)

# 4. Incluir los Routers
app.include_router(visitas.router, prefix="/api", tags=["Visitas"])
app.include_router(sedes.router, prefix="/api", tags=["Sedes"])
app.include_router(dashboard.router, prefix="/api/dashboard", tags=["Dashboard"])
app.include_router(auth.router, prefix="/api")
app.include_router(visitas_completas.router, prefix="/api", tags=["Visitas Completas PAE"])
app.include_router(usuarios.router, prefix="/api", tags=["Usuarios"])
app.include_router(reportes.router, prefix="/api/reportes", tags=["Reportes"])
app.include_router(instituciones.router, prefix="/api", tags=["Instituciones"])
app.include_router(municipios.router, prefix="/api", tags=["Municipios"])
app.include_router(visitas_programadas.router, prefix="/api", tags=["Visitas Programadas"])
app.include_router(items_pae.router, prefix="/api", tags=["Items PAE"])
app.include_router(visitas_asignadas.router, prefix="/api", tags=["Visitas Asignadas"])
app.include_router(supervisor.router, prefix="/api", tags=["Supervisor"])
app.include_router(admin_basic.router, prefix="/api/admin", tags=["Administración"])

app.include_router(notificaciones.router)

# 5. Ruta de Bienvenida
@app.get("/", tags=["Root"])
def read_root():
    return {"mensaje": "API de Seguimiento de Sedes Educativas está en línea"}
