param([ValidateSet('Debug','Release')][string]$Configuration='Debug',[switch]$SoloVerificar,[switch]$RevisionVisual,[switch]$Compilar)
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
if($Compilar){
    if($RevisionVisual){throw 'Usar Compilar con la salida habitual Debug/Release, no con RevisionVisual.'}
    $running=@(Get-CimInstance Win32_Process -Filter "Name = 'ForzaSuplementos.Presentacion.exe'" | Where-Object {$_.ExecutablePath -eq $exe})
    if($running.Count){throw ("Cerrar manualmente la instancia anterior del principal antes de recompilar. PID: "+(($running | ForEach-Object ProcessId) -join ', '))}
    & powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File (Join-Path $cfg.Root 'scripts/compilar.ps1') -Configuration $Configuration
    if($LASTEXITCODE -ne 0){throw 'No se inicia QA: fallo la compilacion. Cerrar la instancia anterior y revisar el error.'}
}
Import-Module (Join-Path $PSScriptRoot 'QA.Build.psm1') -Force
$mvid=Assert-QaExecutable $exe
$head=(& git -C $cfg.Root rev-parse --short=7 HEAD)
if($LASTEXITCODE -ne 0){throw 'No se pudo identificar la version Git local.'}
$dirty=@(& git -C $cfg.Root status --porcelain).Count -gt 0
$hash=Get-QaFileHash $exe
$version=$head+$(if($dirty){'+local'}else{''})+' / EXE '+$hash.Substring(0,8)
$record=[ordered]@{GitHead=$head;CambiosLocales=$dirty;Configuration=$buildFolder;Exe=$exe;SHA256=$hash;MVID=$mvid;Base='ForzaSuplementosDB_QA';Utc=([DateTime]::UtcNow.ToString('o'));PID=$null}
$private=Join-Path $cfg.Root 'private'
$null=[IO.Directory]::CreateDirectory($private)
$recordPath=Join-Path $private 'ultimo-inicio-qa.json'
$record | ConvertTo-Json | Set-Content -LiteralPath $recordPath -Encoding UTF8
Write-Output "QA PRINCIPAL | $version"
Write-Output "Ejecutable verificado: $exe"
$start=New-Object Diagnostics.ProcessStartInfo
$start.FileName=$exe;$start.WorkingDirectory=Split-Path $exe -Parent
$start.UseShellExecute=$false;$start.CreateNoWindow=$true
$start.EnvironmentVariables['FORZA_ENTORNO']='QA'
$start.EnvironmentVariables['FORZA_QA_BUILD_ID']=$version
$start.EnvironmentVariables['FORZA_QA_CONFIG']=$cfg.Path
$process=[Diagnostics.Process]::Start($start)
$record.PID=$process.Id
$record | ConvertTo-Json | Set-Content -LiteralPath $recordPath -Encoding UTF8
Write-Output "Aplicacion QA iniciada (PID $($process.Id)). Las variables pertenecen solo a ese proceso, sin cambiar configuraciones permanentes."
