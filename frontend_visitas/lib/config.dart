// lib/config.dart

// CONFIGURACIÓN PARA DIFERENTES ENTORNOS
// Descomenta la línea que corresponda a tu entorno

// 🏠 DESARROLLO LOCAL (Emulador Android)
//const String baseUrl = 'http://10.10.140.40:8000';
//const String baseUrl = 'http://192.168.240.64:8000';
// 🖥️ DESARROLLO LOCAL (Dispositivo real - IP de tu computadora)
//const String baseUrl = 'http://192.168.1.83:8000';  // Tu IP real
//const String baseUrl = 'http://172.19.0.214:8000'; 
//const String baseUrl = 'http://localhost:8000';  // Para pruebas locales y web
//const String baseUrl = 'http://10.0.2.15:8000'; // ✅ ¡ACTIVA ESTA! (IP de tu Kali)

// 🐳 DOCKER CONTAINER (Servidor en contenedor)
const String baseUrl = 'http://192.168.1.60:8000'; // IP del contenedor Docker

// 🌐 PRODUCCIÓN (Servidor remoto)
// const String baseUrl = 'http://138.0.90.98:1912';

// 📱 NOTAS IMPORTANTES:
// 1. Para EMULADOR: usa 10.0.2.2:8000
// 2. Para DISPOSITIVO REAL: usa la IP de tu computadora (192.168.1.83)
// 3. Para obtener tu IP: ejecuta 'ipconfig' en Windows
// 4. Asegúrate de que el firewall permita conexiones al puerto 8000
// 5. Para DOCKER: usa la IP del contenedor o del host donde corre Docker