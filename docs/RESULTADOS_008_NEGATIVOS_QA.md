# Resultado real: diez negativos de Compras e Inventario 008

Fecha local: 2026-11-01. Repositorio exclusivo ForzaSuplementos_GitHub. Autorizacion limitada a una ejecucion de tests/qa/Negativos_Compras_Inventario_Preparados.sql, sin cambiar sus casos.

## Resultado y alcance real

**10 APROBADOS, 0 FALLIDOS, 0 BLOQUEADOS.** El archivo permanecio identico al preparado en HEAD; se comprobo diff limpio del archivo y hash antes de ejecutar. Scripts/qa/Ejecutar-008-Negativos.ps1 ejecuta exclusivamente ese lote una vez, con bandera explicita, sustituyendo variables SQLCMD y retirando solo la directiva de cliente :on error exit. No reintenta ni repara.

Antes de ejecutar se verificaron servidor local esperado, base exacta ForzaSuplementosDB_QA, marca Forza-QA-Aislada-v1 y estructura 18 tablas/50 SP/21 FK/33 indices/17 CHECK. Los 25 contratos vigentes de 005-008 coinciden con fuentes (la ultima definicion reemplaza la anterior cuando corresponde); sin transacciones de usuario QA incompatibles, proceso del EXE del repositorio ni residuos con prefijo QA Negativo. PBKDF2 inactivo y credenciales derivadas vacias.

Precision de alcance detectada antes de ejecutar: el caso 10 del archivo usa sp_Compras_Registrar con administrador, es decir, compra/entrada de inventario. NO llama directamente sp_Inventario_Ajustar o sp_Inventario_Minimo con administrador; no se declara que esas llamadas directas hayan sido probadas por este caso. Se ejecuto el archivo autorizado sin ampliarlo.

## Resultados individuales

- Caso 1: Producto inactivo. **APROBADO**. Error esperado y validado por el runner: `51705`; rollback y ausencia de residuos por caso comprobados.
- Caso 2: Proveedor inactivo. **APROBADO**. Error esperado y validado por el runner: `51704`; rollback y ausencia de residuos por caso comprobados.
- Caso 3: Cantidad cero. **APROBADO**. Error esperado y validado por el runner: `51701`; rollback y ausencia de residuos por caso comprobados.
- Caso 4: Costo con decimales excesivos. **APROBADO**. Error esperado y validado por el runner: `51701`; rollback y ausencia de residuos por caso comprobados.
- Caso 5: Overflow de stock. **APROBADO**. Error esperado y validado por el runner: `51705`; rollback y ausencia de residuos por caso comprobados.
- Caso 6: GUID vacio. **APROBADO**. Error esperado y validado por el runner: `51701`; rollback y ausencia de residuos por caso comprobados.
- Caso 7: Salida sin stock suficiente. **APROBADO**. Error esperado y validado por el runner: `51806`; rollback y ausencia de residuos por caso comprobados.
- Caso 8: Motivo vacio. **APROBADO**. Error esperado y validado por el runner: `51802`; rollback y ausencia de residuos por caso comprobados.
- Caso 9: Stock esperado obsoleto. **APROBADO**. Error esperado y validado por el runner: `51806`; rollback y ausencia de residuos por caso comprobados.
- Caso 10: Administrador no puede registrar compra/entrada de inventario. **APROBADO**. Error esperado y validado por el runner: `51603`; rollback y ausencia de residuos por caso comprobados.

Los errores se capturan dentro del SQL. El runner compara ERROR_NUMBER con el esperado y solo imprime el resultado del caso despues de coincidir y verificar rollback. Los numeros anteriores provienen de esas condiciones aprobadas; no se presentan como excepciones SQL sin capturar del wrapper. El resultado individual y mensajes SQL originales permanecen en private/008-negativos-* ignorado por Git.

## Rollback e integridad

Los diez casos se ejecutaron en transacciones independientes, creando un proveedor y producto nuevos por caso y modificando solo esos fixtures para provocar el rechazo. Los usuarios fixture solo se usaron como actores, sin modificarlos. Ninguna operacion invalida fue confirmada.

Cada caso comprobo el error, revirtio la transaccion prevista cuando seguia activa y exigio @@TRANCOUNT=0, conteos originales de Productos/Proveedores/Compras/DetalleCompras/MovimientosStock y ausencia de token, operacion o movimientos del producto ficticio. El wrapper comprobo adicionalmente al terminar, en la misma conexion, que las huellas de las 18 tablas y sus conteos coinciden antes/despues. Esa comparacion criptografica es global final, no una captura separada de hashes para cada caso. Los valores de las huellas solo vivieron en memoria, no se exportaron.

Estado final: 18 tablas, 50 SP, 21 FK, 33 indices y 17 CHECK; Compras, DetalleCompras y MovimientosStock vacias; cero productos/proveedores del ensayo y cero transacciones abiertas. Usuarios, credenciales, stock/precios y demas datos anteriores conservados. Los IDENTITY pueden avanzar y no se reiniciaron.

No se ejecutaron Ventas/Caja, otros fixtures, migraciones, cambios de PBKDF2/contrasenas, operaciones sobre otras bases, reparaciones o reversiones adicionales. No hubo push ni reintento.

## Compilacion, archivos y limites

Compilacion Debug/AnyCPU correcta. Regresion offline/de lectura: 749 comprobaciones aprobadas y 66 analisis estaticos SQL correctos. Registro private/regresion-008-negativos.log. El unico codigo nuevo es el wrapper acotado a este archivo; se actualizan este informe y los enlaces/estado de autorizaciones. No se modifico VB, SQL de migraciones, casos del fixture ni conexiones.

En Windows consultar mediante FORZA SUPLEMENTOS - QA (GITHUB); no repetir manualmente los casos ni registrar operaciones con esta autorizacion. En SSMS, tras verificar servidor/base/marca, consultar conteos/metadatos y ausencia de fixtures; no ejecutar el runner otra vez. La revision visual humana, las pruebas de Ventas/Caja posteriores a 008, concurrencia y validacion en netbook siguen pendientes.

## Siguiente autorizacion independiente propuesta

Autorizo una sola ejecucion exclusivamente de tests/qa/Ventas_Caja_008_Rollback_Preparado.sql en ForzaSuplementosDB_QA de la instancia local verificada con marca Forza-QA-Aislada-v1 y estructura 008 completa. Permito crear solo los productos ficticios del archivo con stock inicial 3, abrir/cerrar exclusivamente sus tres sesiones nuevas de Caja y registrar nueve ventas ficticias: efectivo, transferencia y tarjeta por sesion. Debe comprobar asociacion venta/sesion, pagos, un descuento y un movimiento por venta/producto, saldos 3 a 2 a 1 a 0, efectivo esperado 10 frente a total 30 y diferencias de cierre -1/0/+1. Si existe una Caja abierta previa, detenerse sin operarla ni cerrarla. Revertir el unico bloque previsto y verificar conteos, integridad, ausencia de productos/ventas/detalles/pagos/movimientos/sesiones ficticios y @@TRANCOUNT=0. Se aceptan avances IDENTITY sin reseed. Ante error detenerse sin reintentar ni reparar. No incluye negativos de Ventas/Caja, otras suites, compras/ajustes, migraciones, PBKDF2, credenciales, otras bases ni push.

Prioridad restante: este positivo de Ventas/Caja, luego su permiso negativo separado, revision manual, preparar/verificar el entorno QA en netbook y repasar los flujos de codigo para el coloquio del 02/11/2026. No se afirma que la netbook haya sido probada.
