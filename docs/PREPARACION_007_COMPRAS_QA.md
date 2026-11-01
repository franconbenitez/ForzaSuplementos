# Revision previa de 007: Compras

Fecha local: 2026-10-31. Revision offline y lecturas sobre QA, sin despliegue ni ensayos SQL de compras.

## Estado real y dependencias

Preparar-007-Lectura.ps1 se ejecuto correctamente. Verifico servidor local esperado, base exacta ForzaSuplementosDB_QA, marca de aislamiento, transaccion previa cero, 15 tablas/43 SP, seguridad inactiva y credenciales derivadas vacias. Comparo los 15 contratos de 005/006 con sus fuentes: coinciden. Compras, DetalleCompras, MovimientosStock y los tres SP de 007 estan ausentes. Las definiciones previas quedaron conservadas en private/007-revision-*; la lista de contratos 007 anteriores esta vacia.

## Cambios estructurales previstos

007 crea Compras (ID, proveedor, usuario, fecha datetime2, total decimal(18,2), operacion GUID unica y huella varbinary(32)) y DetalleCompras (ID, compra, producto, cantidad, costo unitario y subtotal). Agrega cuatro FK, cinco indices contando dos PK y dos UQ mas IX_Compras_FechaProveedor, cuatro CHECK y default de fecha. La unicidad compra/producto evita repetir lineas; operacion evita duplicar el pedido.

Crea sp_Compras_Registrar, sp_Compras_Historial y sp_Compras_Detalle, sin sustituir SP existentes en el baseline actual. Resultado previsto tras despliegue: 17 tablas, 46 SP, 17 FK, 28 indices y 13 CHECK. No crea compras ni modifica stock al desplegar. No agrega movimientos de inventario: esa capacidad depende de 008, aun no autorizada.

## Contratos revisados y comportamiento

CompraBLL exige Permiso.Productos, exclusivo de gerente; valida proveedor, GUID no vacio, entre 1 y 500 lineas, cantidades positivas, IDs sin duplicados, costos positivos con dos decimales y limites decimales. Toma copia del pedido antes de enviarlo. Historial valida fechas e ID proveedor; Detalle valida compra positiva.

CompraDAL llama a sp_Compras_Registrar con @idActor int, @idProveedor int, @operacion uniqueidentifier y @detalles xml. El XML contiene detalles/item con producto, cantidad y costo, serializado con punto decimal y dos decimales; coincide con SQL. La respuesta requerida es una fila IdCompra positivo. Historial envia @idActor, @desde date, @hasta date y @idProveedor opcional; Detalle envia @idActor y @idCompra. Las columnas devueltas coinciden con las grillas de FrmHistorialCompras/FrmSeleccionTabla.

FrmCompras conserva GUID mientras el pedido no cambia, protege carrito durante envio y no borra su contenido si no recibe confirmacion. Buscar proveedores solo permite activos; productos se obtienen del catalogo activo. El costo de compra es distinto del precio de venta. Historial permite fechas y proveedor y abre detalle. El modulo continua bloqueado hasta que esten los tres SP; no se habilito en esta tarea.

Los tres SP comprueban usuario/perfil activos y rol GERENTE almacenado. Registrar valida XML lexicalmente antes de convertirlo para evitar redondeos silenciosos, valida totales, toma el bloqueo transaccional compartido Forza.Caja.Unica y bloquea filas de productos/proveedor. Guarda cabecera/detalles e incrementa stock en una transaccion; rechaza inactivos y overflow de int. No actualiza Productos.precio.

Un reintento con mismo GUID, actor, proveedor y huella XML devuelve el mismo ID sin sumar stock otra vez. Un GUID reutilizado con contenido diferente se rechaza. La huella depende de la serializacion XML exacta: no se garantiza equivalencia de documentos semanticamente iguales con otro orden/formato. La DAL conserva formato estable para el mismo pedido; no se presenta como idempotencia universal.

Historial incluye hasta el final del dia hasta (limite superior exclusivo), maximo 2000 filas, con opcion por proveedor. Detalle devuelve sus lineas ordenadas. Los limites de grilla son deliberados, no paginacion completa. SQL no autentica independientemente a alguien con acceso directo a la cuenta integrada; el ID proviene de la sesion de la aplicacion y el SP comprueba su rol persistido.

## Protecciones y recuperacion

Cada lote de 007 exige servidor/base/marca QA y no contiene referencias a la base original ni rutas fisicas. Se usa XACT_ABORT y una sola transaccion entre GO, con ausencia de transaccion previa y @@TRANCOUNT=1 antes de COMMIT. No ejecuta otras migraciones ni activa PBKDF2. Los IF NOT EXISTS evitan objetos duplicados, pero no reparan una instalacion parcial arbitraria: debe rechazarse en el preflight.

Antes de autorizar un despliegue, el aplicador debe volver a preservar definiciones y comparar datos preexistentes (incluidas tablas vacias). Ante fallo se detiene y comprueba estado real mediante lecturas. La conexion de despliegue cerrada revierte su transaccion no confirmada; no se debe asumir rollback sin verificar. Tras COMMIT, una migracion inversa o eliminacion de objetos exige autorizacion independiente; no se ejecuta automaticamente.

## Pruebas y limites

ScriptDom analizo correctamente los lotes y cuerpos de SP preparados (dentro de los 65 analisis estaticos de la suite). Esto comprueba sintaxis, no enlace ni comportamiento sobre tablas aun ausentes. Los contratos BLL/DAL/UI se revisaron en codigo; las pruebas offline de compras forman parte de la regresion. No se ejecuto sp_Compras_Registrar ni una operacion SQL de compras.

Compras_007_Rollback_Preparado.sql esta preparado, no autorizado: crea proveedor/producto ficticios dentro de transaccion, registra tres unidades a costo 2.50, repite exactamente el GUID/pedido, exige mismo ID, total 7.50, una linea, stock 3 y precio de venta 99 intacto, y revierte el bloque verificando conteos y @@TRANCOUNT=0. Es un ensayo positivo e idempotente; no se afirma que cubra todos los negativos ni concurrencia. Existen otros runners preparados de negativos y concurrencia que requieren revisiones y autorizaciones separadas; no se ejecutaron.

No se identificaron defectos bloqueantes en esta revision estatica. La validacion funcional real de compras y de la concurrencia queda pendiente de despliegue y ensayos autorizados. No hay autorizacion de 007 ni 008.

## Proxima etapa propuesta

Preparar y autorizar por separado un unico despliegue estructural de sql/qa/007_Compras_QA.sql, con tablas nuevas vacias, tres SP y verificaciones posteriores exclusivamente de lectura. No incluir ensayos, registros de compras, 008, PBKDF2, cambios de contrasenas, otras bases ni push. Despues, solicitar permiso independiente para el runner de compras con rollback.
