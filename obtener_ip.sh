#!/bin/bash

echo "🌐 OBTENIENDO IP PARA LA APK"
echo "============================"

echo "1️⃣ IP de WSL2:"
ip addr show eth0 | grep "inet " | awk '{print $2}' | cut -d/ -f1

echo ""
echo "2️⃣ IP de Windows (desde WSL2):"
ip route | grep default | awk '{print $3}'

echo ""
echo "3️⃣ IPs disponibles en la red:"
ip addr show | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | cut -d/ -f1

echo ""
echo "📱 CONFIGURACIÓN PARA LA APK:"
echo "============================="
echo "• Para EMULADOR Android: http://10.0.2.2:8000"
echo "• Para DISPOSITIVO REAL: http://[IP_DE_TU_COMPUTADORA]:8000"
echo ""
echo "🔧 Para obtener la IP de Windows desde PowerShell:"
echo "ipconfig | findstr IPv4"
