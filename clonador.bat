@echo off
echo ============================================
echo  SINCRONIZANDO MICROSERVICIOS SANOS Y SALVOS
echo ============================================

echo.
echo [1/2] Moviendose al directorio padre...
cd ..
echo Directorio actual: %cd%

echo.
echo [2/2] Verificando repositorios...
echo.

for %%r in (
coincidencias-service
geo-service
mascotas-service
sanos-gateway
sanos-salvos-front
sanos-salvos-astro
notification-service
message-service
) do (

    echo --------------------------------------------
    echo Procesando: %%r

    if exist %%r (
        echo Repositorio existente, actualizando...
        cd %%r
        git checkout main
		git pull --rebase origin main
        cd ..
    ) else (
        echo No existe, clonando...
        git clone https://github.com/Roony11-1/%%r.git
    )

    echo Finalizado: %%r
    echo --------------------------------------------
    echo.
)

echo ============================================
echo PROCESO FINALIZADO
echo ============================================

pause