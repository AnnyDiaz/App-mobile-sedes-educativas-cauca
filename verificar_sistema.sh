#!/bin/bash

echo "🐳 VERIFICANDO SISTEMA DESPLEGADO"
echo "================================="

echo "1️⃣ Verificando contenedores..."
sudo docker ps

echo ""
echo "2️⃣ Verificando logs de la API..."
sudo docker logs visitas_api --tail=20

echo ""
echo "3️⃣ Verificando logs de la base de datos..."
sudo docker logs visitas_db --tail=10

echo ""
echo "4️⃣ Probando API..."
curl -s http://localhost:8000/ || echo "❌ API no responde"

echo ""
echo "5️⃣ Probando municipios..."
curl -s http://localhost:8000/api/municipios | head -c 100 || echo "❌ Municipios no disponibles"

echo ""
echo "6️⃣ Probando login..."
curl -s -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"correo":"admin@test.com","contrasena":"admin"}' | head -c 200 || echo "❌ Login no funciona"

echo ""
echo "7️⃣ Inicializando sistema si es necesario..."
sudo docker exec visitas_api python -c "
import os
import sys
os.environ['DATABASE_URL'] = 'postgresql://postgres:postgres@visitas_db:5432/visitas_cauca'
sys.path.append('/app')
try:
    from app.scripts.init_admin_system import main
    main()
    print('✅ Sistema inicializado correctamente')
except Exception as e:
    print(f'⚠️ Sistema ya inicializado o error: {e}')
"

echo ""
echo "================================="
echo "🎉 Verificación completada"
echo "📱 API: http://localhost:8000"
echo "📚 Docs: http://localhost:8000/docs"
echo "🔐 Login: admin@test.com / admin"
