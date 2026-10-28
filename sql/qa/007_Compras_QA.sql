:on error exit
-- NO EJECUTADA. Requiere 006. No registra compras al desplegar.
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
 THROW 51200,'Destino rechazado: solo QA verificada.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1') THROW 51201,'Falta marca QA.',1;

IF OBJECT_ID('dbo.Proveedores','U') IS NULL THROW 51700,'Requiere 006.',1;
BEGIN TRANSACTION;
IF OBJECT_ID('dbo.Compras','U') IS NULL CREATE TABLE dbo.Compras(idCompra int IDENTITY CONSTRAINT PK_Compras PRIMARY KEY,idProveedor int NOT NULL CONSTRAINT FK_Compras_Proveedor REFERENCES dbo.Proveedores(idProveedor),idUsuario int NOT NULL CONSTRAINT FK_Compras_Usuario REFERENCES dbo.Usuarios(idUsuario),fecha datetime2 NOT NULL CONSTRAINT DF_Compras_Fecha DEFAULT(SYSDATETIME()),total decimal(18,2) NOT NULL CONSTRAINT CK_Compras_Total CHECK(total>0),operacion uniqueidentifier NOT NULL CONSTRAINT UQ_Compras_Operacion UNIQUE,huella varbinary(32) NOT NULL);
IF OBJECT_ID('dbo.DetalleCompras','U') IS NULL CREATE TABLE dbo.DetalleCompras(idDetalleCompra int IDENTITY CONSTRAINT PK_DetalleCompras PRIMARY KEY,idCompra int NOT NULL CONSTRAINT FK_DetalleCompras_Compra REFERENCES dbo.Compras(idCompra),idProducto int NOT NULL CONSTRAINT FK_DetalleCompras_Producto REFERENCES dbo.Productos(idProducto),cantidad int NOT NULL CONSTRAINT CK_DetalleCompras_Cantidad CHECK(cantidad>0),costoUnitario decimal(18,2) NOT NULL CONSTRAINT CK_DetalleCompras_Costo CHECK(costoUnitario>0),subtotal decimal(18,2) NOT NULL CONSTRAINT CK_DetalleCompras_Subtotal CHECK(subtotal=cantidad*costoUnitario),CONSTRAINT UQ_DetalleCompras_Producto UNIQUE(idCompra,idProducto));
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.Compras') AND name='IX_Compras_FechaProveedor') CREATE INDEX IX_Compras_FechaProveedor ON dbo.Compras(fecha,idProveedor) INCLUDE(total,idUsuario);
COMMIT;
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
 THROW 51200,'Destino rechazado: solo QA verificada.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1') THROW 51201,'Falta marca QA.',1;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
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
 UPDATE p SET stock=p.stock+r.cantidad FROM dbo.Productos p JOIN @raw r ON p.idProducto=r.id;
 COMMIT;
 SELECT @id IdCompra;
END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH;

END;';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
 THROW 51200,'Destino rechazado: solo QA verificada.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1') THROW 51201,'Falta marca QA.',1;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.sp_Compras_Historial @idActor int,@desde date,@hasta date,@idProveedor int=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u JOIN dbo.Perfiles p ON p.idPerfil=u.idPerfil WHERE u.idUsuario=@idActor AND u.activo=1 AND p.activo=1 AND UPPER(p.nombrePerfil)=''GERENTE'') THROW 51603,''Solo gerente activo.'',1;

IF @desde IS NULL OR @hasta IS NULL OR @desde>@hasta OR @hasta>=''99991231'' THROW 51706,''Fechas invalidas.'',1;
SELECT TOP(2000) c.idCompra IdCompra,c.fecha Fecha,p.nombre Proveedor,c.idProveedor IdProveedor,c.idUsuario IdUsuario,c.total Total,c.operacion Operacion FROM dbo.Compras c JOIN dbo.Proveedores p ON p.idProveedor=c.idProveedor WHERE c.fecha>=@desde AND c.fecha<DATEADD(day,1,@hasta) AND (@idProveedor IS NULL OR c.idProveedor=@idProveedor) ORDER BY c.fecha DESC,c.idCompra DESC;

END;';
GO
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
 THROW 51200,'Destino rechazado: solo QA verificada.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1') THROW 51201,'Falta marca QA.',1;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.sp_Compras_Detalle @idActor int,@idCompra int
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u JOIN dbo.Perfiles p ON p.idPerfil=u.idPerfil WHERE u.idUsuario=@idActor AND u.activo=1 AND p.activo=1 AND UPPER(p.nombrePerfil)=''GERENTE'') THROW 51603,''Solo gerente activo.'',1;
SELECT d.idProducto IdProducto,p.nombre Nombre,d.cantidad Cantidad,d.costoUnitario CostoUnitario,d.subtotal Subtotal FROM dbo.DetalleCompras d JOIN dbo.Productos p ON p.idProducto=d.idProducto WHERE idCompra=@idCompra ORDER BY d.idDetalleCompra;
END;';
GO
