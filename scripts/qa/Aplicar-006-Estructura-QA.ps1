# Preparado: requiere autorizacion expresa para SOLO 006 estructural.
param([switch]$AutorizarEstructura006)
$ErrorActionPreference='Stop'
if(!$AutorizarEstructura006){throw 'Falta autorizacion expresa para aplicar exclusivamente 006 en QA. No se conecta.'}
Import-Module (Join-Path $PSScriptRoot 'QA.Common.psm1') -Force
$cfg=Get-QaConfig
$running=@(Get-CimInstance Win32_Process -Filter "Name = 'ForzaSuplementos.Presentacion.exe'" | Where-Object {$_.ExecutablePath -and $_.ExecutablePath.StartsWith($cfg.Root+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)})
if($running.Count){throw 'Cerrar la aplicacion del repositorio por su interfaz antes de desplegar. No se finalizan procesos.'}
& (Join-Path $PSScriptRoot 'Preparar-006-Lectura.ps1')
if(!$?){throw 'Preflight 006 no aprobado.'}
$path=Join-Path $cfg.Root 'sql/qa/006_Catalogos_QA.sql'
$source=[IO.File]::ReadAllText($path)
$hash=(Get-FileHash $path -Algorithm SHA256).Hash
$cn=Open-QaConnection
try{
 $counts=Invoke-QaQuery $cn 'SELECT s.name Esquema,t.name Tabla,SUM(p.rows) Filas FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id JOIN sys.partitions p ON p.object_id=t.object_id AND p.index_id IN(0,1) GROUP BY s.name,t.name;'
 $definitions=Invoke-QaQuery $cn 'SELECT p.name Nombre,m.definition Codigo FROM sys.procedures p JOIN sys.sql_modules m ON m.object_id=p.object_id WHERE p.schema_id=SCHEMA_ID(''dbo'');'
 Assert-QaDestination $cn
}finally{$cn.Dispose()}
if((Get-FileHash $path -Algorithm SHA256).Hash -cne $hash){throw 'El script cambio durante la preparacion.'}
$folder=Join-Path $cfg.Root ('private/006-despliegue-'+[datetime]::UtcNow.ToString('yyyyMMdd-HHmmss-fffffff'))
[void][IO.Directory]::CreateDirectory($folder)
$counts | Export-Clixml (Join-Path $folder 'conteos-previos.xml')
$definitions | Export-Clixml (Join-Path $folder 'definiciones-previas.xml')
$sqlcmd=(Get-Command sqlcmd -ErrorAction Stop).Source
$pref=$ErrorActionPreference
try{
 $ErrorActionPreference='Continue'
 $output=& $sqlcmd -S $cfg.Server -d ForzaSuplementosDB_QA -E -C -b -r 1 -v "QaExpectedServer=$($cfg.ExpectedServer)" -i $path 2>&1
 $code=$LASTEXITCODE
}finally{$ErrorActionPreference=$pref}
$output | Set-Content (Join-Path $folder 'sqlcmd.log') -Encoding UTF8
if($code -ne 0){throw '006 no termino correctamente: detener y verificar rollback en lectura. No reintentar ni revertir automaticamente.'}
$cn=Open-QaConnection
try{
 $state=Invoke-QaQuery $cn 'SELECT @@TRANCOUNT Transacciones,(SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped=0) Tablas,(SELECT COUNT(*) FROM sys.procedures WHERE is_ms_shipped=0) Procedimientos,(SELECT activa FROM dbo.SeguridadEstado WHERE id=1) Seguridad,(SELECT COUNT(*) FROM dbo.CredencialesUsuario) Credenciales;'
 $r=$state.Rows[0]
 if($r.Transacciones -ne 0 -or $r.Tablas -ne 15 -or $r.Procedimientos -ne 43 -or $r.Seguridad -or $r.Credenciales -ne 0){throw 'Estado posterior inesperado; detener sin reversion adicional.'}
 $after=Invoke-QaQuery $cn 'SELECT s.name Esquema,t.name Tabla,SUM(p.rows) Filas FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id JOIN sys.partitions p ON p.object_id=t.object_id AND p.index_id IN(0,1) GROUP BY s.name,t.name;'
 foreach($row in $counts.Rows){$m=@($after.Rows | Where-Object {$_.Esquema -eq $row.Esquema -and $_.Tabla -eq $row.Tabla});if($m.Count -ne 1 -or $m[0].Filas -ne $row.Filas){throw 'Conteos existentes cambiaron; detener.'}}
 $installed=Invoke-QaQuery $cn 'SELECT p.name Nombre,m.definition Codigo FROM sys.procedures p JOIN sys.sql_modules m ON m.object_id=p.object_id WHERE p.schema_id=SCHEMA_ID(''dbo'');'
 foreach($old in $definitions.Rows){$m=@($installed.Rows | Where-Object {$_.Nombre -eq $old.Nombre});if($m.Count -ne 1 -or [string]$m[0].Codigo -cne [string]$old.Codigo){throw 'Cambio de definicion preexistente; detener.'}}
 foreach($m in [regex]::Matches($source,"(?s)EXEC sys.sp_executesql N'((?:[^']|'')*)';")){
  $expected=$m.Groups[1].Value.Replace("''","'")
  $name=[regex]::Match($expected,'CREATE OR ALTER PROCEDURE dbo\.(\w+)').Groups[1].Value
  $actual=@($installed.Rows | Where-Object {$_.Nombre -eq $name})
  if($actual.Count -ne 1){throw 'Contrato 006 ausente.'}
  $eb=[regex]::Match($expected,'(?is)\bAS\s+BEGIN\b(.*)').Groups[1].Value
  $ab=[regex]::Match([string]$actual[0].Codigo,'(?is)\bAS\s+BEGIN\b(.*)').Groups[1].Value
  if(($eb -replace '\s+',' ').Trim() -cne ($ab -replace '\s+',' ').Trim()){throw 'Contrato 006 distinto de fuente.'}
 }
 $objects=Invoke-QaQuery $cn "SELECT (SELECT COUNT(*) FROM dbo.Proveedores) Proveedores,(SELECT COUNT(*) FROM dbo.Marcas) Marcas,(SELECT COUNT(*) FROM dbo.Productos WHERE idMarca IS NOT NULL) Asociaciones,(SELECT COUNT(*) FROM sys.foreign_keys WHERE name='FK_Productos_Marca' AND is_disabled=0 AND is_not_trusted=0) FK,(SELECT COUNT(*) FROM sys.indexes WHERE (object_id=OBJECT_ID('dbo.Proveedores') AND name IN('PK_Proveedores','UX_Proveedores_Cuit')) OR (object_id=OBJECT_ID('dbo.Marcas') AND name IN('PK_Marcas','UQ_Marcas_Nombre')) OR (object_id=OBJECT_ID('dbo.Productos') AND name='IX_Productos_Marca')) Indices,(SELECT COUNT(*) FROM sys.check_constraints WHERE name IN('CK_Proveedores_Nombre','CK_Proveedores_Cuit','CK_Marcas_Nombre') AND is_disabled=0 AND is_not_trusted=0) Restricciones;"
 $o=$objects.Rows[0]
 if($o.Proveedores -ne 0 -or $o.Marcas -ne 0 -or $o.Asociaciones -ne 0 -or $o.FK -ne 1 -or $o.Indices -ne 5 -or $o.Restricciones -ne 3){throw 'Objetos 006 inesperados; detener.'}
 [pscustomobject]@{Migracion='006';Tablas=15;Procedimientos=43;NuevosContratos=6;PBKDF2=$false;FixturesEjecutados=$false;ConteosPreviosConservados=$true;DefinicionesPreviasConservadas=$true;VerificacionObjetos=$true} | ConvertTo-Json | Set-Content (Join-Path $folder 'resultado.json') -Encoding UTF8
 Write-Output '006 aplicada exclusivamente a QA. 15 tablas/43 SP; seis contratos nuevos; sin fixtures ni activacion de seguridad.'
}finally{$cn.Dispose()}
