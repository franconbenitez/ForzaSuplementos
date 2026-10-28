-- Solo se ejecuta dentro de una transaccion administrada por Probar-Dashboards-Preparados.ps1.
-- No crea bases ni modifica registros previos. Todas las altas se revierten con ROLLBACK.
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>@QaExpectedServer
    THROW 51200, 'Destino QA incorrecto.', 1;
IF @@TRANCOUNT=0 OR ISNULL(@AutorizarFixtures,0)<>1 THROW 51490, 'Se requiere autorizacion y transaccion externa.', 1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1')
    THROW 51201, 'Falta marca QA.', 1;
IF EXISTS(SELECT 1 FROM dbo.Ventas WHERE fecha>='20990101' AND fecha<'20990201') OR EXISTS(SELECT 1 FROM dbo.AuditoriaBackups WHERE fecha>='20990101' AND fecha<'20990201')
    THROW 51491, 'Periodo ficticio ya ocupado. No se borra informacion.', 1;
DECLARE @v int,@otro int,@admin int,@cliente int,@categoria int,@historico int;
SELECT @v=vendedor,@otro=otroVendedor,@admin=administrador,@cliente=cliente,@categoria=categoria,@historico=productoHistorico FROM qa.Fixtures;
IF @v IS NULL OR @otro IS NULL OR @admin IS NULL THROW 51492, 'Faltan fixtures de referencia.', 1;
INSERT dbo.Productos(idCategoria,nombre,descripcion,precio,stock,activo)
VALUES(@categoria,'QA Reportes Producto B','Fixture transaccional',75,100,1);
DECLARE @nuevo int=CONVERT(int,SCOPE_IDENTITY());
INSERT dbo.Ventas(idCliente,idUsuario,fecha,total,idSesion) VALUES(@cliente,@v,'2099-01-01T12:00:00',350,NULL);
DECLARE @venta int=CONVERT(int,SCOPE_IDENTITY());
INSERT dbo.DetalleVentas(idVenta,idProducto,cantidad,precioUnitario,subtotal) VALUES(@venta,@historico,2,100,200),(@venta,@nuevo,2,75,150);
INSERT dbo.Ventas(idCliente,idUsuario,fecha,total,idSesion) VALUES(@cliente,@otro,'2099-01-02T12:00:00',100,NULL);
SET @venta=CONVERT(int,SCOPE_IDENTITY());
INSERT dbo.DetalleVentas(idVenta,idProducto,cantidad,precioUnitario,subtotal) VALUES(@venta,@historico,1,100,100);
INSERT dbo.AuditoriaBackups(idUsuario,fecha,rutaArchivo) VALUES(@admin,'2099-01-01T12:00:00','QA_FICTICIO/reporte_1.bak'),(@admin,'2099-01-02T12:00:00','QA_FICTICIO/reporte_2.bak');
SELECT @v Vendedor,@otro OtroVendedor,@admin Administrador,@nuevo Producto;
