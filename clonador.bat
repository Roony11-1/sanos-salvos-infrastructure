@echo off
setlocal enabledelayedexpansion

echo ============================================
echo  SINCRONIZANDO MICROSERVICIOS SANOS Y SALVOS
echo ============================================

cd ..

echo.
echo ===== RESUMEN =====
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
user-service
) do (

    echo --------------------------------------------

    if exist %%r (

        echo Procesando: %%r
        cd %%r

        git checkout main >nul 2>&1

        echo Actualizando...
        git pull --rebase origin main > pull_result.txt

        REM Obtener datos
        for /f %%i in ('git branch --show-current') do set BRANCH=%%i
        for /f %%i in ('git rev-parse --short HEAD') do set HASH=%%i
        for /f "delims=" %%i in ('git log -1 --pretty^=format:"%%an"') do set AUTHOR=%%i
        for /f "delims=" %%i in ('git log -1 --pretty^=format:"%%ad" --date^=short') do set DATE=%%i
        for /f "delims=" %%i in ('git log -1 --pretty^=format:"%%s"') do set MESSAGE=%%i

        findstr /c:"Already up to date" pull_result.txt >nul
        if !errorlevel!==0 (
            set STATUS=Sin cambios
        ) else (
            set STATUS=Actualizado
        )

        del pull_result.txt

        echo Repo: %%r
        echo Rama: !BRANCH!
        echo Estado: !STATUS!
        echo Ultimo commit: !HASH!
        echo Autor: !AUTHOR!
        echo Fecha: !DATE!
        echo Mensaje: !MESSAGE!

        cd ..

    ) else (

        echo %%r no existe, clonando...
        git clone https://github.com/Roony11-1/%%r.git

    )

    echo --------------------------------------------
    echo.
)

echo ============================================
echo PROCESO FINALIZADO
echo ============================================

pause