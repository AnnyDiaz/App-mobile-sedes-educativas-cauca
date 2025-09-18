# 🚀 Documentación de Despliegue - Sistema PAE Cauca

## 📋 Índice

1. [Requisitos del Sistema](#requisitos-del-sistema)
2. [Configuración del Backend](#configuración-del-backend)
3. [Configuración del Frontend](#configuración-del-frontend)
4. [Configuración de Base de Datos](#configuración-de-base-de-datos)
5. [Configuración de Notificaciones Push](#configuración-de-notificaciones-push)
6. [Despliegue en Producción](#despliegue-en-producción)
7. [Monitoreo y Mantenimiento](#monitoreo-y-mantenimiento)
8. [Troubleshooting](#troubleshooting)

---

## 🖥️ Requisitos del Sistema

### **Servidor Backend**
- **OS**: Ubuntu 20.04+ / CentOS 8+ / Windows Server 2019+
- **RAM**: Mínimo 4GB, Recomendado 8GB+
- **CPU**: Mínimo 2 cores, Recomendado 4+ cores
- **Almacenamiento**: Mínimo 50GB SSD
- **Python**: 3.8+
- **PostgreSQL**: 12+

### **Cliente Frontend**
- **Android**: 6.0+ (API level 23+)
- **iOS**: 12.0+
- **Web**: Chrome 80+, Firefox 75+, Safari 13+
- **Windows**: Windows 10+
- **macOS**: 10.14+

---

## 🔧 Configuración del Backend

### **1. Instalación de Dependencias**

```bash
# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar Python 3.8+
sudo apt install python3 python3-pip python3-venv -y

# Instalar PostgreSQL
sudo apt install postgresql postgresql-contrib -y

# Instalar dependencias del sistema
sudo apt install build-essential libpq-dev -y
```

### **2. Configuración del Entorno Virtual**

```bash
# Crear directorio del proyecto
mkdir -p /opt/pae-cauca
cd /opt/pae-cauca

# Crear entorno virtual
python3 -m venv venv

# Activar entorno virtual
source venv/bin/activate

# Instalar dependencias Python
pip install --upgrade pip
pip install -r requirements.txt
```

### **3. Configuración de Variables de Entorno**

Crear archivo `.env` en el directorio raíz:

```env
# Base de datos
DATABASE_URL=postgresql://pae_user:password123@localhost:5432/pae_cauca

# JWT Configuration
SECRET_KEY=tu_clave_secreta_muy_segura_aqui_minimo_32_caracteres
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_DAYS=7

# Email Configuration
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=tu_email@gmail.com
EMAIL_PASSWORD=tu_contraseña_de_aplicacion
EMAIL_USE_TLS=true

# Firebase Cloud Messaging
FCM_SERVER_KEY=tu_fcm_server_key_aqui
FCM_PROJECT_ID=tu_project_id_aqui
NOTIFICACIONES_ENABLED=true

# CORS Configuration
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080,https://tu-dominio.com

# Rate Limiting
RATE_LIMIT_ENABLED=true

# Logging
LOG_LEVEL=INFO
LOG_FILE=/var/log/pae-cauca/app.log
```

### **4. Configuración de Base de Datos**

```bash
# Acceder a PostgreSQL
sudo -u postgres psql

# Crear base de datos y usuario
CREATE DATABASE pae_cauca;
CREATE USER pae_user WITH PASSWORD 'password123';
GRANT ALL PRIVILEGES ON DATABASE pae_cauca TO pae_user;
\q

# Ejecutar migraciones
cd /opt/pae-cauca
source venv/bin/activate
cd app
python -c "from database import engine; from models import Base; Base.metadata.create_all(bind=engine)"
```

### **5. Configuración de Gunicorn para Producción**

Crear archivo `gunicorn.conf.py`:

```python
# gunicorn.conf.py
bind = "0.0.0.0:8000"
workers = 4
worker_class = "uvicorn.workers.UvicornWorker"
worker_connections = 1000
max_requests = 1000
max_requests_jitter = 100
timeout = 30
keepalive = 2
preload_app = True
accesslog = "/var/log/pae-cauca/access.log"
errorlog = "/var/log/pae-cauca/error.log"
loglevel = "info"
```

### **6. Configuración de Systemd**

Crear archivo `/etc/systemd/system/pae-cauca.service`:

```ini
[Unit]
Description=PAE Cauca Backend Service
After=network.target postgresql.service

[Service]
Type=exec
User=www-data
Group=www-data
WorkingDirectory=/opt/pae-cauca
Environment=PATH=/opt/pae-cauca/venv/bin
ExecStart=/opt/pae-cauca/venv/bin/gunicorn -c gunicorn.conf.py app.main:app
ExecReload=/bin/kill -s HUP $MAINPID
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### **7. Configuración de Nginx (Opcional)**

Crear archivo `/etc/nginx/sites-available/pae-cauca`:

```nginx
server {
    listen 80;
    server_name tu-dominio.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /static/ {
        alias /opt/pae-cauca/static/;
    }

    location /media/ {
        alias /opt/pae-cauca/media/;
    }
}
```

---

## 📱 Configuración del Frontend

### **1. Instalación de Flutter**

```bash
# Descargar Flutter SDK
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz
tar xf flutter_linux_3.16.0-stable.tar.xz
sudo mv flutter /opt/
export PATH="$PATH:/opt/flutter/bin"

# Verificar instalación
flutter doctor
```

### **2. Configuración del Proyecto**

```bash
# Clonar o copiar el proyecto
cd /opt/pae-cauca/frontend_visitas

# Instalar dependencias
flutter pub get

# Configurar URL del backend
# Editar lib/config.dart
const String baseUrl = 'https://tu-servidor.com';
```

### **3. Configuración de Android**

```bash
# Instalar Android SDK
sudo apt install openjdk-11-jdk -y
sudo apt install android-sdk -y

# Configurar variables de entorno
export ANDROID_HOME=/usr/lib/android-sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools

# Aceptar licencias
flutter doctor --android-licenses
```

### **4. Build para Producción**

#### **Android APK**
```bash
# Build de release
flutter build apk --release

# Build con firma (opcional)
flutter build apk --release --split-per-abi
```

#### **Web**
```bash
# Build para web
flutter build web --release

# Los archivos se generan en build/web/
```

#### **Windows**
```bash
# Build para Windows
flutter build windows --release
```

---

## 🗄️ Configuración de Base de Datos

### **1. Configuración de PostgreSQL**

```bash
# Editar configuración de PostgreSQL
sudo nano /etc/postgresql/12/main/postgresql.conf

# Configuraciones recomendadas:
max_connections = 200
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100

# Reiniciar PostgreSQL
sudo systemctl restart postgresql
```

### **2. Configuración de Backup**

Crear script de backup `/opt/pae-cauca/backup_db.sh`:

```bash
#!/bin/bash
# backup_db.sh

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/opt/pae-cauca/backups"
DB_NAME="pae_cauca"

mkdir -p $BACKUP_DIR

# Crear backup
pg_dump -h localhost -U pae_user -d $DB_NAME > $BACKUP_DIR/pae_cauca_$DATE.sql

# Comprimir backup
gzip $BACKUP_DIR/pae_cauca_$DATE.sql

# Eliminar backups antiguos (más de 30 días)
find $BACKUP_DIR -name "*.sql.gz" -mtime +30 -delete

echo "Backup completado: pae_cauca_$DATE.sql.gz"
```

### **3. Configuración de Cron para Backups**

```bash
# Agregar al crontab
crontab -e

# Backup diario a las 2:00 AM
0 2 * * * /opt/pae-cauca/backup_db.sh >> /var/log/pae-cauca/backup.log 2>&1
```

---

## 🔔 Configuración de Notificaciones Push

### **1. Configuración de Firebase**

1. Ir a [Firebase Console](https://console.firebase.google.com/)
2. Crear nuevo proyecto o usar existente
3. Agregar aplicación Android/iOS
4. Descargar archivo de configuración

### **2. Configuración Android**

```bash
# Copiar google-services.json a android/app/
cp google-services.json frontend_visitas/android/app/

# Configurar build.gradle
# android/app/build.gradle
apply plugin: 'com.google.gms.google-services'
```

### **3. Configuración iOS**

```bash
# Copiar GoogleService-Info.plist a ios/Runner/
cp GoogleService-Info.plist frontend_visitas/ios/Runner/

# Configurar en Xcode
# Agregar archivo al proyecto en Xcode
```

### **4. Configuración del Backend**

```env
# Variables de entorno para FCM
FCM_SERVER_KEY=tu_server_key_aqui
FCM_PROJECT_ID=tu_project_id_aqui
NOTIFICACIONES_ENABLED=true
```

---

## 🚀 Despliegue en Producción

### **1. Configuración del Servidor**

```bash
# Crear directorios necesarios
sudo mkdir -p /var/log/pae-cauca
sudo mkdir -p /opt/pae-cauca/backups
sudo mkdir -p /opt/pae-cauca/media
sudo mkdir -p /opt/pae-cauca/static

# Configurar permisos
sudo chown -R www-data:www-data /opt/pae-cauca
sudo chmod -R 755 /opt/pae-cauca
```

### **2. Iniciar Servicios**

```bash
# Iniciar servicio de backend
sudo systemctl enable pae-cauca
sudo systemctl start pae-cauca

# Verificar estado
sudo systemctl status pae-cauca

# Ver logs
sudo journalctl -u pae-cauca -f
```

### **3. Configuración de SSL (Opcional)**

```bash
# Instalar Certbot
sudo apt install certbot python3-certbot-nginx -y

# Obtener certificado SSL
sudo certbot --nginx -d tu-dominio.com

# Configurar renovación automática
sudo crontab -e
# Agregar: 0 12 * * * /usr/bin/certbot renew --quiet
```

### **4. Configuración de Firewall**

```bash
# Configurar UFW
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

---

## 📊 Monitoreo y Mantenimiento

### **1. Configuración de Logs**

```bash
# Configurar logrotate
sudo nano /etc/logrotate.d/pae-cauca

# Contenido:
/var/log/pae-cauca/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 www-data www-data
}
```

### **2. Monitoreo de Recursos**

```bash
# Instalar herramientas de monitoreo
sudo apt install htop iotop nethogs -y

# Script de monitoreo
cat > /opt/pae-cauca/monitor.sh << 'EOF'
#!/bin/bash
echo "=== PAE Cauca System Status ==="
echo "Date: $(date)"
echo "Uptime: $(uptime)"
echo "Memory Usage:"
free -h
echo "Disk Usage:"
df -h
echo "Service Status:"
systemctl status pae-cauca --no-pager
echo "Database Connections:"
sudo -u postgres psql -c "SELECT count(*) FROM pg_stat_activity WHERE datname='pae_cauca';"
EOF

chmod +x /opt/pae-cauca/monitor.sh
```

### **3. Configuración de Alertas**

```bash
# Instalar herramientas de monitoreo
sudo apt install mailutils -y

# Script de alertas
cat > /opt/pae-cauca/check_service.sh << 'EOF'
#!/bin/bash
if ! systemctl is-active --quiet pae-cauca; then
    echo "PAE Cauca service is down!" | mail -s "Service Alert" admin@tu-dominio.com
    systemctl restart pae-cauca
fi
EOF

chmod +x /opt/pae-cauca/check_service.sh

# Agregar al crontab (cada 5 minutos)
*/5 * * * * /opt/pae-cauca/check_service.sh
```

---

## 🔧 Troubleshooting

### **Problemas Comunes**

#### **1. Error de Conexión a Base de Datos**
```bash
# Verificar estado de PostgreSQL
sudo systemctl status postgresql

# Verificar conexión
sudo -u postgres psql -c "SELECT version();"

# Verificar configuración de red
sudo netstat -tlnp | grep 5432
```

#### **2. Error de Permisos**
```bash
# Verificar permisos
ls -la /opt/pae-cauca/

# Corregir permisos
sudo chown -R www-data:www-data /opt/pae-cauca
sudo chmod -R 755 /opt/pae-cauca
```

#### **3. Error de Memoria**
```bash
# Verificar uso de memoria
free -h
htop

# Ajustar configuración de Gunicorn
# Reducir workers en gunicorn.conf.py
```

#### **4. Error de Notificaciones Push**
```bash
# Verificar configuración FCM
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=TU_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{"to":"TOKEN","notification":{"title":"Test","body":"Test"}}'
```

### **Comandos de Diagnóstico**

```bash
# Ver logs del servicio
sudo journalctl -u pae-cauca -f

# Ver logs de Nginx
sudo tail -f /var/log/nginx/error.log

# Ver logs de PostgreSQL
sudo tail -f /var/log/postgresql/postgresql-12-main.log

# Verificar puertos
sudo netstat -tlnp | grep -E ':(8000|5432|80|443)'

# Verificar procesos
ps aux | grep -E '(gunicorn|postgres|nginx)'
```

### **Recuperación de Emergencia**

```bash
# Restaurar base de datos desde backup
gunzip -c /opt/pae-cauca/backups/pae_cauca_YYYYMMDD_HHMMSS.sql.gz | \
sudo -u postgres psql pae_cauca

# Reiniciar todos los servicios
sudo systemctl restart postgresql
sudo systemctl restart pae-cauca
sudo systemctl restart nginx

# Verificar estado
sudo systemctl status postgresql pae-cauca nginx
```

---

## 📋 Checklist de Despliegue

### **Pre-Despliegue**
- [ ] Servidor configurado con requisitos mínimos
- [ ] Python 3.8+ instalado
- [ ] PostgreSQL 12+ instalado y configurado
- [ ] Flutter SDK instalado
- [ ] Variables de entorno configuradas
- [ ] Base de datos creada y migrada
- [ ] Certificados SSL configurados (si aplica)

### **Despliegue**
- [ ] Código desplegado en servidor
- [ ] Dependencias instaladas
- [ ] Servicios configurados y iniciados
- [ ] Firewall configurado
- [ ] Backups configurados
- [ ] Monitoreo configurado

### **Post-Despliegue**
- [ ] Pruebas de conectividad
- [ ] Pruebas de autenticación
- [ ] Pruebas de notificaciones push
- [ ] Pruebas de sincronización
- [ ] Documentación actualizada
- [ ] Equipo entrenado

---

Esta documentación proporciona una guía completa para el despliegue del Sistema PAE Cauca en producción. Para soporte adicional, consultar los logs del sistema y la documentación técnica específica de cada componente.
