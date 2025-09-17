from fastapi import Depends, HTTPException
from jose import jwt, JWTError
from sqlalchemy.orm import Session
from fastapi.security import OAuth2PasswordBearer

from app.database import get_db
from app import models

SECRET_KEY = "clave-secreta"
ALGORITHM = "HS256"
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")

def verificar_rol_permitido(roles_permitidos: list):
    def validador(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
        try:
            payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
            correo = payload.get("sub")
            rol = payload.get("rol")
            if correo is None or rol is None:
                raise HTTPException(status_code=401, detail="Token inválido")
            if rol not in roles_permitidos:
                raise HTTPException(status_code=403, detail="Acceso denegado: rol no autorizado")
        except JWTError:
            raise HTTPException(status_code=401, detail="Token inválido")

        usuario = db.query(models.Usuario).filter(models.Usuario.correo == correo).first()
        if usuario is None:
            raise HTTPException(status_code=401, detail="Usuario no encontrado")
        return usuario
    return validador
