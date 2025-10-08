## Despliegue con Docker

### Requisitos
- Docker 24+
- Docker Compose v2

### Variables de entorno
Crear un archivo `.env` en la raíz (mismo nivel que docker-compose.yml) con al menos:

```
SECRET_KEY=pon_una_clave_segura
EMAIL_USER=
EMAIL_PASSWORD=
```

Opcionales (tienen valores por defecto en compose):
- ACCESS_TOKEN_EXPIRE_MINUTES, REFRESH_TOKEN_EXPIRE_DAYS
- ALLOWED_ORIGINS

### Construir y levantar

```bash
docker compose build
docker compose up -d
```

La API quedará en http://localhost:8000

### Base de datos
- Se usa Postgres en `db` con usuario/clave `visitas/visitas` y base `visitas_cauca`
- El volumen `db_data` persiste datos

### Media
- Volumen `media_data` montado en `/app/media` para archivos subidos y exportaciones

### Inicialización opcional
Para cargar roles/usuario admin por defecto, ejecutar dentro del contenedor:

```bash
docker compose exec api python -m app.scripts.init_admin_system
```

### Notas de seguridad
- Cambia `SECRET_KEY` y credenciales de Postgres en producción
- Restringe `ALLOWED_ORIGINS` a tus dominios
- Considera un servidor frontal (nginx) para TLS y manejo de estáticos


