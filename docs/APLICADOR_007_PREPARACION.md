# Aplicador estructural 007 preparado: sin despliegue

Actualizacion posterior: el intento autorizado de despliegue fallo por la declaracion de CK_DetalleCompras_Subtotal. 007 no esta instalada. Ver [RESULTADOS_007_ESTRUCTURAL_QA.md](RESULTADOS_007_ESTRUCTURAL_QA.md). Este documento conserva la preparacion anterior al intento.

Fecha local: 2026-10-31. Repositorio exclusivo ForzaSuplementos_GitHub. Complementa PREPARACION_007_COMPRAS_QA.md. No se ejecuto 007 ni una suite SQL de escritura en esta tarea.

## Estado real verificado

El aplicador se ejecuto solo con -VerificarSoloLectura. Verifico servidor local esperado, base exacta ForzaSuplementosDB_QA, marca Forza-QA-Aislada-v1, @@TRANCOUNT=0, ausencia de otras transacciones de usuario QA, 15 tablas, 43 SP, 13 FK, 23 indices y 9 CHECK. Los 15 contratos de 005/006 coinciden con las fuentes; PBKDF2 inactivo y CredencialesUsuario vacia. No existen objetos de 007 ni 008.

Preservo definiciones (incluidas opciones ANSI), conteos, columnas/tipos, indices, restricciones y relaciones en private/007-preflight-* y las definiciones de dependencia en private/007-revision-*. Git ignora esas carpetas. No se exportaron filas ni claves. La huella SHA-256 de cada tabla solo vive en memoria y no se registra: se compararon dos lecturas de las 15 tablas, incluidas tablas vacias.

## Archivos preparados y controles

- scripts/qa/Aplicar-007-Estructura-QA.ps1: exige permiso especifico o modo solo lectura, ambos mutuamente excluyentes. Sin uno de ellos rechaza antes de conectar. No mata procesos. El modo de lectura retorna antes de resolver o llamar sqlcmd.
- scripts/qa/007.Validacion.psm1: funciones compartidas de validacion de destino, baseline, huella de integridad y alcance SQL. La huella del texto normalizado LF/CRLF fija exactamente la version revisada del SQL. Cualquier cambio requiere nueva revision y actualizacion explicita de esa huella; no se admite SQL adicional. Rechaza operaciones DML fuera de las definiciones.
- tests/qa/Verificar-007-Lectura.ps1: verificacion futura de 17 tablas/46 SP/17 FK/28 indices/13 CHECK, tablas nuevas vacias, FK y CHECK habilitados/confiables, default de fecha, claves e inclusiones de los cinco indices, parametros y cuerpos de los tres SP. No llama Registrar. No se ejecuto porque 007 aun esta ausente.
- tests/qa/Probar-Aplicador007-SinSql.ps1: 28 comprobaciones offline de rechazo/aceptacion de destino, cambios de SQL, estado parcial/incompatible, autorizacion, modos y sintaxis PowerShell. Integrado en scripts/Validar-Avance.ps1.
- tests/qa/Compras_007_Rollback_Preparado.sql: reforzado, preparado y NO ejecutado. Requiere baseline 007 sin 008 y fixtures inequívocos. Valida IDs y una sola compra al repetir GUID; total/detalle exactos; stock 3 y precio de venta 99; historial/detalle; revierte y comprueba conteos, ausencia del token, operacion/detalles de prueba y @@TRANCOUNT=0. La comparacion del segundo ID ahora rechaza tambien NULL, que antes podia escapar por logica ternaria SQL.
- tests/qa/Probar-Modulos-Pendientes-Lectura.ps1: reconoce el futuro baseline 007 para probar disponibilidad sin guardados. La rama 006 actual fue ejecutada correctamente; la rama 007 queda pendiente del despliegue.

## Alcance y contratos revisados

Se mantiene sin cambios sql/qa/007_Compras_QA.sql: crea exclusivamente Compras, DetalleCompras y sp_Compras_Registrar, sp_Compras_Historial, sp_Compras_Detalle, con cuatro FK, cinco indices (dos PK, dos UQ, un indice de fecha/proveedor), cuatro CHECK y default SYSDATETIME para fecha. No ejecuta Registrar, no inserta compras y no modifica Productos al desplegar. Los INSERT/UPDATE de negocio estan dentro de la definicion del SP y solo ocurriran al invocarlo posteriormente.

FrmCompras conserva GUID al fallar la confirmacion y bloquea edicion mientras envia; proveedor/producto deben estar activos. CompraBLL exige gerente, valida cantidades/costos/duplicados y toma snapshot del pedido. CompraDAL envia @idActor, @idProveedor, @operacion y @detalles con tipos correctos y XML detalles/item con producto/cantidad/costo; exige IdCompra positivo. Historial y Detalle coinciden con sus parametros y grillas. No se modifico VB, permisos, estetica, Login, Caja o Ventas.

Idempotencia: en el SP preparado, el bloqueo transaccional Forza.Caja.Unica precede a la consulta de GUID con UPDLOCK/HOLDLOCK. Mismo GUID/actor/proveedor/huella XML devuelve el ID existente antes de insertar o sumar stock. Otro contenido para el GUID se rechaza. La huella es de la serializacion XML exacta, no una equivalencia semantica universal. La UI y DAL preservan pedido/formato para reintentar sin cambios.

Costos positivos, maximo dos decimales y limites numericos se validan en BLL y en SQL antes de convertir XML. Los costos y subtotales se guardan en DetalleCompras; no se actualiza Productos.precio. El stock se incrementa una sola vez por la operacion confirmada. Esto es analisis offline, no prueba de ejecucion SQL ni de concurrencia real de Compras.

## Transaccion, integridad y recuperacion

Cada lote de 007 exige base/servidor/marca. El SQL revisado usa SET XACT_ABORT ON, rechaza transaccion externa, inicia una transaccion que atraviesa GO y exige @@TRANCOUNT=1 antes de COMMIT. El aplicador futuro llama una sola vez a sqlcmd -E -C -b, con base fija QA y archivo fijo 007; no encadena otras migraciones. Verifica hash antes de ejecutar. No hay reintento automatico.

El preflight bloquea tablas/SP parciales, residuos de indices, totales inesperados, seguridad activada y transacciones incompatibles. Una instalacion completa tambien se rechaza: no se usa como reparador ni para repetir despliegues. Los IF NOT EXISTS del SQL no justifican aceptar un esquema parcial arbitrario.

Las huellas usan COALESCE de XML vacio a varbinary vacio antes de HASHBYTES para producir siempre 32 bytes. Despues del despliegue futuro se comparan todas las columnas preexistentes de las 15 tablas, conteos y las 43 definiciones/opciones anteriores. Se exige que tablas nuevas sigan vacias, sin compras ni variaciones de stock o precios.

Si sqlcmd falla se conserva log y se inspecciona el estado con lecturas, sin reparacion, ROLLBACK adicional ni reintento. La transaccion no confirmada de una conexion cerrada se revierte por SQL Server; debe comprobarse mediante objetos/datos reales. @@TRANCOUNT=0 en una conexion nueva por si solo no prueba la integridad de ese rollback. Un fallo posterior al COMMIT detiene la etapa; cualquier reversion necesita autorizacion independiente. No se ejecutaran DROP DATABASE, restauraciones, 008, activacion PBKDF2 ni modificaciones de otras bases.

## Resultados y pasos exactos

Compilacion Debug/AnyCPU correcta. Regresion: 683 comprobaciones aprobadas (655 existentes y 28 nuevas), mas 65 lotes/procedimientos SQL analizados estaticamente, incluido el fixture modificado. Registro privado: private/regresion-preparacion-007.log. Despues de la ultima adaptacion de disponibilidad se repitieron sus 21 comprobaciones de lectura: aprobadas. El preflight completo del aplicador y sus huellas se ejecuto en modo lectura y paso; los cuerpos de las tres SP nuevos y los CHECK/indices aun no se enlazaron ni probaron en SQL Server, porque no estan instalados.

Desde Windows PowerShell en la raiz del repositorio, permitido ahora:

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File scripts/qa/Aplicar-007-Estructura-QA.ps1 -VerificarSoloLectura
```

NO ejecutar hasta nueva autorizacion:

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File scripts/qa/Aplicar-007-Estructura-QA.ps1 -AutorizarEstructura007
```

No iniciar F5 sin el entorno protegido. Para consultar el estado actual usar FORZA SUPLEMENTOS - QA (GITHUB): Compras debe seguir bloqueado y Catalogos disponible para gerente. En SSMS, tras verificar servidor/base/marca, consultar sys.tables/sys.procedures; deben seguir siendo 15/43. No ejecutar 007 desde SSMS por cuenta de esta preparacion.

## Autorizacion exacta propuesta

Autorizo exclusivamente aplicar sql/qa/007_Compras_QA.sql mediante scripts/qa/Aplicar-007-Estructura-QA.ps1 -AutorizarEstructura007 en ForzaSuplementosDB_QA de la instancia local verificada, con marca Forza-QA-Aislada-v1. El alcance es crear Compras y DetalleCompras, los tres SP previstos, sus cuatro FK, cinco indices, cuatro CHECK y default de fecha, conservar metadata previa y ejecutar verificaciones posteriores solo de lectura, incluida integridad de datos anteriores. No autoriza registrar compras, modificar stock o precios, ejecutar ensayos SQL de escritura, aplicar 008, activar PBKDF2, cambiar contrasenas, escribir en otras bases ni hacer push. Ante error detenerse, inspeccionar el estado sin reparar ni reintentar; una reversion posterior al COMMIT requiere autorizacion separada.
