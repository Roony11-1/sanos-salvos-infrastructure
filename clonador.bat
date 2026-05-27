@echo off
setlocal enabledelayedexpansion

echo ============================================
echo   SINCRONIZANDO MICROSERVICIOS SANOS Y SALVOS
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

        REM =========================================
        REM FETCH
        REM =========================================
        git fetch origin >nul 2>&1

        REM =========================================
        REM MAIN
        REM =========================================
        git checkout main >nul 2>&1
        git pull origin main >nul 2>&1

        REM =========================================
        REM DEV
        REM =========================================

        REM Intentar entrar a dev
        git checkout dev >nul 2>&1

        if errorlevel 1 (

            REM Si no existe dev local, intentar crearla desde origin/dev
            git checkout -b dev origin/dev >nul 2>&1

            if errorlevel 1 (

                REM Si tampoco existe origin/dev, usar origin/development
                git checkout -b dev origin/development >nul 2>&1

            )

        ) else (

            git pull origin dev >nul 2>&1

        )

        REM =========================================
        REM INFO ULTIMO COMMIT MAIN
        REM =========================================

        for /f %%i in ('git rev-parse --short main') do set HASH=%%i
        for /f "delims=" %%i in ('git log -1 main --pretty^=format:"%%an"') do set AUTHOR=%%i
        for /f "delims=" %%i in ('git log -1 main --pretty^=format:"%%ad" --date^=short') do set DATE=%%i
        for /f "delims=" %%i in ('git log -1 main --pretty^=format:"%%s"') do set MESSAGE=%%i

        echo Repo: %%r
        echo Rama activa final: main
        echo Ultimo commit main: !HASH!
        echo Autor: !AUTHOR!
        echo Fecha: !DATE!
        echo Mensaje: !MESSAGE!

        REM =========================================
        REM VOLVER A MAIN
        REM =========================================
        git checkout main >nul 2>&1

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