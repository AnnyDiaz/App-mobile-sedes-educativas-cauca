# 🚀 Inicio Rápido - Sistema Visitas PAE

Esta es una guía rápida para desplegar el sistema en 5 minutos.

---

## ⚡ Despliegue Automático

### Windows (PowerShell)

```powershell
# Ejecutar el script de despliegue automático
.\desplegar_completo.ps1
```

### Linux/Mac

```bash
# Dar permisos de ejecución
chmod +x desplegar_completo.sh

# Ejecutar el script de despliegue automático
./desplegar_completo.sh
```

**¡Eso es todo!** El script hará todo automáticamente:
1. ✅ Limpiar contenedores anteriores
2. ✅ Construir y levantar Docker
3. ✅ Esperar a que la BD esté lista
4. ✅ Cargar 41 municipios, 564 instituciones y 2,556 sedes
5. ✅ Cargar checklist PAE (15 categorías, 64 items)
6. ✅ Verificar que todo funciona

---

## 📋 Despliegue Manual Paso a Paso

Si prefieres hacerlo manualmente:

### 1. Levantar contenedores
```bash
docker compose up --build -d
```

### 2. Esperar 30 segundos
```bash
# Windows
Start-Sleep -Seconds 30

# Linux/Mac
sleep 30
```

### 3. Cargar datos
```bash
# Copiar archivos
docker cp insert_data_optimized.sql visitas_db:/tmp/insert_data_optimized.sql
docker cp insert_datos_normalizados.sql visitas_db:/tmp/insert_datos_normalizados.sql

# Cargar en la BD
docker exec -i visitas_db psql -U visitas -d visitas_cauca -f /tmp/insert_data_optimized.sql
docker exec -i visitas_db psql -U visitas -d visitas_cauca -f /tmp/insert_datos_normalizados.sql
```

### 4. Verificar checklist (se carga automáticamente)
```bash
# El checklist se carga automáticamente durante la inicialización
# Solo verifica que esté completo:
docker exec -i visitas_db psql -U visitas -d visitas_cauca -c "SELECT COUNT(*) FROM checklist_items;"
# Debe mostrar: 64

# Si aparece 0, ejecutar manualmente:
# docker exec -i visitas_db bash -c "psql -U visitas -d visitas_cauca -f /app/insert_checklist_items.sql"
```

---

## ✅ Verificación

### Abrir en tu navegador:
- 📄 **Documentación API:** http://localhost:8000/docs

### Probar login:
- **Email:** `admin@test.com`
- **Password:** `admin`

### Verificar datos:
```bash
# Ver municipios (debe mostrar 41)
docker exec -i visitas_db psql -U visitas -d visitas_cauca -c "SELECT COUNT(*) FROM municipios;"

# Ver checklist (debe mostrar 15 categorías y 64 items)
docker exec -i visitas_db psql -U visitas -d visitas_cauca -c "SELECT COUNT(*) FROM checklist_categorias;"
docker exec -i visitas_db psql -U visitas -d visitas_cauca -c "SELECT COUNT(*) FROM checklist_items;"
```

---

## 🔧 Comandos Útiles

```bash
# Ver logs en tiempo real
docker compose logs -f

# Detener el sistema
docker compose stop

# Reiniciar el sistema
docker compose restart

# Eliminar todo y empezar de nuevo
docker compose down -v
```

---

## 🆘 ¿Problemas?

Consulta la **[Guía Completa de Despliegue](GUIA_DESPLIEGUE_DOCKER.md)** para:
- Solución de problemas detallada
- Configuración avanzada
- Comandos adicionales
- Consideraciones de seguridad

---

## 📊 Datos que se cargan:

| Tipo | Cantidad |
|------|----------|
| Municipios | 41 |
| Instituciones Educativas | 564 |
| Sedes Educativas | 2,556 |
| Categorías Checklist PAE | 15 |
| Items Checklist PAE | 64 |
| Roles de Usuario | 4 |
| Usuario Admin | 1 |

---

## 🎯 URLs Importantes

- **API Backend:** http://localhost:8000
- **Documentación Swagger:** http://localhost:8000/docs
- **Documentación ReDoc:** http://localhost:8000/redoc

---

**¡Sistema listo en 5 minutos! 🎉**

