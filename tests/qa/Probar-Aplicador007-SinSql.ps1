# Guardas del aplicador 007: sin conexion SQL; no se usa -AutorizarEstructura007 solo.
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Import-Module (Join-Path $root 'scripts/qa/007.Validacion.psm1') -Force -DisableNameChecking
$n=0
function Check($ok,$text){if(!$ok){throw $text};$script:n++;Write-Output "OK: $text"}
function Reject($text,[scriptblock]$code){$rejected=$false;try{&$code | Out-Null}catch{$rejected=$true};Check $rejected $text}
$source=[IO.File]::ReadAllText((Join-Path $root 'sql/qa/007_Compras_QA.sql'))
Assert-007Plan $source;Check $true 'Plan SQL revisado aceptado'
Assert-007Plan ($source.Replace("`r`n","`n").Replace("`n","`r`n"));Check $true 'Hash normalizado admite LF y CRLF'
Reject 'Cambio del SQL exige nueva revision' {Assert-007Plan ($source+"`nINSERT dbo.Productos DEFAULT VALUES;")}
Reject 'Destino SQL distinto rechazado offline' {Assert-007Plan ($source.Replace('ForzaSuplementosDB_QA','OTRA_BASE'))}
Reject 'Cambio de contratos rechazado' {Assert-007Plan ($source.Replace('sp_Compras_Detalle','sp_Otro_Detalle'))}
Assert-007Destination 'ForzaSuplementosDB_QA' 'QA-SERVIDOR' 'QA-SERVIDOR' 'Forza-QA-Aislada-v1';Check $true 'Destino QA coincidente aceptado'
Reject 'Base original rechazada' {Assert-007Destination 'ForzaSuplementosDB' 'QA-SERVIDOR' 'QA-SERVIDOR' 'Forza-QA-Aislada-v1'}
Reject 'Otra base rechazada' {Assert-007Destination 'OTRA_BASE' 'QA-SERVIDOR' 'QA-SERVIDOR' 'Forza-QA-Aislada-v1'}
Reject 'Servidor distinto rechazado' {Assert-007Destination 'ForzaSuplementosDB_QA' 'OTRO' 'QA-SERVIDOR' 'Forza-QA-Aislada-v1'}
Reject 'Marca incorrecta rechazada' {Assert-007Destination 'ForzaSuplementosDB_QA' 'QA-SERVIDOR' 'QA-SERVIDOR' 'OTRA'}
Reject 'Servidor esperado vacio rechazado' {Assert-007Destination 'ForzaSuplementosDB_QA' 'QA-SERVIDOR' '' 'Forza-QA-Aislada-v1'}
function Baseline{return @{Transacciones=0;OtrasTransacciones=0;Tablas=15;Procedimientos=43;FK=13;Indices=23;Checks=9;Objetos007=0;Residuos007=0;Seguridad=0;Credenciales=0}}
$b=Baseline;Assert-007Baseline ([pscustomobject]$b);Check $true 'Baseline 006 valido aceptado'
foreach($pair in @(@('Transacciones',1),@('OtrasTransacciones',1),@('Tablas',16),@('Procedimientos',44),@('FK',14),@('Indices',24),@('Checks',10),@('Objetos007',1),@('Residuos007',1),@('Seguridad',1),@('Credenciales',1))){
 $b=Baseline;$b[$pair[0]]=$pair[1]
 Reject ('Estado incompatible rechazado: '+$pair[0]) {Assert-007Baseline ([pscustomobject]$b)}
}
$app=Join-Path $root 'scripts/qa/Aplicar-007-Estructura-QA.ps1'
foreach($p in @($app,(Join-Path $root 'scripts/qa/007.Validacion.psm1'),(Join-Path $root 'tests/qa/Verificar-007-Lectura.ps1'))){
 $tokens=$null;$errors=$null;[void][Management.Automation.Language.Parser]::ParseFile($p,[ref]$tokens,[ref]$errors);Check ($errors.Count -eq 0) ('Sintaxis PowerShell: '+[IO.Path]::GetFileName($p))
}
$previous=$ErrorActionPreference
try{
 $ErrorActionPreference='Continue'
 $output=& powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File $app 2>&1
 $code=$LASTEXITCODE
}finally{$ErrorActionPreference=$previous}
Check ($code -ne 0 -and ($output | Out-String) -match 'Falta autorizacion especifica' -and ($output | Out-String) -notmatch 'Revision 007 en lectura') 'Sin permiso ni modo lectura rechaza antes de conectar'
try{
 $ErrorActionPreference='Continue'
 $output=& powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File $app -AutorizarEstructura007 -VerificarSoloLectura 2>&1
 $code=$LASTEXITCODE
}finally{$ErrorActionPreference=$previous}
Check ($code -ne 0 -and ($output | Out-String) -match 'no ambos') 'Modos contradictorios rechazados antes de conectar'
Write-Output "TOTAL APLICADOR 007 OFFLINE: $n comprobaciones aprobadas. Sin SQL."
