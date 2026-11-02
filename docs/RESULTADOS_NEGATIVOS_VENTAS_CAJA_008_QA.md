# Ocho negativos Ventas/Caja 008: resultado real

Fecha local 01/11/2026. Repositorio ForzaSuplementos_GitHub, HEAD previo a71b345. Una sola ejecucion autorizada del fixture sin cambios frente a Git, mediante scripts/qa/Ejecutar-008-Negativos-Ventas-Caja.ps1 -AutorizarNegativosVentasCaja008. El runner reutiliza las protecciones del positivo, pero queda fijado exclusivamente al archivo negativo y exige los ocho mensajes individuales de aprobacion.

## Preflight

Servidor local esperado, ForzaSuplementosDB_QA y marca Forza-QA-Aislada-v1 comprobados. 18 tablas, 50 SP, 21 FK, 33 indices, 17 CHECK; ocho contratos 008 y 25 contratos vigentes 005-008 comprobados. Sin Caja previa abierta, instancia de aplicacion incompatible, transaccion previa ni residuos del prefijo. SHA256 del fixture registrado y vuelto a verificar antes de ejecutar. No hubo cambios del archivo, reintentos ni reparaciones.

## Casos ejecutados

1. Venta sin Caja abierta: APROBADO; error 51006; rollback comprobado.
2. Venta con stock insuficiente: APROBADO; error 51013; rollback comprobado.
3. Venta con total incorrecto: APROBADO; error 51014; rollback comprobado.
4. Venta con medio de pago invalido: APROBADO; error 51009; rollback comprobado.
5. Apertura duplicada: APROBADO; error 51005; rollback comprobado.
6. Apertura con monto negativo: APROBADO; error 51003; rollback comprobado.
7. Cierre duplicado: APROBADO; error 51006; rollback comprobado.
8. Gerente intentando abrir Caja: APROBADO; error 51001; rollback comprobado.

Total: 8 aprobados, 0 fallidos, 0 bloqueados. Cada mensaje solo se emite despues de comprobar numero exacto de error, rollback, conteos de Productos/SesionesCaja/Ventas/DetalleVentas/PagosVenta/MovimientosStock, ausencia del producto/sesion/movimientos ficticios del caso y @@TRANCOUNT=0. Se aceptaron avances de IDENTITY sin reseed.

## Estado final e integridad

Resultado del runner: Ejecutado=true, Exito=true, ConteosIguales=true, DatosIguales=true. Las 18 tablas conservan conteos y huellas anteriores. Cero Cajas abiertas, movimientos, productos del prefijo y transacciones. La sesion historica y demas datos preexistentes permanecen intactos. No se ejecutaron compras, ajustes, migraciones, otros fixtures, operaciones de seguridad ni push.

Evidencia privada ignorada: private/008-negativos-ventas-caja-20261102-000256-7153181; el nombre usa UTC, la fecha local del ensayo es 01/11. Contiene preflight, conteos, ocho mensajes SQL y resultado; no se versionan datos ni secretos.

Compilacion Debug/AnyCPU aprobada. Regresion offline/de lectura finalizada con codigo 0: 749 comprobaciones aprobadas y 66 lotes/procedimientos analizados estaticamente. Log privado: private/regresion-cierre-final.log. No se declara validacion visual humana nueva.
