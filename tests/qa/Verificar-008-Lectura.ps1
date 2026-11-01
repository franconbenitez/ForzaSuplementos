# Preparada: solo lecturas despues de 008. NO invoca Ajustar/Minimo/Registrar.
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Import-Module (Join-Path $root 'scripts/qa/QA.Common.psm1') -Force
Import-Module (Join-Path $root 'scripts/qa/008.Validacion.psm1') -Force -DisableNameChecking
$cn=Open-QaConnection
try{
 $state=Invoke-QaQuery $cn 'SELECT @@TRANCOUNT Transacciones,(SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped=0) Tablas,(SELECT COUNT(*) FROM sys.procedures WHERE is_ms_shipped=0) Procedimientos,(SELECT COUNT(*) FROM sys.foreign_keys) FK,(SELECT COUNT(*) FROM sys.indexes WHERE object_id IN(SELECT object_id FROM sys.tables) AND index_id>0) Indices,(SELECT COUNT(*) FROM sys.check_constraints) Checks,(SELECT activa FROM dbo.SeguridadEstado WHERE id=1) Seguridad,(SELECT COUNT(*) FROM dbo.CredencialesUsuario) Credenciales;'
 $r=$state.Rows[0]
 if($r.Transacciones -ne 0 -or $r.Tablas -ne 18 -or $r.Procedimientos -ne 50 -or $r.FK -ne 21 -or $r.Indices -ne 33 -or $r.Checks -ne 17 -or $r.Seguridad -or $r.Credenciales -ne 0){throw 'Estado posterior 008 inesperado.'}
 $obj=Invoke-QaQuery $cn "SELECT (SELECT COUNT(*) FROM dbo.MovimientosStock) Movimientos,(SELECT COUNT(*) FROM dbo.Productos WHERE stockMinimo<>0) MinimosDistintos,(SELECT COUNT(*) FROM sys.columns WHERE object_id=OBJECT_ID('dbo.Productos') AND name='stockMinimo' AND TYPE_NAME(user_type_id)='int' AND is_nullable=0) Columna,(SELECT COUNT(*) FROM sys.foreign_keys WHERE name IN('FK_Movimientos_Producto','FK_Movimientos_Usuario','FK_Movimientos_Compra','FK_Movimientos_Venta') AND is_disabled=0 AND is_not_trusted=0) FK,(SELECT COUNT(*) FROM sys.check_constraints WHERE name IN('CK_Productos_StockMinimo','CK_Movimientos_Stock','CK_Movimientos_Motivo','CK_Movimientos_Tipo') AND is_disabled=0 AND is_not_trusted=0) Checks,(SELECT COUNT(*) FROM sys.default_constraints WHERE name IN('DF_Productos_StockMinimo','DF_Movimientos_Fecha')) Defaults;"
 $o=$obj.Rows[0]
 if($o.Movimientos -ne 0 -or $o.MinimosDistintos -ne 0 -or $o.Columna -ne 1 -or $o.FK -ne 4 -or $o.Checks -ne 4 -or $o.Defaults -ne 2){throw 'Objetos nuevos, minimos o movimientos inesperados.'}
 $idx=Invoke-QaQuery $cn "SELECT i.name Nombre,i.is_unique Unico,i.has_filter Filtrado,i.filter_definition Filtro,c.name Columna,ic.key_ordinal Orden,ic.is_included_column Incluida FROM sys.indexes i JOIN sys.index_columns ic ON ic.object_id=i.object_id AND ic.index_id=i.index_id JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id WHERE i.object_id=OBJECT_ID('dbo.MovimientosStock') AND i.index_id>0;"
 $expected=@{
  PK_MovimientosStock=@{Keys='idMovimiento';Unique=$true;Filter=''}
  UX_Movimientos_Ajuste=@{Keys='operacion';Unique=$true;Filter='operacionISNOTNULL'}
  UX_Movimientos_Compra=@{Keys='idCompra,idProducto';Unique=$true;Filter='idCompraISNOTNULL'}
  UX_Movimientos_Venta=@{Keys='idVenta,idProducto';Unique=$true;Filter='idVentaISNOTNULL'}
  IX_Movimientos_FechaProducto=@{Keys='fecha,idProducto';Unique=$false;Filter=''}
 }
 if(@($idx.Rows | Group-Object Nombre).Count -ne 5){throw 'Indices 008 incompletos.'}
 foreach($name in $expected.Keys){
  $rows=@($idx.Rows | Where-Object {$_.Nombre -eq $name});$e=$expected[$name]
  $keys=(@($rows | Where-Object {!$_.Incluida} | Sort-Object Orden | ForEach-Object {$_.Columna}) -join ',')
  $filter=if($rows.Count){([string]$rows[0].Filtro -replace '[\[\]()\s]','')}else{''}
  if(!$rows.Count -or $keys -cne $e.Keys -or [bool]$rows[0].Unico -ne $e.Unique -or $filter -ine $e.Filter -or [bool]$rows[0].Filtrado -ne ($e.Filter -ne '') -or @($rows | Where-Object {$_.Incluida}).Count){throw 'Contrato de indice 008 distinto.'}
 }
 $source=[IO.File]::ReadAllText((Join-Path $root 'sql/qa/008_Inventario_QA.sql'))
 $defs=Invoke-QaQuery $cn 'SELECT p.name Nombre,m.definition Codigo,m.uses_ansi_nulls AnsiNulls,m.uses_quoted_identifier QuotedIdentifier FROM sys.procedures p JOIN sys.sql_modules m ON m.object_id=p.object_id WHERE p.schema_id=SCHEMA_ID(''dbo'');'
 $n=0
 foreach($m in [regex]::Matches($source,"(?s)EXEC sys.sp_executesql N'((?:[^']|'')*)';")){
  $exp=$m.Groups[1].Value.Replace("''","'");$name=[regex]::Match($exp,'CREATE OR ALTER PROCEDURE dbo\.(\w+)').Groups[1].Value
  $actual=@($defs.Rows | Where-Object {$_.Nombre -eq $name});if($actual.Count -ne 1){throw 'Contrato 008 ausente.'}
  if(!$actual[0].AnsiNulls -or !$actual[0].QuotedIdentifier){throw 'Opciones ANSI de contrato 008 incorrectas.'}
  if((Get-008ProcedureContract $exp).Firma -cne (Get-008ProcedureContract ([string]$actual[0].Codigo)).Firma){throw 'Firma de uno de los ocho SP distinta.'}
  $eb=[regex]::Match($exp,'(?is)\bAS\s+BEGIN\b(.*)').Groups[1].Value;$ab=[regex]::Match([string]$actual[0].Codigo,'(?is)\bAS\s+BEGIN\b(.*)').Groups[1].Value
  if(($eb -replace '\s+',' ').Trim() -cne ($ab -replace '\s+',' ').Trim()){throw 'Contrato 008 distinto de fuente.'};$n++
 }
 if($n -ne 8){throw 'Verificacion de 8 contratos incompleta.'}
 $params=Invoke-QaQuery $cn "SELECT o.name Procedimiento,p.name Parametro,TYPE_NAME(p.user_type_id) Tipo,p.parameter_id Orden FROM sys.procedures o JOIN sys.parameters p ON p.object_id=o.object_id WHERE o.schema_id=SCHEMA_ID('dbo') AND o.name IN('sp_Inventario_Stock','sp_Inventario_Historial','sp_Inventario_Minimo','sp_Inventario_Ajustar') ORDER BY o.name,p.parameter_id;"
 $contracts=@{sp_Inventario_Stock='@idActor:int';sp_Inventario_Historial='@idActor:int,@desde:date,@hasta:date,@idProducto:int';sp_Inventario_Minimo='@idActor:int,@idProducto:int,@minimo:int';sp_Inventario_Ajustar='@idActor:int,@idProducto:int,@cantidad:int,@stockEsperado:int,@motivo:nvarchar,@operacion:uniqueidentifier'}
 foreach($name in $contracts.Keys){$signature=(@($params.Rows | Where-Object {$_.Procedimiento -eq $name} | Sort-Object Orden | ForEach-Object {$_.Parametro+':'+$_.Tipo}) -join ',');if($signature -cne $contracts[$name]){throw 'Parametros Inventario no coinciden con DAL.'}}
 Write-Output '008 verificacion posterior: 18 tablas/50 SP/21 FK/33 indices/17 CHECK, movimientos vacios, minimos cero, 8 contratos verificados; sin escrituras.'
}finally{$cn.Dispose()}
