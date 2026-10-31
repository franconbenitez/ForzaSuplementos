:on error exit
-- PROPUESTA NO EJECUTADA. Desplegar y activar son decisiones separadas.
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
 THROW 51200,'Destino rechazado: solo QA verificada.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1')
 THROW 51201,'Falta marca QA.',1;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;
SET XACT_ABORT ON;
IF @@TRANCOUNT<>0 THROW 51950,'Ejecutar migracion sin transaccion externa.',1;
BEGIN TRANSACTION;
IF COL_LENGTH('dbo.Perfiles','activo') IS NULL ALTER TABLE dbo.Perfiles ADD activo bit NOT NULL CONSTRAINT DF_Perfiles_Activo DEFAULT(1);
IF OBJECT_ID('dbo.SeguridadEstado','U') IS NULL CREATE TABLE dbo.SeguridadEstado(id int NOT NULL CONSTRAINT PK_SeguridadEstado PRIMARY KEY,activa bit NOT NULL,CONSTRAINT CK_SeguridadEstado_Id CHECK(id=1));
IF NOT EXISTS(SELECT 1 FROM dbo.SeguridadEstado WHERE id=1) INSERT dbo.SeguridadEstado VALUES(1,0);
IF OBJECT_ID('dbo.CredencialesUsuario','U') IS NULL CREATE TABLE dbo.CredencialesUsuario(idUsuario int NOT NULL CONSTRAINT PK_CredencialesUsuario PRIMARY KEY CONSTRAINT FK_Credenciales_Usuario REFERENCES dbo.Usuarios(idUsuario),formato varchar(256) NOT NULL,fechaCambio datetime2 NOT NULL CONSTRAINT DF_Credenciales_Fecha DEFAULT(SYSUTCDATETIME()),CONSTRAINT CK_Credenciales_Formato CHECK(formato LIKE 'PBKDF2-SHA256$1$600000$%'));
-- La transaccion continua hasta desplegar todos los contratos.
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
 THROW 51200,'Destino rechazado: solo QA verificada.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1')
 THROW 51201,'Falta marca QA.',1;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.sp_Seguridad_Estado 
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
IF NOT EXISTS(SELECT 1 FROM dbo.SeguridadEstado WHERE id=1) THROW 51512,''Falta estado de seguridad; detener.'',1;
SELECT activa FROM dbo.SeguridadEstado WHERE id=1;
END;';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
 THROW 51200,'Destino rechazado: solo QA verificada.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1')
 THROW 51201,'Falta marca QA.',1;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.sp_Seguridad_Credencial @usuario varchar(50)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
IF NOT EXISTS(SELECT 1 FROM dbo.SeguridadEstado WHERE id=1 AND activa=1) THROW 51501,''Seguridad pendiente de activacion.'',1;
SELECT u.idUsuario,u.idPerfil,p.nombrePerfil,u.nombre,u.apellido,c.formato
FROM dbo.Usuarios u JOIN dbo.Perfiles p ON p.idPerfil=u.idPerfil JOIN dbo.CredencialesUsuario c ON c.idUsuario=u.idUsuario
WHERE u.usuario=@usuario AND u.activo=1 AND p.activo=1;

END;';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
 THROW 51200,'Destino rechazado: solo QA verificada.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1')
 THROW 51201,'Falta marca QA.',1;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.sp_Seguridad_Cambiar @idActor int,@idDestino int,@nuevo varchar(256),@anterior varchar(256)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
IF NOT EXISTS(SELECT 1 FROM dbo.SeguridadEstado WHERE id=1 AND activa=1) THROW 51501,''Seguridad pendiente de activacion.'',1;
IF @nuevo IS NULL OR LEN(@nuevo)<>92 OR LEFT(@nuevo,23) COLLATE Latin1_General_100_BIN2<>''PBKDF2-SHA256$1$600000$'' OR SUBSTRING(@nuevo,48,1)<>''$'' OR SUBSTRING(@nuevo,46,2)<>''=='' OR RIGHT(@nuevo,1)<>''='' OR SUBSTRING(@nuevo,24,22) COLLATE Latin1_General_100_BIN2 LIKE ''%[^A-Za-z0-9+/]%'' OR SUBSTRING(@nuevo,49,43) COLLATE Latin1_General_100_BIN2 LIKE ''%[^A-Za-z0-9+/]%'' THROW 51502,''Formato no admitido.'',1;
BEGIN TRY
 BEGIN TRANSACTION;
 IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u WITH(UPDLOCK,HOLDLOCK) JOIN dbo.Perfiles p ON p.idPerfil=u.idPerfil WHERE u.idUsuario=@idActor AND u.activo=1 AND p.activo=1) THROW 51503,''Actor no activo.'',1;
 IF @idActor<>@idDestino OR @anterior IS NULL
 BEGIN
 IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u JOIN dbo.Perfiles p ON p.idPerfil=u.idPerfil WHERE u.idUsuario=@idActor AND u.activo=1 AND p.activo=1 AND UPPER(p.nombrePerfil)=''ADMINISTRADOR'') THROW 51503,''Solo administrador activo.'',1;
 END
 ELSE IF NOT EXISTS(SELECT 1 FROM dbo.CredencialesUsuario WITH(UPDLOCK,HOLDLOCK) WHERE idUsuario=@idDestino AND formato COLLATE Latin1_General_100_BIN2=@anterior COLLATE Latin1_General_100_BIN2) THROW 51504,''La credencial cambio; repetir autenticacion.'',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios WHERE idUsuario=@idDestino) THROW 51505,''Usuario inexistente.'',1;
 UPDATE dbo.CredencialesUsuario SET formato=@nuevo,fechaCambio=SYSUTCDATETIME() WHERE idUsuario=@idDestino;
 IF @@ROWCOUNT=0 INSERT dbo.CredencialesUsuario(idUsuario,formato) VALUES(@idDestino,@nuevo);
 COMMIT;
END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH;

END;';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
 THROW 51200,'Destino rechazado: solo QA verificada.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1')
 THROW 51201,'Falta marca QA.',1;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.sp_Seguridad_UsuarioGuardar @idActor int,@idUsuario int,@idPerfil int,@nombre varchar(50),@apellido varchar(50),@usuario varchar(50),@email varchar(100),@dni varchar(20),@calle varchar(100),@altura varchar(20),@telefono varchar(30),@fechaNacimiento date,@sexo char(1),@formato varchar(256)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
IF NOT EXISTS(SELECT 1 FROM dbo.SeguridadEstado WHERE id=1 AND activa=1) THROW 51501,''Seguridad pendiente de activacion.'',1;
BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @bloqueoAdmin int;
 EXEC @bloqueoAdmin=sys.sp_getapplock @Resource=''Forza.Administradores'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
 IF @bloqueoAdmin<0 THROW 51514,''Administracion ocupada; reintentar.'',1;

 IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u JOIN dbo.Perfiles p ON p.idPerfil=u.idPerfil WHERE u.idUsuario=@idActor AND u.activo=1 AND p.activo=1 AND UPPER(p.nombrePerfil)=''ADMINISTRADOR'') THROW 51503,''Solo administrador activo.'',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Perfiles WHERE idPerfil=@idPerfil AND activo=1) THROW 51506,''Perfil inactivo.'',1;
 IF @formato IS NOT NULL AND (@formato IS NULL OR LEN(@formato)<>92 OR LEFT(@formato,23) COLLATE Latin1_General_100_BIN2<>''PBKDF2-SHA256$1$600000$'' OR SUBSTRING(@formato,48,1)<>''$'' OR SUBSTRING(@formato,46,2)<>''=='' OR RIGHT(@formato,1)<>''='' OR SUBSTRING(@formato,24,22) COLLATE Latin1_General_100_BIN2 LIKE ''%[^A-Za-z0-9+/]%'' OR SUBSTRING(@formato,49,43) COLLATE Latin1_General_100_BIN2 LIKE ''%[^A-Za-z0-9+/]%'') THROW 51502,''Formato no admitido.'',1;
 IF @idUsuario<>0 AND EXISTS(SELECT 1 FROM dbo.Usuarios u JOIN dbo.Perfiles p ON p.idPerfil=u.idPerfil WHERE u.idUsuario=@idUsuario AND u.activo=1 AND p.activo=1 AND UPPER(p.nombrePerfil)=''ADMINISTRADOR'')
 AND NOT EXISTS(SELECT 1 FROM dbo.Perfiles WHERE idPerfil=@idPerfil AND activo=1 AND UPPER(nombrePerfil)=''ADMINISTRADOR'')
 AND NOT EXISTS(SELECT 1 FROM dbo.Usuarios u JOIN dbo.Perfiles p ON p.idPerfil=u.idPerfil WHERE u.idUsuario<>@idUsuario AND u.activo=1 AND p.activo=1 AND UPPER(p.nombrePerfil)=''ADMINISTRADOR'') THROW 51511,''No se puede quitar el ultimo administrador activo.'',1;
 IF @idUsuario=0
 BEGIN
  IF @formato IS NULL THROW 51502,''Nueva cuenta requiere credencial.'',1;
  INSERT dbo.Usuarios(idPerfil,nombre,apellido,usuario,contrasena,email,dni,calle,altura,telefono,fechaNacimiento,sexo,activo)
  VALUES(@idPerfil,@nombre,@apellido,@usuario,CONVERT(varchar(36),NEWID()),@email,@dni,@calle,@altura,@telefono,@fechaNacimiento,@sexo,1);
  SET @idUsuario=CONVERT(int,SCOPE_IDENTITY());
 END
 ELSE BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios WITH(UPDLOCK,HOLDLOCK) WHERE idUsuario=@idUsuario) THROW 51505,''Usuario inexistente.'',1;
  UPDATE dbo.Usuarios SET idPerfil=@idPerfil,nombre=@nombre,apellido=@apellido,usuario=@usuario,email=@email,dni=@dni,calle=@calle,altura=@altura,telefono=@telefono,fechaNacimiento=@fechaNacimiento,sexo=@sexo WHERE idUsuario=@idUsuario;
 END;
 IF @formato IS NOT NULL BEGIN
  UPDATE dbo.CredencialesUsuario SET formato=@formato,fechaCambio=SYSUTCDATETIME() WHERE idUsuario=@idUsuario;
  IF @@ROWCOUNT=0 INSERT dbo.CredencialesUsuario(idUsuario,formato) VALUES(@idUsuario,@formato);
 END;
 COMMIT;
END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH;

END;';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
 THROW 51200,'Destino rechazado: solo QA verificada.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1')
 THROW 51201,'Falta marca QA.',1;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.sp_Seguridad_Provisionar @idUsuario int,@formato varchar(256)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;

IF ISNULL(IS_MEMBER(''db_owner''),0)<>1 AND ISNULL(IS_SRVROLEMEMBER(''sysadmin''),0)<>1 THROW 51507,''Provision solo por operador SQL autorizado.'',1;
IF EXISTS(SELECT 1 FROM dbo.SeguridadEstado WHERE activa=1) THROW 51508,''Tras activar usar restablecimiento autenticado.'',1;
IF @formato IS NULL OR LEN(@formato)<>92 OR LEFT(@formato,23) COLLATE Latin1_General_100_BIN2<>''PBKDF2-SHA256$1$600000$'' OR SUBSTRING(@formato,48,1)<>''$'' OR SUBSTRING(@formato,46,2)<>''=='' OR RIGHT(@formato,1)<>''='' OR SUBSTRING(@formato,24,22) COLLATE Latin1_General_100_BIN2 LIKE ''%[^A-Za-z0-9+/]%'' OR SUBSTRING(@formato,49,43) COLLATE Latin1_General_100_BIN2 LIKE ''%[^A-Za-z0-9+/]%'' THROW 51502,''Formato invalido.'',1;
IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios WHERE idUsuario=@idUsuario) THROW 51505,''Usuario inexistente.'',1;
BEGIN TRY
BEGIN TRANSACTION;
IF NOT EXISTS(SELECT 1 FROM dbo.SeguridadEstado WITH(UPDLOCK,HOLDLOCK) WHERE id=1 AND activa=0) THROW 51508,''No provisionar despues del corte.'',1;
UPDATE dbo.CredencialesUsuario WITH(UPDLOCK,HOLDLOCK) SET formato=@formato,fechaCambio=SYSUTCDATETIME() WHERE idUsuario=@idUsuario;
IF @@ROWCOUNT=0 INSERT dbo.CredencialesUsuario(idUsuario,formato) VALUES(@idUsuario,@formato);
COMMIT;
END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH;

END;';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
 THROW 51200,'Destino rechazado: solo QA verificada.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1')
 THROW 51201,'Falta marca QA.',1;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.sp_Seguridad_Activar @confirmacion varchar(50)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;

IF ISNULL(IS_MEMBER(''db_owner''),0)<>1 AND ISNULL(IS_SRVROLEMEMBER(''sysadmin''),0)<>1 THROW 51507,''Activacion por operador SQL autorizado.'',1;
IF @confirmacion IS NULL OR @confirmacion<>''ACTIVAR_SIN_RETORNO_A_TEXTO_PLANO'' THROW 51508,''Falta confirmacion de corte.'',1;
BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @modo bit;
 SELECT @modo=activa FROM dbo.SeguridadEstado WITH(UPDLOCK,HOLDLOCK) WHERE id=1;
 IF @modo IS NULL OR @modo=1 THROW 51508,''Estado inexistente o seguridad ya activa.'',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u JOIN dbo.Perfiles p ON p.idPerfil=u.idPerfil JOIN dbo.CredencialesUsuario c ON c.idUsuario=u.idUsuario WHERE u.activo=1 AND p.activo=1 AND UPPER(p.nombrePerfil)=''ADMINISTRADOR'') THROW 51511,''Provisionar al menos un administrador activo antes del corte.'',1;
 IF EXISTS(SELECT 1 FROM dbo.CredencialesUsuario c WHERE c.formato IS NULL OR LEN(c.formato)<>92 OR LEFT(c.formato,23) COLLATE Latin1_General_100_BIN2<>''PBKDF2-SHA256$1$600000$'' OR SUBSTRING(c.formato,48,1)<>''$'' OR SUBSTRING(c.formato,46,2)<>''=='' OR RIGHT(c.formato,1)<>''='' OR SUBSTRING(c.formato,24,22) COLLATE Latin1_General_100_BIN2 LIKE ''%[^A-Za-z0-9+/]%'' OR SUBSTRING(c.formato,49,43) COLLATE Latin1_General_100_BIN2 LIKE ''%[^A-Za-z0-9+/]%'' ) THROW 51502,''Credencial malformada; no activar.'',1;
 IF EXISTS(SELECT 1 FROM dbo.Usuarios u WITH(UPDLOCK,HOLDLOCK) JOIN dbo.Perfiles p ON p.idPerfil=u.idPerfil WHERE u.activo=1 AND p.activo=1 AND NOT EXISTS(SELECT 1 FROM dbo.CredencialesUsuario c WHERE c.idUsuario=u.idUsuario)) THROW 51509,''Provisionar primero todas las cuentas activas.'',1;
 UPDATE dbo.SeguridadEstado SET activa=1 WHERE id=1;
 -- Inutiliza claves recuperables de todas las cuentas; no se intenta convertir secretos existentes.
 UPDATE dbo.Usuarios SET contrasena=CONVERT(varchar(36),NEWID());
 COMMIT;
END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH;

END;';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
 THROW 51200,'Destino rechazado: solo QA verificada.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1')
 THROW 51201,'Falta marca QA.',1;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;
EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.sp_Usuarios_Login @usuario varchar(50),@contrasena varchar(100)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;

IF EXISTS(SELECT 1 FROM dbo.SeguridadEstado WHERE activa=1) THROW 51510,''Login heredado deshabilitado.'',1;
SELECT u.idUsuario,u.idPerfil,p.nombrePerfil,u.nombre,u.apellido FROM dbo.Usuarios u JOIN dbo.Perfiles p ON p.idPerfil=u.idPerfil
WHERE u.usuario=@usuario AND u.contrasena=@contrasena AND u.activo=1 AND p.activo=1;

END;';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
 THROW 51200,'Destino rechazado: solo QA verificada.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1') THROW 51201,'Falta marca QA.',1;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.sp_Seguridad_RecuperarAdministrador @idUsuario int,@formato varchar(256),@confirmacion varchar(50)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;

IF ISNULL(IS_MEMBER(''db_owner''),0)<>1 AND ISNULL(IS_SRVROLEMEMBER(''sysadmin''),0)<>1 THROW 51507,''Solo operador SQL autorizado.'',1;
IF @confirmacion IS NULL OR @confirmacion<>''RECUPERAR_SOLO_ADMINISTRADOR'' THROW 51508,''Falta confirmacion.'',1;
IF NOT EXISTS(SELECT 1 FROM dbo.SeguridadEstado WHERE activa=1) THROW 51501,''Usar provision antes del corte.'',1;
IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u JOIN dbo.Perfiles p ON p.idPerfil=u.idPerfil WHERE u.idUsuario=@idUsuario AND u.activo=1 AND p.activo=1 AND UPPER(p.nombrePerfil)=''ADMINISTRADOR'') THROW 51503,''No es administrador activo.'',1;
IF @formato IS NULL OR LEN(@formato)<>92 OR LEFT(@formato,23) COLLATE Latin1_General_100_BIN2<>''PBKDF2-SHA256$1$600000$'' OR SUBSTRING(@formato,48,1)<>''$'' OR SUBSTRING(@formato,46,2)<>''=='' OR RIGHT(@formato,1)<>''='' OR SUBSTRING(@formato,24,22) COLLATE Latin1_General_100_BIN2 LIKE ''%[^A-Za-z0-9+/]%'' OR SUBSTRING(@formato,49,43) COLLATE Latin1_General_100_BIN2 LIKE ''%[^A-Za-z0-9+/]%'' THROW 51502,''Formato no admitido.'',1;
UPDATE dbo.CredencialesUsuario SET formato=@formato,fechaCambio=SYSUTCDATETIME() WHERE idUsuario=@idUsuario;
IF @@ROWCOUNT=0 THROW 51505,''Falta credencial de administrador.'',1;

END;';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
 THROW 51200,'Destino rechazado: solo QA verificada.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1')
 THROW 51201,'Falta marca QA.',1;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.sp_Usuarios_CambiarEstado @idUsuario int,@activo bit
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @idUsuario IS NULL OR @idUsuario<=0 OR @activo IS NULL THROW 51505,''Usuario o estado invalido.'',1;
 BEGIN TRY
  BEGIN TRANSACTION;
 DECLARE @bloqueoAdmin int;
 EXEC @bloqueoAdmin=sys.sp_getapplock @Resource=''Forza.Administradores'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
 IF @bloqueoAdmin<0 THROW 51514,''Administracion ocupada; reintentar.'',1;

  IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios WHERE idUsuario=@idUsuario) THROW 51505,''Usuario inexistente.'',1;
  IF @activo=0 AND EXISTS(SELECT 1 FROM dbo.Usuarios u JOIN dbo.Perfiles p ON p.idPerfil=u.idPerfil WHERE u.idUsuario=@idUsuario AND u.activo=1 AND p.activo=1 AND UPPER(p.nombrePerfil)=''ADMINISTRADOR'')
  AND NOT EXISTS(SELECT 1 FROM dbo.Usuarios u JOIN dbo.Perfiles p ON p.idPerfil=u.idPerfil WHERE u.idUsuario<>@idUsuario AND u.activo=1 AND p.activo=1 AND UPPER(p.nombrePerfil)=''ADMINISTRADOR'') THROW 51511,''No se puede desactivar el ultimo administrador activo.'',1;
  UPDATE dbo.Usuarios SET activo=@activo WHERE idUsuario=@idUsuario;
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
