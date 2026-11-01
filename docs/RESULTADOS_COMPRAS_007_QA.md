# Resultado real del ensayo ficticio de Compras 007

Fecha local: 2026-11-01. Repositorio exclusivo ForzaSuplementos_GitHub. El usuario autorizo una sola ejecucion de tests/qa/Compras_007_Rollback_Preparado.sql y ningun otro fixture SQL de escritura.

## Ejecucion y resultado

**Un ensayo transaccional aprobado, sin fallos ni reintentos.** El archivo SQL autorizado no se modifico ni se ampliaron sus casos. scripts/qa/Ejecutar-007-Ensayo.ps1 exige permiso, valida QA y ejecuta solo ese archivo en la conexion controlada, resolviendo sus variables SQLCMD y quitando la directiva de cliente :on error exit. Capturo el mensaje final de exito despues de todas las verificaciones del runner. Evidencia en private/007-ensayo-*, ignorada por Git.

Antes de ejecutar se verificaron servidor local esperado, base exacta ForzaSuplementosDB_QA y marca Forza-QA-Aislada-v1; 17 tablas, 46 SP, 17 FK, 28 indices y 13 CHECK; los 18 cuerpos de procedimientos de 005/006/007 coinciden con sus fuentes. No habia transaccion previa, otra transaccion de usuario QA incompatible ni proceso del EXE del repositorio abierto. 008, MovimientosStock, stockMinimo y sus SP estaban ausentes. PBKDF2 inactivo y CredencialesUsuario vacia.

## Cada validacion realmente realizada

1. Alta del proveedor ficticio: ID positivo confirmado. APROBADA.
2. Producto ficticio con stock inicial 0 y precio de venta 99, creado dentro de la misma transaccion. APROBADA.
3. Compra de 3 unidades a costo 2.50: total y subtotal 7.50, una cabecera para la operacion y un detalle con producto/cantidad/costo correctos. APROBADA.
4. Repeticion del mismo GUID y XML: ambas respuestas contienen exactamente un ID positivo y es el mismo. La operacion sigue con una sola cabecera y detalle. APROBADA.
5. Stock observado despues de ambas invocaciones: 3, no 6. Precio de venta observado: 99. APROBADA.
6. Historial filtrado por fecha y proveedor devuelve la compra con GUID, actor, proveedor y total esperados; detalle devuelve exactamente una linea de 3 unidades a 2.50, subtotal 7.50. APROBADA.
7. ROLLBACK previsto en el runner: conteos iniciales de Productos/Proveedores/Compras/DetalleCompras conservados, sin token ficticio ni operacion/detalle del ensayo y @@TRANCOUNT=0. APROBADA.
8. Verificacion adicional en la misma conexion: cero Compras y DetalleCompras, cero proveedores/productos con prefijo QA Compra; conteos y huellas agregadas de las 17 tablas antes/despues coinciden. APROBADA.

La idempotencia se comprobo para dos invocaciones del mismo pedido dentro del ensayo controlado. Esto no equivale a una prueba de concurrencia entre conexiones ni de recuperacion tras caida real de red.

## Estado final e integridad

QA conserva 17 tablas/46 SP/17 FK/28 indices/13 CHECK. Compras y DetalleCompras vacias. No quedaron proveedor, producto, compra, detalle o transaccion del ensayo. Los datos preexistentes, incluidos productos, precios, stock, ventas, usuarios y credenciales, coinciden segun las huellas de todas las tablas; esas huellas solo vivieron en memoria y no se exportaron. Los valores IDENTITY pueden avanzar como se autorizo; no hubo reseed ni DBCC CHECKIDENT.

No se ejecuto otro fixture de escritura, 008, PBKDF2, cambios de contrasenas ni operaciones sobre otras bases. No hubo reparaciones, reversiones adicionales o push. El rollback ejecutado fue exclusivamente el previsto por el runner autorizado.

## Pruebas posteriores y siguiente etapa

Se preparo el aplicador protegido de 008 por analisis offline y lecturas. Su modo -VerificarSoloLectura paso sobre QA actual; no se ejecuto su rama de despliegue. Ver PREPARACION_008_INVENTARIO_QA.md.

Compilacion Debug/AnyCPU correcta. Regresion offline/de lectura: 736 comprobaciones aprobadas y 65 analisis estaticos SQL; registro private/regresion-ensayo-007-preparacion-008.log. No se declaran ensayos de 008 ni validacion visual humana completados.

Para inspeccionar en Windows, usar FORZA SUPLEMENTOS - QA (GITHUB), ingresar como gerente y consultar Historial de Compras (debe seguir vacio). No registrar compras manuales dentro de esta autorizacion. En SSMS, tras verificar servidor/base/marca, consultar COUNT_BIG de Compras/DetalleCompras (0/0) y metadata, sin volver a ejecutar este runner.
