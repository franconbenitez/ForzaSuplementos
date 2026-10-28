:on error exit
-- NO EJECUTADA. Requiere 007. No crea movimientos retroactivos.
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
 THROW 51200,'Destino rechazado: solo QA verificada.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1') THROW 51201,'Falta marca QA.',1;

IF OBJECT_ID('dbo.Compras','U') IS NULL THROW 51800,'Requiere 007.',1;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;
SET XACT_ABORT ON;
IF @@TRANCOUNT<>0 THROW 51950,'Ejecutar migracion sin transaccion externa.',1;
BEGIN TRANSACTION;
IF COL_LENGTH('dbo.Productos','stockMinimo') IS NULL ALTER TABLE dbo.Productos ADD stockMinimo int NOT NULL CONSTRAINT DF_Productos_StockMinimo DEFAULT(0) CONSTRAINT CK_Productos_StockMinimo CHECK(stockMinimo>=0);
IF OBJECT_ID('dbo.MovimientosStock','U') IS NULL CREATE TABLE dbo.MovimientosStock(idMovimiento int IDENTITY CONSTRAINT PK_MovimientosStock PRIMARY KEY,idProducto int NOT NULL CONSTRAINT FK_Movimientos_Producto REFERENCES dbo.Productos(idProducto),idUsuario int NOT NULL CONSTRAINT FK_Movimientos_Usuario REFERENCES dbo.Usuarios(idUsuario),fecha datetime2 NOT NULL CONSTRAINT DF_Movimientos_Fecha DEFAULT(SYSDATETIME()),tipo varchar(10) NOT NULL,cantidad int NOT NULL,anterior int NOT NULL,posterior int NOT NULL,motivo nvarchar(250) NOT NULL,idCompra int NULL CONSTRAINT FK_Movimientos_Compra REFERENCES dbo.Compras(idCompra),idVenta int NULL CONSTRAINT FK_Movimientos_Venta REFERENCES dbo.Ventas(idVenta),operacion uniqueidentifier NULL,CONSTRAINT CK_Movimientos_Stock CHECK(anterior>=0 AND posterior>=0 AND CONVERT(bigint,posterior)=CONVERT(bigint,anterior)+cantidad AND cantidad<>0),CONSTRAINT CK_Movimientos_Motivo CHECK(LEN(LTRIM(RTRIM(motivo)))>0),CONSTRAINT CK_Movimientos_Tipo CHECK((tipo='Compra' AND cantidad>0 AND idCompra IS NOT NULL AND idVenta IS NULL AND operacion IS NULL) OR (tipo='Venta' AND cantidad<0 AND idVenta IS NOT NULL AND idCompra IS NULL AND operacion IS NULL) OR (tipo='Ajuste' AND idCompra IS NULL AND idVenta IS NULL AND operacion IS NOT NULL)));
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.MovimientosStock') AND name='UX_Movimientos_Ajuste') CREATE UNIQUE INDEX UX_Movimientos_Ajuste ON dbo.MovimientosStock(operacion) WHERE operacion IS NOT NULL;
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.MovimientosStock') AND name='UX_Movimientos_Compra') CREATE UNIQUE INDEX UX_Movimientos_Compra ON dbo.MovimientosStock(idCompra,idProducto) WHERE idCompra IS NOT NULL;
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.MovimientosStock') AND name='UX_Movimientos_Venta') CREATE UNIQUE INDEX UX_Movimientos_Venta ON dbo.MovimientosStock(idVenta,idProducto) WHERE idVenta IS NOT NULL;
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.MovimientosStock') AND name='IX_Movimientos_FechaProducto') CREATE INDEX IX_Movimientos_FechaProducto ON dbo.MovimientosStock(fecha,idProducto);
-- La transaccion continua hasta desplegar todos los contratos.
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
 THROW 51200,'Destino rechazado: solo QA verificada.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1') THROW 51201,'Falta marca QA.',1;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.sp_Inventario_Stock @idActor int
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u JOIN dbo.Perfiles p ON p.idPerfil=u.idPerfil WHERE u.idUsuario=@idActor AND u.activo=1 AND p.activo=1 AND UPPER(p.nombrePerfil)=''GERENTE'') THROW 51603,''Solo gerente activo.'',1;
SELECT TOP(2000) idProducto IdProducto,nombre Nombre,stock Stock,stockMinimo StockMinimo,activo Activo,CASE WHEN stock=0 THEN ''Agotado'' WHEN stock<=stockMinimo THEN ''Bajo'' ELSE ''Disponible'' END Estado FROM dbo.Productos ORDER BY CASE WHEN stock<=stockMinimo THEN 0 ELSE 1 END,nombre,idProducto;
END;';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
 THROW 51200,'Destino rechazado: solo QA verificada.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1') THROW 51201,'Falta marca QA.',1;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.sp_Inventario_Historial @idActor int,@desde date,@hasta date,@idProducto int=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u JOIN dbo.Perfiles p ON p.idPerfil=u.idPerfil WHERE u.idUsuario=@idActor AND u.activo=1 AND p.activo=1 AND UPPER(p.nombrePerfil)=''GERENTE'') THROW 51603,''Solo gerente activo.'',1;

IF @desde IS NULL OR @hasta IS NULL OR @desde>@hasta OR @hasta>=''99991231'' THROW 51801,''Fechas invalidas.'',1;
SELECT TOP(2000) m.idMovimiento IdMovimiento,m.fecha Fecha,m.idProducto IdProducto,p.nombre Producto,m.idUsuario IdUsuario,m.tipo Tipo,m.cantidad Cantidad,m.anterior Anterior,m.posterior Posterior,m.motivo Motivo,m.idCompra IdCompra,m.idVenta IdVenta FROM dbo.MovimientosStock m JOIN dbo.Productos p ON p.idProducto=m.idProducto WHERE m.fecha>=@desde AND m.fecha<DATEADD(day,1,@hasta) AND (@idProducto IS NULL OR m.idProducto=@idProducto) ORDER BY m.fecha DESC,m.idMovimiento DESC;

END;';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
 THROW 51200,'Destino rechazado: solo QA verificada.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1') THROW 51201,'Falta marca QA.',1;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.sp_Inventario_Minimo @idActor int,@idProducto int,@minimo int
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u JOIN dbo.Perfiles p ON p.idPerfil=u.idPerfil WHERE u.idUsuario=@idActor AND u.activo=1 AND p.activo=1 AND UPPER(p.nombrePerfil)=''GERENTE'') THROW 51603,''Solo gerente activo.'',1;
IF @minimo<0 THROW 51802,''Minimo no puede ser negativo.'',1; UPDATE dbo.Productos SET stockMinimo=@minimo WHERE idProducto=@idProducto; IF @@ROWCOUNT=0 THROW 51803,''Producto inexistente.'',1;
END;';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
 THROW 51200,'Destino rechazado: solo QA verificada.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1') THROW 51201,'Falta marca QA.',1;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.sp_Inventario_Ajustar @idActor int,@idProducto int,@cantidad int,@stockEsperado int,@motivo nvarchar(250),@operacion uniqueidentifier
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u JOIN dbo.Perfiles p ON p.idPerfil=u.idPerfil WHERE u.idUsuario=@idActor AND u.activo=1 AND p.activo=1 AND UPPER(p.nombrePerfil)=''GERENTE'') THROW 51603,''Solo gerente activo.'',1;

IF @cantidad=0 OR @operacion IS NULL OR @stockEsperado<0 OR LEN(LTRIM(RTRIM(@motivo)))=0 OR @motivo IS NULL THROW 51802,''Ajuste invalido.'',1;
DECLARE @lock int,@existente int;
BEGIN TRY
 BEGIN TRANSACTION;
 EXEC @lock=sys.sp_getapplock @Resource=''Forza.Caja.Unica'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
 IF @lock<0 THROW 51804,''Stock ocupado; reintentar.'',1;
 SELECT @existente=idMovimiento FROM dbo.MovimientosStock WITH(UPDLOCK,HOLDLOCK) WHERE operacion=@operacion;
 IF @existente IS NOT NULL BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.MovimientosStock WHERE idMovimiento=@existente AND idProducto=@idProducto AND idUsuario=@idActor AND cantidad=@cantidad AND motivo=@motivo AND anterior=@stockEsperado) THROW 51805,''Identificador reutilizado con otro contenido.'',1;
  COMMIT; RETURN;
 END;
 DECLARE @cambios TABLE(id int,anterior int,posterior int);
 UPDATE dbo.Productos SET stock=CONVERT(bigint,stock)+@cantidad OUTPUT inserted.idProducto,deleted.stock,inserted.stock INTO @cambios
 WHERE idProducto=@idProducto AND activo=1 AND stock=@stockEsperado AND CONVERT(bigint,stock)+@cantidad BETWEEN 0 AND 2147483647;
 IF NOT EXISTS(SELECT 1 FROM @cambios) THROW 51806,''Stock cambio o el ajuste es invalido. Volver a consultar.'',1;
 INSERT dbo.MovimientosStock(idProducto,idUsuario,tipo,cantidad,anterior,posterior,motivo,operacion) SELECT id,@idActor,''Ajuste'',@cantidad,anterior,posterior,@motivo,@operacion FROM @cambios;
 COMMIT;
END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH;

END;';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
 THROW 51200,'Destino rechazado: solo QA verificada.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1') THROW 51201,'Falta marca QA.',1;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.sp_Compras_Registrar @idActor int,@idProveedor int,@operacion uniqueidentifier,@detalles xml
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u JOIN dbo.Perfiles p ON p.idPerfil=u.idPerfil WHERE u.idUsuario=@idActor AND u.activo=1 AND p.activo=1 AND UPPER(p.nombrePerfil)=''GERENTE'') THROW 51603,''Solo gerente activo.'',1;

IF @operacion IS NULL OR @idProveedor<=0 OR @detalles IS NULL THROW 51701,''Compra invalida.'',1;
DECLARE @raw TABLE(id int,cantidad int,costo decimal(38,10));
INSERT @raw SELECT TRY_CONVERT(int,d.n.value(''(@producto)[1]'',''varchar(100)'')),TRY_CONVERT(int,d.n.value(''(@cantidad)[1]'',''varchar(100)'')),TRY_CONVERT(decimal(38,10),d.n.value(''(@costo)[1]'',''varchar(100)'')) FROM @detalles.nodes(''/detalles/item'') d(n);
IF (SELECT COUNT(*) FROM @raw) NOT BETWEEN 1 AND 500 OR EXISTS(SELECT 1 FROM @raw WHERE id IS NULL OR cantidad IS NULL OR costo IS NULL OR id<=0 OR cantidad<=0 OR costo<=0 OR costo>9999999999.99 OR costo<>ROUND(costo,2)) OR EXISTS(SELECT id FROM @raw GROUP BY id HAVING COUNT(*)>1) THROW 51701,''Detalles invalidos o duplicados.'',1;
DECLARE @total decimal(38,2)=(SELECT SUM(CONVERT(decimal(10,0),cantidad)*CONVERT(decimal(18,2),costo)) FROM @raw);
IF @total>9999999999999999.99 THROW 51701,''Total excedido.'',1;
DECLARE @hash varbinary(32)=HASHBYTES(''SHA2_256'',CONVERT(nvarchar(max),@detalles)),@id int,@lock int;
BEGIN TRY
 BEGIN TRANSACTION;
 -- Orden comun con ventas/caja: serializa modificaciones cortas de stock.
 EXEC @lock=sys.sp_getapplock @Resource=''Forza.Caja.Unica'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
 IF @lock<0 THROW 51702,''Stock ocupado; reintentar.'',1;
 SELECT @id=idCompra FROM dbo.Compras WITH(UPDLOCK,HOLDLOCK) WHERE operacion=@operacion;
 IF @id IS NOT NULL BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.Compras WHERE idCompra=@id AND idUsuario=@idActor AND idProveedor=@idProveedor AND huella=@hash) THROW 51703,''Identificador reutilizado con otro contenido.'',1;
  COMMIT; SELECT @id IdCompra; RETURN;
 END;
 IF NOT EXISTS(SELECT 1 FROM dbo.Proveedores WITH(HOLDLOCK) WHERE idProveedor=@idProveedor AND activo=1) THROW 51704,''Proveedor inactivo.'',1;
 IF EXISTS(SELECT 1 FROM @raw r LEFT JOIN dbo.Productos p WITH(UPDLOCK,HOLDLOCK) ON p.idProducto=r.id WHERE p.idProducto IS NULL OR p.activo=0 OR CONVERT(bigint,p.stock)+r.cantidad>2147483647) THROW 51705,''Producto inactivo o limite de stock excedido.'',1;
 INSERT dbo.Compras(idProveedor,idUsuario,total,operacion,huella) VALUES(@idProveedor,@idActor,@total,@operacion,@hash);
 SET @id=CONVERT(int,SCOPE_IDENTITY());
 INSERT dbo.DetalleCompras(idCompra,idProducto,cantidad,costoUnitario,subtotal) SELECT @id,id,cantidad,costo,cantidad*costo FROM @raw;
 DECLARE @cambios TABLE(id int,anterior int,posterior int);
 UPDATE p SET stock=p.stock+r.cantidad OUTPUT inserted.idProducto,deleted.stock,inserted.stock INTO @cambios FROM dbo.Productos p JOIN @raw r ON p.idProducto=r.id;
 INSERT dbo.MovimientosStock(idProducto,idUsuario,tipo,cantidad,anterior,posterior,motivo,idCompra) SELECT id,@idActor,''Compra'',posterior-anterior,anterior,posterior,N''Compra registrada'',@id FROM @cambios;
 COMMIT;
 SELECT @id IdCompra;
END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH;

END;';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
 THROW 51200,'Destino rechazado: solo QA verificada.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1') THROW 51201,'Falta marca QA.',1;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.sp_Ventas_RegistrarConCaja @idCliente int,@idUsuario int,@idSesion int,@medioPago varchar(20),
    @detalles xml,@totalEsperado decimal(10,2),@nuevaVentaId int OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @nuevaVentaId=NULL;
    IF @medioPago IS NULL OR @medioPago NOT IN (''Efectivo'',''Transferencia'',''Tarjeta'')
        THROW 51009, ''Seleccionar un medio de pago valido.'', 1;
    IF @detalles IS NULL OR @detalles.exist(''/detalles/detalle[1]'')=0
        THROW 51010, ''La venta debe contener detalles.'', 1;
    DECLARE @items TABLE(idProducto int PRIMARY KEY,cantidad int NOT NULL,precio decimal(19,4) NOT NULL);
    -- La PK rechaza productos duplicados; conversiones inválidas abortan antes de escribir.
    INSERT @items(idProducto,cantidad,precio)
    SELECT d.n.value(''(@idProducto)[1]'',''int''),d.n.value(''(@cantidad)[1]'',''int''),d.n.value(''(@precio)[1]'',''decimal(19,4)'')
    FROM @detalles.nodes(''/detalles/detalle'') d(n);
    IF EXISTS(SELECT 1 FROM @items WHERE idProducto<=0 OR cantidad<=0 OR precio<=0 OR precio>99999999.99 OR precio<>ROUND(precio,2))
        THROW 51011, ''Productos, cantidades o precios invalidos.'', 1;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @bloqueo int,@total decimal(38,4),@inicial decimal(10,2),@efectivo decimal(19,2);
        EXEC @bloqueo=sys.sp_getapplock @Resource=''Forza.Caja.Unica'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
        IF @bloqueo<0 THROW 51004, ''Caja ocupada por otra operacion. Actualizar e intentar nuevamente.'', 1;
        EXEC dbo.sp_Caja_ValidarVendedor @idUsuario;
        SELECT @inicial=montoInicial FROM dbo.SesionesCaja WITH(UPDLOCK,HOLDLOCK)
        WHERE idSesion=@idSesion AND estado=''Abierta'' AND idUsuarioApertura=@idUsuario;
        IF @inicial IS NULL THROW 51006, ''Abrir una caja propia antes de vender. La sesion puede haberse cerrado.'', 1;
        IF NOT EXISTS(SELECT 1 FROM dbo.Clientes WITH(HOLDLOCK) WHERE idCliente=@idCliente AND activo=1)
            THROW 51012, ''El cliente no existe o esta inactivo.'', 1;
        IF EXISTS(SELECT 1 FROM @items i LEFT JOIN dbo.Productos p WITH(UPDLOCK,HOLDLOCK) ON p.idProducto=i.idProducto
            WHERE p.idProducto IS NULL OR p.activo=0 OR p.precio<>i.precio OR p.stock<i.cantidad)
            THROW 51013, ''Producto inactivo, precio actualizado o stock insuficiente. Actualizar catalogo.'', 1;
        SELECT @total=SUM(CAST(cantidad AS decimal(10,0))*precio) FROM @items;
        IF @total IS NULL OR @total<=0 OR @total>99999999.99 OR @totalEsperado IS NULL OR @total<>@totalEsperado
            THROW 51014, ''El total no coincide con los detalles o excede el limite.'', 1;
        SELECT @efectivo=COALESCE(SUM(CAST(p.importe AS decimal(19,2))),0)
        FROM dbo.Ventas v JOIN dbo.PagosVenta p ON p.idVenta=v.idVenta
        WHERE v.idSesion=@idSesion AND p.medioPago=''Efectivo'';
        IF @medioPago=''Efectivo'' AND @inicial+@efectivo+@total>99999999.99
            THROW 51008, ''El efectivo esperado excederia el limite de la sesion. Cerrar caja primero.'', 1;
        -- UPDATE condicional bajo bloqueos de actualización retenidos hasta COMMIT.
        DECLARE @movimientos TABLE(id int,anterior int,posterior int);
        UPDATE p SET stock=p.stock-i.cantidad OUTPUT inserted.idProducto,deleted.stock,inserted.stock INTO @movimientos FROM dbo.Productos p JOIN @items i ON i.idProducto=p.idProducto
        WHERE p.activo=1 AND p.stock>=i.cantidad AND p.precio=i.precio;
        IF @@ROWCOUNT<>(SELECT COUNT(*) FROM @items) THROW 51013, ''Stock o precio modificado concurrentemente.'', 1;
        INSERT dbo.Ventas(idCliente,idUsuario,fecha,total,idSesion) VALUES(@idCliente,@idUsuario,GETDATE(),@total,@idSesion);
        DECLARE @venta int=CONVERT(int,SCOPE_IDENTITY());
        INSERT dbo.DetalleVentas(idVenta,idProducto,cantidad,precioUnitario,subtotal)
        SELECT @venta,idProducto,cantidad,precio,cantidad*precio FROM @items;
        INSERT dbo.PagosVenta(idVenta,medioPago,importe) VALUES(@venta,@medioPago,@total);
        INSERT dbo.MovimientosStock(idProducto,idUsuario,tipo,cantidad,anterior,posterior,motivo,idVenta) SELECT id,@idUsuario,''Venta'',posterior-anterior,anterior,posterior,N''Venta registrada'',@venta FROM @movimientos;
        COMMIT TRANSACTION;
        SET @nuevaVentaId=@venta;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        SET @nuevaVentaId=NULL;
        THROW;
    END CATCH;

END;';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
 THROW 51200,'Destino rechazado: solo QA verificada.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1') THROW 51201,'Falta marca QA.',1;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.sp_Productos_Modificar @idProducto int,@idCategoria int,@nombre varchar(100),@descripcion varchar(255),@precio decimal(10,2),@stock int
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;

UPDATE dbo.Productos SET idCategoria=@idCategoria,nombre=@nombre,descripcion=@descripcion,precio=@precio WHERE idProducto=@idProducto AND stock=@stock;
IF @@ROWCOUNT=0 THROW 51807,''No editar stock desde Productos. Usar Inventario con motivo o actualizar catalogo.'',1;

END;';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
 THROW 51200,'Destino rechazado: solo QA verificada.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1') THROW 51201,'Falta marca QA.',1;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.sp_Productos_Insertar @idCategoria int,@nombre varchar(100),@descripcion varchar(255),@precio decimal(10,2),@stock int,@nuevoId int OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;

IF @stock<>0 THROW 51807,''Crear producto con stock cero; usar compra o ajuste con motivo.'',1;
INSERT dbo.Productos(idCategoria,nombre,descripcion,precio,stock,activo) VALUES(@idCategoria,@nombre,@descripcion,@precio,0,1);
SET @nuevoId=CONVERT(int,SCOPE_IDENTITY());

END;';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
 THROW 51200,'Destino rechazado: solo QA verificada.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1') THROW 51201,'Falta marca QA.',1;
IF @@TRANCOUNT<>1 THROW 51951,'Transaccion de migracion inesperada: detener.',1;
COMMIT TRANSACTION;
GO
