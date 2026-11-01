:on error exit
-- PREPARADO, NO EJECUTADO. Requiere autorizacion especifica del script y sus fixtures.
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)' THROW 51200,'Solo QA verificada.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1') THROW 51201,'Falta marca QA.',1;
IF N'$(AutorizarEnsayo)'<>N'SOLO_FIXTURES_ROLLBACK' THROW 51900,'Falta autorizacion especifica.',1;
IF @@TRANCOUNT<>0 THROW 51932,'Conexion sin transaccion previa requerida.',1;
SET IMPLICIT_TRANSACTIONS OFF; SET XACT_ABORT ON; SET NOCOUNT ON;
IF (SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped=0)<>18 OR (SELECT COUNT(*) FROM sys.procedures WHERE is_ms_shipped=0)<>50 THROW 51900,'Requiere estructura 008 completa.',1;
IF (SELECT COUNT(*) FROM qa.Fixtures)<>1 THROW 51900,'Fixtures ambiguos.',1;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;
IF OBJECT_ID('dbo.MovimientosStock','U') IS NULL THROW 51900,'Requiere 008.',1;
IF EXISTS(SELECT 1 FROM dbo.SesionesCaja WHERE estado='Abierta') THROW 51947,'Hay una caja abierta: no se opera ni se cierra una sesion ajena.',1;
DECLARE @vendedor int=(SELECT TOP(1) vendedor FROM qa.Fixtures),@cliente int=(SELECT TOP(1) cliente FROM qa.Fixtures),@categoria int=(SELECT TOP(1) categoria FROM qa.Fixtures);
DECLARE @bp bigint=(SELECT COUNT_BIG(*) FROM dbo.Productos),@bs bigint=(SELECT COUNT_BIG(*) FROM dbo.SesionesCaja),@bv bigint=(SELECT COUNT_BIG(*) FROM dbo.Ventas),@bd bigint=(SELECT COUNT_BIG(*) FROM dbo.DetalleVentas),@bg bigint=(SELECT COUNT_BIG(*) FROM dbo.PagosVenta),@bm bigint=(SELECT COUNT_BIG(*) FROM dbo.MovimientosStock);
BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @caso int=0;
 WHILE @caso<3
 BEGIN
  DECLARE @nombre nvarchar(100)=N'QA Venta movimiento '+CONVERT(nvarchar(36),NEWID());
  INSERT dbo.Productos(idCategoria,nombre,descripcion,precio,stock,activo) VALUES(@categoria,@nombre,N'QA Ficticio',10,3,1);
  DECLARE @producto int=CONVERT(int,SCOPE_IDENTITY()),@sesion int=NULL,@venta int=NULL,@pago int=0,@medio varchar(20),@xml xml;
  EXEC dbo.sp_Caja_Abrir @idUsuario=@vendedor,@montoInicial=0,@idSesion=@sesion OUTPUT;
  IF @sesion IS NULL THROW 51948,'Caja sin ID.',1;
  WHILE @pago<3
  BEGIN
   SET @medio=CASE @pago WHEN 0 THEN 'Efectivo' WHEN 1 THEN 'Transferencia' ELSE 'Tarjeta' END;
   SET @xml=CONVERT(xml,N'<detalles><detalle idProducto="'+CONVERT(nvarchar(20),@producto)+N'" cantidad="1" precio="10.00" /></detalles>');
   EXEC dbo.sp_Ventas_RegistrarConCaja @idCliente=@cliente,@idUsuario=@vendedor,@idSesion=@sesion,@medioPago=@medio,@detalles=@xml,@totalEsperado=10,@nuevaVentaId=@venta OUTPUT;
   IF @venta IS NULL OR NOT EXISTS(SELECT 1 FROM dbo.Ventas WHERE idVenta=@venta AND idSesion=@sesion) THROW 51949,'Venta no asociada a sesion.',1;
   IF NOT EXISTS(SELECT 1 FROM dbo.PagosVenta WHERE idVenta=@venta AND medioPago=@medio AND importe=10) THROW 51949,'Pago incorrecto.',1;
   IF (SELECT COUNT(*) FROM dbo.MovimientosStock WHERE idVenta=@venta AND idProducto=@producto AND tipo='Venta' AND cantidad=-1 AND anterior=3-@pago AND posterior=2-@pago)<>1 THROW 51949,'Movimiento ausente o duplicado.',1;
   IF (SELECT stock FROM dbo.Productos WHERE idProducto=@producto)<>2-@pago THROW 51949,'Descuento de stock incorrecto.',1;
   SET @pago+=1;
  END;
  DECLARE @real decimal(10,2)=9+@caso;
  EXEC dbo.sp_Caja_Cerrar @idUsuario=@vendedor,@idSesion=@sesion,@montoReal=@real;
  IF NOT EXISTS(SELECT 1 FROM dbo.SesionesCaja WHERE idSesion=@sesion AND estado='Cerrada' AND montoFinalEsperado=10 AND diferencia=@caso-1) THROW 51949,'Efectivo esperado o diferencia incorrecta.',1;
  IF (SELECT COUNT(*) FROM dbo.Ventas WHERE idSesion=@sesion)<>3 THROW 51949,'Se mezclaron sesiones.',1;
  SET @caso+=1;
 END;
 ROLLBACK;
 IF @@TRANCOUNT<>0 OR (SELECT COUNT_BIG(*) FROM dbo.Productos)<>@bp OR (SELECT COUNT_BIG(*) FROM dbo.SesionesCaja)<>@bs OR (SELECT COUNT_BIG(*) FROM dbo.Ventas)<>@bv OR (SELECT COUNT_BIG(*) FROM dbo.DetalleVentas)<>@bd OR (SELECT COUNT_BIG(*) FROM dbo.PagosVenta)<>@bg OR (SELECT COUNT_BIG(*) FROM dbo.MovimientosStock)<>@bm OR EXISTS(SELECT 1 FROM dbo.Productos WHERE nombre LIKE N'QA Venta movimiento %') OR EXISTS(SELECT 1 FROM dbo.MovimientosStock WHERE idProducto=@producto) OR EXISTS(SELECT 1 FROM dbo.SesionesCaja WHERE idSesion=@sesion) THROW 51943,'Rollback inconsistente; detener.',1;
 PRINT 'Ventas/Caja 008: tres medios y tres diferencias, rollback aprobado (solo tras ejecutar).';
END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH;
