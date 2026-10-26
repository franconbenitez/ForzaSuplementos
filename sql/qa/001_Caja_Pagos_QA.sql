:on error exit
-- COPIA QA generada desde sql/migrations/001_Caja_Pagos.sql. No ejecutar sobre otra base.
-- SOURCE_SHA256: 3C8D49B2F54CFE144CB7003E4C1F003BC308CED4393664270ED92026C1A4DE34
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1') THROW 51200, 'Falta la marca QA aislada.', 1;
-- Requiere modo SQLCMD. Ejecutar manualmente en una BASE DE PRUEBA verificada.
-- No contiene USE: la base destino debe seleccionarse expresamente con -d.
SET NOCOUNT ON;
SET XACT_ABORT ON;
-- Opciones requeridas para crear/mantener el indice filtrado.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
BEGIN TRANSACTION;

-- Contrato verificado contra sys.columns el 26/10/2026. No recrea tablas existentes.
DECLARE @esperado TABLE(tabla sysname, columna sysname, tipo sysname, precision tinyint, escala tinyint, nullable bit);
INSERT @esperado VALUES
('SesionesCaja','idSesion','int',10,0,0),
('SesionesCaja','idUsuarioApertura','int',10,0,0),
('SesionesCaja','idUsuarioCierre','int',10,0,1),
('SesionesCaja','fechaApertura','datetime',23,3,0),
('SesionesCaja','fechaCierre','datetime',23,3,1),
('SesionesCaja','montoInicial','decimal',10,2,0),
('SesionesCaja','montoFinalEsperado','decimal',10,2,1),
('SesionesCaja','montoFinalReal','decimal',10,2,1),
('SesionesCaja','diferencia','decimal',10,2,1),
('Ventas','idVenta','int',10,0,0),
('Ventas','idSesion','int',10,0,1),
('Ventas','total','decimal',10,2,0),
('DetalleVentas','cantidad','int',10,0,0),
('DetalleVentas','precioUnitario','decimal',10,2,0),
('DetalleVentas','subtotal','decimal',10,2,0),
('Productos','stock','int',10,0,0),
('Productos','precio','decimal',10,2,0);
IF EXISTS (SELECT 1 FROM @esperado e LEFT JOIN sys.columns c ON c.object_id=OBJECT_ID('dbo.'+e.tabla) AND c.name=e.columna
    LEFT JOIN sys.types t ON t.user_type_id=c.user_type_id
    WHERE c.column_id IS NULL OR t.name<>e.tipo OR c.precision<>e.precision OR c.scale<>e.escala OR c.is_nullable<>e.nullable)
    THROW 51000, 'El esquema no coincide con el contrato auditado. Revisar sin modificar datos.', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('dbo.SesionesCaja') AND name='estado' AND max_length=20 AND TYPE_NAME(user_type_id)='varchar' AND is_nullable=0)
    THROW 51000, 'SesionesCaja.estado no coincide con varchar(20) NOT NULL.', 1;
IF OBJECT_ID('dbo.Usuarios','U') IS NULL OR OBJECT_ID('dbo.Perfiles','U') IS NULL OR OBJECT_ID('dbo.Clientes','U') IS NULL
    THROW 51000, 'Faltan tablas requeridas.', 1;
IF (SELECT COUNT(*) FROM dbo.SesionesCaja WHERE estado='Abierta') > 1
    THROW 51000, 'Hay varias cajas abiertas preexistentes. Resolver manualmente antes de migrar.', 1;
IF EXISTS (SELECT 1 FROM dbo.SesionesCaja WHERE estado NOT IN ('Abierta','Cerrada') OR montoInicial<0 OR montoFinalReal<0)
    THROW 51000, 'Hay estados o importes de caja incompatibles. No se modificaron registros.', 1;
IF EXISTS (SELECT 1 FROM dbo.Productos WHERE stock<0)
    THROW 51000, 'Hay stock negativo previo. Revisar manualmente; no se corrige automaticamente.', 1;

IF OBJECT_ID('dbo.PagosVenta','U') IS NULL
BEGIN
    -- Un pago completo por venta. Evita una tabla de catálogo sin gestión requerida.
    CREATE TABLE dbo.PagosVenta (
        idVenta int NOT NULL CONSTRAINT PK_PagosVenta PRIMARY KEY,
        medioPago varchar(20) NOT NULL,
        importe decimal(10,2) NOT NULL,
        CONSTRAINT FK_PagosVenta_Ventas FOREIGN KEY(idVenta) REFERENCES dbo.Ventas(idVenta),
        CONSTRAINT CK_PagosVenta_Medio CHECK(medioPago IN ('Efectivo','Transferencia','Tarjeta')),
        CONSTRAINT CK_PagosVenta_Importe CHECK(importe>0)
    );
END
ELSE
BEGIN
    IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('dbo.PagosVenta') AND name='idVenta' AND TYPE_NAME(user_type_id)='int' AND is_nullable=0)
        OR NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('dbo.PagosVenta') AND name='medioPago' AND TYPE_NAME(user_type_id)='varchar' AND max_length=20 AND is_nullable=0)
        OR NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('dbo.PagosVenta') AND name='importe' AND TYPE_NAME(user_type_id)='decimal' AND precision=10 AND scale=2 AND is_nullable=0)
        OR OBJECT_ID('dbo.PK_PagosVenta','PK') IS NULL OR OBJECT_ID('dbo.FK_PagosVenta_Ventas','F') IS NULL
        OR OBJECT_ID('dbo.CK_PagosVenta_Medio','C') IS NULL OR OBJECT_ID('dbo.CK_PagosVenta_Importe','C') IS NULL
        THROW 51000, 'Existe PagosVenta con otro contrato. Revisar antes de continuar.', 1;
END;

IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.SesionesCaja') AND name='UX_SesionesCaja_UnicaAbierta')
    CREATE UNIQUE INDEX UX_SesionesCaja_UnicaAbierta ON dbo.SesionesCaja(estado) WHERE estado='Abierta';
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.Ventas') AND name='IX_Ventas_SesionCaja')
    CREATE INDEX IX_Ventas_SesionCaja ON dbo.Ventas(idSesion) INCLUDE(total);
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.SesionesCaja') AND name='IX_SesionesCaja_UsuarioFecha')
    CREATE INDEX IX_SesionesCaja_UsuarioFecha ON dbo.SesionesCaja(idUsuarioApertura,fechaApertura);
IF OBJECT_ID('dbo.CK_Productos_StockNoNegativo','C') IS NULL
    ALTER TABLE dbo.Productos WITH CHECK ADD CONSTRAINT CK_Productos_StockNoNegativo CHECK(stock>=0);
COMMIT TRANSACTION;
PRINT '001 completada. Ningun pago historico fue inferido ni rellenado.';

GO
