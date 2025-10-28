#!/bin/bash

echo "🌐 VERIFICANDO IP DEL SISTEMA"
echo "============================="

echo "1️⃣ IP de WSL2:"
ip addr show eth0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1 || echo "No se pudo obtener"

echo ""
echo "2️⃣ IP de Windows (desde WSL2):"
ip route | grep default | awk '{print $3}' || echo "No se pudo obtener"

echo ""
echo "3️⃣ Todas las IPs disponibles:"
ip addr show | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | cut -d/ -f1 || echo "No se pudo obtener"

echo ""
echo "4️⃣ Verificando conectividad con Docker:"
curl -s http://localhost:8000/ > /dev/null && echo "✅ Backend accesible en localhost:8000" || echo "❌ Backend no accesible en localhost:8000"

echo ""
echo "📱 CONFIGURACIÓN RECOMENDADA PARA LA APK:"
echo "=========================================="
echo "• Para EMULADOR Android: http://10.0.2.2:8000"
echo "• Para DISPOSITIVO REAL: http://[IP_DE_WINDOWS]:8000"
echo ""
echo "🔧 Para obtener la IP de Windows desde PowerShell:"
echo "ipconfig | findstr IPv4"
