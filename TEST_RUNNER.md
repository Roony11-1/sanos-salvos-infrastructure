# Test Runner + SonarQube Automatizado

## Descripción

Suite de pruebas containerizada que ejecuta los tests unitarios de **todos los servicios** y envía los reportes de cobertura a **SonarQube** automáticamente.

## Arquitectura

```
docker compose --profile test up test-runner
       │
       ▼
 ┌──────────────┐     ┌─────────────┐
 │  test-runner │────▶│  SonarQube  │
 │  (cont.)     │HTTP │  (cont.)    │
 │              │     │             │
 │  mounts:     │     │  puerto:    │
 │  · source    │     │  9000       │
 │  · /coverage │     └─────────────┘
 └──────┬───────┘
        │
        ▼
  coverage-data (volumen)
```

El contenedor `test-runner`:
1. Espera a que SonarQube esté saludable (`service_healthy`)
2. Monta todos los directorios de código fuente como bind mounts
3. Ejecuta pruebas secuencialmente en cada servicio
4. Envía análisis a SonarQube vía HTTP
5. Copia los reportes al volumen `coverage-data:/coverage`

## Servicios y Comandos

| Servicio | Lenguaje | Test Command | Cobertura | Envío SonarQube |
|---|---|---|---|---|
| `sanos-gateway` | Java 21 | `mvnw clean test` | JaCoCo XML | `sonar:sonar` |
| `coincidencias-service` | Java 21 | `mvnw clean test` | JaCoCo XML | `sonar:sonar` |
| `notification-service` | Java 21 | `mvnw clean test` | JaCoCo XML | `sonar:sonar` |
| `message-service` | Java 21 (Quarkus) | `mvnw clean test` | JaCoCo XML | `sonar:sonar` |
| `mascotas-service` | C# .NET 10 | `dotnet test` + coverlet | Cobertura XML | `sonar-scanner` |
| `user-service` | C++20 | cmake + gcovr | Cobertura XML | `sonar-scanner` |
| `sanos-salvos-front` | TypeScript/React | `npm run test:coverage` | LCOV | `sonar-scanner` |

## Uso

### Desde el proyecto raíz (PowerShell)
```powershell
# Construye y ejecuta el contenedor test-runner
.\run-tests.ps1 -Docker

# O modo local (sin Docker)
.\run-tests.ps1
```

### Directamente con Docker Compose
```powershell
cd sanos-salvos-infrastructure

# Iniciar infraestructura (SonarQube + todo)
docker compose up -d

# Ejecutar tests y análisis
docker compose --profile test up test-runner --abort-on-container-exit

# Reconstruir la imagen del test-runner si hubo cambios
docker compose --profile test build --no-cache test-runner
```

### Ver resultados en SonarQube
```
http://localhost:9000
```
Token por defecto: `sqp_32876bd725f1eb79ef70224758f42a09e93a2ff4`

### Reportes de cobertura (volumen)
Los reportes se copian automáticamente al volumen `coverage-data`:
```
/coverage/
├── sanos-gateway/          (target/site)
├── coincidencias-service/  (target/site)
├── notification-service/   (target/site)
├── message-service/        (target/site)
├── mascotas-service/       (TestResults/)
├── user-service/           (coverage.xml)
└── sanos-salvos-front/     (coverage/)
```

## Estructura de Archivos

```
sanos-salvos-infrastructure/
├── docker-compose.yml        # test-runner service (profile: test)
├── TEST_RUNNER.md            # este archivo
├── docs/
└── ...

tests/                        # raíz del proyecto
├── Dockerfile                # imagen con todas las herramientas
└── run-tests.sh              # script de entrada del contenedor

run-tests.ps1                 # script PowerShell (modo local o -Docker)

mascotas-service/
├── sonar-project.properties  # configuración sonar-scanner
user-service/
├── sonar-project.properties
sanos-salvos-front/
├── sonar-project.properties
```

## Herramientas en la Imagen (`tests/Dockerfile`)

- Java 21 + Maven 3.9.9 (Eclipse Temurin)
- .NET SDK 10.0
- Node.js 22 + npm
- CMake, g++, gcc, make, gcovr
- SonarScanner CLI 6.2.1
- Drogon 1.9.13 (precompilado para user-service)

## Notas

- Los proyectos Maven tienen el `sonar-maven-plugin 5.1.0.2024` declarado en su `pom.xml`
- El análisis de SonarQube se omite si los tests fallan en ese servicio
- El healthcheck de SonarQube espera hasta ~2.5 minutos antes de declararlo como listo
