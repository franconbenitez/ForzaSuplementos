# Preparado. SIN permiso nuevo solo se admite -VerificarSoloLectura.
param([switch]$AutorizarEstructura007,[switch]$VerificarSoloLectura)
$ErrorActionPreference='Stop'
if($AutorizarEstructura007 -and $VerificarSoloLectura){throw 'Elegir solo lectura o despliegue autorizado; no ambos.'}
if(!$AutorizarEstructura007 -and !$VerificarSoloLectura){throw 'Falta autorizacion especifica para 007. No se conecta.'}
Import-Module (Join-Path $PSScriptRoot 'QA.Common.psm1') -Force
Import-Module (Join-Path $PSScriptRoot '007.Validacion.psm1') -Force -DisableNameChecking
$cfg=Get-QaConfig
$path=Join-Path $cfg.Root 'sql/qa/007_Compras_QA.sql'
$source=[IO.File]::ReadAllText($path)
Assert-007Plan $source
$hash=(Get-FileHash $path -Algorithm SHA256).Hash
$running=@(Get-CimInstance Win32_Process -Filter "Name = 'ForzaSuplementos.Presentacion.exe'" | Where-Object {$_.ExecutablePath -and $_.ExecutablePath.StartsWith($cfg.Root+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)})
if($running.Count){throw 'Cerrar aplicacion del repositorio por su interfaz. No se finalizan procesos.'}
& (Join-Path $PSScriptRoot 'Preparar-007-Lectura.ps1')
if(!$?){throw 'Preflight de dependencias no aprobado.'}
$folder=Join-Path $cfg.Root ('private/007-'+$(if($VerificarSoloLectura){'preflight-'}else{'despliegue-'})+[datetime]::UtcNow.ToString('yyyyMMdd-HHmmss-fffffff'))
[void][IO.Directory]::CreateDirectory($folder)
$cn=Open-QaConnection
try{
 $destination=Invoke-QaQuery $cn "SELECT DB_NAME() Base,CONVERT(nvarchar(128),SERVERPROPERTY('ServerName')) Servidor,(SELECT CONVERT(nvarchar(128),value) FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment') Marca;"
 Assert-007Destination $destination.Rows[0].Base $destination.Rows[0].Servidor $cfg.ExpectedServer $destination.Rows[0].Marca
 $state=Invoke-QaQuery $cn "SELECT @@TRANCOUNT Transacciones,(SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped=0) Tablas,(SELECT COUNT(*) FROM sys.procedures WHERE is_ms_shipped=0) Procedimientos,(SELECT COUNT(*) FROM sys.foreign_keys) FK,(SELECT COUNT(*) FROM sys.indexes WHERE object_id IN(SELECT object_id FROM sys.tables) AND index_id>0) Indices,(SELECT COUNT(*) FROM sys.check_constraints) Checks,(SELECT COUNT(*) FROM sys.objects WHERE name IN('Compras','DetalleCompras','sp_Compras_Registrar','sp_Compras_Historial','sp_Compras_Detalle','MovimientosStock','sp_Inventario_Ajustar')) Objetos007,(SELECT COUNT(*) FROM sys.indexes WHERE name IN('PK_Compras','UQ_Compras_Operacion','IX_Compras_FechaProveedor','PK_DetalleCompras','UQ_DetalleCompras_Producto')) Residuos007,(SELECT activa FROM dbo.SeguridadEstado WHERE id=1) Seguridad,(SELECT COUNT(*) FROM dbo.CredencialesUsuario) Credenciales,(SELECT COUNT(*) FROM sys.dm_tran_session_transactions st JOIN sys.dm_exec_sessions s ON s.session_id=st.session_id JOIN sys.dm_tran_database_transactions dt ON dt.transaction_id=st.transaction_id WHERE dt.database_id=DB_ID() AND s.is_user_process=1 AND s.session_id<>@@SPID) OtrasTransacciones;"
 Assert-007Baseline $state.Rows[0]
 $counts=Invoke-QaQuery $cn 'SELECT s.name Esquema,t.name Tabla,SUM(p.rows) Filas FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id JOIN sys.partitions p ON p.object_id=t.object_id AND p.index_id IN(0,1) GROUP BY s.name,t.name;'
 $definitions=Invoke-QaQuery $cn 'SELECT p.name Nombre,m.definition Codigo,m.uses_ansi_nulls AnsiNulls,m.uses_quoted_identifier QuotedIdentifier FROM sys.procedures p JOIN sys.sql_modules m ON m.object_id=p.object_id WHERE p.schema_id=SCHEMA_ID(''dbo'');'
 if(@($definitions.Rows | Where-Object {$_.Codigo -is [DBNull]}).Count){throw 'Definicion previa ilegible.'}
 $counts | Export-Clixml (Join-Path $folder 'conteos-previos.xml')
 $definitions | Export-Clixml (Join-Path $folder 'definiciones-previas.xml')
 $columns=Invoke-QaQuery $cn 'SELECT t.object_id Id,QUOTENAME(s.name)+''.''+QUOTENAME(t.name) Tabla,QUOTENAME(c.name) Columna,c.column_id Orden,TYPE_NAME(c.user_type_id) Tipo,c.max_length Longitud,c.precision Precision,c.scale Escala,c.is_nullable Nulable FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id JOIN sys.columns c ON c.object_id=t.object_id ORDER BY s.name,t.name,c.column_id;'
 $columns | Export-Clixml (Join-Path $folder 'columnas-previas.xml')
 $indexes=Invoke-QaQuery $cn 'SELECT s.name Esquema,t.name Tabla,i.name Indice,i.is_unique Unico,i.has_filter Filtrado,i.filter_definition Filtro FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id JOIN sys.indexes i ON i.object_id=t.object_id WHERE i.index_id>0;'
 $indexes | Export-Clixml (Join-Path $folder 'indices-previos.xml')
 $constraints=Invoke-QaQuery $cn 'SELECT s.name Esquema,t.name Tabla,o.name Restriccion,o.type Tipo,OBJECT_DEFINITION(o.object_id) Definicion FROM sys.objects o JOIN sys.tables t ON t.object_id=o.parent_object_id JOIN sys.schemas s ON s.schema_id=t.schema_id WHERE o.type IN(''C'',''D'',''PK'',''UQ'',''F'');'
 $constraints | Export-Clixml (Join-Path $folder 'restricciones-previas.xml')
 $foreignKeys=Invoke-QaQuery $cn 'SELECT f.name Nombre,OBJECT_SCHEMA_NAME(f.parent_object_id) EsquemaHija,OBJECT_NAME(f.parent_object_id) Hija,COL_NAME(k.parent_object_id,k.parent_column_id) ColumnaHija,OBJECT_SCHEMA_NAME(f.referenced_object_id) EsquemaPadre,OBJECT_NAME(f.referenced_object_id) Padre,COL_NAME(k.referenced_object_id,k.referenced_column_id) ColumnaPadre,f.is_disabled Deshabilitada,f.is_not_trusted NoConfiable FROM sys.foreign_keys f JOIN sys.foreign_key_columns k ON k.constraint_object_id=f.object_id;'
 $foreignKeys | Export-Clixml (Join-Path $folder 'relaciones-previas.xml')
 $integrity=@()
 foreach($group in ($columns.Rows | Group-Object Tabla)){
  $cols=(@($group.Group | Sort-Object Orden | ForEach-Object {[string]$_.Columna}) -join ',')
  $query=Get-007IntegrityQuery $group.Name $cols
  $digest=(Invoke-QaQuery $cn $query).Rows[0].Huella
  if($digest -isnot [byte[]] -or $digest.Length -ne 32){throw 'Huella previa invalida.'}
  $integrity+=@{Query=$query;Digest=[Convert]::ToBase64String($digest)}
 }
 Assert-QaDestination $cn
 [pscustomobject]@{SoloLectura=[bool]$VerificarSoloLectura;ScriptSHA256=$hash;Head=(& git -C $cfg.Root rev-parse HEAD);Tablas=15;Procedimientos=43;FK=13;Indices=23;Checks=9;IntegridadTablas=$integrity.Count;SinInstalacionParcial=$true;DestinoVerificado=$true} | ConvertTo-Json | Set-Content (Join-Path $folder 'preflight.json') -Encoding UTF8
 if($VerificarSoloLectura){
  foreach($entry in $integrity){$digest=(Invoke-QaQuery $cn $entry.Query).Rows[0].Huella;if([Convert]::ToBase64String($digest) -cne $entry.Digest){throw 'Datos cambiantes durante preflight.'}}
  $integrity=$null;$digest=$null
  Write-Output '007 preflight SOLO LECTURA aprobado: 15 tablas/43 SP; destino, dependencias, ausencia de objetos parciales y huellas (incluidas tablas vacias) verificados. NO se ejecuta sqlcmd.'
  return
 }
}finally{$cn.Dispose()}
# Solo se alcanza con autorizacion expresa. El SQL revisado es el unico archivo ejecutable.
if((Get-FileHash $path -Algorithm SHA256).Hash -cne $hash){throw 'Script modificado durante preflight.'}
Assert-007Plan ([IO.File]::ReadAllText($path))
$sqlcmd=(Get-Command sqlcmd -ErrorAction Stop).Source
$pref=$ErrorActionPreference
try{
 $ErrorActionPreference='Continue'
 $output=& $sqlcmd -S $cfg.Server -d ForzaSuplementosDB_QA -E -C -b -r 1 -v "QaExpectedServer=$($cfg.ExpectedServer)" -i $path 2>&1
 $code=$LASTEXITCODE
}finally{$ErrorActionPreference=$pref}
$output | Set-Content (Join-Path $folder 'sqlcmd.log') -Encoding UTF8
if($code -ne 0){
 # sqlcmd ya termino: inspeccion de objetos en conexion nueva, sin ROLLBACK/DDL/DML.
 $inspect=Open-QaConnection
 try{
  $actual=Invoke-QaQuery $inspect "SELECT @@TRANCOUNT TransaccionesEnConexionDeInspeccion,(SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped=0) Tablas,(SELECT COUNT(*) FROM sys.procedures WHERE is_ms_shipped=0) Procedimientos,OBJECT_ID('dbo.Compras','U') Compras,OBJECT_ID('dbo.DetalleCompras','U') DetalleCompras;"
  $actual | Export-Clixml (Join-Path $folder 'estado-tras-error.xml')
 }finally{$inspect.Dispose()}
 throw '007 no termino correctamente. Inspeccion de estado guardada; detener sin reintento ni reversion. La transaccion cero de la conexion nueva no demuestra por si sola integridad del rollback.'
}
& (Join-Path $cfg.Root 'tests/qa/Verificar-007-Lectura.ps1')
if(!$?){throw 'Verificacion posterior 007 fallo; detener sin reversion adicional.'}
$cn=Open-QaConnection
try{
 $after=Invoke-QaQuery $cn 'SELECT s.name Esquema,t.name Tabla,SUM(p.rows) Filas FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id JOIN sys.partitions p ON p.object_id=t.object_id AND p.index_id IN(0,1) GROUP BY s.name,t.name;'
 foreach($row in $counts.Rows){$m=@($after.Rows | Where-Object {$_.Esquema -eq $row.Esquema -and $_.Tabla -eq $row.Tabla});if($m.Count -ne 1 -or $m[0].Filas -ne $row.Filas){throw 'Conteos anteriores distintos.'}}
 foreach($entry in $integrity){$digest=(Invoke-QaQuery $cn $entry.Query).Rows[0].Huella;if([Convert]::ToBase64String($digest) -cne $entry.Digest){throw 'Datos anteriores distintos; detener.'}}
 $integrity=$null;$digest=$null
 $installed=Invoke-QaQuery $cn 'SELECT p.name Nombre,m.definition Codigo,m.uses_ansi_nulls AnsiNulls,m.uses_quoted_identifier QuotedIdentifier FROM sys.procedures p JOIN sys.sql_modules m ON m.object_id=p.object_id WHERE p.schema_id=SCHEMA_ID(''dbo'');'
 foreach($old in $definitions.Rows){$m=@($installed.Rows | Where-Object {$_.Nombre -eq $old.Nombre});if($m.Count -ne 1 -or [string]$m[0].Codigo -cne [string]$old.Codigo -or $m[0].AnsiNulls -ne $old.AnsiNulls -or $m[0].QuotedIdentifier -ne $old.QuotedIdentifier){throw 'Contrato anterior distinto.'}}
 [pscustomobject]@{Migracion='007';Tablas=17;Procedimientos=46;FK=17;Indices=28;Checks=13;DatosPreviosConservados=$true;DefinicionesPreviasConservadas=$true;FixturesEjecutados=$false;PBKDF2=$false} | ConvertTo-Json | Set-Content (Join-Path $folder 'resultado.json') -Encoding UTF8
 Write-Output '007 estructural aplicada exclusivamente en QA: 17 tablas/46 SP. Datos anteriores conservados; sin compras, ensayos ni activacion PBKDF2.'
}finally{$cn.Dispose()}
