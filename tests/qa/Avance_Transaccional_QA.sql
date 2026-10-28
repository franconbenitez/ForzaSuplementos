:on error exit
-- PREPARADO, NO EJECUTADO. Requiere autorizacion especifica y 005 (estructura),006,007,008.
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)' THROW 51200,'Solo QA verificada.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1') THROW 51201,'Falta marca QA.',1;
IF N'$(AutorizarEnsayo)'<>N'SOLO_FIXTURES_ROLLBACK' THROW 51900,'Falta autorizacion especifica.',1;
IF OBJECT_ID('dbo.sp_Inventario_Ajustar','P') IS NULL THROW 51900,'Aplicar migraciones autorizadas primero.',1;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;
SET XACT_ABORT ON; SET NOCOUNT ON;
DECLARE @gerente int=(SELECT TOP(1) gerente FROM qa.Fixtures),@admin int=(SELECT TOP(1) administrador FROM qa.Fixtures),@vendedor int=(SELECT TOP(1) vendedor FROM qa.Fixtures),@categoria int=(SELECT TOP(1) categoria FROM qa.Fixtures);
DECLARE @productos bigint=(SELECT COUNT_BIG(*) FROM dbo.Productos),@proveedores bigint=(SELECT COUNT_BIG(*) FROM dbo.Proveedores),@compras bigint=(SELECT COUNT_BIG(*) FROM dbo.Compras),@movimientos bigint=(SELECT COUNT_BIG(*) FROM dbo.MovimientosStock);
BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @nombre nvarchar(100)=N'QA Ensayo '+CONVERT(nvarchar(36),NEWID());
 EXEC dbo.sp_Proveedores_Guardar @gerente,0,@nombre,N'QA Ficticio',NULL,1;
 DECLARE @proveedor int=(SELECT idProveedor FROM dbo.Proveedores WHERE nombre=@nombre);
 INSERT dbo.Productos(idCategoria,nombre,descripcion,precio,stock,activo) VALUES(@categoria,@nombre,N'Fixture transitorio',99,0,1);
 DECLARE @producto int=CONVERT(int,SCOPE_IDENTITY()),@op uniqueidentifier=NEWID(),@xml xml;
 SET @xml=CONVERT(xml,N'<detalles><item producto="'+CONVERT(nvarchar(20),@producto)+N'" cantidad="3" costo="2.50" /></detalles>');
 DECLARE @confirmacion TABLE(IdCompra int);
 INSERT @confirmacion EXEC dbo.sp_Compras_Registrar @gerente,@proveedor,@op,@xml;
 DECLARE @compra int=(SELECT IdCompra FROM @confirmacion);
 IF (SELECT stock FROM dbo.Productos WHERE idProducto=@producto)<>3 THROW 51901,'Stock compra incorrecto.',1;
 IF (SELECT precio FROM dbo.Productos WHERE idProducto=@producto)<>99 THROW 51902,'Compra altero precio de venta.',1;
 IF (SELECT total FROM dbo.Compras WHERE idCompra=@compra)<>7.50 THROW 51903,'Total incorrecto.',1;
 IF (SELECT COUNT(*) FROM dbo.MovimientosStock WHERE idCompra=@compra)<>1 THROW 51904,'Trazabilidad de compra incorrecta.',1;
 EXEC dbo.sp_Compras_Registrar @gerente,@proveedor,@op,@xml;
 IF (SELECT stock FROM dbo.Productos WHERE idProducto=@producto)<>3 THROW 51905,'Compra duplicada.',1;
 DECLARE @ajuste uniqueidentifier=NEWID();
 EXEC dbo.sp_Inventario_Ajustar @gerente,@producto,-1,3,N'QA Ajuste ficticio',@ajuste;
 EXEC dbo.sp_Inventario_Ajustar @gerente,@producto,-1,3,N'QA Ajuste ficticio',@ajuste;
 IF (SELECT stock FROM dbo.Productos WHERE idProducto=@producto)<>2 THROW 51906,'Ajuste incorrecto o duplicado.',1;
 EXEC dbo.sp_Inventario_Minimo @gerente,@producto,3;
 IF (SELECT stockMinimo FROM dbo.Productos WHERE idProducto=@producto)<>3 THROW 51907,'Minimo incorrecto.',1;
 ROLLBACK;
 IF (SELECT COUNT_BIG(*) FROM dbo.Productos)<>@productos OR (SELECT COUNT_BIG(*) FROM dbo.Proveedores)<>@proveedores OR (SELECT COUNT_BIG(*) FROM dbo.Compras)<>@compras OR (SELECT COUNT_BIG(*) FROM dbo.MovimientosStock)<>@movimientos THROW 51908,'Rollback no coincide; DETENER.',1;
 IF @@TRANCOUNT<>0 THROW 51909,'Transaccion abierta; DETENER.',1;
 PRINT 'Comprobaciones positivas y rollback aprobados (solo tras ejecutar).';
END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH;
