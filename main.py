# main.py - Punto de entrada principal del servidor
from app.main import app

# Este archivo permite que uvicorn encuentre la aplicación FastAPI
# desde el directorio raíz del proyecto

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
