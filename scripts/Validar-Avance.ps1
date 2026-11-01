param([switch]$IncluirLecturaQa)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
& powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File (Join-Path $PSScriptRoot 'compilar.ps1') -Configuration Debug
if($LASTEXITCODE -ne 0){throw 'Fallo compilacion.'}
$suites=@('tests/ui/Probar-Permisos-SinSql.ps1','tests/ui/Probar-Navegacion-SinSql.ps1','tests/ui/Probar-Interfaz-SinSql.ps1','tests/Probar-Caja-SinSql.ps1','tests/ui/Probar-Buscadores-SinSql.ps1','tests/qa/Probar-Identidad-Binario.ps1','tests/ui/Probar-Dashboards-SinSql.ps1','tests/ui/Probar-Seguridad-SinSql.ps1','tests/ui/Probar-Catalogos-SinSql.ps1','tests/ui/Probar-Compras-SinSql.ps1','tests/ui/Probar-Inventario-SinSql.ps1','tests/ui/Probar-Adversariales-SinSql.ps1','tests/ui/Probar-Catalogo-Adversarial-SinSql.ps1','tests/ui/Probar-Seguridad-Adversarial-SinSql.ps1','tests/qa/Validar-Avance-SinSql.ps1','tests/qa/Validar-Preparacion-SinSql.ps1','tests/qa/Probar-Aplicador007-SinSql.ps1')
if($IncluirLecturaQa){$suites+=@('tests/qa/Probar-Seleccion-Lectura.ps1','tests/qa/Probar-Buscadores-Visibles.ps1','tests/qa/Probar-Dashboards-Lectura.ps1','tests/qa/Probar-Modulos-Pendientes-Lectura.ps1')}
foreach($suite in $suites){
 Write-Output "SUITE: $suite"
 & powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File (Join-Path $root $suite)
 if($LASTEXITCODE -ne 0){throw "Fallo suite $suite"}
}
Write-Output 'Regresion finalizada. Este script no ejecuta fixtures de escritura ni migraciones.'
