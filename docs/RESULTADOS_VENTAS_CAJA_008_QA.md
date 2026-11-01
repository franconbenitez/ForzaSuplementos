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
