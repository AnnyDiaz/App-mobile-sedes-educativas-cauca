#!/usr/bin/env python3
"""
Configuración de Email para el Sistema de Notificaciones

Para habilitar el envío real de emails:
1. Configura las variables de entorno o edita las constantes aquí
2. Descomenta el código de envío real en app/routes/admin_basic.py
3. Usa App Passwords para Gmail (no la contraseña normal)

Proveedores SMTP recomendados:
- Gmail: smtp.gmail.com:587
- Outlook: smtp-mail.outlook.com:587  
- SendGrid: smtp.sendgrid.net:587
- Mailgun: smtp.mailgun.org:587
"""

import os
from typing import Dict, Any

# Configuración de email del sistema
EMAIL_CONFIG = {
    # Servidor SMTP
    "smtp_server": os.getenv("SMTP_SERVER", "smtp.gmail.com"),
    "smtp_port": int(os.getenv("SMTP_PORT", "587")),
    
    # Credenciales del remitente
    "sender_email": os.getenv("SENDER_EMAIL", "sistema.visitas.cauca@gmail.com"),
    "sender_password": os.getenv("SENDER_PASSWORD", ""),  # App password, NO la contraseña normal
    "sender_name": os.getenv("SENDER_NAME", "Sistema de Visitas Cauca"),
    
    # Configuración de emails
    "use_tls": True,
    "timeout": 30,
    
    # Templates
    "subject_prefix": "🔔",
    "footer_text": "Sistema de Visitas Educativas del Cauca",
}

def get_email_template(usuario_nombre: str, notificacion: Dict[str, Any]) -> str:
    """
    Genera el template HTML para emails de notificación.
    """
    from datetime import datetime
    
    # Mapeo de tipos a colores
    type_colors = {
        "info": "#2196F3",
        "warning": "#FF9800", 
        "error": "#F44336",
        "success": "#4CAF50"
    }
    
    color = type_colors.get(notificacion['tipo'], "#2196F3")
    
    return f"""
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>{notificacion['titulo']}</title>
        <style>
            * {{ margin: 0; padding: 0; box-sizing: border-box; }}
            body {{ 
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
                background-color: #f8f9fa; 
                line-height: 1.6;
                color: #333;
            }}
            .email-container {{ 
                max-width: 600px; 
                margin: 20px auto; 
                background: white; 
                border-radius: 12px; 
                box-shadow: 0 4px 20px rgba(0,0,0,0.1);
                overflow: hidden;
            }}
            .header {{ 
                background: linear-gradient(135deg, #2E7D32, #4CAF50);
                color: white; 
                padding: 30px 20px; 
                text-align: center; 
            }}
            .header h1 {{ 
                font-size: 24px; 
                margin-bottom: 8px;
                font-weight: 600;
            }}
            .header p {{ 
                opacity: 0.9; 
                font-size: 14px;
            }}
            .content {{ 
                padding: 30px; 
            }}
            .greeting {{ 
                font-size: 18px; 
                margin-bottom: 20px;
                color: #2E7D32;
                font-weight: 500;
            }}
            .notification-card {{ 
                background: #f8f9fa; 
                padding: 25px; 
                border-radius: 8px; 
                border-left: 4px solid {color};
                margin: 20px 0;
                position: relative;
            }}
            .type-badge {{ 
                display: inline-block; 
                background: {color}; 
                color: white; 
                padding: 6px 12px; 
                border-radius: 20px; 
                font-size: 12px; 
                font-weight: 600;
                text-transform: uppercase;
                margin-bottom: 12px;
            }}
            .notification-title {{ 
                font-size: 20px; 
                font-weight: 600; 
                margin: 12px 0;
                color: #2c3e50;
            }}
            .notification-message {{ 
                font-size: 16px; 
                color: #555;
                margin-bottom: 15px;
            }}
            .metadata {{ 
                background: #e9ecef; 
                padding: 15px; 
                border-radius: 6px; 
                font-size: 14px;
                color: #666;
            }}
            .metadata strong {{ 
                color: #2E7D32; 
            }}
            .divider {{ 
                height: 1px; 
                background: #e9ecef; 
                margin: 25px 0; 
            }}
            .tip {{ 
                background: #e8f5e8; 
                border: 1px solid #c8e6c9; 
                padding: 15px; 
                border-radius: 6px; 
                font-size: 14px;
                color: #2e7d32;
            }}
            .footer {{ 
                background: #2c3e50; 
                color: #ecf0f1; 
                padding: 20px; 
                text-align: center; 
                font-size: 12px;
            }}
            .footer a {{ 
                color: #3498db; 
                text-decoration: none; 
            }}
            .icon {{ 
                font-size: 18px; 
                margin-right: 8px;
            }}
            @media (max-width: 600px) {{
                .email-container {{ margin: 0; border-radius: 0; }}
                .content {{ padding: 20px; }}
                .header {{ padding: 20px; }}
            }}
        </style>
    </head>
    <body>
        <div class="email-container">
            <div class="header">
                <h1>🏛️ Sistema de Visitas Cauca</h1>
                <p>Plataforma de Gestión Educativa</p>
            </div>
            
            <div class="content">
                <div class="greeting">
                    👋 Hola <strong>{usuario_nombre}</strong>,
                </div>
                
                <div class="notification-card">
                    <div class="type-badge">
                        {notificacion['tipo'].upper()}
                    </div>
                    
                    <div class="notification-title">
                        {notificacion['titulo']}
                    </div>
                    
                    <div class="notification-message">
                        {notificacion['mensaje']}
                    </div>
                    
                    <div class="metadata">
                        <div><span class="icon">📅</span><strong>Fecha:</strong> {datetime.now().strftime('%d/%m/%Y a las %H:%M')}</div>
                        <div><span class="icon">🏷️</span><strong>Categoría:</strong> {notificacion['categoria'].replace('_', ' ').title()}</div>
                        <div><span class="icon">🆔</span><strong>ID:</strong> {notificacion['id']}</div>
                    </div>
                </div>
                
                <div class="divider"></div>
                
                <div class="tip">
                    <span class="icon">💡</span>
                    <strong>Consejo:</strong> Puedes personalizar tus preferencias de notificaciones 
                    desde el panel administrativo del sistema. ¡Mantente siempre informado de lo que importa!
                </div>
            </div>
            
            <div class="footer">
                <p><strong>📧 Sistema de Notificaciones Automatizadas</strong></p>
                <p>{EMAIL_CONFIG['footer_text']}</p>
                <p style="margin-top: 10px; opacity: 0.7;">
                    Este es un mensaje automático. Para soporte, contacta al administrador del sistema.
                </p>
            </div>
        </div>
    </body>
    </html>
    """

def validate_email_config() -> bool:
    """
    Valida si la configuración de email está completa.
    """
    required_fields = ["sender_email", "sender_password"]
    
    for field in required_fields:
        if not EMAIL_CONFIG.get(field):
            print(f"❌ Falta configuración: {field}")
            return False
    
    if "@" not in EMAIL_CONFIG["sender_email"]:
        print("❌ Email del remitente inválido")
        return False
    
    return True

def get_smtp_config() -> Dict[str, Any]:
    """
    Retorna la configuración SMTP para uso en el sistema.
    """
    return {
        "server": EMAIL_CONFIG["smtp_server"],
        "port": EMAIL_CONFIG["smtp_port"],
        "email": EMAIL_CONFIG["sender_email"],
        "password": EMAIL_CONFIG["sender_password"],
        "name": EMAIL_CONFIG["sender_name"],
        "use_tls": EMAIL_CONFIG["use_tls"],
        "timeout": EMAIL_CONFIG["timeout"]
    }

if __name__ == "__main__":
    print("🔧 CONFIGURACIÓN DE EMAIL PARA NOTIFICACIONES")
    print("=" * 50)
    
    print(f"📧 Servidor SMTP: {EMAIL_CONFIG['smtp_server']}:{EMAIL_CONFIG['smtp_port']}")
    print(f"👤 Remitente: {EMAIL_CONFIG['sender_name']} <{EMAIL_CONFIG['sender_email']}>")
    print(f"🔒 Contraseña configurada: {'✅ Sí' if EMAIL_CONFIG['sender_password'] else '❌ No'}")
    print(f"🔐 TLS habilitado: {'✅ Sí' if EMAIL_CONFIG['use_tls'] else '❌ No'}")
    
    print("\n📋 ESTADO DE CONFIGURACIÓN:")
    if validate_email_config():
        print("✅ Configuración completa - Listo para envío real")
    else:
        print("⚠️ Configuración incompleta - Solo modo simulación")
    
    print("\n🚀 PARA HABILITAR ENVÍO REAL:")
    print("1. Configura SENDER_EMAIL y SENDER_PASSWORD como variables de entorno")
    print("2. Para Gmail, usa App Passwords (no la contraseña normal)")
    print("3. Descomenta el código de envío en app/routes/admin_basic.py")
    print("4. Reinicia el servidor FastAPI")
    
    print("\n🔗 GUÍAS ÚTILES:")
    print("• Gmail App Passwords: https://support.google.com/accounts/answer/185833")
    print("• SendGrid API: https://sendgrid.com/docs/for-developers/sending-email/")
    print("• Mailgun SMTP: https://help.mailgun.com/hc/en-us/articles/203380100")
