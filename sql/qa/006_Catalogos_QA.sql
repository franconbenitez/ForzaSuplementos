:on error exit
-- NO EJECUTADA. Requiere estructura 005, sin activar contrasenas.
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
 THROW 51200,'Destino rechazado: solo QA verificada.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1') THROW 51201,'Falta marca QA.',1;
IF COL_LENGTH('dbo.Perfiles','activo') IS NULL THROW 51600,'Requiere estructura 005.',1;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;
SET XACT_ABORT ON;
IF @@TRANCOUNT<>0 THROW 51950,'Ejecutar migracion sin transaccion externa.',1;
BEGIN TRANSACTION;
IF OBJECT_ID('dbo.Proveedores','U') IS NULL CREATE TABLE dbo.Proveedores(idProveedor int IDENTITY CONSTRAINT PK_Proveedores PRIMARY KEY,nombre nvarchar(100) NOT NULL,razonSocial nvarchar(150) NOT NULL,cuit varchar(11) NULL,activo bit NOT NULL CONSTRAINT DF_Proveedores_Activo DEFAULT(1),CONSTRAINT CK_Proveedores_Nombre CHECK(LEN(LTRIM(RTRIM(nombre)))>0 AND LEN(LTRIM(RTRIM(razonSocial)))>0),CONSTRAINT CK_Proveedores_Cuit CHECK(cuit IS NULL OR (LEN(cuit)=11 AND cuit NOT LIKE '%[^0-9]%')));
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.Proveedores') AND name='UX_Proveedores_Cuit') CREATE UNIQUE INDEX UX_Proveedores_Cuit ON dbo.Proveedores(cuit) WHERE cuit IS NOT NULL;
IF OBJECT_ID('dbo.Marcas','U') IS NULL CREATE TABLE dbo.Marcas(idMarca int IDENTITY CONSTRAINT PK_Marcas PRIMARY KEY,nombre nvarchar(100) NOT NULL CONSTRAINT UQ_Marcas_Nombre UNIQUE,activo bit NOT NULL CONSTRAINT DF_Marcas_Activo DEFAULT(1),CONSTRAINT CK_Marcas_Nombre CHECK(LEN(LTRIM(RTRIM(nombre)))>0));
IF COL_LENGTH('dbo.Productos','idMarca') IS NULL ALTER TABLE dbo.Productos ADD idMarca int NULL CONSTRAINT FK_Productos_Marca REFERENCES dbo.Marcas(idMarca);
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.Productos') AND name='IX_Productos_Marca') CREATE INDEX IX_Productos_Marca ON dbo.Productos(idMarca);
-- La transaccion continua hasta desplegar todos los contratos.
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
 THROW 51200,'Destino rechazado: solo QA verificada.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1') THROW 51201,'Falta marca QA.',1;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.sp_Comercial_Estado @modulo varchar(30)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
SELECT CONVERT(bit,CASE
WHEN @modulo=''Catalogos'' AND OBJECT_ID(''dbo.sp_Proveedores_Guardar'',''P'') IS NOT NULL AND OBJECT_ID(''dbo.sp_Marcas_Guardar'',''P'') IS NOT NULL THEN 1
WHEN @modulo=''Compras'' AND OBJECT_ID(''dbo.sp_Compras_Registrar'',''P'') IS NOT NULL THEN 1
WHEN @modulo=''Inventario'' AND OBJECT_ID(''dbo.sp_Inventario_Ajustar'',''P'') IS NOT NULL THEN 1 ELSE 0 END) disponible;
END;';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
 THROW 51200,'Destino rechazado: solo QA verificada.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1') THROW 51201,'Falta marca QA.',1;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.sp_Proveedores_Buscar @idActor int,@filtro nvarchar(100)=N''''
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u JOIN dbo.Perfiles p ON p.idPerfil=u.idPerfil WHERE u.idUsuario=@idActor AND u.activo=1 AND p.activo=1 AND UPPER(p.nombrePerfil)=''GERENTE'') THROW 51603,''Solo gerente activo.'',1;
SELECT TOP(500) idProveedor Id,nombre Nombre,razonSocial RazonSocial,cuit Cuit,activo Activo FROM dbo.Proveedores WHERE @filtro=N'''' OR CHARINDEX(@filtro,nombre)>0 OR CHARINDEX(@filtro,razonSocial)>0 OR CHARINDEX(@filtro,ISNULL(cuit,''''))>0 ORDER BY nombre,idProveedor;
END;';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
 THROW 51200,'Destino rechazado: solo QA verificada.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1') THROW 51201,'Falta marca QA.',1;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.sp_Proveedores_Guardar @idActor int,@id int,@nombre nvarchar(100),@razonSocial nvarchar(150),@cuit varchar(11)=NULL,@activo bit=1
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u JOIN dbo.Perfiles p ON p.idPerfil=u.idPerfil WHERE u.idUsuario=@idActor AND u.activo=1 AND p.activo=1 AND UPPER(p.nombrePerfil)=''GERENTE'') THROW 51603,''Solo gerente activo.'',1;

IF @id<0 OR LEN(LTRIM(RTRIM(@nombre)))=0 THROW 51601,''Nombre o ID invalido.'',1;
BEGIN TRY
 BEGIN TRANSACTION;
 IF @id=0 INSERT dbo.Proveedores(nombre,activo,razonSocial,cuit) VALUES(@nombre,@activo,@razonSocial,NULLIF(@cuit,''''));
 ELSE BEGIN
  UPDATE dbo.Proveedores SET nombre=@nombre,activo=@activo,razonSocial=@razonSocial,cuit=@cuit WHERE idProveedor=@id;
  IF @@ROWCOUNT=0 THROW 51602,''Registro inexistente.'',1;
 END;
 COMMIT;
END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH;

END;';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
 THROW 51200,'Destino rechazado: solo QA verificada.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1') THROW 51201,'Falta marca QA.',1;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.sp_Marcas_Buscar @idActor int,@filtro nvarchar(100)=N''''
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u JOIN dbo.Perfiles p ON p.idPerfil=u.idPerfil WHERE u.idUsuario=@idActor AND u.activo=1 AND p.activo=1 AND UPPER(p.nombrePerfil)=''GERENTE'') THROW 51603,''Solo gerente activo.'',1;
SELECT TOP(500) idMarca Id,nombre Nombre,activo Activo FROM dbo.Marcas WHERE @filtro=N'''' OR CHARINDEX(@filtro,nombre)>0 ORDER BY nombre,idMarca;
END;';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
 THROW 51200,'Destino rechazado: solo QA verificada.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1') THROW 51201,'Falta marca QA.',1;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.sp_Marcas_Guardar @idActor int,@id int,@nombre nvarchar(100),@activo bit=1
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u JOIN dbo.Perfiles p ON p.idPerfil=u.idPerfil WHERE u.idUsuario=@idActor AND u.activo=1 AND p.activo=1 AND UPPER(p.nombrePerfil)=''GERENTE'') THROW 51603,''Solo gerente activo.'',1;

IF @id<0 OR LEN(LTRIM(RTRIM(@nombre)))=0 THROW 51601,''Nombre o ID invalido.'',1;
BEGIN TRY
 BEGIN TRANSACTION;
 IF @id=0 INSERT dbo.Marcas(nombre,activo) VALUES(@nombre,@activo);
 ELSE BEGIN
  UPDATE dbo.Marcas SET nombre=@nombre,activo=@activo WHERE idMarca=@id;
  IF @@ROWCOUNT=0 THROW 51602,''Registro inexistente.'',1;
 END;
 COMMIT;
END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH;

END;';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
 THROW 51200,'Destino rechazado: solo QA verificada.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1') THROW 51201,'Falta marca QA.',1;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.sp_Marcas_AsociarProducto @idActor int,@idProducto int,@idMarca int
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u JOIN dbo.Perfiles p ON p.idPerfil=u.idPerfil WHERE u.idUsuario=@idActor AND u.activo=1 AND p.activo=1 AND UPPER(p.nombrePerfil)=''GERENTE'') THROW 51603,''Solo gerente activo.'',1;

BEGIN TRY
 BEGIN TRANSACTION;
 IF NOT EXISTS(SELECT 1 FROM dbo.Marcas WITH(HOLDLOCK) WHERE idMarca=@idMarca AND activo=1) THROW 51604,''Marca inactiva o inexistente.'',1;
 UPDATE dbo.Productos SET idMarca=@idMarca WHERE idProducto=@idProducto AND activo=1;
 IF @@ROWCOUNT=0 THROW 51605,''Producto inactivo o inexistente.'',1;
 COMMIT;
END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH;

END;';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
 THROW 51200,'Destino rechazado: solo QA verificada.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1') THROW 51201,'Falta marca QA.',1;
IF @@TRANCOUNT<>1 THROW 51951,'Transaccion de migracion inesperada: detener.',1;
COMMIT TRANSACTION;
GO
