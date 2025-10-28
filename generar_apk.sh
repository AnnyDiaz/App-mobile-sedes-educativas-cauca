#!/bin/bash

echo "📱 INSTALANDO FLUTTER Y GENERANDO APK"
echo "====================================="

# 1. Instalar dependencias
echo "1️⃣ Instalando dependencias..."
sudo apt update -y
sudo apt install -y curl git unzip xz-utils zip libglu1-mesa openjdk-17-jdk

# 2. Descargar Flutter
echo "2️⃣ Descargando Flutter..."
cd ~
if [ ! -d "flutter" ]; then
    curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz
    tar xf flutter_linux_3.24.5-stable.tar.xz
    rm flutter_linux_3.24.5-stable.tar.xz
fi

# 3. Agregar Flutter al PATH
echo "3️⃣ Configurando PATH..."
export PATH="$PATH:$HOME/flutter/bin"
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc

# 4. Verificar instalación
echo "4️⃣ Verificando Flutter..."
flutter --version

# 5. Configurar Flutter
echo "5️⃣ Configurando Flutter..."
flutter config --no-analytics
flutter doctor

# 6. Navegar al proyecto
echo "6️⃣ Navegando al proyecto..."
cd /mnt/c/Users/ANNY/Desktop/App-mobile-sedes-educativas-cauca/frontend_visitas

# 7. Limpiar proyecto
echo "7️⃣ Limpiando proyecto..."
flutter clean

# 8. Obtener dependencias
echo "8️⃣ Obteniendo dependencias..."
flutter pub get

# 9. Verificar configuración
echo "9️⃣ Verificando configuración..."
flutter doctor

# 10. Generar APK
echo "🔟 Generando APK..."
flutter build apk --release

# 11. Verificar APK generado
echo "1️⃣1️⃣ Verificando APK generado..."
ls -la build/app/outputs/flutter-apk/

echo ""
echo "====================================="
echo "🎉 APK generado exitosamente!"
echo "📱 Ubicación: build/app/outputs/flutter-apk/"
echo "📄 Archivo: app-release.apk"
echo "====================================="
