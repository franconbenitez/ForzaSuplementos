:on error exit
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado antes de crear datos ficticios.', 1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1')
    THROW 51200, 'Falta la marca de base QA aislada.', 1;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
IF OBJECT_ID('qa.Fixtures','U') IS NOT NULL
BEGIN
    IF (SELECT COUNT(*) FROM qa.Fixtures)=1 BEGIN PRINT 'Fixtures ya existentes; no se reemplazaron.'; RETURN; END;
    THROW 51204, 'Fixtures incompletas. Inspeccionar sin borrar registros.', 1;
END;
IF EXISTS(SELECT 1 FROM dbo.Usuarios) OR EXISTS(SELECT 1 FROM dbo.Ventas)
    THROW 51204, 'La carga inicial requiere QA vacia y no reemplaza personas ni ventas.', 1;
BEGIN TRANSACTION;
IF SCHEMA_ID('qa') IS NULL EXEC(N'CREATE SCHEMA qa AUTHORIZATION dbo;');
CREATE TABLE qa.Fixtures (
    vendedor int NOT NULL,otroVendedor int NOT NULL,administrador int NOT NULL,gerente int NOT NULL,
    inactivo int NOT NULL,cliente int NOT NULL,categoria int NOT NULL,productoHistorico int NOT NULL,ventaHistorica int NOT NULL
);
DECLARE @pv int,@pa int,@pg int,@v int,@v2 int,@a int,@g int,@i int,@c int,@cat int,@p int,@h int;
INSERT dbo.Perfiles(nombrePerfil,descripcion) VALUES('VENDEDOR','Perfil ficticio QA'); SET @pv=CONVERT(int,SCOPE_IDENTITY());
INSERT dbo.Perfiles(nombrePerfil,descripcion) VALUES('ADMINISTRADOR','Perfil ficticio QA'); SET @pa=CONVERT(int,SCOPE_IDENTITY());
INSERT dbo.Perfiles(nombrePerfil,descripcion) VALUES('GERENTE','Perfil ficticio QA'); SET @pg=CONVERT(int,SCOPE_IDENTITY());
-- Claves nuevas aleatorias: no se copian del origen ni se imprimen. Para UI usar Establecer-Clave-QA.ps1.
INSERT dbo.Usuarios(idPerfil,nombre,apellido,usuario,contrasena,email,dni,telefono,fechaNacimiento,sexo,activo,calle,altura)
VALUES(@pv,'QA','VendedorUno','qa_vendedor',CONVERT(varchar(36),NEWID()),'qa-vendedor@example.invalid','00000001','0000000000','20000101','M',1,'QA','0'); SET @v=CONVERT(int,SCOPE_IDENTITY());
INSERT dbo.Usuarios(idPerfil,nombre,apellido,usuario,contrasena,email,dni,telefono,fechaNacimiento,sexo,activo,calle,altura)
VALUES(@pv,'QA','VendedorDos','qa_vendedor2',CONVERT(varchar(36),NEWID()),'qa-vendedor2@example.invalid','00000002','0000000000','20000101','F',1,'QA','0'); SET @v2=CONVERT(int,SCOPE_IDENTITY());
INSERT dbo.Usuarios(idPerfil,nombre,apellido,usuario,contrasena,email,dni,telefono,fechaNacimiento,sexo,activo,calle,altura)
VALUES(@pa,'QA','Administrador','qa_admin',CONVERT(varchar(36),NEWID()),'qa-admin@example.invalid','00000003','0000000000','20000101','M',1,'QA','0'); SET @a=CONVERT(int,SCOPE_IDENTITY());
INSERT dbo.Usuarios(idPerfil,nombre,apellido,usuario,contrasena,email,dni,telefono,fechaNacimiento,sexo,activo,calle,altura)
VALUES(@pg,'QA','Gerente','qa_gerente',CONVERT(varchar(36),NEWID()),'qa-gerente@example.invalid','00000004','0000000000','20000101','F',1,'QA','0'); SET @g=CONVERT(int,SCOPE_IDENTITY());
INSERT dbo.Usuarios(idPerfil,nombre,apellido,usuario,contrasena,email,dni,telefono,fechaNacimiento,sexo,activo,calle,altura)
VALUES(@pv,'QA','Inactivo','qa_inactivo',CONVERT(varchar(36),NEWID()),'qa-inactivo@example.invalid','00000005','0000000000','20000101','M',0,'QA','0'); SET @i=CONVERT(int,SCOPE_IDENTITY());
INSERT dbo.Clientes(dni,nombre,apellido,telefono,email,activo) VALUES('00000006','QA','Cliente','0000000000','qa-cliente@example.invalid',1); SET @c=CONVERT(int,SCOPE_IDENTITY());
INSERT dbo.Categorias(nombreCategoria) VALUES('QA Sintetica'); SET @cat=CONVERT(int,SCOPE_IDENTITY());
INSERT dbo.Productos(idCategoria,nombre,descripcion,precio,stock,activo) VALUES(@cat,'QA Historico','Producto ficticio',100,100,1); SET @p=CONVERT(int,SCOPE_IDENTITY());
INSERT dbo.Ventas(idCliente,idUsuario,fecha,total,idSesion) VALUES(@c,@v,'20250101',100,NULL); SET @h=CONVERT(int,SCOPE_IDENTITY());
INSERT dbo.DetalleVentas(idVenta,idProducto,cantidad,precioUnitario,subtotal) VALUES(@h,@p,1,100,100);
INSERT qa.Fixtures VALUES(@v,@v2,@a,@g,@i,@c,@cat,@p,@h);
COMMIT TRANSACTION;
PRINT 'Solo datos ficticios creados; historico sintetico sin sesion conservado para pruebas.';
