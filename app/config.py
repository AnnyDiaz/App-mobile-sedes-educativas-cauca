# app/config.py

import os
from typing import Optional

# Configuración de Firebase Cloud Messaging (FCM)
FCM_SERVER_KEY = os.getenv("FCM_SERVER_KEY", "")
FCM_PROJECT_ID = os.getenv("FCM_PROJECT_ID", "")

# Configuración de notificaciones
NOTIFICACIONES_ENABLED = os.getenv("NOTIFICACIONES_ENABLED", "true").lower() == "true"
NOTIFICACIONES_MAX_RETRY = int(os.getenv("NOTIFICACIONES_MAX_RETRY", "3"))
NOTIFICACIONES_TIMEOUT = int(os.getenv("NOTIFICACIONES_TIMEOUT", "30"))

# Configuración de recordatorios automáticos
RECORDATORIOS_VISITA_PROXIMA_HORAS = int(os.getenv("RECORDATORIOS_VISITA_PROXIMA_HORAS", "24"))
RECORDATORIOS_VISITA_VENCIDA_DIAS = int(os.getenv("RECORDATORIOS_VISITA_VENCIDA_DIAS", "7"))

# Configuración de limpieza de notificaciones
LIMPIAR_NOTIFICACIONES_ANTIGUAS_DIAS = int(os.getenv("LIMPIAR_NOTIFICACIONES_ANTIGUAS_DIAS", "30"))

# URLs de FCM
FCM_SEND_URL = "https://fcm.googleapis.com/fcm/send"
FCM_TOPIC_SUBSCRIBE_URL = "https://iid.googleapis.com/iid/v1:batchAdd"
FCM_TOPIC_UNSUBSCRIBE_URL = "https://iid.googleapis.com/iid/v1:batchRemove"

# Headers para FCM
FCM_HEADERS = {
    "Authorization": f"key={FCM_SERVER_KEY}",
    "Content-Type": "application/json"
}

# Configuración de notificaciones por defecto
NOTIFICACIONES_DEFAULT = {
    "visita_proxima": {
        "titulo": "Visita Próxima",
        "prioridad": "alta",
        "icono": "schedule"
    },
    "visita_vencida": {
        "titulo": "Visita Vencida",
        "prioridad": "urgente",
        "icono": "warning"
    },
    "recordatorio": {
        "titulo": "Recordatorio",
        "prioridad": "normal",
        "icono": "notifications"
    },
    "sistema": {
        "titulo": "Sistema",
        "prioridad": "baja",
        "icono": "info"
    }
}
