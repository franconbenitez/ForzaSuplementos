# Solo el fixture negativo 008 autorizado. Una invocacion, sin cambiar sus casos ni reintentar.
param([switch]$AutorizarNegativos008)
$ErrorActionPreference='Stop'
if(!$AutorizarNegativos008){throw 'Falta autorizacion expresa del fixture negativo 008; no se conecta.'}
Import-Module (Join-Path $PSScriptRoot 'QA.Common.psm1') -Force
Import-Module (Join-Path $PSScriptRoot '008.Validacion.psm1') -Force -DisableNameChecking
$cfg=Get-QaConfig
$running=@(Get-CimInstance Win32_Process -Filter "Name = 'ForzaSuplementos.Presentacion.exe'" | Where-Object {$_.ExecutablePath -and $_.ExecutablePath.StartsWith($cfg.Root+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)})
if($running.Count){throw 'Cerrar aplicacion del repositorio por su interfaz; no se finalizan procesos.'}
& (Join-Path $cfg.Root 'tests/qa/Verificar-008-Lectura.ps1')
if(!$?){throw 'Verificacion inicial 008 rechazada.'}
$relative='tests/qa/Negativos_Compras_Inventario_Preparados.sql'
& git -C $cfg.Root diff --quiet HEAD -- $relative
if($LASTEXITCODE -ne 0){throw 'Fixture distinto del preparado en HEAD; no se ejecuta.'}
$path=Join-Path $cfg.Root $relative
$source=[IO.File]::ReadAllText($path)
if($source -match '(?im)^\s*GO\s*$'){throw 'Runner distinto del revisado.'}
$hash=(Get-FileHash $path -Algorithm SHA256).Hash
$source=$source.Replace('$(QaExpectedServer)',$cfg.ExpectedServer).Replace('$(AutorizarEnsayo)','SOLO_NEGATIVOS_ROLLBACK') -replace '(?m)^:on error exit\s*',''
if($source -match '\$\('){throw 'Variable SQLCMD sin resolver.'}
$folder=Join-Path $cfg.Root ('private/008-negativos-'+[datetime]::UtcNow.ToString('yyyyMMdd-HHmmss-fffffff'))
[void][IO.Directory]::CreateDirectory($folder)
$cn=Open-QaConnection;$failure=$null;$executed=$false
$messages=New-Object 'System.Collections.Generic.List[string]'
$handler=[Data.SqlClient.SqlInfoMessageEventHandler]{param($sender,$e) $messages.Add($e.Message)}
$cn.add_InfoMessage($handler)
try{
 $state=Invoke-QaQuery $cn "SELECT @@TRANCOUNT Transacciones,(SELECT COUNT(*) FROM sys.dm_tran_session_transactions st JOIN sys.dm_exec_sessions s ON s.session_id=st.session_id JOIN sys.dm_tran_database_transactions dt ON dt.transaction_id=st.transaction_id WHERE dt.database_id=DB_ID() AND s.is_user_process=1 AND s.session_id<>@@SPID) OtrasTransacciones,(SELECT COUNT(*) FROM dbo.Productos WHERE nombre LIKE N'QA Negativo %') ProductosPrevios,(SELECT COUNT(*) FROM dbo.Proveedores WHERE nombre LIKE N'QA Negativo %') ProveedoresPrevios;"
 if($state.Rows[0].Transacciones -ne 0 -or $state.Rows[0].OtrasTransacciones -ne 0 -or $state.Rows[0].ProductosPrevios -ne 0 -or $state.Rows[0].ProveedoresPrevios -ne 0){throw 'Transaccion incompatible o residuos de fixture; no se ejecuta.'}
 $defs=Invoke-QaQuery $cn 'SELECT p.name Nombre,m.definition Codigo FROM sys.procedures p JOIN sys.sql_modules m ON m.object_id=p.object_id WHERE p.schema_id=SCHEMA_ID(''dbo'');'
 $planned=@{}
 foreach($file in @('005_Seguridad_QA.sql','006_Catalogos_QA.sql','007_Compras_QA.sql','008_Inventario_QA.sql')){
  $sql=[IO.File]::ReadAllText((Join-Path $cfg.Root ('sql/qa/'+$file)))
  foreach($m in [regex]::Matches($sql,"(?s)EXEC sys.sp_executesql N'((?:[^']|'')*)';")){
   $exp=$m.Groups[1].Value.Replace("''","'");$name=[regex]::Match($exp,'CREATE OR ALTER PROCEDURE dbo\.(\w+)').Groups[1].Value
   $planned[$name]=$exp
  }
 }
 if($planned.Count -ne 25){throw 'Mapa de contratos inesperado.'}
 foreach($name in $planned.Keys){
  $actual=@($defs.Rows | Where-Object {$_.Nombre -eq $name});if($actual.Count -ne 1){throw 'Contrato previo ausente.'}
  $eb=[regex]::Match($planned[$name],'(?is)\bAS\s+BEGIN\b(.*)').Groups[1].Value;$ab=[regex]::Match([string]$actual[0].Codigo,'(?is)\bAS\s+BEGIN\b(.*)').Groups[1].Value
  if(($eb -replace '\s+',' ').Trim() -cne ($ab -replace '\s+',' ').Trim()){throw 'Contrato previo distinto.'}
 }
 $counts=Invoke-QaQuery $cn 'SELECT s.name Esquema,t.name Tabla,SUM(p.rows) Filas FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id JOIN sys.partitions p ON p.object_id=t.object_id AND p.index_id IN(0,1) GROUP BY s.name,t.name;'
 $counts | Export-Clixml (Join-Path $folder 'conteos-previos.xml')
 $integrity=@()
 $tables=Invoke-QaQuery $cn "SELECT t.object_id Id,QUOTENAME(s.name)+'.'+QUOTENAME(t.name) Nombre FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id WHERE t.is_ms_shipped=0;"
 foreach($table in $tables.Rows){
  $cols=Invoke-QaQuery $cn 'SELECT QUOTENAME(name) Nombre FROM sys.columns WHERE object_id=@id ORDER BY column_id;' @{'@id'=[int]$table.Id}
  $query=Get-008IntegrityQuery $table.Nombre (@($cols.Rows | ForEach-Object {[string]$_.Nombre}) -join ',')
  $digest=(Invoke-QaQuery $cn $query).Rows[0].Huella
  $integrity+=@{Query=$query;Digest=[Convert]::ToBase64String($digest)}
 }
 [pscustomobject]@{ScriptSHA256=$hash;Head=(& git -C $cfg.Root rev-parse HEAD);ContratosVigentes=25;SinTransaccionPrevia=$true;SinOtraTransaccionQa=$true} | ConvertTo-Json | Set-Content (Join-Path $folder 'preflight.json') -Encoding UTF8
 Assert-QaDestination $cn
 if((Get-FileHash $path -Algorithm SHA256).Hash -cne $hash){throw 'Fixture cambio durante preflight.'}
 $cmd=$cn.CreateCommand();$cmd.CommandText=$source;$cmd.CommandTimeout=120
 try{$executed=$true;[void]$cmd.ExecuteNonQuery()}catch{$failure=$_.Exception.ToString();$failure | Set-Content (Join-Path $folder 'error-privado.log') -Encoding UTF8}finally{$cmd.Dispose()}
 # Solo lecturas posteriores, incluso ante error. Nunca se reintenta ni repara.
 $final=Invoke-QaQuery $cn "SELECT @@TRANCOUNT Transacciones,(SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped=0) Tablas,(SELECT COUNT(*) FROM sys.procedures WHERE is_ms_shipped=0) Procedimientos,(SELECT COUNT(*) FROM dbo.Compras) Compras,(SELECT COUNT(*) FROM dbo.DetalleCompras) Detalles,(SELECT COUNT(*) FROM dbo.MovimientosStock) Movimientos,(SELECT COUNT(*) FROM dbo.Productos WHERE nombre LIKE N'QA Negativo %') ProductosFixture,(SELECT COUNT(*) FROM dbo.Proveedores WHERE nombre LIKE N'QA Negativo %') ProveedoresFixture;"
 $f=$final.Rows[0]
 $after=Invoke-QaQuery $cn 'SELECT s.name Esquema,t.name Tabla,SUM(p.rows) Filas FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id JOIN sys.partitions p ON p.object_id=t.object_id AND p.index_id IN(0,1) GROUP BY s.name,t.name;'
 $sameCounts=$true
 foreach($row in $counts.Rows){$m=@($after.Rows | Where-Object {$_.Esquema -eq $row.Esquema -and $_.Tabla -eq $row.Tabla});if($m.Count -ne 1 -or $m[0].Filas -ne $row.Filas){$sameCounts=$false}}
 $sameData=$true
 foreach($entry in $integrity){$digest=(Invoke-QaQuery $cn $entry.Query).Rows[0].Huella;if([Convert]::ToBase64String($digest) -cne $entry.Digest){$sameData=$false}}
 $integrity=$null;$digest=$null
 $passed=@([regex]::Matches(($messages -join "`n"),'Caso negativo (\d+) aprobado con rollback') | ForEach-Object {[int]$_.Groups[1].Value} | Sort-Object -Unique)
 $ok=(!$failure -and ($passed -join ',') -eq '1,2,3,4,5,6,7,8,9,10' -and $f.Transacciones -eq 0 -and $f.Tablas -eq 18 -and $f.Procedimientos -eq 50 -and $f.Compras -eq 0 -and $f.Detalles -eq 0 -and $f.Movimientos -eq 0 -and $f.ProductosFixture -eq 0 -and $f.ProveedoresFixture -eq 0 -and $sameCounts -and $sameData)
 $descriptions=@('Producto inactivo','Proveedor inactivo','Cantidad cero','Costo con decimales excesivos','Overflow de stock','GUID vacio','Salida sin stock suficiente','Motivo vacio','Stock esperado obsoleto','Administrador no puede registrar compra/entrada de inventario')
 $expected=@(51705,51704,51701,51701,51705,51701,51806,51802,51806,51603)
 $cases=@()
 for($i=1;$i -le 10;$i++){
  $status=if($passed -contains $i -and $sameCounts -and $sameData -and $f.Transacciones -eq 0){'APROBADO'}elseif($failure -and $i -eq $passed.Count+1){'FALLIDO'}else{'BLOQUEADO'}
  $cases+=[pscustomobject]@{Caso=$i;Descripcion=$descriptions[$i-1];ErrorEsperado=$expected[$i-1];ErrorCoincidenteSegunRunner=($passed -contains $i);RollbackPorCasoComprobado=($passed -contains $i);Estado=$status}
 }
 $messages | Set-Content (Join-Path $folder 'mensajes-sql.log') -Encoding UTF8
 [pscustomobject]@{Ejecutado=$executed;Exito=$ok;Aprobados=@($cases | Where-Object {$_.Estado -eq 'APROBADO'}).Count;Fallidos=@($cases | Where-Object {$_.Estado -eq 'FALLIDO'}).Count;Bloqueados=@($cases | Where-Object {$_.Estado -eq 'BLOQUEADO'}).Count;Transacciones=[int]$f.Transacciones;Tablas=[int]$f.Tablas;Procedimientos=[int]$f.Procedimientos;Compras=[int]$f.Compras;Detalles=[int]$f.Detalles;Movimientos=[int]$f.Movimientos;ProductosFixture=[int]$f.ProductosFixture;ProveedoresFixture=[int]$f.ProveedoresFixture;ConteosIguales=$sameCounts;DatosIguales=$sameData;Casos=$cases} | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $folder 'resultado.json') -Encoding UTF8
 $cases | Format-Table Caso,Descripcion,ErrorEsperado,Estado -AutoSize
 if(!$ok){throw 'Negativos 008 no completados o rollback/integridad no comprobados; detener sin reintento ni reparacion. Consultar evidencia privada.'}
 Write-Output '10 negativos aprobados, 0 fallidos, 0 bloqueados. Diez rollback verificados por el runner; cero fixtures/transacciones; conteos y huellas de 18 tablas conservados. Sin reintentos.'

}finally{$cn.remove_InfoMessage($handler);$cn.Dispose()}
