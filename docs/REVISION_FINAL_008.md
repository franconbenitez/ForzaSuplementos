# Revision final de 008: autorizacion estructural pendiente

Actualizacion posterior: 008 se instalo bajo autorizacion estructural especifica; ver [RESULTADOS_008_ESTRUCTURAL_QA.md](RESULTADOS_008_ESTRUCTURAL_QA.md). Este documento conserva la revision previa. Ningun ensayo de escritura esta incluido en ese despliegue.

Fecha local: 2026-11-01. Trabajo exclusivo en ForzaSuplementos_GitHub. NO se ejecuto 008 ni ningun fixture SQL de escritura. No se abrieron, cerraron ni modificaron sesiones de Caja.

## Estado actual comprobado por lecturas

Servidor local esperado, base exacta ForzaSuplementosDB_QA y marca Forza-QA-Aislada-v1 validados. QA conserva 17 tablas, 46 SP, 17 FK, 28 indices y 13 CHECK. Los 18 contratos desplegados de 005/006/007 coinciden con sus fuentes. Compras/DetalleCompras vacias despues del ensayo anterior revertido; 008, MovimientosStock y Productos.stockMinimo ausentes. PBKDF2 inactivo y CredencialesUsuario vacia. No se detectaron transacciones de usuario QA incompatibles ni procesos del EXE del repositorio abiertos durante el preflight.

Aplicar-008-Estructura-QA.ps1 se ejecuto exclusivamente con -VerificarSoloLectura. Paso el control de hash, semantica de CHECK, baseline, firmas compatibles e integridad de las 17 tablas. Su rama de sqlcmd no se alcanzo. Conservo en private/008-preflight-* las definiciones originales con opciones ANSI, parametros (tipo, longitud, precision, escala, salida y metadata de default), conteos, columnas, indices, restricciones y relaciones. Los defaults T-SQL se conservan tambien en el texto original: sys.parameters no expone todos sus valores por si solo. Los archivos privados estan ignorados por Git; no se exportan filas, contrasenas ni huellas de datos.

## Alcance exacto de 008

Una tabla nueva dbo.MovimientosStock, con PK identity, cuatro FK, fecha/default, tipo, cantidades con signo, stock anterior/posterior, motivo y referencia a compra/venta/GUID. Agrega Productos.stockMinimo int NOT NULL con DEFAULT(0) y CHECK >=0. Los productos existentes recibiran cero SOLO en esa columna nueva. No cambia stock, precios ni compras/ventas previas. No genera movimientos retroactivos.

Cuatro SP NUEVOS: sp_Inventario_Stock, sp_Inventario_Historial, sp_Inventario_Minimo, sp_Inventario_Ajustar.

Cuatro SP EXISTENTES REEMPLAZADOS: sp_Compras_Registrar, sp_Ventas_RegistrarConCaja, sp_Productos_Modificar, sp_Productos_Insertar. Las 42 definiciones restantes deben quedar identicas, incluidas opciones ANSI.

Resultado previsto: 18 tablas, 50 SP, 21 FK, 33 indices y 17 CHECK. Se agregan una tabla, cuatro SP netos, cuatro FK, cinco indices contando PK, cuatro CHECK y dos DEFAULT. Los ocho cuerpos de SP se instalan, pero NO se invocan sus operaciones de escritura durante la estructura.

Huella SHA-256 normalizada revisada de sql/qa/008_Inventario_QA.sql (archivo sin cambios):

`AFEBAF6E4B68809B6897313BE876129328CE96186514F342F27E7A2ED09F7486`

## Contratos anteriores y posteriores

Las cuatro firmas existentes se compararon con las definiciones reales de QA y son compatibles, incluidos tamanos, precision/escala y OUTPUT. Se conserva el resultado de confirmacion esperado por DAL.

- sp_Compras_Registrar: antes y despues @idActor int, @idProveedor int, @operacion uniqueidentifier, @detalles xml; devuelve IdCompra positivo. Conserva validacion de XML/costos, total, proveedor/producto activo, bloqueo y GUID idempotente. Despues registra un movimiento por producto a partir del OUTPUT del unico incremento de stock, dentro de la misma transaccion.
- sp_Ventas_RegistrarConCaja: antes y despues @idCliente int, @idUsuario int, @idSesion int, @medioPago varchar(20), @detalles xml, @totalEsperado decimal(10,2), @nuevaVentaId int OUTPUT. Conserva validacion de vendedor, Caja propia abierta, cliente/producto activo, precio/stock, total y pago. Despues usa el OUTPUT del unico descuento para insertar movimientos antes del COMMIT; no abre/cierra Caja.
- sp_Productos_Modificar: antes y despues @idProducto int, @idCategoria int, @nombre varchar(100), @descripcion varchar(255), @precio decimal(10,2), @stock int. Antes permitia asignar stock; despues edita metadata/precio solo si stock sigue siendo el esperado, sin asignar existencias. Cambio deliberado de flujo: usar Inventario con motivo o Compras para cambiar stock.
- sp_Productos_Insertar: antes y despues @idCategoria int, @nombre varchar(100), @descripcion varchar(255), @precio decimal(10,2), @stock int, @nuevoId int OUTPUT. Despues exige stock inicial cero y conserva el ID confirmado. No es una baja de funcionalidad de compra: la carga de existencias pasa por compra/ajuste trazable.

Las cuatro firmas nuevas, aun no instaladas ni ejecutadas:

- sp_Inventario_Stock(@idActor int): IdProducto, Nombre, Stock, StockMinimo, Activo, Estado; maximo 2000 filas.
- sp_Inventario_Historial(@idActor int,@desde date,@hasta date,@idProducto int=NULL): historial por fecha/producto, maximo 2000 filas; rango hasta inclusivo mediante limite superior exclusivo.
- sp_Inventario_Minimo(@idActor int,@idProducto int,@minimo int): cambia minimo no negativo, no existencias.
- sp_Inventario_Ajustar(@idActor int,@idProducto int,@cantidad int,@stockEsperado int,@motivo nvarchar(250),@operacion uniqueidentifier): cantidad con signo, motivo obligatorio, stock esperado, limite int y GUID idempotente.

InventarioBLL/DAL y FrmInventario coinciden con esos parametros/columnas; BLL exige gerente y los cuatro nuevos SP comprueban usuario/perfil activos y rol GERENTE. Los SP de Productos conservan su antigua firma sin actor: sus permisos proceden de la aplicacion, no son autenticacion independiente ante acceso SQL directo con la cuenta integrada. No se cambio VB, permisos ni tema.

## Dependencias y ausencia de doble stock

Compras y Ventas conservan un solo UPDATE de Productos.stock; OUTPUT captura inserted/deleted en una tabla variable y solo esa captura alimenta INSERT de MovimientosStock. No hay un segundo UPDATE al registrar el movimiento ni se agrega un trigger de descuento. Ajustar hace otro UPDATE propio, condicionado por stock esperado y rango bigint de 0 a int.MaxValue; cada accion tiene GUID y contenido verificados.

Compras, Ventas y Ajustar usan Forza.Caja.Unica con LockOwner Transaction. Mantener el orden reduce carreras pero serializa operaciones breves y puede producir timeout de bloqueo; no se debe reintentar a ciegas una venta de resultado incierto. Venta NO incorpora idempotencia por GUID: se conserva su comportamiento anterior y el manejo existente de respuesta incierta.

Caja conserva sus SP, vista de resumen y sesiones. El nuevo movimiento forma parte de la transaccion de la venta: si el registro de movimiento falla, debe revertirse venta, detalle, pago y descuento. Eso se analiza en codigo y queda pendiente de los ensayos autorizados; no se declara demostrado en SQL hoy. El efectivo esperado sigue distinguiendo Efectivo de Transferencia/Tarjeta. Las ventas historicas sin movimientos permanecen asi; no se inventa una apertura de inventario historica.

## Restricciones y controles revisados

CK_Productos_StockMinimo es de columna propia. CK_Movimientos_Stock, CK_Movimientos_Motivo y CK_Movimientos_Tipo son de tabla y solo usan columnas locales existentes; incorporan saldo no negativo y suma en bigint, motivo no vacio y coherencia Compra/Venta/Ajuste con referencias nullable. Se aplica el detector semantico aprendido del error 8141 de 007 antes de conectar. No se encontraron CHECK de columna con referencias cruzadas.

FK_Movimientos_Producto/Usuario/Compra/Venta apuntan a PK int existentes. PK_MovimientosStock es la unica clustered prevista en la tabla. UX_Movimientos_Ajuste (GUID), UX_Movimientos_Compra y UX_Movimientos_Venta (origen/producto) tienen filtros IS NOT NULL; IX_Movimientos_FechaProducto usa fecha/int. Los tipos son indexables y las claves pequenas. Los SET requeridos para indices filtrados permanecen en todos los lotes. DF_Productos_StockMinimo es constante 0 y DF_Movimientos_Fecha es SYSDATETIME() hacia datetime2. Los montos siguen en decimal; bigint precede a sumas de stock y diferencias de extremos no negativos caben en int.

El aplicador rechaza otra base, servidor o marca, cambio del hash, objetos/columna/indices/restricciones parciales, baseline distinto, transacciones incompatibles y modos contradictorios. Una instalacion completa tambien se rechaza como baseline incorrecto: no es un reparador ni un reintento automatico. Cada lote SQL exige QA; el despliegue futuro es una llamada al archivo fijo con -E -C -b, XACT_ABORT y una transaccion entre GO, @@TRANCOUNT=1 antes de COMMIT. No hay USE ambiguo ni acceso a la base original.

## Defectos locales corregidos en esta revision

Se agrego respaldo explicito de sys.parameters; antes solo estaba la firma en el texto completo. Se incorporo analisis/comparacion de firmas de los ocho SP, incluidos los cuatro actualizados (tamanos, precision/escala, OUTPUT y defaults NULL). La primera version de ese analizador rechazo cabeceras antiguas sin dbo explicito; se corrigio usando el esquema dbo ya validado por metadata y se agrego prueba de regresion. Fue un fallo local de analisis en lectura, no un error ni intento de migracion.

Se reforzo la verificacion posterior de opciones ANSI en los ocho SP y de todas las columnas preexistentes; solo se permiten 12 columnas de MovimientosStock y stockMinimo como agregados. Se mantiene la comparacion de huellas/conteos completos de las 17 tablas, con soporte de vacias. Las columnas nuevas no reemplazan esa comparacion.

No fue necesario modificar sql/qa/008_Inventario_QA.sql ni su huella.

## Ensayos preparados, NO ejecutados

- Avance_Transaccional_QA.sql: compra ficticia y reintento por GUID, un movimiento +3 y stock 3/precio intacto; ajuste -1 y reintento con un solo movimiento 3 a 2; minimo 3; rollback de productos/proveedor/cabecera/detalle/movimientos. Reforzado para rechazar IDs ausentes, evitar que NULL escape a una comprobacion, verificar saldos anteriores/posteriores y ausencia del token.
- Negativos_Compras_Inventario_Preparados.sql: diez rechazos (producto/proveedor inactivo, cantidad cero, costo con decimales excesivos, overflow de stock, GUID vacio, salida insuficiente, motivo vacio, stock obsoleto y rol administrador). Cada caso usa su propia transaccion y exige error esperado, rollback, conteos y ausencia de token/movimientos; ahora incluye DetalleCompras.
- Ventas_Caja_008_Rollback_Preparado.sql: tres sesiones NUEVAS ficticias, cada una con efectivo/transferencia/tarjeta; verifica nueve descuentos/movimientos unicos, saldos, pagos, asociacion a sesion, efectivo esperado 10 frente a venta total 30, diferencias de cierre -1/0/+1 y rollback. Aborta antes de operar si existe cualquier Caja abierta; no cierra una sesion preexistente.
- Negativos_Ventas_Caja_008_Preparados.sql (nuevo): ocho rechazos independientes: venta sin Caja, stock insuficiente, total incorrecto, medio invalido, apertura duplicada, apertura negativa, cierre duplicado y gerente intentando operar Caja. Cada caso crea solo su fixture y revierte sus productos/sesiones; valida errores, conteos, ausencia de token y transaccion cero. Se analizo estaticamente, NO se ejecuto.

Todos exigen base/servidor/marca, autorizacion especifica, baseline 18 tablas/50 SP y ausencia de transaccion externa previa. IDENTITY puede avanzar pese a rollback: no se reseedea. La autorizacion estructural propuesta NO incluye ninguno de estos ensayos ni operaciones de Caja.

El runner de concurrencia de Compras tambien se reviso: requiere un proveedor QA ficticio existente y usa el productoHistorico identificado en qa.Fixtures con dos transacciones revertidas. Actualmente no hay proveedores persistidos; su ejecucion requiere revisar/proveer ese fixture bajo otro permiso. No se incluye en la aprobacion estructural ni se presenta como ejecutable sin ese requisito.

## Verificacion posterior preparada y riesgos pendientes

Verificar-008-Lectura.ps1 debe comprobar 18/50/21/33/17, MovimientosStock vacia, stockMinimo cero/no nulo, cuatro FK y cuatro CHECK confiables/habilitados, defaults, cinco indices con claves/unicidad/filtros, ocho cuerpos/firmas/opciones ANSI y parametros de Inventario. El aplicador compara las huellas de datos anteriores, las 42 definiciones no afectadas, y metadata de todas las columnas preexistentes. Las cuatro definiciones reemplazadas se respaldan y sus nuevos cuerpos se validan contra el SQL revisado.

No se ha ejecutado esa verificacion posterior ni el DDL 008. Los riesgos reales pendientes son el enlace/aceptacion por SQL Server de la estructura y de los ocho cuerpos, la atomicidad del movimiento con compra/venta, la integracion Caja/pagos, el flujo stock cero de Productos y la concurrencia/timeout. Hasta desplegar y autorizar ensayos no se consideran validados. Un fallo post-COMMIT no habilita una reversion: detenerse, conservar evidencia y pedir permiso independiente.

## Pruebas y reproduccion

Compilacion Debug/AnyCPU correcta y regresion completa aprobada: 749 comprobaciones y 66 analisis estaticos SQL. Registro: private/regresion-revision-final-008.log. Se agregaron 13 comprobaciones al aplicador: equivalencia de firmas antiguas/cualificadas, precision/tamanos, OUTPUT, default NULL, tipos desconocidos, ocho firmas y ausencia de doble UPDATE, OUTPUT/movimiento y bloqueo comun. Total del aplicador offline: 42. Los cuatro fixtures preparados pasaron el analisis de sintaxis/guardas, no pruebas de ejecucion.

Windows PowerShell desde la raiz, permitido sin desplegar:

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File scripts/qa/Aplicar-008-Estructura-QA.ps1 -VerificarSoloLectura
```

En SSMS solo consultar metadata tras verificar servidor/base/marca. En la aplicacion usar el acceso directo QA protegido; Inventario debe seguir deshabilitado. No usar F5, registrar operaciones ni ejecutar los fixtures para verificar esta preparacion.

## Autorizacion exacta propuesta: solo estructura

Autorizo una unica ejecucion de sql/qa/008_Inventario_QA.sql con huella SHA-256 normalizada AFEBAF6E4B68809B6897313BE876129328CE96186514F342F27E7A2ED09F7486 mediante scripts/qa/Aplicar-008-Estructura-QA.ps1 -AutorizarEstructura008, exclusivamente en ForzaSuplementosDB_QA de la instancia local verificada con marca Forza-QA-Aislada-v1. Incluye crear MovimientosStock, agregar Productos.stockMinimo con default cero, cuatro SP nuevos y actualizar los cuatro SP identificados, sus FK/indices/CHECK/defaults; preservar originales y verificar estructura e integridad posterior SOLO mediante lecturas. No autoriza fixtures SQL de escritura, movimientos, compras/ventas/ajustes, operaciones de Caja, cambios de existencias/precios/credenciales, PBKDF2, otras migraciones/bases ni push. Ante error detenerse e inspeccionar sin reparaciones, reversiones o reintentos automaticos; una reversion posterior al COMMIT requiere otra autorizacion.
