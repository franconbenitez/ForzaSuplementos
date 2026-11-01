# Inventario real de ForzaSuplementosDB_QA

Fecha: 2026-11-01. Extracción exclusivamente de sys.* mediante conexión QA validada. No se ejecutó DDL/DML ni se exportaron filas, credenciales, rutas de backups o identificadores de equipo.

**18 tablas**: 17 tablas en dbo y 1 tabla(s) auxiliar(es). **21 claves foráneas, 33 índices, 17 restricciones CHECK y 50 procedimientos.** La tabla de fixtures no forma parte del modelo comercial.

## dbo.AuditoriaBackups

- `idBackup`: `int`, NOT NULL IDENTITY.
- `idUsuario`: `int`, NOT NULL.
- `fecha`: `datetime`, NOT NULL; DEFAULT `DF__Auditoria__fecha__4AB81AF0` (getdate()).
- `rutaArchivo`: `varchar(255)`, NOT NULL.

Índices y claves:

- `PK__Auditori__F34D6CE0C214ECFA`: CLUSTERED; PK=True, UNIQUE=True, deshabilitado=False; columnas (idBackup ASC).

## dbo.Categorias

- `idCategoria`: `int`, NOT NULL IDENTITY.
- `nombreCategoria`: `varchar(50)`, NOT NULL.

Índices y claves:

- `PK__Categori__8A3D240CC7BE2120`: CLUSTERED; PK=True, UNIQUE=True, deshabilitado=False; columnas (idCategoria ASC).

## dbo.Clientes

- `idCliente`: `int`, NOT NULL IDENTITY.
- `dni`: `varchar(20)`, NOT NULL.
- `nombre`: `varchar(50)`, NOT NULL.
- `apellido`: `varchar(50)`, NOT NULL.
- `telefono`: `varchar(30)`, NULL.
- `email`: `varchar(100)`, NULL.
- `activo`: `bit`, NOT NULL; DEFAULT `DF__Clientes__activo__4F7CD00D` ((1)).

Índices y claves:

- `PK__Clientes__885457EEB20DAE12`: CLUSTERED; PK=True, UNIQUE=True, deshabilitado=False; columnas (idCliente ASC).

## dbo.Compras

- `idCompra`: `int`, NOT NULL IDENTITY.
- `idProveedor`: `int`, NOT NULL.
- `idUsuario`: `int`, NOT NULL.
- `fecha`: `datetime2`, NOT NULL; DEFAULT `DF_Compras_Fecha` (sysdatetime()).
- `total`: `decimal(18,2)`, NOT NULL.
- `operacion`: `uniqueidentifier`, NOT NULL.
- `huella`: `varbinary(32)`, NOT NULL.

Índices y claves:

- `IX_Compras_FechaProveedor`: NONCLUSTERED; PK=False, UNIQUE=False, deshabilitado=False; columnas (fecha ASC, idProveedor ASC); INCLUDE (total, idUsuario).
- `PK_Compras`: CLUSTERED; PK=True, UNIQUE=True, deshabilitado=False; columnas (idCompra ASC).
- `UQ_Compras_Operacion`: NONCLUSTERED; PK=False, UNIQUE=True, deshabilitado=False; columnas (operacion ASC).
- CHECK `CK_Compras_Total`: `([total]>(0))`; deshabilitada=False, no confiable=False.

## dbo.CredencialesUsuario

- `idUsuario`: `int`, NOT NULL.
- `formato`: `varchar(256)`, NOT NULL.
- `fechaCambio`: `datetime2`, NOT NULL; DEFAULT `DF_Credenciales_Fecha` (sysutcdatetime()).

Índices y claves:

- `PK_CredencialesUsuario`: CLUSTERED; PK=True, UNIQUE=True, deshabilitado=False; columnas (idUsuario ASC).
- CHECK `CK_Credenciales_Formato`: `([formato] like 'PBKDF2-SHA256$1$600000$%')`; deshabilitada=False, no confiable=False.

## dbo.DetalleCompras

- `idDetalleCompra`: `int`, NOT NULL IDENTITY.
- `idCompra`: `int`, NOT NULL.
- `idProducto`: `int`, NOT NULL.
- `cantidad`: `int`, NOT NULL.
- `costoUnitario`: `decimal(18,2)`, NOT NULL.
- `subtotal`: `decimal(18,2)`, NOT NULL.

Índices y claves:

- `PK_DetalleCompras`: CLUSTERED; PK=True, UNIQUE=True, deshabilitado=False; columnas (idDetalleCompra ASC).
- `UQ_DetalleCompras_Producto`: NONCLUSTERED; PK=False, UNIQUE=True, deshabilitado=False; columnas (idCompra ASC, idProducto ASC).
- CHECK `CK_DetalleCompras_Cantidad`: `([cantidad]>(0))`; deshabilitada=False, no confiable=False.
- CHECK `CK_DetalleCompras_Costo`: `([costoUnitario]>(0))`; deshabilitada=False, no confiable=False.
- CHECK `CK_DetalleCompras_Subtotal`: `([subtotal]=CONVERT([decimal](10,0),[cantidad])*[costoUnitario])`; deshabilitada=False, no confiable=False.

## dbo.DetalleVentas

- `idDetalle`: `int`, NOT NULL IDENTITY.
- `idVenta`: `int`, NOT NULL.
- `idProducto`: `int`, NOT NULL.
- `cantidad`: `int`, NOT NULL.
- `precioUnitario`: `decimal(10,2)`, NOT NULL.
- `subtotal`: `decimal(10,2)`, NOT NULL.

Índices y claves:

- `PK__DetalleV__49CAE2FB138EB16A`: CLUSTERED; PK=True, UNIQUE=True, deshabilitado=False; columnas (idDetalle ASC).

## dbo.Marcas

- `idMarca`: `int`, NOT NULL IDENTITY.
- `nombre`: `nvarchar(100)`, NOT NULL.
- `activo`: `bit`, NOT NULL; DEFAULT `DF_Marcas_Activo` ((1)).

Índices y claves:

- `PK_Marcas`: CLUSTERED; PK=True, UNIQUE=True, deshabilitado=False; columnas (idMarca ASC).
- `UQ_Marcas_Nombre`: NONCLUSTERED; PK=False, UNIQUE=True, deshabilitado=False; columnas (nombre ASC).
- CHECK `CK_Marcas_Nombre`: `(len(ltrim(rtrim([nombre])))>(0))`; deshabilitada=False, no confiable=False.

## dbo.MovimientosStock

- `idMovimiento`: `int`, NOT NULL IDENTITY.
- `idProducto`: `int`, NOT NULL.
- `idUsuario`: `int`, NOT NULL.
- `fecha`: `datetime2`, NOT NULL; DEFAULT `DF_Movimientos_Fecha` (sysdatetime()).
- `tipo`: `varchar(10)`, NOT NULL.
- `cantidad`: `int`, NOT NULL.
- `anterior`: `int`, NOT NULL.
- `posterior`: `int`, NOT NULL.
- `motivo`: `nvarchar(250)`, NOT NULL.
- `idCompra`: `int`, NULL.
- `idVenta`: `int`, NULL.
- `operacion`: `uniqueidentifier`, NULL.

Índices y claves:

- `IX_Movimientos_FechaProducto`: NONCLUSTERED; PK=False, UNIQUE=False, deshabilitado=False; columnas (fecha ASC, idProducto ASC).
- `PK_MovimientosStock`: CLUSTERED; PK=True, UNIQUE=True, deshabilitado=False; columnas (idMovimiento ASC).
- `UX_Movimientos_Ajuste`: NONCLUSTERED; PK=False, UNIQUE=True, deshabilitado=False; columnas (operacion ASC); filtro `([operacion] IS NOT NULL)`.
- `UX_Movimientos_Compra`: NONCLUSTERED; PK=False, UNIQUE=True, deshabilitado=False; columnas (idCompra ASC, idProducto ASC); filtro `([idCompra] IS NOT NULL)`.
- `UX_Movimientos_Venta`: NONCLUSTERED; PK=False, UNIQUE=True, deshabilitado=False; columnas (idVenta ASC, idProducto ASC); filtro `([idVenta] IS NOT NULL)`.
- CHECK `CK_Movimientos_Motivo`: `(len(ltrim(rtrim([motivo])))>(0))`; deshabilitada=False, no confiable=False.
- CHECK `CK_Movimientos_Stock`: `([anterior]>=(0) AND [posterior]>=(0) AND CONVERT([bigint],[posterior])=(CONVERT([bigint],[anterior])+[cantidad]) AND [cantidad]<>(0))`; deshabilitada=False, no confiable=False.
- CHECK `CK_Movimientos_Tipo`: `([tipo]='Compra' AND [cantidad]>(0) AND [idCompra] IS NOT NULL AND [idVenta] IS NULL AND [operacion] IS NULL OR [tipo]='Venta' AND [cantidad]<(0) AND [idVenta] IS NOT NULL AND [idCompra] IS NULL AND [operacion] IS NULL OR [tipo]='Ajuste' AND [idCompra] IS NULL AND [idVenta] IS NULL AND [operacion] IS NOT NULL)`; deshabilitada=False, no confiable=False.

## dbo.PagosVenta

- `idVenta`: `int`, NOT NULL.
- `medioPago`: `varchar(20)`, NOT NULL.
- `importe`: `decimal(10,2)`, NOT NULL.

Índices y claves:

- `PK_PagosVenta`: CLUSTERED; PK=True, UNIQUE=True, deshabilitado=False; columnas (idVenta ASC).
- CHECK `CK_PagosVenta_Importe`: `([importe]>(0))`; deshabilitada=False, no confiable=False.
- CHECK `CK_PagosVenta_Medio`: `([medioPago]='Tarjeta' OR [medioPago]='Transferencia' OR [medioPago]='Efectivo')`; deshabilitada=False, no confiable=False.

## dbo.Perfiles

- `idPerfil`: `int`, NOT NULL IDENTITY.
- `nombrePerfil`: `varchar(50)`, NOT NULL.
- `descripcion`: `varchar(150)`, NULL.
- `activo`: `bit`, NOT NULL; DEFAULT `DF_Perfiles_Activo` ((1)).

Índices y claves:

- `PK_Perfiles`: CLUSTERED; PK=True, UNIQUE=True, deshabilitado=False; columnas (idPerfil ASC).
- `UQ_Perfiles_Nombre`: NONCLUSTERED; PK=False, UNIQUE=True, deshabilitado=False; columnas (nombrePerfil ASC).

## dbo.Productos

- `idProducto`: `int`, NOT NULL IDENTITY.
- `idCategoria`: `int`, NOT NULL.
- `nombre`: `varchar(100)`, NOT NULL.
- `descripcion`: `varchar(255)`, NULL.
- `precio`: `decimal(10,2)`, NOT NULL.
- `stock`: `int`, NOT NULL.
- `activo`: `bit`, NOT NULL; DEFAULT `DF__Productos__activ__571DF1D5` ((1)).
- `idMarca`: `int`, NULL.
- `stockMinimo`: `int`, NOT NULL; DEFAULT `DF_Productos_StockMinimo` ((0)).

Índices y claves:

- `IX_Productos_Marca`: NONCLUSTERED; PK=False, UNIQUE=False, deshabilitado=False; columnas (idMarca ASC).
- `PK__Producto__07F4A132E33100FE`: CLUSTERED; PK=True, UNIQUE=True, deshabilitado=False; columnas (idProducto ASC).
- CHECK `CK_Productos_StockMinimo`: `([stockMinimo]>=(0))`; deshabilitada=False, no confiable=False.
- CHECK `CK_Productos_StockNoNegativo`: `([stock]>=(0))`; deshabilitada=False, no confiable=False.

## dbo.Proveedores

- `idProveedor`: `int`, NOT NULL IDENTITY.
- `nombre`: `nvarchar(100)`, NOT NULL.
- `razonSocial`: `nvarchar(150)`, NOT NULL.
- `cuit`: `varchar(11)`, NULL.
- `activo`: `bit`, NOT NULL; DEFAULT `DF_Proveedores_Activo` ((1)).

Índices y claves:

- `PK_Proveedores`: CLUSTERED; PK=True, UNIQUE=True, deshabilitado=False; columnas (idProveedor ASC).
- `UX_Proveedores_Cuit`: NONCLUSTERED; PK=False, UNIQUE=True, deshabilitado=False; columnas (cuit ASC); filtro `([cuit] IS NOT NULL)`.
- CHECK `CK_Proveedores_Cuit`: `([cuit] IS NULL OR len([cuit])=(11) AND NOT [cuit] like '%[^0-9]%')`; deshabilitada=False, no confiable=False.
- CHECK `CK_Proveedores_Nombre`: `(len(ltrim(rtrim([nombre])))>(0) AND len(ltrim(rtrim([razonSocial])))>(0))`; deshabilitada=False, no confiable=False.

## dbo.SeguridadEstado

- `id`: `int`, NOT NULL.
- `activa`: `bit`, NOT NULL.

Índices y claves:

- `PK_SeguridadEstado`: CLUSTERED; PK=True, UNIQUE=True, deshabilitado=False; columnas (id ASC).
- CHECK `CK_SeguridadEstado_Id`: `([id]=(1))`; deshabilitada=False, no confiable=False.

## dbo.SesionesCaja

- `idSesion`: `int`, NOT NULL IDENTITY.
- `idUsuarioApertura`: `int`, NOT NULL.
- `idUsuarioCierre`: `int`, NULL.
- `fechaApertura`: `datetime`, NOT NULL; DEFAULT `DF__SesionesC__fecha__59FA5E80` (getdate()).
- `fechaCierre`: `datetime`, NULL.
- `montoInicial`: `decimal(10,2)`, NOT NULL.
- `montoFinalEsperado`: `decimal(10,2)`, NULL.
- `montoFinalReal`: `decimal(10,2)`, NULL.
- `diferencia`: `decimal(10,2)`, NULL.
- `estado`: `varchar(20)`, NOT NULL; DEFAULT `DF__SesionesC__estad__5AEE82B9` ('Abierta').

Índices y claves:

- `IX_SesionesCaja_UsuarioFecha`: NONCLUSTERED; PK=False, UNIQUE=False, deshabilitado=False; columnas (idUsuarioApertura ASC, fechaApertura ASC).
- `PK__Sesiones__DB6C2DE6E7EDBD99`: CLUSTERED; PK=True, UNIQUE=True, deshabilitado=False; columnas (idSesion ASC).
- `UX_SesionesCaja_UnicaAbierta`: NONCLUSTERED; PK=False, UNIQUE=True, deshabilitado=False; columnas (estado ASC); filtro `([estado]='Abierta')`.

## dbo.Usuarios

- `idUsuario`: `int`, NOT NULL IDENTITY.
- `idPerfil`: `int`, NOT NULL.
- `nombre`: `varchar(50)`, NOT NULL.
- `apellido`: `varchar(50)`, NOT NULL.
- `usuario`: `varchar(50)`, NOT NULL.
- `contrasena`: `varchar(100)`, NOT NULL.
- `email`: `varchar(100)`, NOT NULL.
- `dni`: `varchar(20)`, NOT NULL.
- `telefono`: `varchar(30)`, NOT NULL.
- `fechaNacimiento`: `date`, NOT NULL.
- `sexo`: `char(1)`, NOT NULL.
- `activo`: `bit`, NOT NULL; DEFAULT `DF__Usuarios__activo__5FB337D6` ((1)).
- `fechaAlta`: `datetime`, NOT NULL; DEFAULT `DF__Usuarios__fechaA__60A75C0F` (getdate()).
- `calle`: `varchar(100)`, NOT NULL; DEFAULT `DF__Usuarios__calle__619B8048` ('').
- `altura`: `varchar(20)`, NOT NULL; DEFAULT `DF__Usuarios__altura__628FA481` ('').

Índices y claves:

- `PK_Usuarios`: CLUSTERED; PK=True, UNIQUE=True, deshabilitado=False; columnas (idUsuario ASC).
- `UQ_Usuarios_Dni`: NONCLUSTERED; PK=False, UNIQUE=True, deshabilitado=False; columnas (dni ASC).
- `UQ_Usuarios_Usuario`: NONCLUSTERED; PK=False, UNIQUE=True, deshabilitado=False; columnas (usuario ASC).
- CHECK `CK_Usuarios_Sexo`: `([sexo]='F' OR [sexo]='M')`; deshabilitada=False, no confiable=False.

## dbo.Ventas

- `idVenta`: `int`, NOT NULL IDENTITY.
- `idCliente`: `int`, NOT NULL.
- `idUsuario`: `int`, NOT NULL.
- `fecha`: `datetime`, NOT NULL; DEFAULT `DF__Ventas__fecha__66603565` (getdate()).
- `total`: `decimal(10,2)`, NOT NULL.
- `idSesion`: `int`, NULL.

Índices y claves:

- `IX_Ventas_SesionCaja`: NONCLUSTERED; PK=False, UNIQUE=False, deshabilitado=False; columnas (idSesion ASC); INCLUDE (total).
- `PK__Ventas__077D5614CD141ADB`: CLUSTERED; PK=True, UNIQUE=True, deshabilitado=False; columnas (idVenta ASC).

## qa.Fixtures

- `vendedor`: `int`, NOT NULL.
- `otroVendedor`: `int`, NOT NULL.
- `administrador`: `int`, NOT NULL.
- `gerente`: `int`, NOT NULL.
- `inactivo`: `int`, NOT NULL.
- `cliente`: `int`, NOT NULL.
- `categoria`: `int`, NOT NULL.
- `productoHistorico`: `int`, NOT NULL.
- `ventaHistorica`: `int`, NOT NULL.

Índices y claves:

- Sin índices declarados.

## Relaciones reales

- `FK__Auditoria__idUsu__1DB06A4F`: `AuditoriaBackups(idUsuario)` → `Usuarios(idUsuario)`; DELETE NO_ACTION, UPDATE NO_ACTION; deshabilitada=False, no confiable=False.
- `FK__DetalleVe__idPro__76969D2E`: `DetalleVentas(idProducto)` → `Productos(idProducto)`; DELETE NO_ACTION, UPDATE NO_ACTION; deshabilitada=False, no confiable=False.
- `FK__DetalleVe__idVen__75A278F5`: `DetalleVentas(idVenta)` → `Ventas(idVenta)`; DELETE NO_ACTION, UPDATE NO_ACTION; deshabilitada=False, no confiable=False.
- `FK__Productos__idCat__619B8048`: `Productos(idCategoria)` → `Categorias(idCategoria)`; DELETE NO_ACTION, UPDATE NO_ACTION; deshabilitada=False, no confiable=False.
- `FK__SesionesC__idUsu__17F790F9`: `SesionesCaja(idUsuarioApertura)` → `Usuarios(idUsuario)`; DELETE NO_ACTION, UPDATE NO_ACTION; deshabilitada=False, no confiable=False.
- `FK__SesionesC__idUsu__18EBB532`: `SesionesCaja(idUsuarioCierre)` → `Usuarios(idUsuario)`; DELETE NO_ACTION, UPDATE NO_ACTION; deshabilitada=False, no confiable=False.
- `FK__Ventas__idClient__70DDC3D8`: `Ventas(idCliente)` → `Clientes(idCliente)`; DELETE NO_ACTION, UPDATE NO_ACTION; deshabilitada=False, no confiable=False.
- `FK__Ventas__idSesion__19DFD96B`: `Ventas(idSesion)` → `SesionesCaja(idSesion)`; DELETE NO_ACTION, UPDATE NO_ACTION; deshabilitada=False, no confiable=False.
- `FK__Ventas__idUsuari__71D1E811`: `Ventas(idUsuario)` → `Usuarios(idUsuario)`; DELETE NO_ACTION, UPDATE NO_ACTION; deshabilitada=False, no confiable=False.
- `FK_Compras_Proveedor`: `Compras(idProveedor)` → `Proveedores(idProveedor)`; DELETE NO_ACTION, UPDATE NO_ACTION; deshabilitada=False, no confiable=False.
- `FK_Compras_Usuario`: `Compras(idUsuario)` → `Usuarios(idUsuario)`; DELETE NO_ACTION, UPDATE NO_ACTION; deshabilitada=False, no confiable=False.
- `FK_Credenciales_Usuario`: `CredencialesUsuario(idUsuario)` → `Usuarios(idUsuario)`; DELETE NO_ACTION, UPDATE NO_ACTION; deshabilitada=False, no confiable=False.
- `FK_DetalleCompras_Compra`: `DetalleCompras(idCompra)` → `Compras(idCompra)`; DELETE NO_ACTION, UPDATE NO_ACTION; deshabilitada=False, no confiable=False.
- `FK_DetalleCompras_Producto`: `DetalleCompras(idProducto)` → `Productos(idProducto)`; DELETE NO_ACTION, UPDATE NO_ACTION; deshabilitada=False, no confiable=False.
- `FK_Movimientos_Compra`: `MovimientosStock(idCompra)` → `Compras(idCompra)`; DELETE NO_ACTION, UPDATE NO_ACTION; deshabilitada=False, no confiable=False.
- `FK_Movimientos_Producto`: `MovimientosStock(idProducto)` → `Productos(idProducto)`; DELETE NO_ACTION, UPDATE NO_ACTION; deshabilitada=False, no confiable=False.
- `FK_Movimientos_Usuario`: `MovimientosStock(idUsuario)` → `Usuarios(idUsuario)`; DELETE NO_ACTION, UPDATE NO_ACTION; deshabilitada=False, no confiable=False.
- `FK_Movimientos_Venta`: `MovimientosStock(idVenta)` → `Ventas(idVenta)`; DELETE NO_ACTION, UPDATE NO_ACTION; deshabilitada=False, no confiable=False.
- `FK_PagosVenta_Ventas`: `PagosVenta(idVenta)` → `Ventas(idVenta)`; DELETE NO_ACTION, UPDATE NO_ACTION; deshabilitada=False, no confiable=False.
- `FK_Productos_Marca`: `Productos(idMarca)` → `Marcas(idMarca)`; DELETE NO_ACTION, UPDATE NO_ACTION; deshabilitada=False, no confiable=False.
- `FK_Usuarios_Perfiles`: `Usuarios(idPerfil)` → `Perfiles(idPerfil)`; DELETE NO_ACTION, UPDATE NO_ACTION; deshabilitada=False, no confiable=False.

## Procedimientos existentes y parámetros

- `sp_Backup_Generar`: `@rutaDestino varchar(255)`.
- `sp_Caja_Abrir`: `@idUsuario int`; `@montoInicial decimal(10,2)`; `@idSesion int OUTPUT`.
- `sp_Caja_Cerrar`: `@idUsuario int`; `@idSesion int`; `@montoReal decimal(10,2)`.
- `sp_Caja_Historial`: `@idUsuario int`; `@desde date`; `@hasta date`.
- `sp_Caja_ObtenerAbierta`: `@idUsuario int`.
- `sp_Caja_Reporte`: `@idUsuario int`; `@idSesion int`.
- `sp_Caja_ValidarVendedor`: `@idUsuario int`.
- `sp_Categorias_Listar`: sin parámetros.
- `sp_Clientes_CambiarEstado`: `@idCliente int`; `@activo bit`.
- `sp_Clientes_Insertar`: `@dni varchar(20)`; `@nombre varchar(50)`; `@apellido varchar(50)`; `@telefono varchar(30)`; `@email varchar(100)`; `@nuevoId int OUTPUT`.
- `sp_Clientes_ListarPorEstado`: `@activo bit`.
- `sp_Clientes_Modificar`: `@idCliente int`; `@dni varchar(20)`; `@nombre varchar(50)`; `@apellido varchar(50)`; `@telefono varchar(30)`; `@email varchar(100)`.
- `sp_Comercial_Estado`: `@modulo varchar(30)`.
- `sp_Compras_Detalle`: `@idActor int`; `@idCompra int`.
- `sp_Compras_Historial`: `@idActor int`; `@desde date`; `@hasta date`; `@idProveedor int`.
- `sp_Compras_Registrar`: `@idActor int`; `@idProveedor int`; `@operacion uniqueidentifier`; `@detalles xml`.
- `sp_DetalleVentas_Insertar`: `@idVenta int`; `@idProducto int`; `@cantidad int`; `@precioUnitario decimal(10,2)`; `@subtotal decimal(10,2)`.
- `sp_Inventario_Ajustar`: `@idActor int`; `@idProducto int`; `@cantidad int`; `@stockEsperado int`; `@motivo nvarchar(250)`; `@operacion uniqueidentifier`.
- `sp_Inventario_Historial`: `@idActor int`; `@desde date`; `@hasta date`; `@idProducto int`.
- `sp_Inventario_Minimo`: `@idActor int`; `@idProducto int`; `@minimo int`.
- `sp_Inventario_Stock`: `@idActor int`.
- `sp_Marcas_AsociarProducto`: `@idActor int`; `@idProducto int`; `@idMarca int`.
- `sp_Marcas_Buscar`: `@idActor int`; `@filtro nvarchar(100)`.
- `sp_Marcas_Guardar`: `@idActor int`; `@id int`; `@nombre nvarchar(100)`; `@activo bit`.
- `sp_Perfiles_Listar`: sin parámetros.
- `sp_Productos_CambiarEstado`: `@idProducto int`; `@activo bit`.
- `sp_Productos_Insertar`: `@idCategoria int`; `@nombre varchar(100)`; `@descripcion varchar(255)`; `@precio decimal(10,2)`; `@stock int`; `@nuevoId int OUTPUT`.
- `sp_Productos_ListarPorEstado`: `@activo bit`.
- `sp_Productos_Modificar`: `@idProducto int`; `@idCategoria int`; `@nombre varchar(100)`; `@descripcion varchar(255)`; `@precio decimal(10,2)`; `@stock int`.
- `sp_Proveedores_Buscar`: `@idActor int`; `@filtro nvarchar(100)`.
- `sp_Proveedores_Guardar`: `@idActor int`; `@id int`; `@nombre nvarchar(100)`; `@razonSocial nvarchar(150)`; `@cuit varchar(11)`; `@activo bit`.
- `sp_Reporte_BajoStock`: sin parámetros.
- `sp_Reporte_HistorialVentas`: sin parámetros.
- `sp_Reporte_MisVentas`: `@idUsuario int`.
- `sp_Reportes_BackupsDashboard`: `@idActor int`; `@desde date`; `@hasta date`.
- `sp_Reportes_VentasDashboard`: `@idActor int`; `@desde date`; `@hasta date`; `@idVendedor int`; `@idProducto int`.
- `sp_Seguridad_Activar`: `@confirmacion varchar(50)`.
- `sp_Seguridad_Cambiar`: `@idActor int`; `@idDestino int`; `@nuevo varchar(256)`; `@anterior varchar(256)`.
- `sp_Seguridad_Credencial`: `@usuario varchar(50)`.
- `sp_Seguridad_Estado`: sin parámetros.
- `sp_Seguridad_Provisionar`: `@idUsuario int`; `@formato varchar(256)`.
- `sp_Seguridad_RecuperarAdministrador`: `@idUsuario int`; `@formato varchar(256)`; `@confirmacion varchar(50)`.
- `sp_Seguridad_UsuarioGuardar`: `@idActor int`; `@idUsuario int`; `@idPerfil int`; `@nombre varchar(50)`; `@apellido varchar(50)`; `@usuario varchar(50)`; `@email varchar(100)`; `@dni varchar(20)`; `@calle varchar(100)`; `@altura varchar(20)`; `@telefono varchar(30)`; `@fechaNacimiento date`; `@sexo char(1)`; `@formato varchar(256)`.
- `sp_Usuarios_CambiarEstado`: `@idUsuario int`; `@activo bit`.
- `sp_Usuarios_Insertar`: `@idPerfil int`; `@nombre varchar(50)`; `@apellido varchar(50)`; `@usuario varchar(50)`; `@contrasena varchar(100)`; `@email varchar(100)`; `@dni varchar(20)`; `@calle varchar(100)`; `@altura varchar(20)`; `@telefono varchar(30)`; `@fechaNacimiento date`; `@sexo char(1)`; `@nuevoId int OUTPUT`.
- `sp_Usuarios_ListarPorEstado`: `@activo bit`.
- `sp_Usuarios_Login`: `@usuario varchar(50)`; `@contrasena varchar(100)`.
- `sp_Usuarios_Modificar`: `@idUsuario int`; `@idPerfil int`; `@nombre varchar(50)`; `@apellido varchar(50)`; `@usuario varchar(50)`; `@contrasena varchar(100)`; `@email varchar(100)`; `@dni varchar(20)`; `@calle varchar(100)`; `@altura varchar(20)`; `@telefono varchar(30)`; `@fechaNacimiento date`; `@sexo char(1)`.
- `sp_Ventas_Registrar`: `@idCliente int`; `@idUsuario int`; `@total decimal(10,2)`; `@nuevaVentaId int OUTPUT`.
- `sp_Ventas_RegistrarConCaja`: `@idCliente int`; `@idUsuario int`; `@idSesion int`; `@medioPago varchar(20)`; `@detalles xml`; `@totalEsperado decimal(10,2)`; `@nuevaVentaId int OUTPUT`.

## Vistas y triggers

- Vista `dbo.vw_Caja_Resumen`.
- Trigger `tr_QA_FalloPago` en `dbo.PagosVenta`; deshabilitado=False.

## Indicadores posibles y datos faltantes

- Ventas.total y fecha permiten facturación, operaciones y evolución por fecha. Ventas.idUsuario permite alcance propio y comparación de vendedores identificados, evitando mezclar homónimos.
- DetalleVentas.cantidad/subtotal permiten unidades y ranking por producto. Productos.idCategoria permite ranking por categoría actual; no existe una instantánea histórica de categoría/nombre del producto.
- PagosVenta registra medio e importe: es posible separar efectivo, transferencia y tarjeta donde existe el pago. Las ventas históricas sin pago/sesión no deben convertirse automáticamente en efectivo.
- AuditoriaBackups registra idBackup, idUsuario, fecha y rutaArchivo. Permite historial y cantidad por período; no registra estado de intento, fallo, motivo, tamaño, hash o verificación de restauración. No es válido dibujar un gráfico de exitosos/fallidos inventando esos datos.
- No hay costo histórico, margen, descuento separado, devoluciones/cancelaciones o retiros/aportes de caja: no pueden calcularse indicadores confiables de ganancia neta, devoluciones o flujo completo de caja.
- El total de cabecera se deduplica por idVenta; no se suma después de un JOIN a detalle que lo multiplique. Ventas sin detalle se informan como tales; unidades son las registradas, no una estimación.
- Los SP heredados de historial y mis ventas alcanzan para resumen temporal básico; no devuelven detalle/IDs suficientes para rankings completos. Los SP nuevos de dashboard se preparan aparte y no forman parte del conteo existente hasta que se apliquen.
- Metadatos no equivalen a verificar contenido ni permisos efectivos de SQL. No se afirmaron resultados de SP todavía no desplegados.

Extracción reproducible: `powershell -NoProfile -ExecutionPolicy RemoteSigned -File scripts/qa/Inventariar-Base-Lectura.ps1`; generación: `python scripts/qa/Generar-Inventario.py --fecha AAAA-MM-DD`. La instantánea intermedia se guarda en private, ignorada. El inventario no contiene definiciones de SP ni rutas físicas.
