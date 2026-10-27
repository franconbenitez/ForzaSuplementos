param([string]$Configuration='Debug')
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Import-Module (Join-Path $root 'scripts/qa/QA.Build.psm1') -Force
$out=Join-Path $root "ForzaSuplementos\ForzaSuplementos\ForzaSuplementos.Presentacion\bin\$Configuration"
$exe=Join-Path $out 'ForzaSuplementos.Presentacion.exe'
$id=Assert-QaExecutable $exe
if([string]::IsNullOrWhiteSpace($id)){throw 'No se identifico el modulo compilado'}
Write-Output 'OK: EXE real incluye buscadores y carece de combos antiguos'
$rejected=$false;try{Assert-QaExecutable (Join-Path $out 'no-existe.exe') | Out-Null}catch{$rejected=$true}
if(!$rejected){throw 'Acepto ejecutable inexistente'}
Write-Output 'OK: ejecutable inexistente rechazado'
$rejected=$false;try{Assert-QaExecutable (Join-Path $out 'ForzaSuplementos.Entidades.dll') | Out-Null}catch{$rejected=$true}
if(!$rejected){throw 'Acepto otro ensamblado'}
Write-Output 'OK: ensamblado de otra capa rechazado'
$cmd=[IO.File]::ReadAllText((Join-Path $root 'INICIAR_FORZA_QA.cmd'))
if($cmd -notmatch 'Iniciar-App-QA.ps1.*-Configuration Debug -Compilar'){throw 'El acceso CMD no obliga a compilar antes de iniciar'}
Write-Output 'OK: CMD exige recompilacion antes del inicio'
$hash=Get-QaFileHash $exe
if($hash -cne (Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash){throw 'Hash .NET no coincide con SHA256 esperado'}
Write-Output 'OK: hash .NET coincide con SHA256 del archivo'
Write-Output 'TOTAL IDENTIDAD: 5 comprobaciones aprobadas. Sin SQL.' 
