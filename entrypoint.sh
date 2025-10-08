#!/bin/bash
set -e

echo "🚀 Iniciando contenedor de la aplicación..."

# Función para esperar a que la base de datos esté disponible
wait_for_db() {
    echo "🔄 Esperando a que la base de datos esté disponible..."
    
    # Extraer información de la base de datos de DATABASE_URL
    DB_HOST=$(echo $DATABASE_URL | sed 's/.*@\([^:]*\):.*/\1/')
    DB_PORT=$(echo $DATABASE_URL | sed 's/.*:\([0-9]*\)\/.*/\1/')
    
    echo "📊 Conectando a: $DB_HOST:$DB_PORT"
    
    # Esperar hasta que la base de datos esté disponible
    until python -c "
import sys
import os
sys.path.append('/app')
from sqlalchemy import create_engine, text
try:
    engine = create_engine(os.getenv('DATABASE_URL'))
    with engine.connect() as conn:
        conn.execute(text('SELECT 1'))
    print('✅ Base de datos disponible')
    sys.exit(0)
except Exception as e:
    print(f'⏳ Base de datos no disponible aún: {e}')
    sys.exit(1)
"; do
        echo "⏳ Esperando a que la base de datos esté disponible..."
        sleep 2
    done
}

# Esperar a que la base de datos esté disponible
wait_for_db

# Ejecutar script de inicialización
echo "🔧 Ejecutando inicialización de la base de datos..."
python app/scripts/init_db.py

# Verificar que la inicialización fue exitosa
if [ $? -eq 0 ]; then
    echo "✅ Inicialización completada exitosamente"
else
    echo "❌ Error en la inicialización"
    exit 1
fi

# Iniciar la aplicación
echo "🚀 Iniciando aplicación FastAPI..."
exec uvicorn main:app --host 0.0.0.0 --port 8000

