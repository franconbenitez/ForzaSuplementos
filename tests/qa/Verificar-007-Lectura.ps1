# Preparada para despues de 007. Solo metadatos/lecturas; no llama Registrar.
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Import-Module (Join-Path $root 'scripts/qa/QA.Common.psm1') -Force
$cn=Open-QaConnection
try{
 $t=Invoke-QaQuery $cn 'SELECT @@TRANCOUNT Transacciones,(SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped=0) Tablas,(SELECT COUNT(*) FROM sys.procedures WHERE is_ms_shipped=0) Procedimientos,(SELECT COUNT(*) FROM sys.foreign_keys) FK,(SELECT COUNT(*) FROM sys.indexes WHERE object_id IN(SELECT object_id FROM sys.tables) AND index_id>0) Indices,(SELECT COUNT(*) FROM sys.check_constraints) Checks,(SELECT activa FROM dbo.SeguridadEstado WHERE id=1) Seguridad,(SELECT COUNT(*) FROM dbo.CredencialesUsuario) Credenciales;'
 $r=$t.Rows[0]
 if($r.Transacciones -ne 0 -or $r.Tablas -ne 17 -or $r.Procedimientos -ne 46 -or $r.FK -ne 17 -or $r.Indices -ne 28 -or $r.Checks -ne 13 -or $r.Seguridad -or $r.Credenciales -ne 0){throw 'Estado posterior 007 inesperado.'}
 $obj=Invoke-QaQuery $cn "SELECT (SELECT COUNT(*) FROM dbo.Compras) Compras,(SELECT COUNT(*) FROM dbo.DetalleCompras) Detalles,(SELECT COUNT(*) FROM sys.foreign_keys WHERE name IN('FK_Compras_Proveedor','FK_Compras_Usuario','FK_DetalleCompras_Compra','FK_DetalleCompras_Producto') AND is_disabled=0 AND is_not_trusted=0) FK,(SELECT COUNT(*) FROM sys.check_constraints WHERE name IN('CK_Compras_Total','CK_DetalleCompras_Cantidad','CK_DetalleCompras_Costo','CK_DetalleCompras_Subtotal') AND is_disabled=0 AND is_not_trusted=0) Checks,(SELECT COUNT(*) FROM sys.default_constraints WHERE name='DF_Compras_Fecha' AND object_definition(object_id) LIKE '%sysdatetime%') Defaults;"
 if($obj.Rows[0].Compras -ne 0 -or $obj.Rows[0].Detalles -ne 0 -or $obj.Rows[0].FK -ne 4 -or $obj.Rows[0].Checks -ne 4 -or $obj.Rows[0].Defaults -ne 1){throw 'Objetos nuevos distintos o tablas no vacias.'}
 $idx=Invoke-QaQuery $cn "SELECT t.name Tabla,i.name Indice,i.is_unique Unico,c.name Columna,ic.key_ordinal Orden,ic.is_included_column Incluida FROM sys.tables t JOIN sys.indexes i ON i.object_id=t.object_id JOIN sys.index_columns ic ON ic.object_id=i.object_id AND ic.index_id=i.index_id JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id WHERE t.schema_id=SCHEMA_ID('dbo') AND t.name IN('Compras','DetalleCompras') ORDER BY i.name,ic.key_ordinal,ic.index_column_id;"
 $expected=@{
  PK_Compras=@{Tabla='Compras';Keys='idCompra';Include='';Unique=$true}
  UQ_Compras_Operacion=@{Tabla='Compras';Keys='operacion';Include='';Unique=$true}
  IX_Compras_FechaProveedor=@{Tabla='Compras';Keys='fecha,idProveedor';Include='idUsuario,total';Unique=$false}
  PK_DetalleCompras=@{Tabla='DetalleCompras';Keys='idDetalleCompra';Include='';Unique=$true}
  UQ_DetalleCompras_Producto=@{Tabla='DetalleCompras';Keys='idCompra,idProducto';Include='';Unique=$true}
 }
 if(@($idx.Rows | Group-Object Indice).Count -ne 5){throw 'Cantidad de indices nuevos distinta.'}
 foreach($name in $expected.Keys){
  $e=$expected[$name];$rows=@($idx.Rows | Where-Object {$_.Indice -eq $name})
  $keys=(@($rows | Where-Object {!$_.Incluida} | Sort-Object Orden | ForEach-Object {$_.Columna}) -join ',')
  $inc=(@($rows | Where-Object {$_.Incluida} | ForEach-Object {$_.Columna} | Sort-Object) -join ',')
  if(!$rows.Count -or $rows[0].Tabla -ne $e.Tabla -or [bool]$rows[0].Unico -ne $e.Unique -or $keys -cne $e.Keys -or $inc -cne $e.Include){throw 'Contrato de indice incorrecto.'}
 }
 $defs=Invoke-QaQuery $cn 'SELECT p.name Nombre,m.definition Codigo FROM sys.procedures p JOIN sys.sql_modules m ON m.object_id=p.object_id WHERE p.schema_id=SCHEMA_ID(''dbo'');'
 $source=[IO.File]::ReadAllText((Join-Path $root 'sql/qa/007_Compras_QA.sql'))
 $n=0
 foreach($m in [regex]::Matches($source,"(?s)EXEC sys.sp_executesql N'((?:[^']|'')*)';")){
  $exp=$m.Groups[1].Value.Replace("''","'");$name=[regex]::Match($exp,'CREATE OR ALTER PROCEDURE dbo\.(\w+)').Groups[1].Value
  $actual=@($defs.Rows | Where-Object {$_.Nombre -eq $name});if($actual.Count -ne 1){throw 'SP 007 ausente.'}
  $eb=[regex]::Match($exp,'(?is)\bAS\s+BEGIN\b(.*)').Groups[1].Value;$ab=[regex]::Match([string]$actual[0].Codigo,'(?is)\bAS\s+BEGIN\b(.*)').Groups[1].Value
  if(($eb -replace '\s+',' ').Trim() -cne ($ab -replace '\s+',' ').Trim()){throw 'Cuerpo SP 007 distinto.'};$n++
 }
 $params=Invoke-QaQuery $cn "SELECT o.name Procedimiento,p.name Parametro,TYPE_NAME(p.user_type_id) Tipo,p.parameter_id Orden FROM sys.procedures o JOIN sys.parameters p ON p.object_id=o.object_id WHERE o.schema_id=SCHEMA_ID('dbo') AND o.name IN('sp_Compras_Registrar','sp_Compras_Historial','sp_Compras_Detalle') ORDER BY o.name,p.parameter_id;"
 $contracts=@{sp_Compras_Registrar='@idActor:int,@idProveedor:int,@operacion:uniqueidentifier,@detalles:xml';sp_Compras_Historial='@idActor:int,@desde:date,@hasta:date,@idProveedor:int';sp_Compras_Detalle='@idActor:int,@idCompra:int'}
 foreach($name in $contracts.Keys){$signature=(@($params.Rows | Where-Object {$_.Procedimiento -eq $name} | Sort-Object Orden | ForEach-Object {$_.Parametro+':'+$_.Tipo}) -join ',');if($signature -cne $contracts[$name]){throw 'Parametros SQL no coinciden con DAL.'}}
 if($n -ne 3){throw 'Verificacion de SP incompleta.'}
 Write-Output '007 lectura posterior: 17 tablas, 46 SP, 17 FK, 28 indices y 13 CHECK; tablas nuevas vacias, contratos e indices verificados, PBKDF2 inactivo y sin transaccion previa.'
}finally{$cn.Dispose()}
