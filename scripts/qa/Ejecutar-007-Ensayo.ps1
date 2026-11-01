# Ejecuta UNA vez exclusivamente el archivo de ensayo 007 autorizado; no lo modifica.
param([switch]$AutorizarEnsayo007)
$ErrorActionPreference='Stop'
if(!$AutorizarEnsayo007){throw 'Falta autorizacion expresa del ensayo 007; no se conecta.'}
Import-Module (Join-Path $PSScriptRoot 'QA.Common.psm1') -Force
Import-Module (Join-Path $PSScriptRoot '007.Validacion.psm1') -Force -DisableNameChecking
$cfg=Get-QaConfig
$running=@(Get-CimInstance Win32_Process -Filter "Name = 'ForzaSuplementos.Presentacion.exe'" | Where-Object {$_.ExecutablePath -and $_.ExecutablePath.StartsWith($cfg.Root+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)})
if($running.Count){throw 'Cerrar aplicacion del repositorio por su interfaz; no se finalizan procesos.'}
& (Join-Path $cfg.Root 'tests/qa/Verificar-007-Lectura.ps1')
if(!$?){throw 'Verificacion inicial 007 rechazada.'}
$path=Join-Path $cfg.Root 'tests/qa/Compras_007_Rollback_Preparado.sql'
$source=[IO.File]::ReadAllText($path)
if($source -match '(?im)^\s*GO\s*$'){throw 'Runner distinto del revisado.'}
$hash=(Get-FileHash $path -Algorithm SHA256).Hash
$source=$source.Replace('$(QaExpectedServer)',$cfg.ExpectedServer).Replace('$(AutorizarEnsayo)','SOLO_FIXTURES_ROLLBACK') -replace '(?m)^:on error exit\s*',''
if($source -match '\$\('){throw 'Variable SQLCMD sin resolver.'}
$folder=Join-Path $cfg.Root ('private/007-ensayo-'+[datetime]::UtcNow.ToString('yyyyMMdd-HHmmss-fffffff'))
[void][IO.Directory]::CreateDirectory($folder)
$cn=Open-QaConnection;$failure=$null;$executed=$false
$messages=New-Object 'System.Collections.Generic.List[string]'
$handler=[Data.SqlClient.SqlInfoMessageEventHandler]{param($sender,$e) $messages.Add($e.Message)}
$cn.add_InfoMessage($handler)
try{
 $state=Invoke-QaQuery $cn "SELECT @@TRANCOUNT Transacciones,(SELECT COUNT(*) FROM sys.dm_tran_session_transactions st JOIN sys.dm_exec_sessions s ON s.session_id=st.session_id JOIN sys.dm_tran_database_transactions dt ON dt.transaction_id=st.transaction_id WHERE dt.database_id=DB_ID() AND s.is_user_process=1 AND s.session_id<>@@SPID) OtrasTransacciones,(SELECT COUNT(*) FROM sys.objects WHERE name IN('MovimientosStock','sp_Inventario_Ajustar','sp_Inventario_Stock','sp_Inventario_Historial','sp_Inventario_Minimo')) Objetos008,COL_LENGTH('dbo.Productos','stockMinimo') Minimo;"
 if($state.Rows[0].Transacciones -ne 0 -or $state.Rows[0].OtrasTransacciones -ne 0 -or $state.Rows[0].Objetos008 -ne 0 -or $state.Rows[0].Minimo -isnot [DBNull]){throw 'Transaccion incompatible o 008 presente; no se ejecuta.'}
 $defs=Invoke-QaQuery $cn 'SELECT p.name Nombre,m.definition Codigo FROM sys.procedures p JOIN sys.sql_modules m ON m.object_id=p.object_id WHERE p.schema_id=SCHEMA_ID(''dbo'');'
 $n=0
 foreach($file in @('005_Seguridad_QA.sql','006_Catalogos_QA.sql','007_Compras_QA.sql')){
  $sql=[IO.File]::ReadAllText((Join-Path $cfg.Root ('sql/qa/'+$file)))
  foreach($m in [regex]::Matches($sql,"(?s)EXEC sys.sp_executesql N'((?:[^']|'')*)';")){
   $exp=$m.Groups[1].Value.Replace("''","'");$name=[regex]::Match($exp,'CREATE OR ALTER PROCEDURE dbo\.(\w+)').Groups[1].Value
   $actual=@($defs.Rows | Where-Object {$_.Nombre -eq $name});if($actual.Count -ne 1){throw 'Contrato previo ausente.'}
   $eb=[regex]::Match($exp,'(?is)\bAS\s+BEGIN\b(.*)').Groups[1].Value;$ab=[regex]::Match([string]$actual[0].Codigo,'(?is)\bAS\s+BEGIN\b(.*)').Groups[1].Value
   if(($eb -replace '\s+',' ').Trim() -cne ($ab -replace '\s+',' ').Trim()){throw 'Contrato previo distinto.'};$n++
  }
 }
 if($n -ne 18){throw 'Dependencias incompletas.'}
 $counts=Invoke-QaQuery $cn 'SELECT s.name Esquema,t.name Tabla,SUM(p.rows) Filas FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id JOIN sys.partitions p ON p.object_id=t.object_id AND p.index_id IN(0,1) GROUP BY s.name,t.name;'
 $counts | Export-Clixml (Join-Path $folder 'conteos-previos.xml')
 $integrity=@()
 $tables=Invoke-QaQuery $cn "SELECT t.object_id Id,QUOTENAME(s.name)+'.'+QUOTENAME(t.name) Nombre FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id WHERE t.is_ms_shipped=0;"
 foreach($table in $tables.Rows){
  $cols=Invoke-QaQuery $cn 'SELECT QUOTENAME(name) Nombre FROM sys.columns WHERE object_id=@id ORDER BY column_id;' @{'@id'=[int]$table.Id}
  $query=Get-007IntegrityQuery $table.Nombre (@($cols.Rows | ForEach-Object {[string]$_.Nombre}) -join ',')
  $digest=(Invoke-QaQuery $cn $query).Rows[0].Huella
  $integrity+=@{Query=$query;Digest=[Convert]::ToBase64String($digest)}
 }
 [pscustomobject]@{ScriptSHA256=$hash;Head=(& git -C $cfg.Root rev-parse HEAD);Contratos=18;SinTransaccionPrevia=$true;SinOtraTransaccionQa=$true} | ConvertTo-Json | Set-Content (Join-Path $folder 'preflight.json') -Encoding UTF8
 Assert-QaDestination $cn
 if((Get-FileHash $path -Algorithm SHA256).Hash -cne $hash){throw 'Fixture cambio durante preflight.'}
 $cmd=$cn.CreateCommand();$cmd.CommandText=$source;$cmd.CommandTimeout=120
 try{$executed=$true;[void]$cmd.ExecuteNonQuery()}catch{$failure=$_.Exception.ToString();$failure | Set-Content (Join-Path $folder 'error-privado.log') -Encoding UTF8}finally{$cmd.Dispose()}
 # Solo lectura incluso si hubo error; ninguna reparacion ni reintento.
 $final=Invoke-QaQuery $cn "SELECT @@TRANCOUNT Transacciones,(SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped=0) Tablas,(SELECT COUNT(*) FROM sys.procedures WHERE is_ms_shipped=0) Procedimientos,(SELECT COUNT(*) FROM dbo.Compras) Compras,(SELECT COUNT(*) FROM dbo.DetalleCompras) Detalles,(SELECT COUNT(*) FROM dbo.Productos WHERE nombre LIKE N'QA Compra %') ProductosFixture,(SELECT COUNT(*) FROM dbo.Proveedores WHERE nombre LIKE N'QA Compra %') ProveedoresFixture;"
 $f=$final.Rows[0]
 $after=Invoke-QaQuery $cn 'SELECT s.name Esquema,t.name Tabla,SUM(p.rows) Filas FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id JOIN sys.partitions p ON p.object_id=t.object_id AND p.index_id IN(0,1) GROUP BY s.name,t.name;'
 $sameCounts=$true
 foreach($row in $counts.Rows){$m=@($after.Rows | Where-Object {$_.Esquema -eq $row.Esquema -and $_.Tabla -eq $row.Tabla});if($m.Count -ne 1 -or $m[0].Filas -ne $row.Filas){$sameCounts=$false}}
 $sameData=$true
 foreach($entry in $integrity){$digest=(Invoke-QaQuery $cn $entry.Query).Rows[0].Huella;if([Convert]::ToBase64String($digest) -cne $entry.Digest){$sameData=$false}}
 $integrity=$null;$digest=$null
 $successMessage=($messages -join "`n") -match 'Compras 007 aprobadas con rollback'
 $ok=(!$failure -and $successMessage -and $f.Transacciones -eq 0 -and $f.Tablas -eq 17 -and $f.Procedimientos -eq 46 -and $f.Compras -eq 0 -and $f.Detalles -eq 0 -and $f.ProductosFixture -eq 0 -and $f.ProveedoresFixture -eq 0 -and $sameCounts -and $sameData)
 $messages | Set-Content (Join-Path $folder 'mensajes-sql.log') -Encoding UTF8
 [pscustomobject]@{Ejecutado=$executed;Exito=$ok;MensajeFinalRunner=$successMessage;Transacciones=[int]$f.Transacciones;Tablas=[int]$f.Tablas;Procedimientos=[int]$f.Procedimientos;Compras=[int]$f.Compras;Detalles=[int]$f.Detalles;ProductosFixture=[int]$f.ProductosFixture;ProveedoresFixture=[int]$f.ProveedoresFixture;ConteosIguales=$sameCounts;DatosIguales=$sameData} | ConvertTo-Json | Set-Content (Join-Path $folder 'resultado.json') -Encoding UTF8
 if(!$ok){throw 'Ensayo 007 fallo o rollback no comprobado. Detener sin reintento ni reparacion; consultar evidencia privada.'}
 Write-Output 'Ensayo 007 aprobado: compra 3 x 2.50 = 7.50; GUID repetido devuelve mismo ID; stock ficticio 3 y precio 99; historial/detalle correctos. Rollback: cero compras/detalles/fixtures/transacciones, conteos y huellas de 17 tablas iguales.'
}finally{$cn.remove_InfoMessage($handler);$cn.Dispose()}
