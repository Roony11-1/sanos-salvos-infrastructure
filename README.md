# Proyecto Sanos y Salvos

**Trabajo Semestral - Arquitectura Fullstack 3**

**Sanos y Salvos** es un sistema distribuido basado en una arquitectura de microservicios, diseñado para el registro, geolocalización y emparejamiento (coincidencias) de mascotas perdidas y encontradas.

<br>

---

<br>

## Arquitectura del Sistema

El sistema utiliza una arquitectura orientada a eventos (EDA) impulsada por **Apache Kafka** para garantizar un acoplamiento débil y alta escalabilidad entre los servicios.

### Componentes Principales:

* **Servicio de Mascotas (C# .NET 10 ASP.NET Core):** Gestión y registro de animales. Publica eventos en Kafka. Base de datos **PostgreSQL**.
* **Servicio de Coincidencias (Java Spring):** Consume eventos de Kafka para detectar coincidencias entre mascotas perdidas y encontradas. Base de datos **PostgreSQL**.
* **Servicio de Notificaciones (Java Spring WebFlux):** Consume eventos y envía notificaciones en tiempo real vía WebSocket.
* **Servicio de Mensajeria (Java Quarkus):** Sistema de mensajería entre usuarios. Base de datos **MongoDB**.
* **Servicio de Usuarios (C++ Drogon):** BFF de Keycloak, persiste metadatos extra de usuarios. Base de datos **PostgreSQL**.
* **API Gateway (Java Spring Cloud MVC):** Punto de entrada al backend con validación JWT.
* **Apache Kafka:** Bus de mensajes del sistema (3 topics).
* **Seguridad:** Autenticación y autorización delegadas a **Keycloak**.
* **Frontend (React 19 + Astro 6):** Interfaz de usuario y landing page.
* **Aplicación Móvil (Flutter):** Cliente móvil de la aplicación.

<br>

---

<br>

## Tecnologías Utilizadas

* **Backend:** Java (Spring Boot) (Spring Web Flux) (Quarkus), ASP.NET 10 Core, C++ (Drogon)
* **Bases de Datos:** PostgreSQL 15, PostGIS (para el microservicio geográfico), MongoDB.
* **Mensajería:** Apache Kafka, Zookeeper.
* **Infraestructura:** Docker & Docker Compose.
* **Seguridad:** Spring Security.
* **Proveedor de identidad** Keycloak.

<br>

---

<br>

## Repositorios del Proyecto

El proyecto está dividido en los siguientes repositorios. Es necesario tenerlos todos para el correcto funcionamiento del ecosistema:

* [Mascotas Service](https://github.com/Roony11-1/mascotas-service)
* [Coincidencias Service](https://github.com/Roony11-1/coincidencias-service)
* [Geolocalización Service](https://github.com/Roony11-1/geo-service)
* [Notification Service](https://github.com/Roony11-1/notification-service)
* [Messages Service](https://github.com/Roony11-1/message-service)
* [Users Service](https://github.com/Roony11-1/user-service)
* [API Gateway](https://github.com/Roony11-1/sanos-gateway)
* [Frontend](https://github.com/Roony11-1/sanos-salvos-front)
* [Landing Page](https://github.com/Roony11-1/sanos-salvos-astro)
<br>

---

<br>

## 🚀 Guía de Instalación y Despliegue con Docker

Toda la infraestructura está containerizada, por lo que levantar el proyecto completo requiere solo unos pocos comandos.

### Prerrequisitos
* [Docker Desktop](https://www.docker.com/products/docker-desktop/) instalado y ejecutándose.
* [Git](https://git-scm.com/) instalado en tu máquina.

<br>

### Paso 1: Clonar los repositorios

Ejecuta el archivo clonador.bat que bajara todos los repositorios

<br>

### Paso 2: Correr los contenedores en docker
Con los repositorios clonados ve al directorio de "sanos-salvos-infrastructure" y ejectuta en vs-code los servicios desde el docker-compose.yml o con el comando docker compose up -d

<br>

### Paso 3: El contenido desplegado
El sistema usa un gateway en el puerto 8080, el resto esta privado de la red local, y la pagina web esta en el puerto 80

## Para probar sonarqube para cualquier microservicio Maven Primero runnear las pruebas del microservicio y despues hacer esto:.
.\mvnw.cmd sonar:sonar "-Dsonar.projectKey=message-service" "-Dsonar.host.url=http://localhost:9000" "-Dsonar.login=sqp_32876bd725f1eb79ef70224758f42a09e93a2ff4"

docker compose run --rm --entrypoint jmeter jmeter -n -t /tests/sanos-plan.jmx -l /tests/results.jtl -e -o /tests/report/