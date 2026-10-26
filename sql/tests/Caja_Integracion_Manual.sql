-- NO EJECUTADO POR EL AGENTE. Solo en una base aislada cuyo nombre termine en _Pruebas.
-- Preparar datos FICTICIOS y reemplazar los cuatro identificadores 0 antes de ejecutar.
-- Este ensayo crea sesiones y ventas de prueba; las conserva para inspeccion, sin DELETE.
SET NOCOUNT ON;
IF DB_NAME() NOT LIKE '%[_]Pruebas' THROW 51100, 'Usar una base aislada terminada en _Pruebas.', 1;
DECLARE @vendedor int=0,@noVendedor int=0,@cliente int=0,@producto int=0;
IF @vendedor<=0 OR @noVendedor<=0 OR @cliente<=0 OR @producto<=0
    THROW 51100, 'Configurar los cuatro IDs de datos ficticios de esta base de prueba.', 1;
IF EXISTS(SELECT 1 FROM dbo.SesionesCaja WHERE estado='Abierta')
    THROW 51100, 'La prueba requiere comenzar sin caja abierta. No altera sesiones existentes.', 1;
DECLARE @precio decimal(10,2),@stockInicial int,@sesion int,@venta int,@xml xml,@historicas int;
SELECT @precio=precio,@stockInicial=stock FROM dbo.Productos WHERE idProducto=@producto AND activo=1;
IF @precio IS NULL OR @precio<=0 OR @precio>100000 OR @stockInicial<10 OR @stockInicial>1000
    THROW 51100, 'Elegir un producto ficticio activo con stock entre 10 y 1000 y precio entre 0.01 y 100000.', 1;
IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u JOIN dbo.Perfiles p ON p.idPerfil=u.idPerfil
    WHERE u.idUsuario=@noVendedor AND UPPER(p.nombrePerfil) IN ('ADMINISTRADOR','GERENTE') AND u.activo=1)
    THROW 51100, 'El noVendedor debe ser un administrador o gerente ficticio activo.', 1;
SELECT @historicas=COUNT(*) FROM dbo.Ventas WHERE idSesion IS NULL;
SET @xml=(SELECT @producto AS [@idProducto],1 AS [@cantidad],@precio AS [@precio] FOR XML PATH('detalle'),ROOT('detalles'),TYPE);

BEGIN TRY
    EXEC dbo.sp_Caja_Abrir @noVendedor,500,@sesion OUTPUT;
    THROW 51101, 'ERROR: permitio operar a un perfil sin permiso.', 1;
END TRY BEGIN CATCH
    IF ERROR_NUMBER()<>51001 THROW;
END CATCH;
BEGIN TRY
    EXEC dbo.sp_Ventas_RegistrarConCaja @cliente,@vendedor,NULL,'Efectivo',@xml,@precio,@venta OUTPUT;
    THROW 51101, 'ERROR: permitio vender sin caja.', 1;
END TRY BEGIN CATCH
    IF ERROR_NUMBER()<>51006 THROW;
END CATCH;
EXEC dbo.sp_Caja_Abrir @vendedor,500,@sesion OUTPUT;
BEGIN TRY
    DECLARE @otra int;
    EXEC dbo.sp_Caja_Abrir @vendedor,100,@otra OUTPUT;
    THROW 51101, 'ERROR: permitio abrir dos cajas.', 1;
END TRY BEGIN CATCH
    IF ERROR_NUMBER()<>51005 THROW;
END CATCH;

DECLARE @invalido xml;
SET @invalido=(SELECT @producto AS [@idProducto],-1 AS [@cantidad],@precio AS [@precio] FOR XML PATH('detalle'),ROOT('detalles'),TYPE);
BEGIN TRY
    EXEC dbo.sp_Ventas_RegistrarConCaja @cliente,@vendedor,@sesion,'Efectivo',@invalido,@precio,@venta OUTPUT;
    THROW 51101, 'ERROR: permitio cantidad negativa.', 1;
END TRY BEGIN CATCH
    IF ERROR_NUMBER()<>51011 THROW;
END CATCH;
SET @invalido=(SELECT @producto AS [@idProducto],@stockInicial+1 AS [@cantidad],@precio AS [@precio] FOR XML PATH('detalle'),ROOT('detalles'),TYPE);
BEGIN TRY
    EXEC dbo.sp_Ventas_RegistrarConCaja @cliente,@vendedor,@sesion,'Efectivo',@invalido,@precio,@venta OUTPUT;
    THROW 51101, 'ERROR: permitio vender sin stock suficiente.', 1;
END TRY BEGIN CATCH
    IF ERROR_NUMBER()<>51013 THROW;
END CATCH;
BEGIN TRY
    EXEC dbo.sp_Ventas_RegistrarConCaja @cliente,@vendedor,@sesion,'SinSeleccionar',@xml,@precio,@venta OUTPUT;
    THROW 51101, 'ERROR: permitio medio de pago invalido.', 1;
END TRY BEGIN CATCH
    IF ERROR_NUMBER()<>51009 THROW;
END CATCH;
DECLARE @totalAlterado decimal(10,2)=@precio+1;
BEGIN TRY
    EXEC dbo.sp_Ventas_RegistrarConCaja @cliente,@vendedor,@sesion,'Efectivo',@xml,@totalAlterado,@venta OUTPUT;
    THROW 51101, 'ERROR: permitio total distinto al calculado.', 1;
END TRY BEGIN CATCH
    IF ERROR_NUMBER()<>51014 THROW;
END CATCH;
IF EXISTS(SELECT 1 FROM dbo.Ventas WHERE idSesion=@sesion)
    OR (SELECT stock FROM dbo.Productos WHERE idProducto=@producto)<>@stockInicial
    THROW 51101, 'ERROR: un rechazo dejo datos parciales.', 1;

EXEC dbo.sp_Ventas_RegistrarConCaja @cliente,@vendedor,@sesion,'Efectivo',@xml,@precio,@venta OUTPUT;
EXEC dbo.sp_Ventas_RegistrarConCaja @cliente,@vendedor,@sesion,'Transferencia',@xml,@precio,@venta OUTPUT;
EXEC dbo.sp_Ventas_RegistrarConCaja @cliente,@vendedor,@sesion,'Tarjeta',@xml,@precio,@venta OUTPUT;
IF (SELECT COUNT(*) FROM dbo.Ventas WHERE idSesion=@sesion)<>3
    OR (SELECT stock FROM dbo.Productos WHERE idProducto=@producto)<>@stockInicial-3
    OR (SELECT COUNT(*) FROM dbo.PagosVenta p JOIN dbo.Ventas v ON v.idVenta=p.idVenta WHERE v.idSesion=@sesion)<>3
    THROW 51101, 'ERROR: ventas, pagos o stock no coinciden.', 1;
DECLARE @esperado decimal(10,2)=500+@precio,@real decimal(10,2)=501+@precio;
IF NOT EXISTS(SELECT 1 FROM dbo.vw_Caja_Resumen WHERE idSesion=@sesion AND cantidadVentas=3 AND importeVentas=3*@precio
    AND ventasEfectivo=@precio AND montoFinalEsperado=@esperado AND ventasSinPago=0)
    THROW 51101, 'ERROR: se mezclaron ventas no efectivas en el saldo esperado.', 1;
EXEC dbo.sp_Caja_Cerrar @vendedor,@sesion,@real;
IF NOT EXISTS(SELECT 1 FROM dbo.SesionesCaja WHERE idSesion=@sesion AND estado='Cerrada' AND montoFinalEsperado=@esperado
    AND montoFinalReal=@real AND diferencia=1 AND idUsuarioCierre=@vendedor AND fechaCierre IS NOT NULL)
    THROW 51101, 'ERROR: cierre inconsistente.', 1;
BEGIN TRY
    EXEC dbo.sp_Caja_Cerrar @vendedor,@sesion,@real;
    THROW 51101, 'ERROR: permitio cerrar dos veces.', 1;
END TRY BEGIN CATCH
    IF ERROR_NUMBER()<>51006 THROW;
END CATCH;
BEGIN TRY
    EXEC dbo.sp_Ventas_RegistrarConCaja @cliente,@vendedor,@sesion,'Efectivo',@xml,@precio,@venta OUTPUT;
    THROW 51101, 'ERROR: permitio vender sobre caja cerrada.', 1;
END TRY BEGIN CATCH
    IF ERROR_NUMBER()<>51006 THROW;
END CATCH;
IF (SELECT COUNT(*) FROM dbo.Ventas WHERE idSesion IS NULL)<>@historicas
    THROW 51101, 'ERROR: cambio el conjunto historico sin sesion.', 1;
EXEC dbo.sp_Caja_Reporte @vendedor,@sesion;
PRINT 'OK: permisos, caja unica, importes, stock, pagos, cierre e historicos. No verifica concurrencia entre conexiones.';
