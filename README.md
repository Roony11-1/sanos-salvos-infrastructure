# Proyecto Sanos y Salvos

**Trabajo Semestral - Arquitectura Fullstack 3**

**Sanos y Salvos** es un sistema distribuido basado en una arquitectura de microservicios, diseñado para el registro, geolocalización y emparejamiento (coincidencias) de mascotas perdidas y encontradas.

<br>

---

<br>

## Arquitectura del Sistema

El sistema utiliza una arquitectura orientada a eventos (EDA) impulsada por **Apache Kafka** para garantizar un acoplamiento débil y alta escalabilidad entre los servicios.

### Componentes Principales:

* **Servicio de Mascotas (C# ASP.NET):** Encargado de la gestión y registro de los animales. Publica eventos (Producer) como "Animal registrado como perdido" en Kafka. Utiliza una base de datos **PostgreSQL**.
* **Servicio de Coincidencias (Java Spring):** Consume eventos de Kafka para analizar y marcar coincidencias entre mascotas perdidas y encontradas. Tiene su propia base de datos **PostgreSQL**.
* **Servicio de Geolocalización (Java Spring):** Consume eventos para gestionar las ubicaciones geográficas de los avistamientos y pérdidas. Utiliza **PostGIS** para el manejo avanzado de datos espaciales. *NO REALIZADO*
* **Servicio de Notificaciones (Java Spring WebFlux):** Consume eventos para enviar notificaciones a los usuarios.
* **Servicio de Mensajeria (Java Quarkus):** Centraliza las operaciones en los mensajes.
* **Servicio de Usuarios (C++ Drogon):** BFF de keycloak, además encargado de persistir metadatos extra de los usuarios.
* **Servicio de Api Gateway (Java Spring Cloud MVC):** El punto de entrada hacía el Backend.
* **Apache Kafka:**Es el bus de mensajes del sistema.
* **Seguridad:** Autenticación y autorización delegadas a **Keycloak** propio.
* **Frontend (React & Astro):** Interfaz de usuario final que se comunica a través del Gateway.
* **Aplicación Móvil (Flutter):** Cliente móvil de la aplicación 

<br>

---

<br>

## Tecnologías Utilizadas

* **Backend:** Java (Spring Boot) (Spring Web Flux) (Spring Cloud MVC) (Quarkus), C# (ASP.NET 10 Core), C++ (Drogon).
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
* [Message Service](https://github.com/Roony11-1/message-service)
* [User Service](https://github.com/Roony11-1/user-service)
* [API Gateway](https://github.com/Roony11-1/sanos-gateway)
* [Frontend](https://github.com/Roony11-1/sanos-salvos-front) 
* [Landing](https://github.com/Roony11-1/sanos-salvos-astro)
* [App Móvil](https://github.com/Neytan2214/sanos_salvos_app)

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