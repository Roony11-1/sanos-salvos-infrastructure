# API Documentation

## Información General

### URL Base

Todos los servicios se exponen bajo el siguiente patrón:

```http
/api/{service-name}
```

### Autenticación

Todos los endpoints requieren autenticación mediante un token JWT enviado en la cabecera `Authorization`.

```http
Authorization: Bearer <token>
```

Cuando un endpoint requiere información del usuario autenticado, esta se obtiene directamente desde el token y no debe enviarse explícitamente en la solicitud.

---

# Servicios

## Mascotas Service (ASP.NET 10)

Base URL:

```http
/api/mascotas
```

### Health Check

#### GET `/v1/alive`

Verifica que el servicio se encuentre operativo.

##### Response

```json
{
  "status": "alive"
}
```

---

## Mascotas

### GET `/v1/Mascota`

Obtiene un resumen de todas las mascotas registradas.

#### Response

Lista resumida de mascotas.

---

### GET `/v1/Mascota/select`

Obtiene una colección simplificada para poblar controles HTML tipo `<select>`.

#### Response

```json
[
  {
    "id": 1,
    "nombre": "Firulais"
  }
]
```

---

### GET `/v1/Mascota/by-id/{id}`

Obtiene toda la información de una mascota específica.

#### Parámetros

| Nombre | Tipo | Descripción                 |
| ------ | ---- | --------------------------- |
| id     | Long | Identificador de la mascota |

---

### POST `/v1/Mascota/by-ids`

Obtiene información completa de múltiples mascotas.

#### Request

```json
[
  1,
  2,
  3
]
```

#### Uso

Endpoint principalmente utilizado para comunicación interna entre servicios.

---

## Reportes

### POST `/v1/Reporte/perdida`

Registra un reporte de mascota perdida.

#### Request

```json
{
  // ReportePerdidaRequest
}
```

---

### POST `/v1/Reporte/avistamiento`

Registra un reporte de avistamiento.

#### Request

```json
{
  // ReporteAvistamientoRequest
}
```

---

### GET `/v1/Reporte/{id}`

Obtiene la información completa de un reporte.

#### Parámetros

| Nombre | Tipo |
| ------ | ---- |
| id     | Long |

---

### GET `/v1/Reporte`

Obtiene un resumen de todos los reportes.

---

## Coincidencias (Matches)

Base Route:

```http
/v1/reporte-match/{reporteId}/matches/{matchId}
```

### POST `/accept`

Acepta una coincidencia detectada entre un reporte de pérdida y un avistamiento.

#### Parámetros

| Nombre    | Tipo |
| --------- | ---- |
| reporteId | Long |
| matchId   | Long |

---

### POST `/reject`

Rechaza una coincidencia detectada.

#### Parámetros

| Nombre    | Tipo |
| --------- | ---- |
| reporteId | Long |
| matchId   | Long |

---

# Coincidencias Service (Spring Boot)

Base URL:

```http
/api/coincidencias
```

## Descripción

Este servicio no expone endpoints públicos.

Su funcionamiento está basado exclusivamente en mensajería interna mediante eventos.

### Responsabilidades

* Procesamiento de reportes de pérdida.
* Procesamiento de reportes de avistamiento.
* Detección automática de coincidencias.
* Publicación de eventos de coincidencias encontradas.

---

# Geo Service (Spring Boot)

Base URL:

```http
/api/geo
```

## Estado

Actualmente no se encuentra en uso.

---

# Messages Service (Quarkus)

Base URL:

```http
/api/messages
```

## Conversaciones

### GET `/v1/conversations`

Obtiene todas las conversaciones disponibles para el usuario autenticado.

---

### POST `/v1/conversations/start`

Inicia una conversación con otro usuario.

#### Request

```json
{
  // StartConversationRequest
}
```

---

## Mensajes

### POST `/v1/send`

Envía un mensaje a una conversación.

#### Request

```json
{
  // MessageRequest
}
```

---

### GET `/v1`

Obtiene todos los mensajes accesibles para el usuario.

---

### GET `/v1/conversation/{conversationId}`

Obtiene todos los mensajes pertenecientes a una conversación.

#### Parámetros

| Nombre         | Tipo |
| -------------- | ---- |
| conversationId | Long |

---

# Users Service (C++)

Base URL:

```http
/api/users
```

## Usuarios

### GET `/v1/users`

Obtiene todos los usuarios registrados.

---

## Registro

### POST `/auth/register`

Registra un nuevo usuario.

#### Request

```json
{
  // RegisterRequest
}
```

---

# Authentication Service (Keycloak)

Base URL:

```http
/ auth
```

## Login

### POST `/login`

Autentica un usuario y genera un JWT.

#### Response

---

## Refresh Token

### POST `/refresh`

Obtiene un nuevo token de acceso utilizando un refresh token válido.

---

# Arquitectura General

```text
┌─────────────┐
│  Frontend   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Keycloak   │
└──────┬──────┘
       │ JWT
       ▼
┌─────────────────────────────────────────┐
│Api Gateway                              │
├─────────────────────────────────────────┤
│ Mascotas (ASP.NET 10)                   │
│ Messages (Quarkus)                      │
│ Users (C++)                             │
│ Coincidencias (Spring Boot + Kafka)     │
└─────────────────────────────────────────┘
```