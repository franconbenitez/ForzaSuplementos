:on error exit
-- PREPARADO, NO EJECUTADO. Autorizacion separada para datos ficticios con rollback.
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)' THROW 51200,'Solo QA verificada.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1') THROW 51201,'Falta marca QA.',1;
IF N'$(AutorizarEnsayo)'<>N'SOLO_FIXTURES_ROLLBACK' THROW 51900,'Falta autorizacion especifica.',1;
IF @@TRANCOUNT<>0 THROW 51932,'Conexion sin transaccion previa requerida.',1;
SET IMPLICIT_TRANSACTIONS OFF; SET XACT_ABORT ON; SET NOCOUNT ON;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;
IF OBJECT_ID('dbo.sp_Marcas_AsociarProducto','P') IS NULL THROW 51900,'Requiere 006.',1;
IF (SELECT activa FROM dbo.SeguridadEstado WHERE id=1)<>0 THROW 51900,'Requiere seguridad inactiva.',1;
DECLARE @actor int,@admin int,@seller int,@categoria int;
IF (SELECT COUNT(*) FROM qa.Fixtures)<>1 THROW 51900,'Fixtures ambiguos.',1;
SELECT @actor=gerente,@admin=administrador,@seller=vendedor,@categoria=categoria FROM qa.Fixtures;
IF @actor IS NULL OR @admin IS NULL OR @seller IS NULL OR @categoria IS NULL THROW 51900,'Fixtures incompletos.',1;
IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u JOIN dbo.Perfiles p ON p.idPerfil=u.idPerfil WHERE u.idUsuario=@actor AND u.activo=1 AND p.activo=1 AND UPPER(p.nombrePerfil)='GERENTE') THROW 51900,'Gerente fixture no autorizado.',1;
DECLARE @bp bigint=(SELECT COUNT_BIG(*) FROM dbo.Productos),@bv bigint=(SELECT COUNT_BIG(*) FROM dbo.Proveedores),@bm bigint=(SELECT COUNT_BIG(*) FROM dbo.Marcas);
DECLARE @token nvarchar(100)=N'QA006 '+CONVERT(nvarchar(36),NEWID()),@proveedor int,@marca int,@producto int;
DECLARE @results TABLE(Caso int,Descripcion nvarchar(150),Estado varchar(20));
BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @v TABLE(Id int); DECLARE @m TABLE(Id int);
 INSERT @v EXEC dbo.sp_Proveedores_Guardar @actor,0,@token,N'QA Razon ficticia',NULL,1;
 SELECT @proveedor=Id FROM @v;
 IF @proveedor IS NULL OR @proveedor<=0 THROW 51940,'Proveedor sin ID confirmado.',1;
 INSERT @results VALUES(1,N'Alta proveedor devuelve ID','APROBADO');
 EXEC dbo.sp_Proveedores_Guardar @actor,@proveedor,@token,N'QA Modificado',NULL,0;
 IF (SELECT COUNT(*) FROM dbo.Proveedores WHERE nombre=@token)<>1 OR NOT EXISTS(SELECT 1 FROM dbo.Proveedores WHERE idProveedor=@proveedor AND activo=0 AND razonSocial=N'QA Modificado') THROW 51941,'Edicion o baja logica incorrecta.',1;
 INSERT @results VALUES(2,N'Modificacion y baja logica proveedor sin duplicar','APROBADO');
 EXEC dbo.sp_Proveedores_Guardar @actor,@proveedor,@token,N'QA Modificado',NULL,1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Proveedores WHERE idProveedor=@proveedor AND activo=1) THROW 51941,'Reactivacion incorrecta.',1;
 INSERT @results VALUES(3,N'Reactivacion proveedor','APROBADO');
 INSERT @m EXEC dbo.sp_Marcas_Guardar @actor,0,@token,1;
 SELECT @marca=Id FROM @m;
 IF @marca IS NULL OR @marca<=0 THROW 51940,'Marca sin ID confirmado.',1;
 INSERT @results VALUES(4,N'Alta marca devuelve ID','APROBADO');
 EXEC dbo.sp_Marcas_Guardar @actor,@marca,@token,0;
 IF NOT EXISTS(SELECT 1 FROM dbo.Marcas WHERE idMarca=@marca AND activo=0) THROW 51941,'Baja marca incorrecta.',1;
 EXEC dbo.sp_Marcas_Guardar @actor,@marca,@token,1;
 IF (SELECT COUNT(*) FROM dbo.Marcas WHERE nombre=@token)<>1 OR NOT EXISTS(SELECT 1 FROM dbo.Marcas WHERE idMarca=@marca AND activo=1) THROW 51941,'Reactivacion marca incorrecta.',1;
 INSERT @results VALUES(5,N'Modificacion baja y reactivacion marca sin duplicar','APROBADO');
 INSERT dbo.Productos(idCategoria,nombre,descripcion,precio,stock,activo) VALUES(@categoria,@token,N'QA ficticio',10,0,1);
 SET @producto=CONVERT(int,SCOPE_IDENTITY());
 EXEC dbo.sp_Marcas_AsociarProducto @actor,@producto,@marca;
 IF NOT EXISTS(SELECT 1 FROM dbo.Productos WHERE idProducto=@producto AND idMarca=@marca AND stock=0 AND precio=10) THROW 51942,'Asociacion incorrecta o cambio de precio/stock.',1;
 INSERT @results VALUES(6,N'Asociacion conserva ID precio y stock','APROBADO');
 DECLARE @buscarV TABLE(Id int,Nombre nvarchar(100),RazonSocial nvarchar(150),Cuit varchar(11),Activo bit);
 DECLARE @buscarM TABLE(Id int,Nombre nvarchar(100),Activo bit);
 INSERT @buscarV EXEC dbo.sp_Proveedores_Buscar @actor,@token;
 INSERT @buscarM EXEC dbo.sp_Marcas_Buscar @actor,@token;
 IF NOT EXISTS(SELECT 1 FROM @buscarV WHERE Id=@proveedor) OR NOT EXISTS(SELECT 1 FROM @buscarM WHERE Id=@marca) THROW 51942,'Busqueda no conserva IDs.',1;
 INSERT @results VALUES(7,N'Busquedas y contratos de columnas','APROBADO');
 ROLLBACK;
 IF @@TRANCOUNT<>0 OR (SELECT COUNT_BIG(*) FROM dbo.Productos)<>@bp OR (SELECT COUNT_BIG(*) FROM dbo.Proveedores)<>@bv OR (SELECT COUNT_BIG(*) FROM dbo.Marcas)<>@bm OR EXISTS(SELECT 1 FROM dbo.Productos WHERE nombre=@token) OR EXISTS(SELECT 1 FROM dbo.Proveedores WHERE nombre=@token) OR EXISTS(SELECT 1 FROM dbo.Marcas WHERE nombre=@token) THROW 51943,'Rollback positivo inconsistente; detener.',1;
 -- Cada rechazo tiene transaccion propia: los SP pueden revertir toda la transaccion externa.
 DECLARE @case int=8,@expected int,@observed int;
 WHILE @case<=17
 BEGIN
  SET @observed=NULL;
  SET @expected=CASE WHEN @case IN(8,9,10,11,17) THEN 51603 WHEN @case=12 THEN 51604 WHEN @case=13 THEN 51605 WHEN @case=14 THEN 2627 WHEN @case=15 THEN 51606 WHEN @case=16 THEN 51602 END;
  BEGIN TRY
   BEGIN TRANSACTION;
   IF @case=8 EXEC dbo.sp_Proveedores_Guardar @admin,0,@token,N'QA ficticio',NULL,1;
   IF @case=9 EXEC dbo.sp_Marcas_Guardar @seller,0,@token,1;
   IF @case=10 EXEC dbo.sp_Proveedores_Buscar @admin,@token;
   IF @case=11 EXEC dbo.sp_Marcas_Buscar @seller,@token;
   IF @case IN(12,13)
   BEGIN
    INSERT dbo.Marcas(nombre,activo) VALUES(@token,CASE WHEN @case=12 THEN 0 ELSE 1 END);
    SET @marca=CONVERT(int,SCOPE_IDENTITY());
    INSERT dbo.Productos(idCategoria,nombre,descripcion,precio,stock,activo) VALUES(@categoria,@token,N'QA ficticio',10,0,CASE WHEN @case=13 THEN 0 ELSE 1 END);
    SET @producto=CONVERT(int,SCOPE_IDENTITY());
    EXEC dbo.sp_Marcas_AsociarProducto @actor,@producto,@marca;
   END;
   IF @case=14
   BEGIN
    INSERT dbo.Marcas(nombre,activo) VALUES(@token,1);
    EXEC dbo.sp_Marcas_Guardar @actor,0,@token,1;
   END;
   IF @case=15 EXEC dbo.sp_Proveedores_Guardar @actor,0,@token,N'QA ficticio','INVALIDO',1;
   IF @case=16
   BEGIN
    SELECT @marca=ISNULL(MAX(idMarca),0)+1 FROM dbo.Marcas;
    EXEC dbo.sp_Marcas_Guardar @actor,@marca,@token,1;
   END;
   IF @case=17 EXEC dbo.sp_Marcas_AsociarProducto NULL,1,1;
  END TRY BEGIN CATCH
   SET @observed=ERROR_NUMBER();
  END CATCH;
  IF XACT_STATE()<>0 ROLLBACK;
  IF @observed IS NULL OR @observed<>@expected THROW 51944,'Rechazo distinto del esperado; detener.',1;
  IF @@TRANCOUNT<>0 OR (SELECT COUNT_BIG(*) FROM dbo.Productos)<>@bp OR (SELECT COUNT_BIG(*) FROM dbo.Proveedores)<>@bv OR (SELECT COUNT_BIG(*) FROM dbo.Marcas)<>@bm OR EXISTS(SELECT 1 FROM dbo.Productos WHERE nombre=@token) OR EXISTS(SELECT 1 FROM dbo.Proveedores WHERE nombre=@token) OR EXISTS(SELECT 1 FROM dbo.Marcas WHERE nombre=@token) THROW 51943,'Rollback negativo inconsistente; detener.',1;
  INSERT @results VALUES(@case,CASE @case WHEN 8 THEN N'Administrador no guarda proveedores' WHEN 9 THEN N'Vendedor no guarda marcas' WHEN 10 THEN N'Administrador no consulta proveedores' WHEN 11 THEN N'Vendedor no consulta marcas' WHEN 12 THEN N'Marca inactiva rechazada' WHEN 13 THEN N'Producto inactivo rechazado' WHEN 14 THEN N'Marca duplicada rechazada' WHEN 15 THEN N'CUIT invalido rechazado' WHEN 16 THEN N'Modificacion de ID inexistente rechazada' WHEN 17 THEN N'Actor nulo no asocia' END,'APROBADO');
  SET @case+=1;
 END;
 SELECT Caso,Descripcion,Estado FROM @results ORDER BY Caso;
 PRINT '17 casos completados y datos ficticios revertidos. Identidades pueden avanzar; no se reseedean.';
END TRY BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;
