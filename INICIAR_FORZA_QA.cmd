@echo off
setlocal
title FORZA SUPLEMENTOS - QA
pushd "%~dp0"
if errorlevel 1 goto error
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0scripts\qa\Iniciar-App-QA.ps1" -Configuration Debug
if errorlevel 1 goto error
popd
exit /b 0
:error
echo.
echo No se pudo iniciar Forza en QA. Revise el error mostrado arriba.
echo No abra el ejecutable directamente. Verifique la configuracion QA y la compilacion Debug.
pause
exit /b 1
