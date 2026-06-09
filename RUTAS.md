# Todos los servicios comparten la url

/api/{nombre-del-servicio}

// Todos los servicios requieren autenticación, si se necesita una id de usuario, se obtiene desde la cabecera <b>bearer</b>


## Mascotas (ASP.NET 10)
- /api/mascotas
-- /v1/alive (Controlador de salud)
-- /v1/Mascota (Controlador de mascota)
--- POST [Guarda mascota]
--- GET [GetAll, trae el resumen de todos las mascotas]
--- GET /select [Trae para llenar un select Html]
--- GET /by-id/{id: Long} [Trae toda la información de una mascota]
--- POST /by-ids [long[] ids, trae toda la información de las máscotas, uso interno normalmente]
-- /v1/Reporte (Controlador reportes)
--- POST /perdida [reporte: ReportePerdidaRequest, se ingresa un reporte de perdida]
--- POST /avistamiento [reporte: ReporteAvistamientoRequest, se ingresa un reporte de avistamiento]
--- GET /{id} [id: Long, Trae toda la información de un reporte por id]
--- GET [Trae un resumen de todos los reportes]
-- /v1/reporte-match/{reporteId}/matches/{matchId} (Controlador de matches)
--- POST /accept [Desde la url (ids: Long), obtiene y acepta la coicidencia]
--- POST /reject [Desde la url (ids: Long), obtiene y rechaza la coincidencia]
## Coincidencias (Java Spring)
- /api/coincidencias
--- No tiene endpoints publicos, solo usa mensajeria interna
## Geo (Java Spring)
- /api/geo
--- No se usa
## Messsages (Java Quarkus)
- /api/messages
-- /v1/conversations (Recurso de conversaciones)
--- GET (BUsca todas las conversaciones)
--- POST /start [request: StartConversationRequest, inicia una conversacion con un usuario]
-- /v1 (Recurso de mensajes)
--- POST /send (request: MessageRequest, Envia un mensaje a la conversación)
--- GET (Obtiene todos los mensajes)
--- GET /conversation/{conversationId} (Obtiene los mensajes de una conversación)
## Users (C++)
- /api/users
--- GET /v1/users (Obtiene todos los usuarios)
--- POST /auth/register (registra un usuario, request: RegisterRequest)
## Auth (Keycloak)
- /auth/
-- /login (Logea)
-- /refresh (refresca el token)