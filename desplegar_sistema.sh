#!/bin/bash
# Script de despliegue completo para App Sedes Educativas Cauca
# Este script automatiza todo el proceso de actualización y despliegue

set -e  # Salir si hay algún error

echo "🚀 Iniciando despliegue completo del sistema..."

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir mensajes con color
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar que estamos en el directorio correcto
if [ ! -f "docker-compose.yml" ]; then
    print_error "No se encontró docker-compose.yml. Ejecuta este script desde el directorio raíz del proyecto."
    exit 1
fi

# Paso 1: Verificar cambios pendientes
print_status "Verificando cambios pendientes en Git..."
if [ -n "$(git status --porcelain)" ]; then
    print_warning "Hay cambios sin commitear. ¿Deseas hacer commit automático? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        git add .
        git commit -m "Auto-commit: Actualización del sistema antes del despliegue"
        print_success "Cambios commiteados"
    else
        print_warning "Continuando sin commitear cambios..."
    fi
else
    print_success "No hay cambios pendientes"
fi

# Paso 2: Detener contenedores existentes
print_status "Deteniendo contenedores existentes..."
docker-compose down 2>/dev/null || true
print_success "Contenedores detenidos"

# Paso 3: Limpiar sistema Docker (opcional)
print_status "¿Deseas limpiar el sistema Docker completamente? (y/n)"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    print_status "Limpiando sistema Docker..."
    docker system prune -a -f
    print_success "Sistema Docker limpiado"
fi

# Paso 4: Reconstruir y ejecutar contenedores
print_status "Reconstruyendo y ejecutando contenedores..."
docker-compose up -d --build
print_success "Contenedores reconstruidos y ejecutándose"

# Paso 5: Esperar a que los contenedores estén listos
print_status "Esperando a que los contenedores estén listos..."
sleep 10

# Paso 6: Verificar que los contenedores estén funcionando
print_status "Verificando estado de los contenedores..."
if docker ps | grep -q "visitas_api"; then
    print_success "Contenedor de API está funcionando"
else
    print_error "Contenedor de API no está funcionando"
    exit 1
fi

if docker ps | grep -q "visitas_db"; then
    print_success "Contenedor de base de datos está funcionando"
else
    print_error "Contenedor de base de datos no está funcionando"
    exit 1
fi

# Paso 7: Ejecutar script de limpieza del sistema
print_status "Ejecutando script de limpieza del sistema..."
docker exec visitas_api python -c "
import os
os.environ['DATABASE_URL'] = 'postgresql://postgres:postgres@visitas_db:5432/visitas_cauca'
import sys
sys.path.append('.')
exec(open('app/scripts/limpiar_sistema.py').read())
"

if [ $? -eq 0 ]; then
    print_success "Sistema limpiado correctamente"
else
    print_error "Error al limpiar el sistema"
    exit 1
fi

# Paso 8: Verificar API
print_status "Verificando que la API esté funcionando..."
sleep 5

# Probar endpoint de salud
if curl -s http://localhost:8000/ > /dev/null; then
    print_success "API está respondiendo"
else
    print_error "API no está respondiendo"
    exit 1
fi

# Probar endpoint de municipios
if curl -s http://localhost:8000/api/municipios > /dev/null; then
    print_success "Endpoint de municipios está funcionando"
else
    print_warning "Endpoint de municipios no está respondiendo"
fi

# Paso 9: Probar login de administrador
print_status "Probando login de administrador..."
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"correo": "admin@test.com", "contrasena": "admin"}')

if echo "$LOGIN_RESPONSE" | grep -q "access_token"; then
    print_success "Login de administrador funciona correctamente"
else
    print_warning "Login de administrador no funciona: $LOGIN_RESPONSE"
fi

# Paso 10: Mostrar información del sistema
print_status "Información del sistema:"
echo "  🌐 API disponible en: http://localhost:8000"
echo "  📚 Documentación API: http://localhost:8000/docs"
echo "  👤 Usuario administrador: admin@test.com"
echo "  🔑 Contraseña: admin"
echo "  🗄️ Base de datos: PostgreSQL en puerto 5432"

# Paso 11: Mostrar logs de los contenedores
print_status "Mostrando logs recientes de los contenedores..."
echo "--- Logs del contenedor de API ---"
docker logs --tail=10 visitas_api

echo ""
echo "--- Logs del contenedor de base de datos ---"
docker logs --tail=5 visitas_db

# Paso 12: Instrucciones finales
print_success "🎉 Despliegue completado exitosamente!"
echo ""
echo "📋 Próximos pasos:"
echo "  1. Abre la app móvil Flutter"
echo "  2. Configura la URL en frontend_visitas/lib/config.dart si es necesario"
echo "  3. Haz login con admin@test.com / admin"
echo "  4. Verifica que el dashboard de administrador funcione"
echo "  5. Prueba la carga de municipios e instituciones"
echo ""
echo "🔧 Comandos útiles:"
echo "  - Ver logs: docker logs -f visitas_api"
echo "  - Entrar al contenedor: docker exec -it visitas_api bash"
echo "  - Detener sistema: docker-compose down"
echo "  - Reiniciar sistema: docker-compose restart"
echo ""
echo "📞 Si hay problemas:"
echo "  - Revisa los logs: docker logs visitas_api"
echo "  - Verifica la configuración de red"
echo "  - Asegúrate de que el puerto 8000 esté disponible"
