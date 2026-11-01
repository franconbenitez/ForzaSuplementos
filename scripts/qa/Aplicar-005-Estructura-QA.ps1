# Solo 005 estructural. NO provisiona claves, NO activa seguridad, NO aplica otras migraciones.
param([switch]$AutorizarEstructura005)
$ErrorActionPreference='Stop'
if(!$AutorizarEstructura005){throw 'Falta autorizacion expresa para 005 estructural en QA. No se conecta.'}
Import-Module (Join-Path $PSScriptRoot 'QA.Common.psm1') -Force
$cfg=Get-QaConfig
$exe=Join-Path $cfg.Root 'ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Presentacion/bin/Debug/ForzaSuplementos.Presentacion.exe'
$running=@(Get-CimInstance Win32_Process -Filter "Name = 'ForzaSuplementos.Presentacion.exe'" | Where-Object {$_.ExecutablePath -and $_.ExecutablePath.StartsWith($cfg.Root+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)})
if($running.Count){throw ('Cerrar primero la aplicacion del principal por su interfaz. PID: '+(($running|ForEach-Object ProcessId) -join ', '))}
$sourcePath=Join-Path $cfg.Root 'sql/qa/005_Seguridad_QA.sql'
$source=[IO.File]::ReadAllText($sourcePath)
$batches=@([regex]::Split(($source -replace '(?m)^:on error exit\s*',''),'(?im)^\s*GO\s*\r?$')|Where-Object {![string]::IsNullOrWhiteSpace($_)})
foreach($batch in $batches){if(!$batch.Contains("IF DB_NAME()<>N'ForzaSuplementosDB_QA'") -or !$batch.Contains('Forza-QA-Aislada-v1') -or !$batch.Contains('$(QaExpectedServer)')){throw 'Lote de 005 sin protecciones; no se aplica.'}}
$names=@([regex]::Matches($source,'CREATE OR ALTER PROCEDURE dbo\.(\w+)')|ForEach-Object {$_.Groups[1].Value})
$ddlOnly=[regex]::Replace($source,"(?s)EXEC sys.sp_executesql N'((?:[^']|'')*)';",'-- definicion de procedimiento')
$ddlOnly=$ddlOnly -replace '(?m)--.*$',''
if($ddlOnly -match '\b(UPDATE|DELETE|MERGE|EXEC|EXECUTE|DROP|TRUNCATE|RESTORE|BACKUP)\b'){throw 'Operacion fuera del alcance estructural; no se aplica.'}
if($names.Count -ne 9){throw 'Alcance de 005 distinto del revisado: requiere nueva revision.'}
$cn=Open-QaConnection
$folder=Join-Path $cfg.Root ('private/005-estructura-'+[datetime]::UtcNow.ToString('yyyyMMdd-HHmmss-fffffff'))
[void][IO.Directory]::CreateDirectory($folder)
try{
 $transactionState=Invoke-QaQuery $cn 'SELECT @@TRANCOUNT Cantidad;'
 if($transactionState.Rows[0].Cantidad -ne 0){throw 'Transaccion previa inesperada; no se escribe.'}
 # La huella solo vive en memoria; no se exportan filas, claves ni valores derivados.
 $userDigestBefore=(Invoke-QaQuery $cn "SELECT HASHBYTES('SHA2_256',CONVERT(varbinary(max),(SELECT * FROM dbo.Usuarios ORDER BY idUsuario FOR XML RAW,BINARY BASE64))) Huella;").Rows[0].Huella
 $state=Invoke-QaQuery $cn "SELECT OBJECT_ID('dbo.SeguridadEstado','U') Estado,OBJECT_ID('dbo.CredencialesUsuario','U') Credenciales;"
 if($state.Rows[0].Estado -isnot [DBNull]){throw '005 parece instalada o parcial: inspeccionar antes; no se reejecuta automaticamente.'}
 if($state.Rows[0].Credenciales -isnot [DBNull]){throw 'Credenciales ya existe; revisar estado parcial antes de aplicar.'}
 $before=Invoke-QaQuery $cn "SELECT p.name Nombre,m.definition Definicion,m.uses_ansi_nulls AnsiNulls,m.uses_quoted_identifier QuotedIdentifier FROM sys.procedures p JOIN sys.sql_modules m ON m.object_id=p.object_id WHERE p.schema_id=SCHEMA_ID('dbo') AND p.name IN('sp_Usuarios_Login','sp_Usuarios_CambiarEstado');"
 if($before.Rows.Count -ne 2 -or @($before.Rows|Where-Object {$_['Definicion'] -is [DBNull]}).Count){throw 'No se pueden conservar ambas definiciones anteriores; no se aplica.'}
 $snapshot=@($before.Rows|ForEach-Object {[pscustomobject]@{Nombre=[string]$_.Nombre;Definicion=[string]$_.Definicion;AnsiNulls=[bool]$_.AnsiNulls;QuotedIdentifier=[bool]$_.QuotedIdentifier}})
 ConvertTo-Json -InputObject $snapshot -Depth 5|Set-Content (Join-Path $folder 'definiciones-previas.json') -Encoding UTF8
 $counts=Invoke-QaQuery $cn "SELECT s.name Esquema,t.name Tabla,SUM(p.rows) Filas FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id JOIN sys.partitions p ON p.object_id=t.object_id AND p.index_id IN(0,1) GROUP BY s.name,t.name ORDER BY s.name,t.name;"
 $counts|Export-Clixml (Join-Path $folder 'conteos-previos.xml')
 [pscustomobject]@{Etapa='005 estructural';ScriptSHA256=(Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash;Head=(& git -C $cfg.Root rev-parse HEAD);TablasPrevias=$counts.Rows.Count;ClavesModificadas=$false;CorteActivado=$false}|ConvertTo-Json|Set-Content (Join-Path $folder 'alcance.json') -Encoding UTF8
 Assert-QaDestination $cn
}finally{$cn.Dispose()}
# El SQL administra su propia transaccion entre lotes. sqlcmd cierra la conexion al fallar (-b/:on error exit).
$sqlcmdPath=(Get-Command sqlcmd -ErrorAction Stop).Source
$previousPreference=$ErrorActionPreference
try{
 $ErrorActionPreference='Continue'
 $output=& $sqlcmdPath -S $cfg.Server -d ForzaSuplementosDB_QA -E -C -b -r 1 -v "QaExpectedServer=$($cfg.ExpectedServer)" -i $sourcePath 2>&1
 $sqlExitCode=$LASTEXITCODE
}finally{$ErrorActionPreference=$previousPreference}
$output|Set-Content (Join-Path $folder 'sqlcmd.log') -Encoding UTF8
if($sqlExitCode -ne 0){throw '005 no termino con exito. Revisar estado QA en lectura y log privado; no reintentar ni continuar automaticamente.'}
$cn=Open-QaConnection
try{
 $mode=(Invoke-QaQuery $cn 'SELECT activa FROM dbo.SeguridadEstado WHERE id=1;').Rows
 if($mode.Count -ne 1 -or [bool]$mode[0].activa){throw 'Modo de seguridad inesperado: detener. No se modifica para corregirlo automaticamente.'}
 if((Invoke-QaQuery $cn 'SELECT COUNT(*) Cantidad FROM dbo.CredencialesUsuario;').Rows[0].Cantidad -ne 0){throw 'Credenciales no vacias: detener y revisar.'}
 $after=Invoke-QaQuery $cn "SELECT s.name Esquema,t.name Tabla,SUM(p.rows) Filas FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id JOIN sys.partitions p ON p.object_id=t.object_id AND p.index_id IN(0,1) GROUP BY s.name,t.name ORDER BY s.name,t.name;"
 foreach($row in $counts.Rows){$match=@($after.Rows|Where-Object {$_.Esquema -eq $row.Esquema -and $_.Tabla -eq $row.Tabla});if($match.Count -ne 1 -or $match[0].Filas -ne $row.Filas){throw 'Conteos existentes cambiaron; detener y revisar sin corregir datos automaticamente.'}}
 $userDigestAfter=(Invoke-QaQuery $cn "SELECT HASHBYTES('SHA2_256',CONVERT(varbinary(max),(SELECT * FROM dbo.Usuarios ORDER BY idUsuario FOR XML RAW,BINARY BASE64))) Huella;").Rows[0].Huella
 if([Convert]::ToBase64String($userDigestBefore) -cne [Convert]::ToBase64String($userDigestAfter)){throw 'Usuarios existentes no coinciden: detener; no se revierte sin autorizacion.'}
 $userDigestBefore=$null;$userDigestAfter=$null
 $installed=Invoke-QaQuery $cn 'SELECT name FROM sys.procedures WHERE schema_id=SCHEMA_ID(''dbo'');'
 foreach($name in $names){if(!@($installed.Rows|Where-Object {$_.name -eq $name}).Count){throw 'Falta un contrato de 005; detener.'}}
 $definitions=Invoke-QaQuery $cn 'SELECT p.name Nombre,m.definition Codigo FROM sys.procedures p JOIN sys.sql_modules m ON m.object_id=p.object_id WHERE p.schema_id=SCHEMA_ID(''dbo'');'
 foreach($match in [regex]::Matches($source,"(?s)EXEC sys.sp_executesql N'((?:[^']|'')*)';")){
  $expected=$match.Groups[1].Value.Replace("''","'")
  $procName=[regex]::Match($expected,'CREATE OR ALTER PROCEDURE dbo\.(\w+)').Groups[1].Value
  $actual=@($definitions.Rows|Where-Object {$_.Nombre -eq $procName})
  if($actual.Count -ne 1){throw 'Falta definicion posterior al despliegue.'}
  $expectedBody=[regex]::Match($expected,'(?is)\bAS\s+BEGIN\b(.*)').Groups[1].Value
  $actualBody=[regex]::Match([string]$actual[0].Codigo,'(?is)\bAS\s+BEGIN\b(.*)').Groups[1].Value
  if(($expectedBody -replace '\s+',' ').Trim() -cne ($actualBody -replace '\s+',' ').Trim()){throw 'Definicion posterior distinta de 005: detener.'}
 }
 $sentinel='__QA_CONTRATO_SIN_CUENTA__'
 if((Invoke-QaQuery $cn 'SELECT COUNT(*) Cantidad FROM dbo.Usuarios WHERE usuario=@u;' @{'@u'=$sentinel}).Rows[0].Cantidad -ne 0){throw 'Sentinela existente; no se prueba login.'}
 $cmd=$cn.CreateCommand();$cmd.CommandType='StoredProcedure';$cmd.CommandText='dbo.sp_Usuarios_Login'
 [void]$cmd.Parameters.Add('@usuario',[Data.SqlDbType]::VarChar,50);$cmd.Parameters['@usuario'].Value=$sentinel
 [void]$cmd.Parameters.Add('@contrasena',[Data.SqlDbType]::VarChar,100);$cmd.Parameters['@contrasena'].Value='PRUEBA_CONTRATO_NO_CREDENCIAL'
 try{$reader=$cmd.ExecuteReader();try{if($reader.Read()){throw 'Login de contrato devolvio una cuenta inesperada.'}}finally{$reader.Dispose()}}finally{$cmd.Dispose()}
 [pscustomobject]@{Etapa='005';EstructuraAplicada=$true;ModoSeguroActivo=$false;Credenciales=0;Tablas=$after.Rows.Count;Procedimientos=$installed.Rows.Count;ConteosPreviosConservados=$true;UsuariosSinCambios=$true;ContratosVerificados=9;LoginHeredadoSelectDisponible=$true}|ConvertTo-Json|Set-Content (Join-Path $folder 'resultado.json') -Encoding UTF8
 Write-Output "005 estructural aplicada exclusivamente a QA. Tablas: $($after.Rows.Count); SP: $($installed.Rows.Count). Modo seguro inactivo y sin credenciales provisionadas."
}finally{$cn.Dispose()}
