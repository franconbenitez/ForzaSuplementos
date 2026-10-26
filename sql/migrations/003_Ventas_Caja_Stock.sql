:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF OBJECT_ID('dbo.sp_Caja_ValidarVendedor','P') IS NULL THROW 51000, 'Aplicar primero 002_Caja_Procedimientos.sql.', 1;
BEGIN TRANSACTION;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Ventas_RegistrarConCaja
    @idCliente int,@idUsuario int,@idSesion int,@medioPago varchar(20),
    @detalles xml,@totalEsperado decimal(10,2),@nuevaVentaId int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @nuevaVentaId=NULL;
    IF @medioPago IS NULL OR @medioPago NOT IN ('Efectivo','Transferencia','Tarjeta')
        THROW 51009, 'Seleccionar un medio de pago valido.', 1;
    IF @detalles IS NULL OR @detalles.exist('/detalles/detalle[1]')=0
        THROW 51010, 'La venta debe contener detalles.', 1;
    DECLARE @items TABLE(idProducto int PRIMARY KEY,cantidad int NOT NULL,precio decimal(19,4) NOT NULL);
    -- La PK rechaza productos duplicados; conversiones inválidas abortan antes de escribir.
    INSERT @items(idProducto,cantidad,precio)
    SELECT d.n.value('(@idProducto)[1]','int'),d.n.value('(@cantidad)[1]','int'),d.n.value('(@precio)[1]','decimal(19,4)')
    FROM @detalles.nodes('/detalles/detalle') d(n);
    IF EXISTS(SELECT 1 FROM @items WHERE idProducto<=0 OR cantidad<=0 OR precio<=0 OR precio>99999999.99 OR precio<>ROUND(precio,2))
        THROW 51011, 'Productos, cantidades o precios invalidos.', 1;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @bloqueo int,@total decimal(38,4),@inicial decimal(10,2),@efectivo decimal(19,2);
        EXEC @bloqueo=sys.sp_getapplock @Resource='Forza.Caja.Unica',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
        IF @bloqueo<0 THROW 51004, 'Caja ocupada por otra operacion. Actualizar e intentar nuevamente.', 1;
        EXEC dbo.sp_Caja_ValidarVendedor @idUsuario;
        SELECT @inicial=montoInicial FROM dbo.SesionesCaja WITH(UPDLOCK,HOLDLOCK)
        WHERE idSesion=@idSesion AND estado='Abierta' AND idUsuarioApertura=@idUsuario;
        IF @inicial IS NULL THROW 51006, 'Abrir una caja propia antes de vender. La sesion puede haberse cerrado.', 1;
        IF NOT EXISTS(SELECT 1 FROM dbo.Clientes WITH(HOLDLOCK) WHERE idCliente=@idCliente AND activo=1)
            THROW 51012, 'El cliente no existe o esta inactivo.', 1;
        IF EXISTS(SELECT 1 FROM @items i LEFT JOIN dbo.Productos p WITH(UPDLOCK,HOLDLOCK) ON p.idProducto=i.idProducto
            WHERE p.idProducto IS NULL OR p.activo=0 OR p.precio<>i.precio OR p.stock<i.cantidad)
            THROW 51013, 'Producto inactivo, precio actualizado o stock insuficiente. Actualizar catalogo.', 1;
        SELECT @total=SUM(CAST(cantidad AS decimal(10,0))*precio) FROM @items;
        IF @total IS NULL OR @total<=0 OR @total>99999999.99 OR @totalEsperado IS NULL OR @total<>@totalEsperado
            THROW 51014, 'El total no coincide con los detalles o excede el limite.', 1;
        SELECT @efectivo=COALESCE(SUM(CAST(p.importe AS decimal(19,2))),0)
        FROM dbo.Ventas v JOIN dbo.PagosVenta p ON p.idVenta=v.idVenta
        WHERE v.idSesion=@idSesion AND p.medioPago='Efectivo';
        IF @medioPago='Efectivo' AND @inicial+@efectivo+@total>99999999.99
            THROW 51008, 'El efectivo esperado excederia el limite de la sesion. Cerrar caja primero.', 1;
        -- UPDATE condicional bajo bloqueos de actualización retenidos hasta COMMIT.
        UPDATE p SET stock=p.stock-i.cantidad FROM dbo.Productos p JOIN @items i ON i.idProducto=p.idProducto
        WHERE p.activo=1 AND p.stock>=i.cantidad AND p.precio=i.precio;
        IF @@ROWCOUNT<>(SELECT COUNT(*) FROM @items) THROW 51013, 'Stock o precio modificado concurrentemente.', 1;
        INSERT dbo.Ventas(idCliente,idUsuario,fecha,total,idSesion) VALUES(@idCliente,@idUsuario,GETDATE(),@total,@idSesion);
        DECLARE @venta int=CONVERT(int,SCOPE_IDENTITY());
        INSERT dbo.DetalleVentas(idVenta,idProducto,cantidad,precioUnitario,subtotal)
        SELECT @venta,idProducto,cantidad,precio,cantidad*precio FROM @items;
        INSERT dbo.PagosVenta(idVenta,medioPago,importe) VALUES(@venta,@medioPago,@total);
        COMMIT TRANSACTION;
        SET @nuevaVentaId=@venta;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        SET @nuevaVentaId=NULL;
        THROW;
    END CATCH;
END;
GO
-- Conservar firmas, pero impedir que una aplicación vieja eluda caja/pago/atomicidad.
-- El nuevo DAL no usa estos dos puntos de escritura parciales.
CREATE OR ALTER PROCEDURE dbo.sp_Ventas_Registrar
    @idCliente int,@idUsuario int,@total decimal(10,2),@nuevaVentaId int OUTPUT
AS
BEGIN
    SET @nuevaVentaId=NULL;
    THROW 51015, 'Actualizar la aplicacion: usar sp_Ventas_RegistrarConCaja con detalles y medio de pago.', 1;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_DetalleVentas_Insertar
    @idVenta int,@idProducto int,@cantidad int,@precioUnitario decimal(10,2),@subtotal decimal(10,2)
AS
BEGIN
    THROW 51015, 'No se admiten detalles sueltos: usar sp_Ventas_RegistrarConCaja para la venta atomica.', 1;
END;
GO
COMMIT TRANSACTION;
PRINT '003 completada. Requiere desplegar la nueva aplicacion junto con esta migracion.';
