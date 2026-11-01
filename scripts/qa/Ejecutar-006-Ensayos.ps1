# Ejecuta UNICAMENTE el fixture 006 autorizado, una vez; nunca reintenta ni repara.
param([switch]$AutorizarEnsayos006)
$ErrorActionPreference='Stop'
if(!$AutorizarEnsayos006){throw 'Falta autorizacion especifica. No se conecta.'}
Import-Module (Join-Path $PSScriptRoot 'QA.Common.psm1') -Force
$cfg=Get-QaConfig
$running=@(Get-CimInstance Win32_Process -Filter "Name = 'ForzaSuplementos.Presentacion.exe'" | Where-Object {$_.ExecutablePath -and $_.ExecutablePath.StartsWith($cfg.Root+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)})
if($running.Count){throw 'Cerrar aplicacion por su interfaz antes de ensayos. No se finalizan procesos.'}
& (Join-Path $cfg.Root 'tests/qa/Verificar-006-Lectura.ps1')
if(!$?){throw 'Verificacion inicial 006 no aprobada.'}
$path=Join-Path $cfg.Root 'tests/qa/Catalogos_006_Rollback_Preparado.sql'
$source=[IO.File]::ReadAllText($path)
if($source -match '(?im)^\s*GO\s*$'){throw 'Runner cambiado: requiere revision.'}
$source=$source.Replace('$(QaExpectedServer)',$cfg.ExpectedServer).Replace('$(AutorizarEnsayo)','SOLO_FIXTURES_ROLLBACK') -replace '(?m)^:on error exit\s*',''
if($source -match '\$\('){throw 'Variable SQLCMD no resuelta.'}
$folder=Join-Path $cfg.Root ('private/006-ensayos-'+[datetime]::UtcNow.ToString('yyyyMMdd-HHmmss-fffffff'))
[void][IO.Directory]::CreateDirectory($folder)
$cn=Open-QaConnection
$executed=$false;$failure=$null;$rows=@();$integrity=@()
try{
 $t=Invoke-QaQuery $cn "SELECT @@TRANCOUNT Transacciones,(SELECT COUNT(*) FROM sys.dm_tran_session_transactions st JOIN sys.dm_exec_sessions s ON s.session_id=st.session_id JOIN sys.dm_tran_database_transactions dt ON dt.transaction_id=st.transaction_id WHERE dt.database_id=DB_ID() AND s.is_user_process=1 AND s.session_id<>@@SPID) OtrasTransacciones;"
 if($t.Rows[0].Transacciones -ne 0 -or $t.Rows[0].OtrasTransacciones -ne 0){throw 'Transaccion previa o sesion incompatible; no se ejecuta.'}
 $defs=Invoke-QaQuery $cn 'SELECT p.name Nombre,m.definition Codigo FROM sys.procedures p JOIN sys.sql_modules m ON m.object_id=p.object_id WHERE p.schema_id=SCHEMA_ID(''dbo'');'
 $migration=[IO.File]::ReadAllText((Join-Path $cfg.Root 'sql/qa/006_Catalogos_QA.sql'))
 $checked=0
 foreach($m in [regex]::Matches($migration,"(?s)EXEC sys.sp_executesql N'((?:[^']|'')*)';")){
  $expected=$m.Groups[1].Value.Replace("''","'")
  $name=[regex]::Match($expected,'CREATE OR ALTER PROCEDURE dbo\.(\w+)').Groups[1].Value
  $actual=@($defs.Rows | Where-Object {$_.Nombre -eq $name})
  if($actual.Count -ne 1){throw 'Contrato 006 ausente.'}
  $eb=[regex]::Match($expected,'(?is)\bAS\s+BEGIN\b(.*)').Groups[1].Value
  $ab=[regex]::Match([string]$actual[0].Codigo,'(?is)\bAS\s+BEGIN\b(.*)').Groups[1].Value
  if(($eb -replace '\s+',' ').Trim() -cne ($ab -replace '\s+',' ').Trim()){throw 'Contrato 006 distinto.'};$checked++
 }
 if($checked -ne 6){throw 'Contratos 006 incompletos.'}
 $obj=Invoke-QaQuery $cn "SELECT (SELECT COUNT(*) FROM sys.check_constraints WHERE name IN('CK_Proveedores_Nombre','CK_Proveedores_Cuit','CK_Marcas_Nombre') AND is_disabled=0 AND is_not_trusted=0) Checks,(SELECT COUNT(*) FROM sys.indexes WHERE (object_id=OBJECT_ID('dbo.Proveedores') AND name IN('PK_Proveedores','UX_Proveedores_Cuit')) OR (object_id=OBJECT_ID('dbo.Marcas') AND name IN('PK_Marcas','UQ_Marcas_Nombre')) OR (object_id=OBJECT_ID('dbo.Productos') AND name='IX_Productos_Marca')) Indices;"
 if($obj.Rows[0].Checks -ne 3 -or $obj.Rows[0].Indices -ne 5){throw 'Checks o indices faltantes.'}
 $counts=Invoke-QaQuery $cn 'SELECT s.name Esquema,t.name Tabla,SUM(p.rows) Filas FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id JOIN sys.partitions p ON p.object_id=t.object_id AND p.index_id IN(0,1) GROUP BY s.name,t.name;'
 $counts | Export-Clixml (Join-Path $folder 'conteos-previos.xml')
 $tables=Invoke-QaQuery $cn "SELECT t.object_id Id,QUOTENAME(s.name)+'.'+QUOTENAME(t.name) Nombre FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id WHERE t.is_ms_shipped=0 ORDER BY s.name,t.name;"
 foreach($table in $tables.Rows){
  $columns=Invoke-QaQuery $cn 'SELECT QUOTENAME(name) Nombre FROM sys.columns WHERE object_id=@id ORDER BY column_id;' @{'@id'=[int]$table.Id}
  $cols=(@($columns.Rows | ForEach-Object {[string]$_.Nombre}) -join ',')
  $query="SELECT HASHBYTES('SHA2_256',COALESCE(CONVERT(varbinary(max),(SELECT $cols FROM $($table.Nombre) ORDER BY $cols FOR XML RAW,BINARY BASE64)),CONVERT(varbinary(max),0x))) Huella;"
  $digest=(Invoke-QaQuery $cn $query).Rows[0].Huella
  $integrity+=@{Query=$query;Digest=[Convert]::ToBase64String($digest)}
 }
 [pscustomobject]@{ScriptSHA256=(Get-FileHash $path -Algorithm SHA256).Hash;Head=(& git -C $cfg.Root rev-parse HEAD);Contratos=6;SinTransaccionPrevia=$true;SinOtraTransaccionQA=$true} | ConvertTo-Json | Set-Content (Join-Path $folder 'preflight.json') -Encoding UTF8
 Assert-QaDestination $cn
 $cmd=$cn.CreateCommand();$cmd.CommandText=$source;$cmd.CommandTimeout=120
 try{
  $executed=$true
  $reader=$cmd.ExecuteReader()
  try{
   do{
    $hasCases=$false
    for($i=0;$i -lt $reader.FieldCount;$i++){if($reader.GetName($i) -eq 'Caso'){$hasCases=$true}}
    while($reader.Read()){
     if($hasCases){$rows+= [pscustomobject]@{Caso=[int]$reader['Caso'];Descripcion=[string]$reader['Descripcion'];Estado=[string]$reader['Estado']}}
    }
   }while($reader.NextResult())
  }finally{$reader.Dispose()}
 }catch{$failure=$_.Exception.ToString();$failure | Set-Content (Join-Path $folder 'error-privado.log') -Encoding UTF8}
 finally{$cmd.Dispose()}
 # Solo lecturas incluso ante error; nunca ROLLBACK adicional ni reintento.
 $final=Invoke-QaQuery $cn "SELECT @@TRANCOUNT Transacciones,(SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped=0) Tablas,(SELECT COUNT(*) FROM sys.procedures WHERE is_ms_shipped=0) Procedimientos,(SELECT COUNT(*) FROM dbo.Productos WHERE nombre LIKE N'QA006 %') ProductosFixture,(SELECT COUNT(*) FROM dbo.Proveedores WHERE nombre LIKE N'QA006 %') ProveedoresFixture,(SELECT COUNT(*) FROM dbo.Marcas WHERE nombre LIKE N'QA006 %') MarcasFixture;"
 $f=$final.Rows[0]
 $countsAfter=Invoke-QaQuery $cn 'SELECT s.name Esquema,t.name Tabla,SUM(p.rows) Filas FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id JOIN sys.partitions p ON p.object_id=t.object_id AND p.index_id IN(0,1) GROUP BY s.name,t.name;'
 $sameCounts=$true
 foreach($row in $counts.Rows){$m=@($countsAfter.Rows | Where-Object {$_.Esquema -eq $row.Esquema -and $_.Tabla -eq $row.Tabla});if($m.Count -ne 1 -or $m[0].Filas -ne $row.Filas){$sameCounts=$false}}
 $sameData=$true
 foreach($entry in $integrity){$digest=(Invoke-QaQuery $cn $entry.Query).Rows[0].Huella;if([Convert]::ToBase64String($digest) -cne $entry.Digest){$sameData=$false}}
 $integrity=$null;$digest=$null
 $ok=(!$failure -and $rows.Count -eq 17 -and @($rows | Where-Object {$_.Estado -ne 'APROBADO'}).Count -eq 0 -and (@($rows.Caso | Sort-Object -Unique).Count -eq 17) -and $f.Transacciones -eq 0 -and $f.Tablas -eq 15 -and $f.Procedimientos -eq 43 -and $f.ProductosFixture -eq 0 -and $f.ProveedoresFixture -eq 0 -and $f.MarcasFixture -eq 0 -and $sameCounts -and $sameData)
 [pscustomobject]@{Ejecutado=$executed;Exito=$ok;CasosDevueltos=$rows.Count;Transacciones=[int]$f.Transacciones;Tablas=[int]$f.Tablas;Procedimientos=[int]$f.Procedimientos;RegistrosFixture=[int]$f.ProductosFixture+[int]$f.ProveedoresFixture+[int]$f.MarcasFixture;ConteosIguales=$sameCounts;DatosIguales=$sameData;Casos=$rows} | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $folder 'resultado.json') -Encoding UTF8
 if(!$ok){throw 'Ensayos 006 no completados o verificacion posterior inesperada. Detener: sin reintento ni reparacion. Consultar resultado privado.'}
 $rows | Format-Table -AutoSize
 Write-Output '17 aprobados; rollback comprobado por el runner y verificacion posterior: cero transacciones, cero registros fixture, conteos y datos conservados. Sin reintentos.'
}finally{$cn.Dispose()}
