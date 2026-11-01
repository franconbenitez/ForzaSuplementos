# Ventas/Caja 008: ensayo positivo aprobado con rollback

Fecha local: 2026-11-01. Repositorio exclusivo ForzaSuplementos_GitHub; HEAD previo 02b948f. Nueva autorizacion expresa tras el cierre manual de la sesion historica por su responsable. Una sola invocacion de scripts/qa/Ejecutar-008-Ventas-Caja.ps1 -AutorizarVentasCaja008. Fixture sin cambios respecto de Git. No hubo reintentos.

## Preflight real

Servidor local esperado, ForzaSuplementosDB_QA y marca Forza-QA-Aislada-v1 verificados. Estructura: 18 tablas, 50 SP, 21 FK, 33 indices y 17 CHECK. Contratos vigentes 005-008 comprobados; ausencia de Caja abierta, instancias incompatibles y transacciones previas. No se modificaron migraciones ni el fixture.

## Validaciones ejecutadas

- APROBADO: tres productos ficticios con stock inicial 3 y tres sesiones nuevas, sin operar sesiones historicas.
- APROBADO: nueve ventas, tres por sesion, con Efectivo, Transferencia y Tarjeta; ID de venta devuelto y sesion correspondiente comprobados.
- APROBADO: nueve pagos de 10, con medio e importe correctos. Cada sesion contiene tres ventas de 10: total 30; total del ensayo 90.
- APROBADO: nueve movimientos de salida; exactamente uno por venta/producto, cantidad -1 y saldos anterior/posterior correctos.
- APROBADO: cada producto recorre 3 -> 2 -> 1 -> 0, sin doble descuento.
- APROBADO: cierres con efectivo esperado 10, contados 9/10/11 y diferencias -1/0/+1; transferencia y tarjeta no suman efectivo fisico.
- APROBADO: rollback previsto ejecutado; sin productos, sesiones ni movimientos del ensayo, conteos conservados en las tablas de venta/detalle/pago y resto de tablas.
- APROBADO: conteos y huellas de datos de las 18 tablas iguales antes/despues; cero Cajas abiertas y @@TRANCOUNT=0. MovimientosStock termina vacia.

Precision de cobertura: los procedimientos registran los detalles y sus contratos fueron comprobados; el fixture no contiene una consulta individual de cada fila de DetalleVentas ni una suma independiente de cabeceras. El total 30 se deriva de tres ventas de importe 10, sus pagos y el contrato comprobado. No se agregaron consultas dentro del fixture ni se amplio su alcance para afirmar una comprobacion adicional.

## Integridad y evidencia

Los datos preexistentes, incluida la sesion historica cerrada, stock, precios, ventas y credenciales, mantienen sus huellas. Los contadores IDENTITY pueden avanzar; no se reiniciaron. Sin operaciones sobre otras bases, sin PBKDF2, migraciones, compras, ajustes ni push.

Evidencia privada ignorada por Git: private/008-ventas-caja-20261101-235636-9287998 (preflight, conteos, mensajes SQL y resultado). Resultado: Ejecutado=true, Exito=true, ConteosIguales=true, DatosIguales=true; transacciones, movimientos, productos ficticios y Cajas abiertas finales: cero. No se publican datos personales ni valores de credenciales.

## Compilacion y regresion

Compilacion completa Debug/AnyCPU aprobada en salida habitual. scripts/Validar-Avance.ps1 -IncluirLecturaQa termino con codigo 0: 749 comprobaciones aprobadas y 66 lotes/procedimientos analizados estaticamente. Incluye permisos, navegacion, Caja offline, buscadores, dashboards, contratos, restricciones, modulos y numericos QA de lectura; no ejecuta fixtures de escritura. Evidencia: private/regresion-008-ventas-caja.log. Auditoria de archivos e historial: cero hallazgos actuales, historicos, de metadatos o rutas prohibidas. Las pruebas visuales humanas y la preparacion de la netbook permanecen pendientes. Los ocho negativos NO se ejecutaron; requieren autorizacion independiente.

## Antecedente: bloqueo previo conservado

# Ventas/Caja 008: bloqueado por Caja preexistente, fixture NO ejecutado

Fecha local: 2026-11-01. Repositorio exclusivo ForzaSuplementos_GitHub. HEAD inicial a2dc7cf y arbol limpio. El usuario autorizo una unica ejecucion del archivo tests/qa/Ventas_Caja_008_Rollback_Preparado.sql, exigiendo abortar si existia una Caja abierta previa.

## Resultado exacto y guardas

El wrapper scripts/qa/Ejecutar-008-Ventas-Caja.ps1 se invoco una vez. Antes de llegar al comando del fixture se verificaron destino/servidor local esperado, base ForzaSuplementosDB_QA, marca Forza-QA-Aislada-v1 y estructura 18 tablas/50 SP/21 FK/33 indices/17 CHECK. La verificacion de los ocho contratos 008 (cuerpos/firmas/opciones ANSI y parametros de Inventario) paso. Se comprobo que el archivo de ensayo no tiene cambios respecto de HEAD.

El preflight encontro UNA sesion de Caja abierta preexistente. No habia transaccion previa, otra transaccion de usuario QA incompatible ni productos con prefijo del ensayo. Se aborto ANTES de ExecuteNonQuery del fixture. La comparacion ampliada de los 25 contratos 005-008 y las huellas previas del wrapper no se alcanzo: no se afirma haberla completado en este intento.

Estado: BLOQUEADO por condicion de seguridad, no fallo de una venta o un cierre. Se ejecutaron cero casos SQL del fixture y cero escrituras SQL. No se reintento ni se cerro/modifico la Caja existente. Su identificacion minima quedo en evidencia privada (sesion-preexistente.xml), no en este repositorio compartido.

## Validaciones del ensayo solicitadas

- Productos nuevos/sesiones nuevas: BLOQUEADO antes de crear; cero creados.
- Nueve ventas, detalles y pagos: BLOQUEADO, cero ventas/pagos de prueba ejecutados.
- Nueve movimientos y stock 3 a 2 a 1 a 0: BLOQUEADO, cero movimientos de prueba.
- Asociacion de ventas a sesiones: BLOQUEADO.
- Total 30 y efectivo esperado 10 por sesion: BLOQUEADO, no calculados mediante este ensayo.
- Diferencias de cierre -1/0/+1: BLOQUEADO, no hubo apertura ni cierre.
- Rollback del fixture: NO APLICA; no se inicio su transaccion. No se ejecutaron reversiones adicionales.
- Comparacion criptografica antes/despues de las 18 tablas: NO EJECUTADA; aborto previo. No se declara una prueba de integridad de ese tipo que no ocurrio.

La inspeccion posterior fue solo lectura. Estado real: 18 tablas, 50 SP, 21 FK, 33 indices, 17 CHECK, cero MovimientosStock, cero productos del fixture, una Caja abierta previa y @@TRANCOUNT=0 en la conexion de inspeccion. PBKDF2 inactivo y CredencialesUsuario vacia. Esa sesion se mantuvo abierta, sin operarla. No se tocaron existencias, precios, usuarios, credenciales ni otras bases; no hubo migraciones ni reseeds.

## Compilacion, codigo y evidencia

No se repitieron compilacion ni regresion tras el bloqueo: se respeto la orden de detener el ensayo e inspeccionar el estado. La ultima regresion aprobada pertenece a la etapa anterior; no se atribuye a esta ejecucion. No se cambio VB, conexiones, SQL de migraciones ni el fixture autorizado.

Se agrego el wrapper acotado a ese archivo y se aclaro su mensaje de rechazo para distinguir Caja abierta de otras incompatibilidades. Solo se verifico su sintaxis local, sin volver a invocarlo. La evidencia se conserva en private/008-ventas-caja-* (resultado.json y metadata de estado/sesion) ignorado por Git. No hubo push.

## Desbloqueo y proximo paso

Revisar la sesion preexistente desde FORZA SUPLEMENTOS - QA (GITHUB), FrmCaja, con el vendedor responsable. Cualquier cierre requiere revision y decision explicita con su monto contado correspondiente; este permiso NO autoriza al agente a cerrarla, alterar su estado o cambiar montos para desbloquear pruebas.

Una vez resuelta por el usuario o mediante otra autorizacion independiente, sera necesario autorizar un NUEVO intento del mismo fixture. Antes se volvera a comprobar que no exista Caja abierta y que se mantengan los contratos y archivo revisados. Los ocho negativos de Ventas/Caja NO estan autorizados ni se ejecutaron. No se adelanta una solicitud para ejecutarlos porque el positivo aun esta bloqueado.
