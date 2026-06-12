@echo off
setlocal enabledelayedexpansion

echo ============================================
echo   COMMIT AUTOMATICO SANOS Y SALVOS
echo ============================================

cd ..

for %%r in (
coincidencias-service
mascotas-service
sanos-gateway
sanos-salvos-front
sanos-salvos-astro
notification-service
message-service
user-service
) do (

    echo.
    echo ============================================
    echo Procesando %%r
    echo ============================================

    if exist %%r (

        cd %%r

        git checkout main >nul 2>&1

        git add .

        git diff --cached --quiet

        if errorlevel 1 (

            echo Cambios detectados.

            git commit -m "Commit generado con commiteador automatico"

            if errorlevel 1 (
                echo Error al realizar commit.
            ) else (

                git push origin main

                if errorlevel 1 (
                    echo Error al hacer push.
                ) else (
                    echo Push realizado correctamente.
                )
            )

        ) else (

            echo Sin cambios para commit.

        )

        cd ..

    ) else (

        echo Repositorio %%r no encontrado.

    )

)

echo.
echo ============================================
echo FINALIZADO
echo ============================================

pause