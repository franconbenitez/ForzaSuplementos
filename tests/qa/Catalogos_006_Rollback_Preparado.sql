:on error exit
-- PREPARADO, NO EJECUTADO. Requiere autorizacion especifica del script y sus fixtures.
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)' THROW 51200,'Solo QA verificada.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1') THROW 51201,'Falta marca QA.',1;
IF N'$(AutorizarEnsayo)'<>N'SOLO_FIXTURES_ROLLBACK' THROW 51900,'Falta autorizacion especifica.',1;
IF @@TRANCOUNT<>0 THROW 51932,'Conexion sin transaccion previa requerida.',1;
SET IMPLICIT_TRANSACTIONS OFF; SET XACT_ABORT ON; SET NOCOUNT ON;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;
IF OBJECT_ID('dbo.sp_Marcas_AsociarProducto','P') IS NULL THROW 51900,'Requiere 006.',1;
DECLARE @actor int=(SELECT TOP(1) gerente FROM qa.Fixtures),@categoria int=(SELECT TOP(1) categoria FROM qa.Fixtures);
DECLARE @bp bigint=(SELECT COUNT_BIG(*) FROM dbo.Productos),@bv bigint=(SELECT COUNT_BIG(*) FROM dbo.Proveedores),@bm bigint=(SELECT COUNT_BIG(*) FROM dbo.Marcas);
BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @nombre nvarchar(100)=N'QA Catalogo '+CONVERT(nvarchar(36),NEWID());
 DECLARE @v TABLE(Id int);
 DECLARE @m TABLE(Id int);
 INSERT @v EXEC dbo.sp_Proveedores_Guardar @actor,0,@nombre,N'QA Razon ficticia',NULL,1;
 DECLARE @proveedor int=(SELECT Id FROM @v);
 IF @proveedor IS NULL THROW 51940,'Proveedor sin ID confirmado.',1;
 EXEC dbo.sp_Proveedores_Guardar @actor,@proveedor,@nombre,N'QA Modificado',NULL,0;
 IF (SELECT COUNT(*) FROM dbo.Proveedores WHERE nombre=@nombre)<>1 OR NOT EXISTS(SELECT 1 FROM dbo.Proveedores WHERE idProveedor=@proveedor AND activo=0 AND razonSocial=N'QA Modificado') THROW 51941,'Edicion repitio alta o no guardo baja logica.',1;
 INSERT @m EXEC dbo.sp_Marcas_Guardar @actor,0,@nombre,1;
 DECLARE @marca int=(SELECT Id FROM @m);
 INSERT dbo.Productos(idCategoria,nombre,descripcion,precio,stock,activo) VALUES(@categoria,@nombre,N'QA ficticio',10,0,1);
 DECLARE @producto int=CONVERT(int,SCOPE_IDENTITY());
 EXEC dbo.sp_Marcas_AsociarProducto @actor,@producto,@marca;
 IF NOT EXISTS(SELECT 1 FROM dbo.Productos WHERE idProducto=@producto AND idMarca=@marca) THROW 51942,'Marca no asociada.',1;
 ROLLBACK;
 IF @@TRANCOUNT<>0 OR (SELECT COUNT_BIG(*) FROM dbo.Productos)<>@bp OR (SELECT COUNT_BIG(*) FROM dbo.Proveedores)<>@bv OR (SELECT COUNT_BIG(*) FROM dbo.Marcas)<>@bm THROW 51943,'Rollback inconsistente; detener.',1;
 PRINT 'Catalogos 006 aprobados con rollback (solo tras ejecutar).';
END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH;
