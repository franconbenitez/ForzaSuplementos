# Pruebas numericas reales mediante SELECT y metadatos QA. Sin DDL/DML ni fixtures.
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Import-Module (Join-Path $root 'scripts/qa/QA.Common.psm1') -Force
$cn=Open-QaConnection;$n=0
function Check($ok,$text){if(!$ok){throw $text};$script:n++;Write-Output "OK: $text"}
try{
 $keys=Invoke-QaQuery $cn "SELECT t.name Tabla,c.name Columna,TYPE_NAME(c.user_type_id) Tipo,c.is_nullable Nulable FROM sys.tables t JOIN sys.columns c ON c.object_id=t.object_id WHERE t.schema_id=SCHEMA_ID('dbo') AND ((t.name='Proveedores' AND c.name='idProveedor') OR (t.name='Usuarios' AND c.name='idUsuario') OR (t.name='Productos' AND c.name='idProducto')) AND EXISTS(SELECT 1 FROM sys.indexes i JOIN sys.index_columns k ON k.object_id=i.object_id AND k.index_id=i.index_id WHERE i.object_id=t.object_id AND i.is_unique=1 AND i.has_filter=0 AND k.column_id=c.column_id AND k.key_ordinal=1 AND (SELECT COUNT(*) FROM sys.index_columns k2 WHERE k2.object_id=i.object_id AND k2.index_id=i.index_id AND k2.key_ordinal>0)=1);"
 Check ($keys.Rows.Count -eq 3 -and @($keys.Rows | Where-Object {$_.Tipo -ne 'int' -or $_.Nulable}).Count -eq 0) 'Tres destinos FK existentes: int no nulo y clave unica no filtrada'
 $names=Invoke-QaQuery $cn "SELECT COUNT(*) Cantidad FROM sys.objects WHERE schema_id=SCHEMA_ID('dbo') AND name IN('PK_Compras','FK_Compras_Proveedor','FK_Compras_Usuario','DF_Compras_Fecha','CK_Compras_Total','UQ_Compras_Operacion','PK_DetalleCompras','FK_DetalleCompras_Compra','FK_DetalleCompras_Producto','CK_DetalleCompras_Cantidad','CK_DetalleCompras_Costo','CK_DetalleCompras_Subtotal','UQ_DetalleCompras_Producto');"
 Check ($names.Rows[0].Cantidad -eq 0) 'Nombres de las 13 restricciones 007 no colisionan con objetos existentes'
 $q=Invoke-QaQuery $cn "SELECT CONVERT(decimal(10,0),2147483647)*CONVERT(decimal(18,2),9999999999.99) ProductoMaximo,SQL_VARIANT_PROPERTY(CONVERT(decimal(10,0),2147483647)*CONVERT(decimal(18,2),9999999999.99),'Precision') PrecisionProducto,SQL_VARIANT_PROPERTY(CONVERT(decimal(10,0),2147483647)*CONVERT(decimal(18,2),9999999999.99),'Scale') EscalaProducto,CONVERT(decimal(38,2),CONVERT(decimal(10,0),2147483647)*CONVERT(decimal(18,2),9999999999.99))*CONVERT(decimal(3,0),500) SumaMaxima,CONVERT(decimal(18,2),CONVERT(decimal(10,0),3)*CONVERT(decimal(18,2),2.50)) SubtotalNormal,TRY_CONVERT(decimal(18,2),CONVERT(decimal(10,0),2147483647)*CONVERT(decimal(18,2),9999999999.99)) ConversionExcedida,CONVERT(decimal(10,0),1000000)*CONVERT(decimal(18,2),9999999999.99) DentroLimite,CONVERT(decimal(10,0),1000001)*CONVERT(decimal(18,2),9999999999.99) FueraLimite,SQL_VARIANT_PROPERTY(SYSDATETIME(),'BaseType') TipoFecha,CONVERT(bigint,2147483647)+CONVERT(int,2147483647) SumaStockAmplia;"
 $r=$q.Rows[0]
 Check ($r.PrecisionProducto -eq 29 -and $r.EscalaProducto -eq 2) 'Multiplicacion corregida produce decimal(29,2) en SQL Server'
 Check ([decimal]$r.SubtotalNormal -eq 7.50D) 'Subtotal 3 por 2.50 exacto sin redondeo'
 Check ([decimal]$r.ProductoMaximo -eq (2147483647D*9999999999.99D)) 'Producto maximo admitido por int/costo no desborda el intermediario'
 Check ([decimal]$r.SumaMaxima -eq (2147483647D*9999999999.99D*500D)) 'Acumulacion maxima de 500 lineas cabe en decimal(38,2)'
 Check ($r.ConversionExcedida -is [DBNull]) 'Valor fuera de decimal(18,2) detectado con TRY_CONVERT de lectura'
 Check ([decimal]$r.DentroLimite -le 9999999999999999.99D -and [decimal]$r.FueraLimite -gt 9999999999999999.99D) 'Frontera del limite de total conserva centavos exactos'
 Check ($r.TipoFecha -eq 'datetime2') 'SYSDATETIME compatible con DEFAULT datetime2'
 Check ([long]$r.SumaStockAmplia -eq 4294967294L) 'Comprobacion bigint de stock no desborda int antes del rechazo'
 $state=Invoke-QaQuery $cn 'SELECT @@TRANCOUNT Transacciones,(SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped=0) Tablas,(SELECT COUNT(*) FROM sys.procedures WHERE is_ms_shipped=0) Procedimientos;'
 Check ($state.Rows[0].Transacciones -eq 0 -and $state.Rows[0].Tablas -eq 15 -and $state.Rows[0].Procedimientos -eq 43) 'QA sigue 15 tablas/43 SP sin transaccion previa'
 Write-Output "TOTAL NUMERICOS 007 QA LECTURA: $n comprobaciones aprobadas. Solo SELECT; no demuestra creacion de las tablas."
}finally{$cn.Dispose()}
