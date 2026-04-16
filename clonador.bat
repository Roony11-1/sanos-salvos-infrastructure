@echo off
echo ============================================
echo   CLONANDO MICROSERVICIOS SANOS Y SALVOS
echo ============================================

echo.
echo [1/2] Moviendose al directorio padre...
cd ..
echo Directorio actual: %cd%

echo.
echo [2/2] Iniciando clonacion de repositorios...
echo.

for %%r in (coincidencias-service geo-service mascotas-service sanos-gateway sanos-salvos-front) do (
    echo --------------------------------------------
    echo Clonando repositorio: %%r
    git clone https://github.com/Roony11-1/%%r.git
    echo Finalizado: %%r
    echo --------------------------------------------
    echo.
)

echo ============================================
echo   PROCESO FINALIZADO
echo ============================================
echo.

pause