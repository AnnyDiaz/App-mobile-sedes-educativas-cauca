#!/bin/bash

echo "🐳 VERIFICANDO ESTADO DEL CONTENEDOR DOCKER"
echo "=========================================="

echo "1️⃣ Contenedores ejecutándose:"
sudo docker ps 2>/dev/null || echo "❌ Error al ejecutar docker ps"

echo ""
echo "2️⃣ Todos los contenedores (incluyendo detenidos):"
sudo docker ps -a 2>/dev/null || echo "❌ Error al ejecutar docker ps -a"

echo ""
echo "3️⃣ Logs de la API (últimas 10 líneas):"
sudo docker logs visitas_api --tail=10 2>/dev/null || echo "❌ Error al obtener logs de visitas_api"

echo ""
echo "4️⃣ Logs de la base de datos (últimas 5 líneas):"
sudo docker logs visitas_db --tail=5 2>/dev/null || echo "❌ Error al obtener logs de visitas_db"

echo ""
echo "5️⃣ Probando conectividad con la API:"
curl -s http://localhost:8000/ > /dev/null && echo "✅ API accesible en localhost:8000" || echo "❌ API no accesible en localhost:8000"

echo ""
echo "6️⃣ Probando endpoint de municipios:"
curl -s http://localhost:8000/api/municipios > /dev/null && echo "✅ Municipios accesibles" || echo "❌ Municipios no accesibles"

echo ""
echo "7️⃣ Estado de Docker Compose:"
sudo docker-compose ps 2>/dev/null || echo "❌ Error al ejecutar docker-compose ps"

echo ""
echo "=========================================="
echo "🔧 COMANDOS ÚTILES:"
echo "• Reiniciar contenedores: sudo docker-compose restart"
echo "• Ver logs completos: sudo docker logs visitas_api"
echo "• Detener sistema: sudo docker-compose down"
echo "• Iniciar sistema: sudo docker-compose up -d"
echo "=========================================="
