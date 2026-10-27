:on error exit
-- PENDIENTE DE AUTORIZACION. SQLCMD -d QA explicito; QaExpectedServer proviene de la configuracion local verificada.
-- Solo crea/actualiza dos SP. No altera tablas, ventas, pagos, stock ni respaldos.
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere QA en la instancia verificada.', 1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1')
    THROW 51201, 'Falta la marca de QA aislada.', 1;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.sp_Reportes_VentasDashboard
    @idActor int, @desde date, @hasta date, @idVendedor int=NULL, @idProducto int=NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    IF @desde IS NULL OR @hasta IS NULL OR @desde<CONVERT(date,''17530101'') OR @hasta>=CONVERT(date,''99991231'') OR @desde>@hasta
        THROW 51401, ''Rango de fechas invalido.'', 1;
    IF (@idVendedor IS NOT NULL AND @idVendedor<=0) OR (@idProducto IS NOT NULL AND @idProducto<=0)
        THROW 51402, ''Filtro de identificador invalido.'', 1;
    DECLARE @rol varchar(30), @propia bit=CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END;
    BEGIN TRY
        IF @propia=1 BEGIN TRANSACTION;
        SELECT @rol=UPPER(LTRIM(RTRIM(p.nombrePerfil)))
        FROM dbo.Usuarios u WITH(HOLDLOCK) JOIN dbo.Perfiles p WITH(HOLDLOCK) ON p.idPerfil=u.idPerfil
        WHERE u.idUsuario=@idActor AND u.activo=1;
        IF @rol IS NULL OR @rol NOT IN (''GERENTE'',''VENDEDOR'') THROW 51403, ''Perfil no autorizado para dashboard comercial.'', 1;
        IF @rol=''VENDEDOR''
        BEGIN
            IF @idVendedor IS NOT NULL AND @idVendedor<>@idActor THROW 51404, ''No se permiten estadisticas ajenas.'', 1;
            SET @idVendedor=@idActor;
        END;
        -- Una sola materializacion; cabeceras y detalles quedan protegidos durante la lectura.
        SELECT v.idVenta IdVenta,v.fecha Fecha,v.total Total,v.idUsuario IdVendedor,
               u.nombre+'' ''+u.apellido+'' (#''+CONVERT(varchar(12),u.idUsuario)+'')'' Vendedor,
               d.idDetalle IdDetalle,d.idProducto IdProducto,d.cantidad Cantidad,d.subtotal Subtotal,
               p.nombre Producto,p.idCategoria IdCategoria,c.nombreCategoria Categoria
        INTO #Datos
        FROM dbo.Ventas v WITH(HOLDLOCK)
        JOIN dbo.Usuarios u WITH(HOLDLOCK) ON u.idUsuario=v.idUsuario
        LEFT JOIN dbo.DetalleVentas d WITH(HOLDLOCK) ON d.idVenta=v.idVenta
        LEFT JOIN dbo.Productos p WITH(HOLDLOCK) ON p.idProducto=d.idProducto
        LEFT JOIN dbo.Categorias c WITH(HOLDLOCK) ON c.idCategoria=p.idCategoria
        WHERE v.fecha>=@desde AND v.fecha<DATEADD(day,1,@hasta)
          AND (@idVendedor IS NULL OR v.idUsuario=@idVendedor)
          AND (@idProducto IS NULL OR d.idProducto=@idProducto);
        IF @propia=1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @propia=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
    -- Con filtro de producto el importe es de las lineas elegidas; sin filtro, total de cabecera una vez.
    SELECT IdVenta,MIN(Fecha) Fecha,MAX(IdVendedor) IdVendedor,MAX(Vendedor) Vendedor,
           CASE WHEN @idProducto IS NULL THEN MAX(Total) ELSE SUM(Subtotal) END Importe
    INTO #Cab FROM #Datos GROUP BY IdVenta;
    SELECT ISNULL((SELECT SUM(Importe) FROM #Cab),CONVERT(decimal(38,2),0)) TotalFacturado,
           (SELECT COUNT(*) FROM #Cab) Operaciones,
           ISNULL((SELECT SUM(CONVERT(bigint,Cantidad)) FROM #Datos),CONVERT(bigint,0)) Unidades,
           (SELECT COUNT(DISTINCT CASE WHEN IdDetalle IS NULL THEN IdVenta END) FROM #Datos) VentasSinDetalle;
    SELECT CONVERT(int,NULL) Clave,CONVERT(char(10),Fecha,23) Etiqueta,SUM(Importe) Importe,COUNT_BIG(*) Cantidad
    FROM #Cab GROUP BY CONVERT(char(10),Fecha,23) ORDER BY Etiqueta;
    SELECT CONVERT(int,NULL) Clave,CONVERT(char(7),Fecha,23) Etiqueta,SUM(Importe) Importe,COUNT_BIG(*) Cantidad
    FROM #Cab GROUP BY CONVERT(char(7),Fecha,23) ORDER BY Etiqueta;
    SELECT TOP(10) IdProducto Clave,MAX(Producto) Etiqueta,SUM(Subtotal) Importe,SUM(CONVERT(bigint,Cantidad)) Cantidad
    FROM #Datos WHERE IdDetalle IS NOT NULL GROUP BY IdProducto ORDER BY Cantidad DESC,Clave;
    SELECT TOP(10) IdCategoria Clave,MAX(Categoria) Etiqueta,SUM(Subtotal) Importe,SUM(CONVERT(bigint,Cantidad)) Cantidad
    FROM #Datos WHERE IdDetalle IS NOT NULL AND IdCategoria IS NOT NULL GROUP BY IdCategoria ORDER BY Cantidad DESC,Clave;
    SELECT IdVendedor Clave,MAX(Vendedor) Etiqueta,SUM(Importe) Importe,COUNT_BIG(*) Cantidad
    FROM #Cab GROUP BY IdVendedor ORDER BY Importe DESC,Clave;
END;
';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere QA en la instancia verificada.', 1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1')
    THROW 51201, 'Falta la marca de QA aislada.', 1;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.sp_Reportes_BackupsDashboard
    @idActor int, @desde date, @hasta date
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    IF @desde IS NULL OR @hasta IS NULL OR @desde<CONVERT(date,''17530101'') OR @hasta>=CONVERT(date,''99991231'') OR @desde>@hasta
        THROW 51401, ''Rango de fechas invalido.'', 1;
    DECLARE @rol varchar(30), @propia bit=CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END;
    BEGIN TRY
        IF @propia=1 BEGIN TRANSACTION;
        SELECT @rol=UPPER(LTRIM(RTRIM(p.nombrePerfil)))
        FROM dbo.Usuarios u WITH(HOLDLOCK) JOIN dbo.Perfiles p WITH(HOLDLOCK) ON p.idPerfil=u.idPerfil
        WHERE u.idUsuario=@idActor AND u.activo=1;
        IF @rol IS NULL OR @rol<>''ADMINISTRADOR'' THROW 51405, ''Solo administrador consulta auditoria de backups.'', 1;
        SELECT a.idBackup IdBackup,a.idUsuario IdUsuario,a.fecha Fecha,
            RIGHT(REPLACE(a.rutaArchivo,''/'',NCHAR(92)),CHARINDEX(NCHAR(92),REVERSE(REPLACE(a.rutaArchivo,''/'',NCHAR(92)))+NCHAR(92))-1) Archivo
        INTO #Historial FROM dbo.AuditoriaBackups a WITH(HOLDLOCK)
        WHERE a.fecha>=@desde AND a.fecha<DATEADD(day,1,@hasta);
        IF @propia=1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @propia=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
    SELECT COUNT(*) Cantidad FROM #Historial;
    SELECT IdBackup,IdUsuario,Fecha,Archivo FROM #Historial ORDER BY Fecha DESC,IdBackup DESC;
    SELECT CONVERT(int,NULL) Clave,CONVERT(char(10),Fecha,23) Etiqueta,CONVERT(decimal(10,2),0) Importe,COUNT_BIG(*) Cantidad
    FROM #Historial GROUP BY CONVERT(char(10),Fecha,23) ORDER BY Etiqueta;
    SELECT CONVERT(int,NULL) Clave,CONVERT(char(7),Fecha,23) Etiqueta,CONVERT(decimal(10,2),0) Importe,COUNT_BIG(*) Cantidad
    FROM #Historial GROUP BY CONVERT(char(7),Fecha,23) ORDER BY Etiqueta;
END;
';
GO
