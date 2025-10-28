#!/bin/bash

echo "📱 GENERANDO APK DE LA APLICACIÓN"
echo "================================="

# 1. Navegar al directorio del proyecto
echo "1️⃣ Navegando al proyecto Flutter..."
cd frontend_visitas
pwd

# 2. Verificar que estamos en el directorio correcto
echo "2️⃣ Verificando directorio..."
if [ -f "pubspec.yaml" ]; then
    echo "✅ Proyecto Flutter encontrado"
else
    echo "❌ No se encontró pubspec.yaml"
    exit 1
fi

# 3. Limpiar proyecto
echo "3️⃣ Limpiando proyecto..."
flutter clean

# 4. Obtener dependencias
echo "4️⃣ Obteniendo dependencias..."
flutter pub get

# 5. Verificar configuración
echo "5️⃣ Verificando configuración..."
echo "Configuración actual:"
grep "const String baseUrl" lib/config.dart

# 6. Verificar Flutter doctor
echo "6️⃣ Verificando Flutter doctor..."
flutter doctor --no-version-check

# 7. Generar APK
echo "7️⃣ Generando APK..."
flutter build apk --release

# 8. Verificar APK generado
echo "8️⃣ Verificando APK generado..."
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    echo "✅ APK generado exitosamente!"
    ls -la build/app/outputs/flutter-apk/
    echo ""
    echo "📱 APK disponible en:"
    echo "build/app/outputs/flutter-apk/app-release.apk"
else
    echo "❌ Error al generar APK"
    exit 1
fi

echo ""
echo "================================="
echo "🎉 APK generado exitosamente!"
echo "📱 Instalar en emulador Android"
echo "🌐 Backend configurado para: http://10.0.2.2:8000"
echo "================================="
