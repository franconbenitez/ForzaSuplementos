# Guardas del aplicador 008: sin conexion SQL; no se usa -AutorizarEstructura008 solo.
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Import-Module (Join-Path $root 'scripts/qa/008.Validacion.psm1') -Force -DisableNameChecking
$n=0
function Check($ok,$text){if(!$ok){throw $text};$script:n++;Write-Output "OK: $text"}
function Reject($text,[scriptblock]$code){$rejected=$false;try{&$code | Out-Null}catch{$rejected=$true};Check $rejected $text}
$source=[IO.File]::ReadAllText((Join-Path $root 'sql/qa/008_Inventario_QA.sql'))
Assert-008Plan $source;Check $true 'Plan SQL revisado aceptado'
Assert-008Plan ($source.Replace("`r`n","`n").Replace("`n","`r`n"));Check $true 'Hash normalizado admite LF y CRLF'
Reject 'Cambio del SQL exige nueva revision' {Assert-008Plan ($source+"`nINSERT dbo.Productos DEFAULT VALUES;")}
Reject 'Destino SQL distinto rechazado offline' {Assert-008Plan ($source.Replace('ForzaSuplementosDB_QA','OTRA_BASE'))}
Reject 'Cambio de contratos rechazado' {Assert-008Plan ($source.Replace('sp_Inventario_Stock','sp_Otro_Stock'))}
Assert-008Destination 'ForzaSuplementosDB_QA' 'QA-SERVIDOR' 'QA-SERVIDOR' 'Forza-QA-Aislada-v1';Check $true 'Destino QA coincidente aceptado'
Reject 'Base original rechazada' {Assert-008Destination 'ForzaSuplementosDB' 'QA-SERVIDOR' 'QA-SERVIDOR' 'Forza-QA-Aislada-v1'}
Reject 'Otra base rechazada' {Assert-008Destination 'OTRA_BASE' 'QA-SERVIDOR' 'QA-SERVIDOR' 'Forza-QA-Aislada-v1'}
Reject 'Servidor distinto rechazado' {Assert-008Destination 'ForzaSuplementosDB_QA' 'OTRO' 'QA-SERVIDOR' 'Forza-QA-Aislada-v1'}
Reject 'Marca incorrecta rechazada' {Assert-008Destination 'ForzaSuplementosDB_QA' 'QA-SERVIDOR' 'QA-SERVIDOR' 'OTRA'}
Reject 'Servidor esperado vacio rechazado' {Assert-008Destination 'ForzaSuplementosDB_QA' 'QA-SERVIDOR' '' 'Forza-QA-Aislada-v1'}
function Baseline{return @{Transacciones=0;OtrasTransacciones=0;Tablas=17;Procedimientos=46;FK=17;Indices=28;Checks=13;Objetos008=0;Residuos008=0;Columna008=[DBNull]::Value;Seguridad=0;Credenciales=0}}
$b=Baseline;Assert-008Baseline ([pscustomobject]$b);Check $true 'Baseline 007 valido aceptado'
foreach($pair in @(@('Transacciones',1),@('OtrasTransacciones',1),@('Tablas',18),@('Procedimientos',47),@('FK',18),@('Indices',29),@('Checks',14),@('Objetos008',1),@('Residuos008',1),@('Columna008',4),@('Seguridad',1),@('Credenciales',1))){
 $b=Baseline;$b[$pair[0]]=$pair[1]
 Reject ('Estado incompatible rechazado: '+$pair[0]) {Assert-008Baseline ([pscustomobject]$b)}
}
$app=Join-Path $root 'scripts/qa/Aplicar-008-Estructura-QA.ps1'
foreach($p in @($app,(Join-Path $root 'scripts/qa/008.Validacion.psm1'),(Join-Path $root 'tests/qa/Verificar-008-Lectura.ps1'))){
 $tokens=$null;$errors=$null;[void][Management.Automation.Language.Parser]::ParseFile($p,[ref]$tokens,[ref]$errors);Check ($errors.Count -eq 0) ('Sintaxis PowerShell: '+[IO.Path]::GetFileName($p))
}
$previous=$ErrorActionPreference
try{
 $ErrorActionPreference='Continue'
 $output=& powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File $app 2>&1
 $code=$LASTEXITCODE
}finally{$ErrorActionPreference=$previous}
Check ($code -ne 0 -and ($output | Out-String) -match 'Falta autorizacion especifica' -and ($output | Out-String) -notmatch 'Revision 008 en lectura') 'Sin permiso ni modo lectura rechaza antes de conectar'
try{
 $ErrorActionPreference='Continue'
 $output=& powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File $app -AutorizarEstructura008 -VerificarSoloLectura 2>&1
 $code=$LASTEXITCODE
}finally{$ErrorActionPreference=$previous}
Check ($code -ne 0 -and ($output | Out-String) -match 'no ambos') 'Modos contradictorios rechazados antes de conectar'
$qualified=Get-008ProcedureContract 'CREATE OR ALTER PROCEDURE dbo.sp_T @id int,@monto decimal(10,2),@nuevo int OUTPUT AS BEGIN SELECT 1; END;'
$unqualified=Get-008ProcedureContract 'CREATE PROCEDURE sp_T @id INT, @monto DECIMAL (10, 2), @nuevo INT OUT AS BEGIN SELECT 1; END;'
Check ($qualified.Firma -ceq $unqualified.Firma) 'Cabeceras dbo y antiguas sin esquema equivalentes'
Check ((Get-008ProcedureContract 'CREATE PROCEDURE dbo.sp_T @nombre varchar(20) AS BEGIN SELECT 1; END;').Firma -cne (Get-008ProcedureContract 'CREATE PROCEDURE dbo.sp_T @nombre varchar(21) AS BEGIN SELECT 1; END;').Firma) 'Cambios de longitud no pasan como mismo contrato'
Check ((Get-008ProcedureContract 'CREATE PROCEDURE dbo.sp_T @id int OUTPUT AS BEGIN SELECT 1; END;').Firma -cne (Get-008ProcedureContract 'CREATE PROCEDURE dbo.sp_T @id int AS BEGIN SELECT 1; END;').Firma) 'OUTPUT es parte obligatoria del contrato'
Check ((Get-008ProcedureContract 'CREATE PROCEDURE dbo.sp_T @id int=NULL AS BEGIN SELECT 1; END;').Firma -cne (Get-008ProcedureContract 'CREATE PROCEDURE dbo.sp_T @id int AS BEGIN SELECT 1; END;').Firma) 'Default NULL no se confunde con parametro obligatorio'
Reject 'Tipo no revisado se rechaza al analizar firmas' {Get-008ProcedureContract 'CREATE PROCEDURE dbo.sp_T @id sql_variant AS BEGIN SELECT 1; END;'}
$bodies=@{}
foreach($m in [regex]::Matches($source,"(?s)EXEC sys.sp_executesql N'((?:[^']|'')*)';")){
 $body=$m.Groups[1].Value.Replace("''","'")
 $contract=Get-008ProcedureContract $body
 $bodies[$contract.Nombre]=($body -replace '(?m)--.*$','')
}
Check ($bodies.Count -eq 8) 'Ocho firmas completas analizadas offline'
foreach($name in @('sp_Compras_Registrar','sp_Ventas_RegistrarConCaja')){
 $body=$bodies[$name]
 Check ([regex]::Matches($body,'(?i)\bUPDATE\s+(?:p|dbo\.Productos)\s+SET\s+stock\s*=').Count -eq 1) "$name solo actualiza stock una vez"
 Check ([regex]::Matches($body,'(?i)\bOUTPUT\s+inserted.idProducto,deleted.stock,inserted.stock\s+INTO\s+@').Count -eq 1 -and [regex]::Matches($body,'(?i)INSERT\s+dbo.MovimientosStock').Count -eq 1) "$name deriva movimiento del OUTPUT de ese UPDATE"
}
Check ($bodies['sp_Productos_Modificar'] -notmatch '(?is)SET\s+[^;]*?\bstock\s*=.*?WHERE') 'Modificar producto no asigna existencias en SET'
Check ($bodies['sp_Productos_Insertar'] -match '(?i)@stock<>0' -and $bodies['sp_Productos_Insertar'] -match '(?i)@precio,0,1') 'Insertar producto mantiene contrato de stock inicial cero'
Check (@(@('sp_Compras_Registrar','sp_Ventas_RegistrarConCaja','sp_Inventario_Ajustar') | Where-Object {$bodies[$_] -notmatch "@Resource='Forza.Caja.Unica'"}).Count -eq 0) 'Tres operaciones de stock usan el mismo bloqueo transaccional'
Write-Output "TOTAL APLICADOR 008 OFFLINE: $n comprobaciones aprobadas. Sin SQL."
