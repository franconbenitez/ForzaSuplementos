:on error exit
-- Esquema sin datos. No exporta diagramas ni filas del origen.
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
SET XACT_ABORT ON;
IF EXISTS(SELECT 1 FROM sys.tables WHERE is_ms_shipped=0) THROW 51202, 'El esquema inicial requiere QA vacia; no se sobreescribe.', 1;
BEGIN TRANSACTION;
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
CREATE TABLE dbo.[AuditoriaBackups] (
    [idBackup] int IDENTITY(1,1) NOT NULL,
    [idUsuario] int NOT NULL,
    [fecha] datetime NOT NULL DEFAULT (getdate()),
    [rutaArchivo] varchar(255) NOT NULL,
    CONSTRAINT [PK__Auditori__F34D6CE0C214ECFA] PRIMARY KEY CLUSTERED ([idBackup] ASC)
);
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
CREATE TABLE dbo.[Categorias] (
    [idCategoria] int IDENTITY(1,1) NOT NULL,
    [nombreCategoria] varchar(50) NOT NULL,
    CONSTRAINT [PK__Categori__8A3D240CC7BE2120] PRIMARY KEY CLUSTERED ([idCategoria] ASC)
);
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
CREATE TABLE dbo.[Clientes] (
    [idCliente] int IDENTITY(1,1) NOT NULL,
    [dni] varchar(20) NOT NULL,
    [nombre] varchar(50) NOT NULL,
    [apellido] varchar(50) NOT NULL,
    [telefono] varchar(30) NULL,
    [email] varchar(100) NULL,
    [activo] bit NOT NULL DEFAULT ((1)),
    CONSTRAINT [PK__Clientes__885457EEB20DAE12] PRIMARY KEY CLUSTERED ([idCliente] ASC)
);
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
CREATE TABLE dbo.[DetalleVentas] (
    [idDetalle] int IDENTITY(1,1) NOT NULL,
    [idVenta] int NOT NULL,
    [idProducto] int NOT NULL,
    [cantidad] int NOT NULL,
    [precioUnitario] decimal(10,2) NOT NULL,
    [subtotal] decimal(10,2) NOT NULL,
    CONSTRAINT [PK__DetalleV__49CAE2FB138EB16A] PRIMARY KEY CLUSTERED ([idDetalle] ASC)
);
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
CREATE TABLE dbo.[Perfiles] (
    [idPerfil] int IDENTITY(1,1) NOT NULL,
    [nombrePerfil] varchar(50) NOT NULL,
    [descripcion] varchar(150) NULL,
    CONSTRAINT [PK_Perfiles] PRIMARY KEY CLUSTERED ([idPerfil] ASC),
    CONSTRAINT [UQ_Perfiles_Nombre] UNIQUE NONCLUSTERED ([nombrePerfil] ASC)
);
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
CREATE TABLE dbo.[Productos] (
    [idProducto] int IDENTITY(1,1) NOT NULL,
    [idCategoria] int NOT NULL,
    [nombre] varchar(100) NOT NULL,
    [descripcion] varchar(255) NULL,
    [precio] decimal(10,2) NOT NULL,
    [stock] int NOT NULL,
    [activo] bit NOT NULL DEFAULT ((1)),
    CONSTRAINT [PK__Producto__07F4A132E33100FE] PRIMARY KEY CLUSTERED ([idProducto] ASC)
);
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
CREATE TABLE dbo.[SesionesCaja] (
    [idSesion] int IDENTITY(1,1) NOT NULL,
    [idUsuarioApertura] int NOT NULL,
    [idUsuarioCierre] int NULL,
    [fechaApertura] datetime NOT NULL DEFAULT (getdate()),
    [fechaCierre] datetime NULL,
    [montoInicial] decimal(10,2) NOT NULL,
    [montoFinalEsperado] decimal(10,2) NULL,
    [montoFinalReal] decimal(10,2) NULL,
    [diferencia] decimal(10,2) NULL,
    [estado] varchar(20) NOT NULL DEFAULT ('Abierta'),
    CONSTRAINT [PK__Sesiones__DB6C2DE6E7EDBD99] PRIMARY KEY CLUSTERED ([idSesion] ASC)
);
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
CREATE TABLE dbo.[Usuarios] (
    [idUsuario] int IDENTITY(1,1) NOT NULL,
    [idPerfil] int NOT NULL,
    [nombre] varchar(50) NOT NULL,
    [apellido] varchar(50) NOT NULL,
    [usuario] varchar(50) NOT NULL,
    [contrasena] varchar(100) NOT NULL,
    [email] varchar(100) NOT NULL,
    [dni] varchar(20) NOT NULL,
    [telefono] varchar(30) NOT NULL,
    [fechaNacimiento] date NOT NULL,
    [sexo] char(1) NOT NULL,
    [activo] bit NOT NULL DEFAULT ((1)),
    [fechaAlta] datetime NOT NULL DEFAULT (getdate()),
    [calle] varchar(100) NOT NULL DEFAULT (''),
    [altura] varchar(20) NOT NULL DEFAULT (''),
    CONSTRAINT [PK_Usuarios] PRIMARY KEY CLUSTERED ([idUsuario] ASC),
    CONSTRAINT [UQ_Usuarios_Dni] UNIQUE NONCLUSTERED ([dni] ASC),
    CONSTRAINT [UQ_Usuarios_Usuario] UNIQUE NONCLUSTERED ([usuario] ASC),
    CONSTRAINT [CK_Usuarios_Sexo] CHECK ([sexo]='F' OR [sexo]='M')
);
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
CREATE TABLE dbo.[Ventas] (
    [idVenta] int IDENTITY(1,1) NOT NULL,
    [idCliente] int NOT NULL,
    [idUsuario] int NOT NULL,
    [fecha] datetime NOT NULL DEFAULT (getdate()),
    [total] decimal(10,2) NOT NULL,
    [idSesion] int NULL,
    CONSTRAINT [PK__Ventas__077D5614CD141ADB] PRIMARY KEY CLUSTERED ([idVenta] ASC)
);
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
ALTER TABLE dbo.[AuditoriaBackups] WITH CHECK ADD CONSTRAINT [FK__Auditoria__idUsu__1DB06A4F] FOREIGN KEY ([idUsuario]) REFERENCES dbo.[Usuarios] ([idUsuario]);
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
ALTER TABLE dbo.[DetalleVentas] WITH CHECK ADD CONSTRAINT [FK__DetalleVe__idPro__76969D2E] FOREIGN KEY ([idProducto]) REFERENCES dbo.[Productos] ([idProducto]);
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
ALTER TABLE dbo.[DetalleVentas] WITH CHECK ADD CONSTRAINT [FK__DetalleVe__idVen__75A278F5] FOREIGN KEY ([idVenta]) REFERENCES dbo.[Ventas] ([idVenta]);
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
ALTER TABLE dbo.[Productos] WITH CHECK ADD CONSTRAINT [FK__Productos__idCat__619B8048] FOREIGN KEY ([idCategoria]) REFERENCES dbo.[Categorias] ([idCategoria]);
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
ALTER TABLE dbo.[SesionesCaja] WITH CHECK ADD CONSTRAINT [FK__SesionesC__idUsu__17F790F9] FOREIGN KEY ([idUsuarioApertura]) REFERENCES dbo.[Usuarios] ([idUsuario]);
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
ALTER TABLE dbo.[SesionesCaja] WITH CHECK ADD CONSTRAINT [FK__SesionesC__idUsu__18EBB532] FOREIGN KEY ([idUsuarioCierre]) REFERENCES dbo.[Usuarios] ([idUsuario]);
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
ALTER TABLE dbo.[Ventas] WITH CHECK ADD CONSTRAINT [FK__Ventas__idClient__70DDC3D8] FOREIGN KEY ([idCliente]) REFERENCES dbo.[Clientes] ([idCliente]);
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
ALTER TABLE dbo.[Ventas] WITH CHECK ADD CONSTRAINT [FK__Ventas__idSesion__19DFD96B] FOREIGN KEY ([idSesion]) REFERENCES dbo.[SesionesCaja] ([idSesion]);
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
ALTER TABLE dbo.[Ventas] WITH CHECK ADD CONSTRAINT [FK__Ventas__idUsuari__71D1E811] FOREIGN KEY ([idUsuario]) REFERENCES dbo.[Usuarios] ([idUsuario]);
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
ALTER TABLE dbo.[Usuarios] WITH CHECK ADD CONSTRAINT [FK_Usuarios_Perfiles] FOREIGN KEY ([idPerfil]) REFERENCES dbo.[Perfiles] ([idPerfil]);
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.sp_Backup_Generar @rutaDestino varchar(255) AS BEGIN THROW 51203, ''Backups fisicos deshabilitados en QA. No se crean ni se sobreescriben archivos.'', 1; END;';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'
-- 3. Stored Procedures del CRUD
CREATE   PROCEDURE sp_Categorias_Listar
AS 
BEGIN
    SET NOCOUNT ON;
    SELECT idCategoria, nombreCategoria FROM Categorias ORDER BY nombreCategoria;
END
';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE sp_Clientes_CambiarEstado
    @idCliente INT,
    @activo BIT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Clientes SET activo = @activo WHERE idCliente = @idCliente;
END
';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE sp_Clientes_Insertar
    @dni VARCHAR(20),
    @nombre VARCHAR(50),
    @apellido VARCHAR(50),
    @telefono VARCHAR(30),
    @email VARCHAR(100),
    @nuevoId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Clientes (dni, nombre, apellido, telefono, email, activo)
    VALUES (@dni, @nombre, @apellido, @telefono, @email, 1);
    SET @nuevoId = SCOPE_IDENTITY();
END
';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE sp_Clientes_ListarPorEstado
    @activo BIT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT idCliente, dni, nombre, apellido, telefono, email, activo
    FROM Clientes
    WHERE activo = @activo
    ORDER BY apellido, nombre;
END
';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE sp_Clientes_Modificar
    @idCliente INT,
    @dni VARCHAR(20),
    @nombre VARCHAR(50),
    @apellido VARCHAR(50),
    @telefono VARCHAR(30),
    @email VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Clientes
    SET dni = @dni, nombre = @nombre, apellido = @apellido, telefono = @telefono, email = @email
    WHERE idCliente = @idCliente;
END
';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE sp_DetalleVentas_Insertar
    @idVenta INT,
    @idProducto INT,
    @cantidad INT,
    @precioUnitario DECIMAL(10,2),
    @subtotal DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    -- Insertar el detalle
    INSERT INTO DetalleVentas (idVenta, idProducto, cantidad, precioUnitario, subtotal)
    VALUES (@idVenta, @idProducto, @cantidad, @precioUnitario, @subtotal);

    -- Descontar stock del producto automáticamente
    UPDATE Productos 
    SET stock = stock - @cantidad 
    WHERE idProducto = @idProducto;
END
';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'
-- ==========================================================
-- PROCEDIMIENTOS ALMACENADOS (STORED PROCEDURES)
-- ==========================================================

-- SP: LISTAR PERFILES PARA EL COMBOBOX
CREATE   PROCEDURE sp_Perfiles_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT idPerfil, nombrePerfil FROM Perfiles ORDER BY nombrePerfil ASC;
END
';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE sp_Productos_CambiarEstado
    @idProducto INT, 
    @activo BIT
AS 
BEGIN
    SET NOCOUNT ON;
    UPDATE Productos SET activo = @activo WHERE idProducto = @idProducto;
END
';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE sp_Productos_Insertar
    @idCategoria INT, 
    @nombre VARCHAR(100), 
    @descripcion VARCHAR(255),
    @precio DECIMAL(10,2), 
    @stock INT, 
    @nuevoId INT OUTPUT
AS 
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Productos (idCategoria, nombre, descripcion, precio, stock, activo)
    VALUES (@idCategoria, @nombre, @descripcion, @precio, @stock, 1);
    
    SET @nuevoId = SCOPE_IDENTITY();
END
';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE sp_Productos_ListarPorEstado
    @activo BIT
AS 
BEGIN
    SET NOCOUNT ON;
    SELECT p.idProducto, p.idCategoria, c.nombreCategoria, p.nombre, p.descripcion, p.precio, p.stock, p.activo
    FROM Productos p
    INNER JOIN Categorias c ON p.idCategoria = c.idCategoria
    WHERE p.activo = @activo
    ORDER BY p.nombre ASC;
END
';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE sp_Productos_Modificar
    @idProducto INT, 
    @idCategoria INT, 
    @nombre VARCHAR(100), 
    @descripcion VARCHAR(255),
    @precio DECIMAL(10,2), 
    @stock INT
AS 
BEGIN
    SET NOCOUNT ON;
    UPDATE Productos
    SET idCategoria = @idCategoria, 
        nombre = @nombre, 
        descripcion = @descripcion,
        precio = @precio, 
        stock = @stock
    WHERE idProducto = @idProducto;
END
';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'
-- Reporte 2: Productos con Bajo Stock (Para Admin y Gerente)
CREATE   PROCEDURE sp_Reporte_BajoStock
AS
BEGIN
    SET NOCOUNT ON;
    SELECT c.nombreCategoria AS [Categoría], p.nombre AS [Producto], 
           p.stock AS [Stock Actual], p.precio AS [Precio Unitario]
    FROM Productos p
    INNER JOIN Categorias c ON p.idCategoria = c.idCategoria
    WHERE p.stock <= 5 AND p.activo = 1
    ORDER BY p.stock ASC;
END
';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'
-- Reporte 1: Historial de Ventas (Para Admin y Gerente)
CREATE   PROCEDURE sp_Reporte_HistorialVentas
AS
BEGIN
    SET NOCOUNT ON;
    SELECT v.idVenta AS [Nro Factura], v.fecha AS [Fecha], 
           c.nombre + '' '' + c.apellido AS [Cliente], 
           u.nombre AS [Vendedor], v.total AS [Total ($)]
    FROM Ventas v
    INNER JOIN Clientes c ON v.idCliente = c.idCliente
    INNER JOIN Usuarios u ON v.idUsuario = u.idUsuario
    ORDER BY v.fecha DESC;
END
';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'
-- Reporte 3: Mis Ventas (Exclusivo para el Vendedor)
CREATE   PROCEDURE sp_Reporte_MisVentas
    @idUsuario INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT v.fecha AS [Fecha], c.nombre + '' '' + c.apellido AS [Cliente], v.total AS [Total ($)]
    FROM Ventas v
    INNER JOIN Clientes c ON v.idCliente = c.idCliente
    WHERE v.idUsuario = @idUsuario
    ORDER BY v.fecha DESC;
END
';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'
-- SP: BAJA LÓGICA Y REACTIVACIÓN DE USUARIOS
CREATE   PROCEDURE sp_Usuarios_CambiarEstado
    @idUsuario INT,
    @activo BIT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        UPDATE Usuarios
        SET activo = @activo
        WHERE idUsuario = @idUsuario;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'
-- 3. Actualizar SP Insertar
CREATE   PROCEDURE sp_Usuarios_Insertar
    @idPerfil INT, @nombre VARCHAR(50), @apellido VARCHAR(50), @usuario VARCHAR(50),
    @contrasena VARCHAR(100), @email VARCHAR(100), @dni VARCHAR(20), 
    @calle VARCHAR(100), @altura VARCHAR(20), @telefono VARCHAR(30), 
    @fechaNacimiento DATE, @sexo CHAR(1), @nuevoId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF EXISTS (SELECT 1 FROM Usuarios WHERE usuario = @usuario)
            BEGIN RAISERROR(''El usuario ya está registrado.'', 16, 1); RETURN; END
        IF EXISTS (SELECT 1 FROM Usuarios WHERE dni = @dni)
            BEGIN RAISERROR(''El DNI ya pertenece a otro usuario.'', 16, 1); RETURN; END

        INSERT INTO Usuarios (idPerfil, nombre, apellido, usuario, contrasena, email, dni, calle, altura, telefono, fechaNacimiento, sexo, activo)
        VALUES (@idPerfil, @nombre, @apellido, @usuario, @contrasena, @email, @dni, @calle, @altura, @telefono, @fechaNacimiento, @sexo, 1);

        SET @nuevoId = SCOPE_IDENTITY();
    END TRY
    BEGIN CATCH THROW; END CATCH
END
';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'
-- 2. Actualizar SP Listar
CREATE   PROCEDURE sp_Usuarios_ListarPorEstado
    @activo BIT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        u.idUsuario, u.idPerfil, p.nombrePerfil, u.nombre, u.apellido, 
        u.usuario, u.contrasena, u.email, u.dni, u.calle, u.altura, 
        u.telefono, u.fechaNacimiento, u.sexo, u.activo
    FROM Usuarios u
    INNER JOIN Perfiles p ON u.idPerfil = p.idPerfil
    WHERE u.activo = @activo
    ORDER BY u.apellido ASC, u.nombre ASC;
END
';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE sp_Usuarios_Login
    @usuario VARCHAR(50),
    @contrasena VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT u.idUsuario, u.idPerfil, p.nombrePerfil, u.nombre, u.apellido
    FROM Usuarios u
    INNER JOIN Perfiles p ON u.idPerfil = p.idPerfil
    WHERE u.usuario COLLATE Latin1_General_CS_AS = @usuario 
      AND u.contrasena COLLATE Latin1_General_CS_AS = @contrasena 
      AND u.activo = 1;
END
';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'
-- 4. Actualizar SP Modificar
CREATE   PROCEDURE sp_Usuarios_Modificar
    @idUsuario INT, @idPerfil INT, @nombre VARCHAR(50), @apellido VARCHAR(50), @usuario VARCHAR(50),
    @contrasena VARCHAR(100), @email VARCHAR(100), @dni VARCHAR(20), 
    @calle VARCHAR(100), @altura VARCHAR(20), @telefono VARCHAR(30), 
    @fechaNacimiento DATE, @sexo CHAR(1)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF EXISTS (SELECT 1 FROM Usuarios WHERE usuario = @usuario AND idUsuario <> @idUsuario)
            BEGIN RAISERROR(''El usuario ya está en uso.'', 16, 1); RETURN; END
        IF EXISTS (SELECT 1 FROM Usuarios WHERE dni = @dni AND idUsuario <> @idUsuario)
            BEGIN RAISERROR(''El DNI ya pertenece a otro.'', 16, 1); RETURN; END

        UPDATE Usuarios
        SET idPerfil = @idPerfil, nombre = @nombre, apellido = @apellido, usuario = @usuario, contrasena = @contrasena, 
            email = @email, dni = @dni, calle = @calle, altura = @altura, telefono = @telefono, fechaNacimiento = @fechaNacimiento, sexo = @sexo
        WHERE idUsuario = @idUsuario;
    END TRY
    BEGIN CATCH THROW; END CATCH
END
';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'
-- 3. Stored Procedure para registrar la venta de forma atómica y descontar stock
CREATE   PROCEDURE sp_Ventas_Registrar
    @idCliente INT,
    @idUsuario INT,
    @total DECIMAL(10,2),
    @nuevaVentaId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Ventas (idCliente, idUsuario, fecha, total)
    VALUES (@idCliente, @idUsuario, GETDATE(), @total);
    
    SET @nuevaVentaId = SCOPE_IDENTITY();
END
';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_addextendedproperty @name=N'ForzaQaEnvironment',@value=N'Forza-QA-Aislada-v1';
COMMIT TRANSACTION;
GO
