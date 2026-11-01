# Autorizaciones independientes propuestas para ensayos tras 008

Fecha local: 2026-11-01. Estado actualizado: A fue autorizado y aprobado con rollback; ver RESULTADOS_008_POSITIVO_QA.md. B tambien fue autorizado y sus diez casos aprobaron con rollback: ver RESULTADOS_008_NEGATIVOS_QA.md. C aprobo en una nueva ejecucion autorizada tras el cierre manual de la Caja preexistente; rollback e integridad de 18 tablas verificados. El bloqueo anterior permanece documentado. Ver RESULTADOS_VENTAS_CAJA_008_QA.md. D sigue PENDIENTE, NO ejecutado. El permiso estructural 008 no autoriza ninguno de estos archivos. Se propone autorizar y completar una etapa antes de solicitar la siguiente.

En cada etapa se debe verificar servidor local esperado, base exacta ForzaSuplementosDB_QA, marca Forza-QA-Aislada-v1, estructura 18 tablas/50 SP, ausencia de transaccion previa o incompatible y contratos instalados. Conservar evidencia privada, conteos/huellas antes y despues, verificar el rollback y @@TRANCOUNT=0. Solo los registros ficticios del runner pueden modificarse. Los IDENTITY pueden avanzar y no se reseedean. Ante cualquier error o rollback no comprobable, detenerse sin reintentar, reparar ni ejecutar reversiones adicionales. Ninguna etapa autoriza cambiar credenciales/PBKDF2, escribir otras bases, aplicar migraciones ni hacer push.

## A. Compra e Inventario positivos: ejecutado y aprobado bajo permiso separado

Texto propuesto:

Autorizo una sola ejecucion exclusivamente de tests/qa/Avance_Transaccional_QA.sql en QA verificada. Permito crear el proveedor/producto ficticios del archivo dentro de la transaccion, registrar compra de 3 unidades a costo 2.50 y su reintento con el mismo GUID, verificar un solo movimiento +3 y precio 99; aplicar ajuste ficticio -1 con motivo y repetir su GUID para verificar un solo movimiento 3 a 2; establecer minimo 3; revertir el bloque y verificar ausencia de proveedor/producto/compra/detalle/movimientos ficticios, integridad y transaccion cero. No permite operaciones de Caja, ventas ni otros runners.

Objetivo: probar realmente la integracion Compra/Movimientos y Ajuste/Minimo, sin alterar datos persistidos del proyecto.

## B. Diez negativos de Compra e Inventario: ejecutados y aprobados bajo permiso separado

Texto propuesto:

Autorizo una sola ejecucion exclusivamente de tests/qa/Negativos_Compras_Inventario_Preparados.sql en QA verificada. Permito las altas/modificaciones de fixtures nuevos dentro de cada transaccion para provocar los diez rechazos previstos: producto/proveedor inactivo, cantidad cero, costo con decimales excesivos, overflow de stock, GUID vacio, salida insuficiente, motivo vacio, stock obsoleto y rol administrador. Cada caso debe devolver el error esperado y revertirse, conservando conteos/datos y sin token ni transaccion abiertos. No permite otras suites, ventas u operaciones de Caja.

Los valores extremos o estados inactivos se aplican exclusivamente a productos/proveedores nuevos del ensayo, no a usuarios o productos preexistentes.

## C. Ventas, pagos y Caja positivos: aprobado bajo nueva autorizacion separada

Texto propuesto:

Autorizo una sola ejecucion exclusivamente de tests/qa/Ventas_Caja_008_Rollback_Preparado.sql en QA verificada. Permito crear los productos ficticios de stock 3 previstos y abrir/cerrar exclusivamente las tres sesiones NUEVAS del ensayo, registrar nueve ventas ficticias (efectivo, transferencia y tarjeta por sesion), verificar pagos, asociacion a sesion, descuento unico y un movimiento por venta/producto, efectivo esperado 10 frente a total vendido 30 y diferencias de cierre -1/0/+1. Debe abortar si hay una Caja abierta previa, sin cerrarla o modificarla. Revertir todo y verificar conteos, integridad y ausencia de productos, ventas, pagos, detalles, movimientos o sesiones del ensayo. No permite compras, ajustes ni otros archivos.

Este permiso implica explicitamente operaciones de Caja solo sobre sesiones ficticias nuevas; la autorizacion estructural NO las incluia.

## D. Ocho negativos de Ventas y Caja: permiso posterior separado

Texto propuesto:

Autorizo una sola ejecucion exclusivamente de tests/qa/Negativos_Ventas_Caja_008_Preparados.sql en QA verificada. Permito crear exclusivamente productos/sesiones ficticios del archivo para probar venta sin Caja, stock insuficiente, total incorrecto, medio invalido, apertura duplicada, importe inicial negativo, cierre duplicado y rechazo de gerente en Caja. Abortar si hay una Caja abierta previa y no modificarla. Cada bloque debe producir el error esperado y revertirse completamente, verificando conteos, ausencia de token/sesiones y transaccion cero. No permite otras compras, ventas, ajustes, usuarios o suites.

## Fuera de estas cuatro autorizaciones

Concurrencia necesita su propio permiso y fixture: Probar-Concurrencia-Compras-Preparada.ps1 requiere un proveedor QA persistido identificado y el producto de qa.Fixtures. Actualmente no hay proveedor persistido tras los rollback, por lo que ese requisito debe resolverse y revisarse antes de autorizarlo. No se ejecutara como parte implicita de A-D.

Las pruebas visuales humanas se planifican despues de los ensayos SQL aprobados, desde el lanzador QA protegido. No se solicita autorizacion conjunta de A-D ni se asume aprobacion de una etapa por aprobar otra.
