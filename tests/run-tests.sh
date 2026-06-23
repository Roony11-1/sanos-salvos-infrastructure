#!/bin/bash
# ─── test-runner: ejecuta tests de todos los servicios y envía a SonarQube ───
set -e

SONAR_HOST_URL="${SONAR_HOST_URL:-http://sonarqube:9000}"
SONAR_TOKEN="${SONAR_TOKEN:-sqp_32876bd725f1eb79ef70224758f42a09e93a2ff4}"
COVERAGE_DIR="${COVERAGE_DIR:-/coverage}"

echo "══════════════════════════════════════════════════════"
echo "  SANOS Y SALVOS — Test Runner"
echo "  SonarQube: $SONAR_HOST_URL"
echo "  Coverage:  $COVERAGE_DIR"
echo "  Inicio:    $(date '+%Y-%m-%d %H:%M:%S')"
echo "══════════════════════════════════════════════════════"

mkdir -p "$COVERAGE_DIR"

# Esperar a que SonarQube esté listo
echo ""
echo "→ Esperando a SonarQube..."
for i in $(seq 1 30); do
    if curl -sf "$SONAR_HOST_URL/api/system/status" > /dev/null 2>&1; then
        status=$(curl -sf "$SONAR_HOST_URL/api/system/status" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status',''))" 2>/dev/null || echo "")
        if [ "$status" = "UP" ]; then
            echo "  ✓ SonarQube está UP"
            break
        fi
    fi
    echo "  . esperando ${i}s..."
    sleep 5
done

RESULTS=()
FAILED=0

run_tests() {
    local name="$1"
    shift
    echo ""
    echo "════════════════════════════════════════════════"
    echo "  $name"
    echo "════════════════════════════════════════════════"
    cd "/app/$name" || { echo "  ✗ Directorio no encontrado"; FAILED=1; return; }
    "$@"
    local ok=$?
    if [ $ok -ne 0 ]; then
        echo "  ✗ Falló (exit code: $ok)"
        FAILED=1
    else
        echo "  ✓ OK"
    fi
    RESULTS+=("$name")
}

# ─── 1. Java Maven services ──────────────────────────────────────────────────
for svc in sanos-gateway coincidencias-service notification-service message-service; do
    run_tests "$svc" ./mvnw clean test -q
done

# ─── 2. .NET (mascotas-service) ──────────────────────────────────────────────
run_tests "mascotas-service" \
    dotnet test tests/mascotas-service.tests.csproj \
    --collect "XPlat Code Coverage" \
    --settings codecover.runsettings

# ─── 3. C++ (user-service) ──────────────────────────────────────────────────
run_tests "user-service" bash -c '
    cmake -B build -DENABLE_COVERAGE=ON
    cmake --build build -j$(nproc)
    ./build/user-service-tests
    gcovr -r . \
        --exclude "external/.*" --exclude "test/.*" \
        --exclude "main.cc" --exclude ".*\.h" \
        --cobertura -o build/coverage.xml
'

# ─── 4. Frontend ─────────────────────────────────────────────────────────────
run_tests "sanos-salvos-front" bash -c '
    npm ci --silent 2>/dev/null || true
    npm run test:coverage 2>/dev/null
'

# ─── SonarQube Analysis ──────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════════"
echo "  Enviando análisis a SonarQube"
echo "════════════════════════════════════════════════"

SONAR_OPTS="-Dsonar.host.url=$SONAR_HOST_URL -Dsonar.login=$SONAR_TOKEN"

for svc in sanos-gateway coincidencias-service notification-service message-service; do
    echo "→ $svc (Maven sonar:sonar)..."
    cd "/app/$svc"
    ./mvnw sonar:sonar \
        "-Dsonar.projectKey=$svc" \
        "-Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml" \
        $SONAR_OPTS -q 2>/dev/null || echo "  ⚠ Error en $svc"
done

for svc in mascotas-service user-service sanos-salvos-front; do
    echo "→ $svc (sonar-scanner)..."
    cd "/app/$svc"
    if [ -f sonar-project.properties ]; then
        sonar-scanner $SONAR_OPTS 2>/dev/null || echo "  ⚠ Error en $svc"
    else
        echo "  ⚠ sonar-project.properties no encontrado"
    fi
done

# ─── Copiar reportes a volumen compartido ─────────────────────────────────────
echo ""
echo "→ Copiando reportes a $COVERAGE_DIR..."
for svc in sanos-gateway coincidencias-service notification-service message-service; do
    [ -d "/app/$svc/target/site" ] && cp -r "/app/$svc/target/site" "$COVERAGE_DIR/$svc" 2>/dev/null
done
[ -d "/app/mascotas-service/tests/TestResults" ] && cp -r "/app/mascotas-service/tests/TestResults" "$COVERAGE_DIR/mascotas-service" 2>/dev/null
[ -f "/app/user-service/build/coverage.xml" ] && cp "/app/user-service/build/coverage.xml" "$COVERAGE_DIR/user-service/" 2>/dev/null
[ -d "/app/sanos-salvos-front/coverage" ] && cp -r "/app/sanos-salvos-front/coverage" "$COVERAGE_DIR/sanos-salvos-front" 2>/dev/null

echo ""
echo "════════════════════════════════════════════════"
if [ $FAILED -eq 0 ]; then
    echo "  ✓ Todos los servicios completados"
else
    echo "  ⚠ Algunos servicios fallaron"
fi
echo "  Fin: $(date '+%Y-%m-%d %H:%M:%S')"
echo "════════════════════════════════════════════════"
