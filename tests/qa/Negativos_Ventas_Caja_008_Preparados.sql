:on error exit
-- PREPARADO, NO EJECUTADO: ocho rechazos Ventas/Caja tras 008; permiso independiente.
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)' THROW 51200,'Solo QA verificada.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1') THROW 51201,'Falta marca QA.',1;
IF N'$(AutorizarEnsayo)'<>N'SOLO_NEGATIVOS_ROLLBACK' THROW 51900,'Falta autorizacion especifica.',1;
IF @@TRANCOUNT<>0 THROW 51932,'Conexion sin transaccion previa requerida.',1;
IF (SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped=0)<>18 OR (SELECT COUNT(*) FROM sys.procedures WHERE is_ms_shipped=0)<>50 THROW 51900,'Requiere 008 completa.',1;
IF (SELECT COUNT(*) FROM qa.Fixtures)<>1 THROW 51900,'Fixtures ambiguos.',1;
IF EXISTS(SELECT 1 FROM dbo.SesionesCaja WHERE estado='Abierta') THROW 51947,'Caja previa abierta: no se opera ni cierra.',1;
SET IMPLICIT_TRANSACTIONS OFF; SET XACT_ABORT ON; SET NOCOUNT ON;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;
DECLARE @vendedor int,@gerente int,@cliente int,@categoria int;
SELECT @vendedor=vendedor,@gerente=gerente,@cliente=cliente,@categoria=categoria FROM qa.Fixtures;
DECLARE @bp bigint=(SELECT COUNT_BIG(*) FROM dbo.Productos),@bs bigint=(SELECT COUNT_BIG(*) FROM dbo.SesionesCaja),@bv bigint=(SELECT COUNT_BIG(*) FROM dbo.Ventas),@bd bigint=(SELECT COUNT_BIG(*) FROM dbo.DetalleVentas),@bg bigint=(SELECT COUNT_BIG(*) FROM dbo.PagosVenta),@bm bigint=(SELECT COUNT_BIG(*) FROM dbo.MovimientosStock);
DECLARE @caso int=1;
WHILE @caso<=8
BEGIN
 DECLARE @error int=NULL,@esperado int=CASE @caso WHEN 1 THEN 51006 WHEN 2 THEN 51013 WHEN 3 THEN 51014 WHEN 4 THEN 51009 WHEN 5 THEN 51005 WHEN 6 THEN 51003 WHEN 7 THEN 51006 WHEN 8 THEN 51001 END;
 DECLARE @nombre nvarchar(100)=N'QA Negativo venta '+CONVERT(nvarchar(36),NEWID());
 DECLARE @producto int=NULL,@sesion int=NULL,@otra int=NULL,@venta int=NULL,@xml xml,@cantidad int=1,@medio varchar(20)='Efectivo',@total decimal(10,2)=10;
 BEGIN TRY
  BEGIN TRANSACTION;
  INSERT dbo.Productos(idCategoria,nombre,descripcion,precio,stock,activo) VALUES(@categoria,@nombre,N'QA Ficticio',10,1,1);
  SET @producto=CONVERT(int,SCOPE_IDENTITY());
  IF @caso IN(2,3,4,5,7) EXEC dbo.sp_Caja_Abrir @idUsuario=@vendedor,@montoInicial=0,@idSesion=@sesion OUTPUT;
  IF @caso=2 SET @cantidad=2;
  IF @caso=2 SET @total=20;
  IF @caso=3 SET @total=11;
  IF @caso=4 SET @medio='Cheque';
  IF @caso<=4
  BEGIN
   SET @xml=CONVERT(xml,N'<detalles><detalle idProducto="'+CONVERT(nvarchar(20),@producto)+N'" cantidad="'+CONVERT(nvarchar(20),@cantidad)+N'" precio="10.00" /></detalles>');
   EXEC dbo.sp_Ventas_RegistrarConCaja @idCliente=@cliente,@idUsuario=@vendedor,@idSesion=@sesion,@medioPago=@medio,@detalles=@xml,@totalEsperado=@total,@nuevaVentaId=@venta OUTPUT;
  END;
  IF @caso=5 EXEC dbo.sp_Caja_Abrir @idUsuario=@vendedor,@montoInicial=0,@idSesion=@otra OUTPUT;
  IF @caso=6 EXEC dbo.sp_Caja_Abrir @idUsuario=@vendedor,@montoInicial=-1,@idSesion=@otra OUTPUT;
  IF @caso=7
  BEGIN
   EXEC dbo.sp_Caja_Cerrar @idUsuario=@vendedor,@idSesion=@sesion,@montoReal=0;
   EXEC dbo.sp_Caja_Cerrar @idUsuario=@vendedor,@idSesion=@sesion,@montoReal=0;
  END;
  IF @caso=8 EXEC dbo.sp_Caja_Abrir @idUsuario=@gerente,@montoInicial=0,@idSesion=@otra OUTPUT;
 END TRY BEGIN CATCH SET @error=ERROR_NUMBER(); END CATCH;
 IF XACT_STATE()<>0 ROLLBACK;
 IF @error IS NULL OR @error<>@esperado THROW 51930,'Rechazo Ventas/Caja distinto del esperado; detener.',1;
 IF @@TRANCOUNT<>0 OR (SELECT COUNT_BIG(*) FROM dbo.Productos)<>@bp OR (SELECT COUNT_BIG(*) FROM dbo.SesionesCaja)<>@bs OR (SELECT COUNT_BIG(*) FROM dbo.Ventas)<>@bv OR (SELECT COUNT_BIG(*) FROM dbo.DetalleVentas)<>@bd OR (SELECT COUNT_BIG(*) FROM dbo.PagosVenta)<>@bg OR (SELECT COUNT_BIG(*) FROM dbo.MovimientosStock)<>@bm OR EXISTS(SELECT 1 FROM dbo.Productos WHERE nombre=@nombre) OR EXISTS(SELECT 1 FROM dbo.MovimientosStock WHERE idProducto=@producto) OR EXISTS(SELECT 1 FROM dbo.SesionesCaja WHERE idSesion=@sesion) THROW 51943,'Rollback negativo Ventas/Caja inconsistente; detener.',1;
 PRINT CONCAT('Negativo Ventas/Caja ',@caso,' aprobado con rollback (solo tras ejecutar).');
 SET @caso+=1;
END;
