@echo off
setlocal
title FORZA SUPLEMENTOS - QA (GITHUB)
pushd "%~dp0"
if errorlevel 1 goto error
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0scripts\qa\Iniciar-App-QA.ps1" -Configuration Debug -Compilar
if errorlevel 1 goto error
popd
exit /b 0
:error
echo.
echo No se pudo iniciar Forza en QA. Revise el error mostrado arriba.
echo No abra el ejecutable directamente. Cierre la instancia anterior y revise la configuracion QA o el error de compilacion.
pause
exit /b 1
