# 🔌 Documentación Completa de API Endpoints - Sistema PAE Cauca

## 📋 Índice de Endpoints

### 🔐 Autenticación (`/api/auth`)
- [POST `/api/auth/register`](#post-apiauthregister)
- [POST `/api/auth/login`](#post-apiauthlogin)
- [POST `/api/auth/refresh`](#post-apiauthrefresh)
- [GET `/api/auth/me`](#get-apiauthme)
- [PUT `/api/auth/me/cambiar-contrasena`](#put-apiauthmecambiar-contrasena)
- [POST `/api/auth/olvidaste-contrasena`](#post-apiautholvidaste-contrasena)
- [POST `/api/auth/verificar-codigo`](#post-apiauthverificar-codigo)
- [POST `/api/auth/cambiar-contrasena`](#post-apiauthcambiar-contrasena)

### 🏫 Estructura Educativa
- [GET `/api/municipios`](#get-apimunicipios)
- [GET `/api/instituciones`](#get-apiinstituciones)
- [GET `/api/instituciones/{municipio_id}`](#get-apiinstitucionesmunicipio_id)
- [GET `/api/sedes`](#get-apisedes)
- [GET `/api/sedes/{institucion_id}`](#get-apisedesinstitucion_id)

### 👥 Usuarios (`/api/usuarios`)
- [GET `/api/usuarios`](#get-apiusuarios)
- [GET `/api/usuarios/{usuario_id}`](#get-apiusuariosusuario_id)
- [POST `/api/usuarios`](#post-apiusuarios)
- [PUT `/api/usuarios/{usuario_id}`](#put-apiusuariosusuario_id)
- [DELETE `/api/usuarios/{usuario_id}`](#delete-apiusuariosusuario_id)

### 📋 Visitas PAE (`/api/visitas-completas-pae`)
- [POST `/api/visitas-completas-pae`](#post-apivisitas-completas-pae)
- [GET `/api/visitas-completas-pae`](#get-apivisitas-completas-pae)
- [GET `/api/visitas-completas-pae/pendientes`](#get-apivisitas-completas-paependientes)
- [GET `/api/visitas-completas-pae/{visita_id}`](#get-apivisitas-completas-paevisita_id)
- [GET `/api/visitas-completas-pae/{visita_id}/excel`](#get-apivisitas-completas-paevisita_idexcel)
- [PUT `/api/visitas-completas-pae/{visita_id}/estado`](#put-apivisitas-completas-paevisita_idestado)

### 📅 Visitas Asignadas (`/api/visitas-asignadas`)
- [GET `/api/visitas-asignadas`](#get-apivisitas-asignadas)
- [POST `/api/visitas-asignadas`](#post-apivisitas-asignadas)
- [PUT `/api/visitas-asignadas/{visita_id}`](#put-apivisitas-asignadasvisita_id)

### 📊 Dashboard (`/api/dashboard`)
- [GET `/api/dashboard/estadisticas`](#get-apidashboardestadisticas)
- [GET `/api/dashboard/visitas-recientes`](#get-apidashboardvisitas-recientes)

### 🔔 Notificaciones (`/api/notificaciones`)
- [POST `/api/notificaciones/registrar-dispositivo`](#post-apinotificacionesregistrar-dispositivo)
- [GET `/api/notificaciones`](#get-apinotificaciones)
- [POST `/api/notificaciones/enviar`](#post-apinotificacionesenviar)
- [PUT `/api/notificaciones/{notificacion_id}/marcar-leida`](#put-apinotificacionesnotificacion_idmarcar-leida)

### 📈 Reportes (`/api/reportes`)
- [GET `/api/reportes/visitas-excel`](#get-apireportesvisitas-excel)
- [GET `/api/reportes/visitas-pdf`](#get-apireportesvisitas-pdf)

---

## 🔐 Autenticación

### POST `/api/auth/register`
Registra un nuevo usuario en el sistema.

**Request Body:**
```json
{
  "nombre": "Juan Pérez",
  "correo": "juan@example.com",
  "contrasena": "password123",
  "rol_id": 1
}
```

**Response (201):**
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "token_type": "bearer",
  "usuario": {
    "id": 1,
    "nombre": "Juan Pérez",
    "correo": "juan@example.com",
    "rol": {
      "id": 1,
      "nombre": "visitador"
    }
  }
}
```

**Rate Limit:** 3 requests/minute

---

### POST `/api/auth/login`
Inicia sesión con email y contraseña.

**Request Body:**
```json
{
  "correo": "juan@example.com",
  "contrasena": "password123"
}
```

**Response (200):**
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "token_type": "bearer",
  "usuario": {
    "id": 1,
    "nombre": "Juan Pérez",
    "correo": "juan@example.com",
    "rol": {
      "id": 1,
      "nombre": "visitador"
    }
  }
}
```

**Rate Limit:** 5 requests/minute

---

### POST `/api/auth/refresh`
Renueva el access token usando el refresh token.

**Request Body:**
```json
{
  "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
}
```

**Response (200):**
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "token_type": "bearer"
}
```

---

### GET `/api/auth/me`
Obtiene la información del usuario autenticado.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200):**
```json
{
  "id": 1,
  "nombre": "Juan Pérez",
  "correo": "juan@example.com",
  "rol": {
    "id": 1,
    "nombre": "visitador"
  }
}
```

---

### PUT `/api/auth/me/cambiar-contrasena`
Cambia la contraseña del usuario autenticado.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "actual": "password123",
  "nueva": "newpassword456"
}
```

**Response (200):**
```json
{
  "mensaje": "Contraseña actualizada correctamente"
}
```

---

### POST `/api/auth/olvidaste-contrasena`
Solicita un código de recuperación por email.

**Request Body:**
```json
{
  "correo": "juan@example.com"
}
```

**Response (200):**
```json
{
  "mensaje": "Código de verificación enviado exitosamente",
  "email": "juan@example.com"
}
```

**Rate Limit:** 3 requests/minute

---

### POST `/api/auth/verificar-codigo`
Verifica el código de recuperación.

**Request Body:**
```json
{
  "correo": "juan@example.com",
  "codigo": "123456"
}
```

**Response (200):**
```json
{
  "mensaje": "Código verificado correctamente",
  "valido": true,
  "email": "juan@example.com"
}
```

---

### POST `/api/auth/cambiar-contrasena`
Cambia la contraseña usando el código de verificación.

**Request Body:**
```json
{
  "correo": "juan@example.com",
  "codigo": "123456",
  "nueva_contrasena": "newpassword456"
}
```

**Response (200):**
```json
{
  "mensaje": "Contraseña cambiada exitosamente"
}
```

---

## 🏫 Estructura Educativa

### GET `/api/municipios`
Obtiene la lista de todos los municipios.

**Response (200):**
```json
[
  {
    "id": 1,
    "nombre": "Popayán"
  },
  {
    "id": 2,
    "nombre": "Santander de Quilichao"
  }
]
```

---

### GET `/api/instituciones`
Obtiene todas las instituciones educativas.

**Response (200):**
```json
[
  {
    "id": 1,
    "nombre": "Institución Educativa San José",
    "municipio_id": 1
  }
]
```

---

### GET `/api/instituciones/{municipio_id}`
Obtiene las instituciones de un municipio específico.

**Parameters:**
- `municipio_id` (int): ID del municipio

**Response (200):**
```json
[
  {
    "id": 1,
    "nombre": "Institución Educativa San José",
    "municipio_id": 1
  }
]
```

---

### GET `/api/sedes`
Obtiene todas las sedes educativas.

**Response (200):**
```json
[
  {
    "id": 1,
    "nombre": "Sede Principal",
    "dane": "190001001",
    "due": "DUE001",
    "lat": 2.4444,
    "lon": -76.6067,
    "principal": true,
    "municipio": {
      "id": 1,
      "nombre": "Popayán"
    },
    "institucion": {
      "id": 1,
      "nombre": "Institución Educativa San José"
    }
  }
]
```

---

### GET `/api/sedes/{institucion_id}`
Obtiene las sedes de una institución específica.

**Parameters:**
- `institucion_id` (int): ID de la institución

**Response (200):**
```json
[
  {
    "id": 1,
    "nombre": "Sede Principal",
    "dane": "190001001",
    "due": "DUE001",
    "lat": 2.4444,
    "lon": -76.6067,
    "principal": true,
    "municipio": {
      "id": 1,
      "nombre": "Popayán"
    },
    "institucion": {
      "id": 1,
      "nombre": "Institución Educativa San José"
    }
  }
]
```

---

## 👥 Usuarios

### GET `/api/usuarios`
Obtiene la lista de usuarios (requiere autenticación de administrador).

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200):**
```json
[
  {
    "id": 1,
    "nombre": "Juan Pérez",
    "correo": "juan@example.com",
    "rol": {
      "id": 1,
      "nombre": "visitador"
    }
  }
]
```

---

### GET `/api/usuarios/{usuario_id}`
Obtiene un usuario específico.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Parameters:**
- `usuario_id` (int): ID del usuario

**Response (200):**
```json
{
  "id": 1,
  "nombre": "Juan Pérez",
  "correo": "juan@example.com",
  "rol": {
    "id": 1,
    "nombre": "visitador"
  }
}
```

---

### POST `/api/usuarios`
Crea un nuevo usuario (requiere autenticación de administrador).

**Headers:**
```
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "nombre": "María García",
  "correo": "maria@example.com",
  "contrasena": "password123",
  "rol_id": 2
}
```

**Response (201):**
```json
{
  "id": 2,
  "nombre": "María García",
  "correo": "maria@example.com",
  "rol": {
    "id": 2,
    "nombre": "supervisor"
  }
}
```

---

### PUT `/api/usuarios/{usuario_id}`
Actualiza un usuario existente.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Parameters:**
- `usuario_id` (int): ID del usuario

**Request Body:**
```json
{
  "nombre": "María García Actualizada",
  "correo": "maria.actualizada@example.com"
}
```

**Response (200):**
```json
{
  "id": 2,
  "nombre": "María García Actualizada",
  "correo": "maria.actualizada@example.com",
  "rol": {
    "id": 2,
    "nombre": "supervisor"
  }
}
```

---

### DELETE `/api/usuarios/{usuario_id}`
Elimina un usuario (requiere autenticación de administrador).

**Headers:**
```
Authorization: Bearer <access_token>
```

**Parameters:**
- `usuario_id` (int): ID del usuario

**Response (200):**
```json
{
  "mensaje": "Usuario eliminado correctamente"
}
```

---

## 📋 Visitas PAE

### POST `/api/visitas-completas-pae`
Crea una visita completa PAE con checklist.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "fecha_visita": "2024-01-15T10:00:00",
  "contrato": "CONTRATO-001",
  "operador": "OPERADOR-ABC",
  "caso_atencion_prioritaria": "SI",
  "municipio_id": 1,
  "institucion_id": 1,
  "sede_id": 1,
  "profesional_id": 1,
  "observaciones": "Visita realizada correctamente",
  "respuestas_checklist": [
    {
      "item_id": 1,
      "respuesta": "Cumple",
      "observacion": "Cumple con todos los requisitos"
    },
    {
      "item_id": 2,
      "respuesta": "No Cumple",
      "observacion": "Requiere mejoras en infraestructura"
    }
  ]
}
```

**Response (201):**
```json
{
  "id": 1,
  "fecha_visita": "2024-01-15T10:00:00",
  "contrato": "CONTRATO-001",
  "operador": "OPERADOR-ABC",
  "caso_atencion_prioritaria": "SI",
  "municipio_id": 1,
  "institucion_id": 1,
  "sede_id": 1,
  "profesional_id": 1,
  "fecha_creacion": "2024-01-15T09:00:00",
  "estado": "completada",
  "observaciones": "Visita realizada correctamente",
  "municipio": {
    "id": 1,
    "nombre": "Popayán"
  },
  "institucion": {
    "id": 1,
    "nombre": "Institución Educativa San José"
  },
  "sede": {
    "id": 1,
    "nombre": "Sede Principal",
    "dane": "190001001",
    "due": "DUE001"
  },
  "profesional": {
    "id": 1,
    "nombre": "Juan Pérez",
    "correo": "juan@example.com"
  },
  "respuestas_checklist": [
    {
      "item_id": 1,
      "respuesta": "Cumple",
      "observacion": "Cumple con todos los requisitos"
    }
  ]
}
```

---

### GET `/api/visitas-completas-pae`
Obtiene todas las visitas completas PAE.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200):**
```json
[
  {
    "id": 1,
    "fecha_visita": "2024-01-15T10:00:00",
    "contrato": "CONTRATO-001",
    "operador": "OPERADOR-ABC",
    "caso_atencion_prioritaria": "SI",
    "municipio_id": 1,
    "institucion_id": 1,
    "sede_id": 1,
    "profesional_id": 1,
    "fecha_creacion": "2024-01-15T09:00:00",
    "estado": "completada",
    "observaciones": "Visita realizada correctamente",
    "municipio": {
      "id": 1,
      "nombre": "Popayán"
    },
    "institucion": {
      "id": 1,
      "nombre": "Institución Educativa San José"
    },
    "sede": {
      "id": 1,
      "nombre": "Sede Principal"
    },
    "profesional": {
      "id": 1,
      "nombre": "Juan Pérez"
    }
  }
]
```

---

### GET `/api/visitas-completas-pae/pendientes`
Obtiene solo las visitas pendientes.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200):**
```json
[
  {
    "id": 2,
    "fecha_visita": "2024-01-16T10:00:00",
    "contrato": "CONTRATO-002",
    "operador": "OPERADOR-DEF",
    "caso_atencion_prioritaria": "NO",
    "municipio_id": 1,
    "institucion_id": 1,
    "sede_id": 1,
    "profesional_id": 1,
    "fecha_creacion": "2024-01-15T09:00:00",
    "estado": "pendiente",
    "observaciones": null,
    "municipio": {
      "id": 1,
      "nombre": "Popayán"
    },
    "institucion": {
      "id": 1,
      "nombre": "Institución Educativa San José"
    },
    "sede": {
      "id": 1,
      "nombre": "Sede Principal"
    },
    "profesional": {
      "id": 1,
      "nombre": "Juan Pérez"
    }
  }
]
```

---

### GET `/api/visitas-completas-pae/{visita_id}`
Obtiene una visita específica.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Parameters:**
- `visita_id` (int): ID de la visita

**Response (200):**
```json
{
  "id": 1,
  "fecha_visita": "2024-01-15T10:00:00",
  "contrato": "CONTRATO-001",
  "operador": "OPERADOR-ABC",
  "caso_atencion_prioritaria": "SI",
  "municipio_id": 1,
  "institucion_id": 1,
  "sede_id": 1,
  "profesional_id": 1,
  "fecha_creacion": "2024-01-15T09:00:00",
  "estado": "completada",
  "observaciones": "Visita realizada correctamente",
  "municipio": {
    "id": 1,
    "nombre": "Popayán"
  },
  "institucion": {
    "id": 1,
    "nombre": "Institución Educativa San José"
  },
  "sede": {
    "id": 1,
    "nombre": "Sede Principal"
  },
  "profesional": {
    "id": 1,
    "nombre": "Juan Pérez"
  }
}
```

---

### GET `/api/visitas-completas-pae/{visita_id}/excel`
Genera un reporte Excel de una visita específica.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Parameters:**
- `visita_id` (int): ID de la visita

**Response (200):**
```
Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
Content-Disposition: attachment; filename=historial_visita_1.xlsx

[Archivo Excel binario]
```

---

### PUT `/api/visitas-completas-pae/{visita_id}/estado`
Actualiza el estado de una visita.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Parameters:**
- `visita_id` (int): ID de la visita

**Query Parameters:**
- `estado` (string): Nuevo estado (pendiente, completada, cancelada)

**Response (200):**
```json
{
  "mensaje": "Visita 1 actualizada a estado: completada",
  "visita_id": 1,
  "estado": "completada"
}
```

---

## 📅 Visitas Asignadas

### GET `/api/visitas-asignadas`
Obtiene las visitas asignadas al usuario autenticado.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200):**
```json
[
  {
    "id": 1,
    "sede_id": 1,
    "sede_nombre": "Sede Principal",
    "visitador_id": 1,
    "visitador_nombre": "Juan Pérez",
    "supervisor_id": 2,
    "supervisor_nombre": "María García",
    "fecha_programada": "2024-01-15T10:00:00",
    "tipo_visita": "PAE",
    "prioridad": "normal",
    "estado": "pendiente",
    "contrato": "CONTRATO-001",
    "operador": "OPERADOR-ABC",
    "caso_atencion_prioritaria": "SI",
    "municipio_id": 1,
    "municipio_nombre": "Popayán",
    "institucion_id": 1,
    "institucion_nombre": "Institución Educativa San José",
    "observaciones": null,
    "fecha_creacion": "2024-01-15T09:00:00",
    "fecha_inicio": null,
    "fecha_completada": null
  }
]
```

---

### POST `/api/visitas-asignadas`
Crea una nueva visita asignada (requiere rol de supervisor).

**Headers:**
```
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "sede_id": 1,
  "visitador_id": 1,
  "fecha_programada": "2024-01-20T10:00:00",
  "tipo_visita": "PAE",
  "prioridad": "alta",
  "contrato": "CONTRATO-003",
  "operador": "OPERADOR-GHI",
  "caso_atencion_prioritaria": "NO",
  "municipio_id": 1,
  "institucion_id": 1,
  "observaciones": "Visita de seguimiento"
}
```

**Response (201):**
```json
{
  "id": 2,
  "sede_id": 1,
  "sede_nombre": "Sede Principal",
  "visitador_id": 1,
  "visitador_nombre": "Juan Pérez",
  "supervisor_id": 2,
  "supervisor_nombre": "María García",
  "fecha_programada": "2024-01-20T10:00:00",
  "tipo_visita": "PAE",
  "prioridad": "alta",
  "estado": "pendiente",
  "contrato": "CONTRATO-003",
  "operador": "OPERADOR-GHI",
  "caso_atencion_prioritaria": "NO",
  "municipio_id": 1,
  "municipio_nombre": "Popayán",
  "institucion_id": 1,
  "institucion_nombre": "Institución Educativa San José",
  "observaciones": "Visita de seguimiento",
  "fecha_creacion": "2024-01-15T09:00:00",
  "fecha_inicio": null,
  "fecha_completada": null
}
```

---

### PUT `/api/visitas-asignadas/{visita_id}`
Actualiza una visita asignada.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Parameters:**
- `visita_id` (int): ID de la visita asignada

**Request Body:**
```json
{
  "estado": "en_proceso",
  "fecha_inicio": "2024-01-15T10:30:00",
  "observaciones": "Visita iniciada"
}
```

**Response (200):**
```json
{
  "id": 1,
  "sede_id": 1,
  "sede_nombre": "Sede Principal",
  "visitador_id": 1,
  "visitador_nombre": "Juan Pérez",
  "supervisor_id": 2,
  "supervisor_nombre": "María García",
  "fecha_programada": "2024-01-15T10:00:00",
  "tipo_visita": "PAE",
  "prioridad": "normal",
  "estado": "en_proceso",
  "contrato": "CONTRATO-001",
  "operador": "OPERADOR-ABC",
  "caso_atencion_prioritaria": "SI",
  "municipio_id": 1,
  "municipio_nombre": "Popayán",
  "institucion_id": 1,
  "institucion_nombre": "Institución Educativa San José",
  "observaciones": "Visita iniciada",
  "fecha_creacion": "2024-01-15T09:00:00",
  "fecha_inicio": "2024-01-15T10:30:00",
  "fecha_completada": null
}
```

---

## 📊 Dashboard

### GET `/api/dashboard/estadisticas`
Obtiene estadísticas generales del dashboard.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200):**
```json
{
  "total_visitas": 150,
  "visitas_completadas": 120,
  "visitas_pendientes": 25,
  "visitas_vencidas": 5,
  "usuarios_activos": 15,
  "municipios_cubiertos": 42,
  "instituciones_visitadas": 200,
  "sedes_visitadas": 350
}
```

---

### GET `/api/dashboard/visitas-recientes`
Obtiene las visitas más recientes.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200):**
```json
[
  {
    "id": 1,
    "fecha_visita": "2024-01-15T10:00:00",
    "sede_nombre": "Sede Principal",
    "municipio_nombre": "Popayán",
    "institucion_nombre": "Institución Educativa San José",
    "profesional_nombre": "Juan Pérez",
    "estado": "completada",
    "contrato": "CONTRATO-001"
  }
]
```

---

## 🔔 Notificaciones

### POST `/api/notificaciones/registrar-dispositivo`
Registra un dispositivo para recibir notificaciones push.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "token_dispositivo": "fcm_token_aqui",
  "plataforma": "android"
}
```

**Response (200):**
```json
{
  "mensaje": "Dispositivo registrado correctamente",
  "dispositivo_id": 1
}
```

---

### GET `/api/notificaciones`
Obtiene las notificaciones del usuario autenticado.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200):**
```json
[
  {
    "id": 1,
    "usuario_id": 1,
    "titulo": "Visita Próxima",
    "mensaje": "Tienes una visita programada para mañana a las 10:00 AM",
    "tipo": "visita_proxima",
    "prioridad": "alta",
    "leida": false,
    "fecha_envio": "2024-01-15T09:00:00",
    "fecha_lectura": null,
    "datos_adicionales": null
  }
]
```

---

### POST `/api/notificaciones/enviar`
Envía una notificación push (requiere rol de administrador).

**Headers:**
```
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "titulo": "Recordatorio Importante",
  "mensaje": "No olvides completar las visitas pendientes",
  "tipo": "recordatorio",
  "prioridad": "normal",
  "usuario_ids": [1, 2, 3],
  "datos_adicionales": {
    "visita_id": 1,
    "fecha_limite": "2024-01-20"
  }
}
```

**Response (200):**
```json
{
  "exitosas": 3,
  "fallidas": 0,
  "detalles": [
    {
      "usuario_id": 1,
      "enviada": true,
      "mensaje": "Notificación enviada correctamente"
    }
  ],
  "mensaje": "3 notificaciones enviadas exitosamente"
}
```

---

### PUT `/api/notificaciones/{notificacion_id}/marcar-leida`
Marca una notificación como leída.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Parameters:**
- `notificacion_id` (int): ID de la notificación

**Response (200):**
```json
{
  "mensaje": "Notificación marcada como leída",
  "notificacion_id": 1
}
```

---

## 📈 Reportes

### GET `/api/reportes/visitas-excel`
Genera un reporte Excel de todas las visitas.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Query Parameters:**
- `fecha_inicio` (string, optional): Fecha de inicio (YYYY-MM-DD)
- `fecha_fin` (string, optional): Fecha de fin (YYYY-MM-DD)
- `municipio_id` (int, optional): ID del municipio
- `estado` (string, optional): Estado de las visitas

**Response (200):**
```
Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
Content-Disposition: attachment; filename=reporte_visitas_2024-01-15.xlsx

[Archivo Excel binario]
```

---

### GET `/api/reportes/visitas-pdf`
Genera un reporte PDF de todas las visitas.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Query Parameters:**
- `fecha_inicio` (string, optional): Fecha de inicio (YYYY-MM-DD)
- `fecha_fin` (string, optional): Fecha de fin (YYYY-MM-DD)
- `municipio_id` (int, optional): ID del municipio
- `estado` (string, optional): Estado de las visitas

**Response (200):**
```
Content-Type: application/pdf
Content-Disposition: attachment; filename=reporte_visitas_2024-01-15.pdf

[Archivo PDF binario]
```

---

## 🔧 Endpoints de Sincronización

### POST `/api/sincronizar-todas-las-visitas`
Sincroniza todas las visitas del usuario autenticado.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200):**
```json
{
  "mensaje": "Sincronización completa realizada. 5 visitas sincronizadas.",
  "visitas_sincronizadas": 5
}
```

---

### POST `/api/sincronizar-visitas-en-proceso`
Sincroniza visitas asignadas en proceso con visitas completas pendientes.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200):**
```json
{
  "mensaje": "Sincronización completada. 3 visitas en proceso actualizadas.",
  "visitas_sincronizadas": 3
}
```

---

## 🚨 Códigos de Error

### Errores de Autenticación
- `401 Unauthorized`: Token inválido o expirado
- `403 Forbidden`: Acceso denegado por rol insuficiente

### Errores de Validación
- `400 Bad Request`: Datos de entrada inválidos
- `422 Unprocessable Entity`: Error de validación de schema

### Errores de Recurso
- `404 Not Found`: Recurso no encontrado
- `409 Conflict`: Conflicto de datos (ej: email duplicado)

### Errores del Servidor
- `500 Internal Server Error`: Error interno del servidor
- `503 Service Unavailable`: Servicio temporalmente no disponible

### Rate Limiting
- `429 Too Many Requests`: Límite de solicitudes excedido

---

## 📝 Notas Importantes

1. **Autenticación**: La mayoría de endpoints requieren autenticación con JWT token
2. **Rate Limiting**: Algunos endpoints tienen límites de solicitudes por minuto
3. **Roles**: Algunos endpoints requieren roles específicos (admin, supervisor)
4. **Paginación**: Los endpoints de listado pueden implementar paginación en el futuro
5. **Filtros**: Los endpoints de reportes soportan filtros por fecha, municipio, etc.
6. **Sincronización**: Los endpoints de sincronización son cruciales para el funcionamiento offline

---

Esta documentación cubre todos los endpoints principales de la API. Para información más detallada sobre schemas de datos, consultar la documentación automática de FastAPI en `/docs` cuando el servidor esté ejecutándose.
