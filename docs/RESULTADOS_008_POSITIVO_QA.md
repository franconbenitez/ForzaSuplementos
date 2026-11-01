# Resultado real del positivo de Compra e Inventario tras 008

Fecha local: 2026-11-01. Repositorio exclusivo ForzaSuplementos_GitHub. Se uso la autorizacion especifica para una unica ejecucion de tests/qa/Avance_Transaccional_QA.sql. No se ejecutaron otras suites SQL de escritura.

## Preflight y alcance ejecutado

Servidor local esperado, base exacta ForzaSuplementosDB_QA y marca Forza-QA-Aislada-v1 verificados. Estado 18 tablas, 50 SP, 21 FK, 33 indices y 17 CHECK, con los ocho contratos/opciones ANSI/firmas de 008 verificados. Se compararon ademas 25 contratos vigentes de 005-008, usando la ultima definicion cuando 008 reemplaza una de 007. Sin transaccion previa, otras transacciones de usuario QA incompatibles, residuos del token o proceso del EXE del repositorio abierto.

El wrapper scripts/qa/Ejecutar-008-Positivo.ps1 requiere permiso explicito, rechaza un fixture con cambios frente a HEAD y verifica hash antes de invocarlo una sola vez. No cambia sus casos: solo resuelve las variables SQLCMD y elimina la directiva de cliente :on error exit para ejecutar el mismo lote con SqlCommand. El hash, HEAD, conteos y mensaje SQL final quedan en private/008-positivo-* ignorado por Git. No se exportan filas ni contrasenas.

## Validaciones individuales observadas

El runner emitio su mensaje final de exito despues de completar todas sus comprobaciones y rollback. Resultado del ensayo: APROBADO, sin fallidos ni bloqueos.

1. Compra ficticia de tres unidades: stock inicial 0, stock observado 3. APROBADA.
2. Precio de venta despues de la compra: 99; cabecera con ID positivo y total 7.50. APROBADA.
3. Movimiento de Compra: exactamente uno para producto/compra, cantidad +3, anterior 0 y posterior 3. APROBADA.
4. Repeticion del GUID/pedido de compra: una sola cabecera y movimiento; stock observado sigue 3. APROBADA.
5. Ajuste ficticio de -1 con el motivo previsto y stock esperado 3: stock observado final temporal 2. APROBADA.
6. Movimiento de Ajuste: exactamente uno para GUID/producto, tipo Ajuste, cantidad -1, anterior 3 y posterior 2. APROBADA.
7. Repeticion del mismo GUID/contenido del ajuste: stock sigue 2 y no se agrega otro movimiento. APROBADA.
8. Stock minimo: el SP recibio 3 y la consulta directa a Productos dentro del runner comprobo stockMinimo=3. APROBADA. No se declara una prueba visual del panel de alertas mientras ese fixture temporal estaba presente.
9. ROLLBACK del unico bloque previsto: conteos originales de Productos/Proveedores/Compras/DetalleCompras/MovimientosStock y ausencia de token/operacion/movimientos comprobados, con @@TRANCOUNT=0. APROBADA.
10. Verificacion adicional posterior en la misma conexion: cero Compras, DetalleCompras, MovimientosStock y proveedor/producto con prefijo QA Ensayo; conteos y huellas de todas las 18 tablas iguales al inicio. APROBADA.

La idempotencia se comprobo en las invocaciones secuenciales del mismo GUID dentro del ensayo transaccional. No se presenta como una prueba de concurrencia entre conexiones ni de recuperacion tras fallo de red.

## Estado final e integridad

QA conserva 18 tablas/50 SP/21 FK/33 indices/17 CHECK. No quedaron productos, proveedores, compras, detalles o movimientos del ensayo; no hay transaccion de prueba abierta. Las huellas de las 18 tablas (incluidos usuarios, credenciales, Caja, ventas, precios y existencias preexistentes) coinciden antes/despues; los valores de las huellas solo vivieron en memoria, sin persistirlos en archivos.

Los valores temporales stock 2/minimo 3 pertenecian exclusivamente al producto nuevo y desaparecieron con el rollback. Los productos preexistentes conservaron sus datos; sus minimos siguen como al comienzo. Los contadores IDENTITY pueden avanzar, conforme al permiso; no se hizo reseed ni DBCC CHECKIDENT.

No se registraron ventas ni operaciones de Caja, no se ejecutaron negativos, otras migraciones, cambios de PBKDF2/contrasenas, escrituras en otras bases ni push. No hubo error SQL, reparacion, reversion adicional o reintento del fixture.

## Compilacion, regresion y verificacion manual

Compilacion Debug/AnyCPU correcta. Regresion offline/de lectura: 749 comprobaciones aprobadas y 66 analisis estaticos SQL correctos, registrados en private/regresion-008-positivo.log. El fixture autorizado no se modifico. Los cambios locales son el wrapper y documentacion de evidencia/estado; no se cambio VB ni configuraciones.

Para consultar desde Windows usar FORZA SUPLEMENTOS - QA (GITHUB), ingresar como gerente y abrir Stock/Movimientos; el fixture ya no debe existir. No repetir operaciones manualmente con este permiso. En SSMS verificar servidor/base/marca y consultar COUNT_BIG de Compras, DetalleCompras y MovimientosStock (esperado 0/0/0), sin volver a ejecutar el archivo.

## Siguiente autorizacion propuesta, NO concedida

Autorizo una sola ejecucion exclusivamente de tests/qa/Negativos_Compras_Inventario_Preparados.sql en ForzaSuplementosDB_QA de la instancia local verificada, con marca Forza-QA-Aislada-v1 y estructura 008 completa. Permito crear/modificar solo los productos y proveedores ficticios nuevos de cada caso para los diez rechazos previstos: producto inactivo, proveedor inactivo, cantidad cero, costo con decimales excesivos, overflow de stock, GUID vacio, salida insuficiente, motivo vacio, stock esperado obsoleto y perfil administrador sin permiso. Cada caso debera rechazar con el error esperado y revertirse, comprobando conteos, ausencia de registros ficticios, integridad y @@TRANCOUNT=0. Se aceptan avances IDENTITY sin reseed. Ante fallo detenerse sin reintentos, reparaciones o reversiones adicionales. No incluye ventas, Caja, otros fixtures, migraciones, PBKDF2, credenciales, otras bases ni push.

Los ensayos de Ventas/Caja y sus negativos siguen pendientes de permisos independientes.
