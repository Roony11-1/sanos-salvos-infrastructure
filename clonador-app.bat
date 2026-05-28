@echo off
setlocal enabledelayedexpansion

echo ============================================
echo      SINCRONIZANDO SANOS SALVOS APP
echo ============================================

cd ..

if exist sanos_salvos_app (

    echo.
    echo Procesando: sanos_salvos_app
    echo.

    cd sanos_salvos_app

    REM =========================================
    REM FETCH
    REM =========================================
    git fetch origin

    REM =========================================
    REM MAIN
    REM =========================================
    git checkout main
    git pull origin main

    REM =========================================
    REM DEV
    REM =========================================
    git checkout dev >nul 2>&1

    if errorlevel 1 (

        git checkout -b dev origin/dev >nul 2>&1

        if errorlevel 1 (

            git checkout -b dev origin/development

        )

    ) else (

        git pull origin dev

    )

    REM =========================================
    REM INFO
    REM =========================================

    for /f %%i in ('git rev-parse --short main') do set HASH=%%i
    for /f "delims=" %%i in ('git log -1 main --pretty^=format:"%%an"') do set AUTHOR=%%i
    for /f "delims=" %%i in ('git log -1 main --pretty^=format:"%%ad" --date^=short') do set DATE=%%i
    for /f "delims=" %%i in ('git log -1 main --pretty^=format:"%%s"') do set MESSAGE=%%i

    echo ============================================
    echo Repo: sanos_salvos_app
    echo Hash: !HASH!
    echo Autor: !AUTHOR!
    echo Fecha: !DATE!
    echo Commit: !MESSAGE!
    echo ============================================

    git checkout main

    cd ..

) else (

    echo Repo no encontrado, clonando...

    git clone https://github.com/Neytan2214/sanos_salvos_app.git

)

echo.
echo ============================================
echo PROCESO FINALIZADO
echo ============================================

pause