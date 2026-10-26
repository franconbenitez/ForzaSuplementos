:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
IF OBJECT_ID('dbo.PagosVenta','U') IS NULL THROW 51000, 'Aplicar primero 001_Caja_Pagos.sql.', 1;
BEGIN TRANSACTION;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Caja_ValidarVendedor @idUsuario int
AS
BEGIN
    SET NOCOUNT ON;
    IF @idUsuario IS NULL OR NOT EXISTS (
        SELECT 1 FROM dbo.Usuarios u JOIN dbo.Perfiles p ON p.idPerfil=u.idPerfil
        WHERE u.idUsuario=@idUsuario AND u.activo=1 AND UPPER(LTRIM(RTRIM(p.nombrePerfil)))='VENDEDOR')
        THROW 51001, 'Solo un vendedor activo puede operar Caja y Ventas.', 1;
END;
GO
CREATE OR ALTER VIEW dbo.vw_Caja_Resumen
AS
SELECT s.idSesion,s.idUsuarioApertura,s.idUsuarioCierre,
    ua.nombre+' '+ua.apellido AS usuarioApertura,uc.nombre+' '+uc.apellido AS usuarioCierre,
    s.fechaApertura,s.fechaCierre,s.montoInicial,
    CASE WHEN s.estado='Cerrada' THEN CAST(s.montoFinalEsperado AS decimal(19,2))
         WHEN COALESCE(a.ventasSinPago,0)>0 THEN NULL
         ELSE s.montoInicial+COALESCE(a.ventasEfectivo,0) END AS montoFinalEsperado,
    s.montoFinalReal,s.diferencia,s.estado,
    COALESCE(a.cantidadVentas,0) AS cantidadVentas,
    COALESCE(a.importeVentas,0) AS importeVentas,
    COALESCE(a.ventasEfectivo,0) AS ventasEfectivo,
    COALESCE(a.ventasSinPago,0) AS ventasSinPago
FROM dbo.SesionesCaja s
JOIN dbo.Usuarios ua ON ua.idUsuario=s.idUsuarioApertura
LEFT JOIN dbo.Usuarios uc ON uc.idUsuario=s.idUsuarioCierre
OUTER APPLY (
    SELECT COUNT(*) AS cantidadVentas, SUM(CAST(v.total AS decimal(19,2))) AS importeVentas,
        SUM(CASE WHEN p.medioPago='Efectivo' THEN CAST(p.importe AS decimal(19,2)) ELSE CAST(0 AS decimal(19,2)) END) AS ventasEfectivo,
        SUM(CASE WHEN p.idVenta IS NULL OR p.importe<>v.total THEN 1 ELSE 0 END) AS ventasSinPago
    FROM dbo.Ventas v LEFT JOIN dbo.PagosVenta p ON p.idVenta=v.idVenta
    WHERE v.idSesion=s.idSesion
) a;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Caja_ObtenerAbierta @idUsuario int
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.sp_Caja_ValidarVendedor @idUsuario;
    SELECT * FROM dbo.vw_Caja_Resumen WHERE estado='Abierta' AND idUsuarioApertura=@idUsuario;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Caja_Historial @idUsuario int,@desde date,@hasta date
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.sp_Caja_ValidarVendedor @idUsuario;
    IF @desde IS NULL OR @hasta IS NULL OR @desde>@hasta OR @hasta='99991231'
        THROW 51002, 'Rango de fechas invalido.', 1;
    SELECT * FROM dbo.vw_Caja_Resumen
    WHERE idUsuarioApertura=@idUsuario AND fechaApertura>=@desde AND fechaApertura<DATEADD(day,1,@hasta)
    ORDER BY fechaApertura DESC,idSesion DESC;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Caja_Reporte @idUsuario int,@idSesion int
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.sp_Caja_ValidarVendedor @idUsuario;
    SELECT * FROM dbo.vw_Caja_Resumen WHERE idSesion=@idSesion AND idUsuarioApertura=@idUsuario;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Caja_Abrir @idUsuario int,@montoInicial decimal(10,2),@idSesion int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @idSesion=NULL;
    IF @montoInicial IS NULL OR @montoInicial<0 THROW 51003, 'El monto inicial no puede ser negativo.', 1;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @bloqueo int;
        EXEC @bloqueo=sys.sp_getapplock @Resource='Forza.Caja.Unica',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
        IF @bloqueo<0 THROW 51004, 'Caja ocupada por otra operacion. Actualizar e intentar nuevamente.', 1;
        EXEC dbo.sp_Caja_ValidarVendedor @idUsuario;
        IF EXISTS(SELECT 1 FROM dbo.SesionesCaja WITH(UPDLOCK,HOLDLOCK) WHERE estado='Abierta')
            THROW 51005, 'Ya existe una caja fisica abierta. Debe cerrarla su vendedor responsable.', 1;
        INSERT dbo.SesionesCaja(idUsuarioApertura,fechaApertura,montoInicial,estado)
        VALUES(@idUsuario,GETDATE(),@montoInicial,'Abierta');
        SET @idSesion=CONVERT(int,SCOPE_IDENTITY());
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        SET @idSesion=NULL;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Caja_Cerrar @idUsuario int,@idSesion int,@montoReal decimal(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF @montoReal IS NULL OR @montoReal<0 THROW 51003, 'El monto contado no puede ser negativo.', 1;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @bloqueo int,@inicial decimal(10,2),@esperado decimal(19,2);
        EXEC @bloqueo=sys.sp_getapplock @Resource='Forza.Caja.Unica',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
        IF @bloqueo<0 THROW 51004, 'Caja ocupada por otra operacion. Actualizar e intentar nuevamente.', 1;
        EXEC dbo.sp_Caja_ValidarVendedor @idUsuario;
        SELECT @inicial=montoInicial FROM dbo.SesionesCaja WITH(UPDLOCK,HOLDLOCK)
        WHERE idSesion=@idSesion AND estado='Abierta' AND idUsuarioApertura=@idUsuario;
        IF @inicial IS NULL THROW 51006, 'La caja no esta abierta o no pertenece al vendedor.', 1;
        IF EXISTS(SELECT 1 FROM dbo.Ventas v LEFT JOIN dbo.PagosVenta p ON p.idVenta=v.idVenta
            WHERE v.idSesion=@idSesion AND (p.idVenta IS NULL OR p.importe<>v.total))
            THROW 51007, 'Hay ventas sin pago identificado o con importe inconsistente. Cierre bloqueado.', 1;
        SELECT @esperado=@inicial+COALESCE(SUM(CAST(p.importe AS decimal(19,2))),0)
        FROM dbo.Ventas v JOIN dbo.PagosVenta p ON p.idVenta=v.idVenta
        WHERE v.idSesion=@idSesion AND p.medioPago='Efectivo';
        IF @esperado>99999999.99 OR ABS(@montoReal-@esperado)>99999999.99
            THROW 51008, 'El cierre excede la capacidad decimal del esquema. Revisar sin truncar importes.', 1;
        UPDATE dbo.SesionesCaja SET idUsuarioCierre=@idUsuario,fechaCierre=GETDATE(),
            montoFinalEsperado=@esperado,montoFinalReal=@montoReal,diferencia=@montoReal-@esperado,estado='Cerrada'
        WHERE idSesion=@idSesion;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
COMMIT TRANSACTION;
PRINT '002 completada.';
