:on error exit
-- PREPARADO, NO EJECUTADO: requiere 005 estructura, 006,007,008 y autorizacion especifica.
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)' THROW 51200,'Solo QA verificada.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1') THROW 51201,'Falta marca QA.',1;
IF N'$(AutorizarEnsayo)'<>N'SOLO_NEGATIVOS_ROLLBACK' THROW 51900,'Falta autorizacion especifica.',1;
IF OBJECT_ID('dbo.sp_Inventario_Ajustar','P') IS NULL THROW 51900,'Requiere 008.',1;
IF @@TRANCOUNT<>0 THROW 51932,'El ensayo requiere una conexion sin transaccion previa.',1;
SET IMPLICIT_TRANSACTIONS OFF;
SET NOCOUNT ON; SET XACT_ABORT ON;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;
DECLARE @actor int=(SELECT TOP(1) gerente FROM qa.Fixtures),@admin int=(SELECT TOP(1) administrador FROM qa.Fixtures),@cat int=(SELECT TOP(1) categoria FROM qa.Fixtures),@caso int=1;
DECLARE @baseProductos bigint=(SELECT COUNT_BIG(*) FROM dbo.Productos),@baseProveedores bigint=(SELECT COUNT_BIG(*) FROM dbo.Proveedores),@baseCompras bigint=(SELECT COUNT_BIG(*) FROM dbo.Compras),@baseMov bigint=(SELECT COUNT_BIG(*) FROM dbo.MovimientosStock);
WHILE @caso<=10
BEGIN
 DECLARE @error int=NULL,@esperado int=CASE @caso WHEN 1 THEN 51705 WHEN 2 THEN 51704 WHEN 3 THEN 51701 WHEN 4 THEN 51701 WHEN 5 THEN 51705 WHEN 6 THEN 51701 WHEN 7 THEN 51806 WHEN 8 THEN 51802 WHEN 9 THEN 51806 WHEN 10 THEN 51603 END;
 BEGIN TRY
  BEGIN TRANSACTION;
  DECLARE @nombre nvarchar(100)=N'QA Negativo '+CONVERT(nvarchar(36),NEWID());
  INSERT dbo.Proveedores(nombre,razonSocial,activo) VALUES(@nombre,N'QA Ficticio',1);
  DECLARE @proveedor int=CONVERT(int,SCOPE_IDENTITY());
  INSERT dbo.Productos(idCategoria,nombre,descripcion,precio,stock,activo) VALUES(@cat,@nombre,N'Fixture transitorio',10,1,1);
  DECLARE @producto int=CONVERT(int,SCOPE_IDENTITY()),@cantidad varchar(20)='1',@costo varchar(30)='1.00',@operacion uniqueidentifier=NEWID(),@xml xml;
  IF @caso=1 UPDATE dbo.Productos SET activo=0 WHERE idProducto=@producto;
  IF @caso=2 UPDATE dbo.Proveedores SET activo=0 WHERE idProveedor=@proveedor;
  IF @caso=3 SET @cantidad='0';
  IF @caso=4 SET @costo='1.00000000001';
  IF @caso=5 UPDATE dbo.Productos SET stock=2147483647 WHERE idProducto=@producto;
  IF @caso=6 SET @operacion='00000000-0000-0000-0000-000000000000';
  SET @xml=CONVERT(xml,N'<detalles><item producto="'+CONVERT(nvarchar(20),@producto)+N'" cantidad="'+@cantidad+N'" costo="'+@costo+N'" /></detalles>');
  IF @caso<=6 EXEC dbo.sp_Compras_Registrar @actor,@proveedor,@operacion,@xml;
  IF @caso=7 EXEC dbo.sp_Inventario_Ajustar @actor,@producto,-2,1,N'QA salida insuficiente',@operacion;
  IF @caso=8 EXEC dbo.sp_Inventario_Ajustar @actor,@producto,1,1,N'',@operacion;
  IF @caso=9 EXEC dbo.sp_Inventario_Ajustar @actor,@producto,1,2,N'QA stock obsoleto',@operacion;
  IF @caso=10 EXEC dbo.sp_Compras_Registrar @admin,@proveedor,@operacion,@xml;
 END TRY
 BEGIN CATCH
  SET @error=ERROR_NUMBER();
 END CATCH;
 IF XACT_STATE()<>0 ROLLBACK;
 IF @error IS NULL OR @error<>@esperado THROW 51930,'Caso no rechazo con el contrato esperado; detener.',1;
 IF @@TRANCOUNT<>0 OR (SELECT COUNT_BIG(*) FROM dbo.Productos)<>@baseProductos OR (SELECT COUNT_BIG(*) FROM dbo.Proveedores)<>@baseProveedores OR (SELECT COUNT_BIG(*) FROM dbo.Compras)<>@baseCompras OR (SELECT COUNT_BIG(*) FROM dbo.MovimientosStock)<>@baseMov THROW 51931,'Rollback inconsistente; detener.',1;
 PRINT CONCAT('Caso negativo ',@caso,' aprobado con rollback (solo tras ejecutar).');
 SET @caso+=1;
END;
