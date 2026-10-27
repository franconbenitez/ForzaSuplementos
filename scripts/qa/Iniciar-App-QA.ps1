param([ValidateSet('Debug','Release')][string]$Configuration='Debug',[switch]$SoloVerificar,[switch]$RevisionVisual)
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'QA.Common.psm1') -Force
$cfg=Get-QaConfig
$cn=Open-QaConnection
try {
    $result=Invoke-QaQuery $cn "SELECT CASE WHEN OBJECT_ID('dbo.sp_Ventas_RegistrarConCaja','P') IS NOT NULL AND OBJECT_ID('dbo.sp_Caja_Cerrar','P') IS NOT NULL THEN 1 ELSE 0 END AS ready;"
    if([int]$result.Rows[0].ready -ne 1){throw 'QA aun no tiene las migraciones completas.'}
} finally {$cn.Dispose()}
if($SoloVerificar){Write-Output 'Configuracion QA verificada en lectura; no se inicio la aplicacion.';return}
$buildFolder=if($RevisionVisual){'UIRevision'}else{$Configuration}
$exe=Join-Path $cfg.Root "ForzaSuplementos\ForzaSuplementos\ForzaSuplementos.Presentacion\bin\$buildFolder\ForzaSuplementos.Presentacion.exe"
if(!(Test-Path $exe)){throw 'Compilar la solucion antes de iniciar QA.'}
$start=New-Object Diagnostics.ProcessStartInfo
$start.FileName=$exe;$start.WorkingDirectory=Split-Path $exe -Parent
$start.UseShellExecute=$false;$start.CreateNoWindow=$true
$start.EnvironmentVariables['FORZA_ENTORNO']='QA'
$start.EnvironmentVariables['FORZA_QA_CONFIG']=$cfg.Path
$process=[Diagnostics.Process]::Start($start)
Write-Output "Aplicacion QA iniciada (PID $($process.Id)). Las variables pertenecen solo a ese proceso, sin cambiar configuraciones permanentes."
