:on error exit
-- PREPARADO, NO EJECUTADO. Requiere autorizacion especifica del script y sus fixtures.
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)' THROW 51200,'Solo QA verificada.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1') THROW 51201,'Falta marca QA.',1;
IF N'$(AutorizarEnsayo)'<>N'SOLO_FIXTURES_ROLLBACK' THROW 51900,'Falta autorizacion especifica.',1;
IF @@TRANCOUNT<>0 THROW 51932,'Conexion sin transaccion previa requerida.',1;
SET IMPLICIT_TRANSACTIONS OFF; SET XACT_ABORT ON; SET NOCOUNT ON;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;
IF OBJECT_ID('dbo.sp_Compras_Registrar','P') IS NULL THROW 51900,'Requiere 007.',1;
DECLARE @actor int=(SELECT TOP(1) gerente FROM qa.Fixtures),@categoria int=(SELECT TOP(1) categoria FROM qa.Fixtures);
DECLARE @bp bigint=(SELECT COUNT_BIG(*) FROM dbo.Productos),@bv bigint=(SELECT COUNT_BIG(*) FROM dbo.Proveedores),@bc bigint=(SELECT COUNT_BIG(*) FROM dbo.Compras),@bd bigint=(SELECT COUNT_BIG(*) FROM dbo.DetalleCompras);
BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @nombre nvarchar(100)=N'QA Compra '+CONVERT(nvarchar(36),NEWID());
 DECLARE @v TABLE(Id int);
 INSERT @v EXEC dbo.sp_Proveedores_Guardar @actor,0,@nombre,N'QA Ficticio',NULL,1;
 DECLARE @proveedor int=(SELECT Id FROM @v);
 INSERT dbo.Productos(idCategoria,nombre,descripcion,precio,stock,activo) VALUES(@categoria,@nombre,N'QA Ficticio',99,0,1);
 DECLARE @producto int=CONVERT(int,SCOPE_IDENTITY()),@op uniqueidentifier=NEWID(),@xml xml;
 DECLARE @uno TABLE(IdCompra int);
 DECLARE @dos TABLE(IdCompra int);
 SET @xml=CONVERT(xml,N'<detalles><item producto="'+CONVERT(nvarchar(20),@producto)+N'" cantidad="3" costo="2.50" /></detalles>');
 INSERT @uno EXEC dbo.sp_Compras_Registrar @actor,@proveedor,@op,@xml;
 INSERT @dos EXEC dbo.sp_Compras_Registrar @actor,@proveedor,@op,@xml;
 DECLARE @compra int=(SELECT IdCompra FROM @uno);
 IF @compra IS NULL OR @compra<>(SELECT IdCompra FROM @dos) THROW 51944,'Reintento no conserva ID.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Compras WHERE idCompra=@compra AND total=7.50) OR (SELECT COUNT(*) FROM dbo.DetalleCompras WHERE idCompra=@compra)<>1 THROW 51945,'Cabecera o detalle incorrecto.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Productos WHERE idProducto=@producto AND stock=3 AND precio=99) THROW 51946,'Stock duplicado o precio alterado.',1;
 ROLLBACK;
 IF @@TRANCOUNT<>0 OR (SELECT COUNT_BIG(*) FROM dbo.Productos)<>@bp OR (SELECT COUNT_BIG(*) FROM dbo.Proveedores)<>@bv OR (SELECT COUNT_BIG(*) FROM dbo.Compras)<>@bc OR (SELECT COUNT_BIG(*) FROM dbo.DetalleCompras)<>@bd THROW 51943,'Rollback inconsistente; detener.',1;
 PRINT 'Compras 007 aprobadas con rollback (solo tras ejecutar).';
END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH;
