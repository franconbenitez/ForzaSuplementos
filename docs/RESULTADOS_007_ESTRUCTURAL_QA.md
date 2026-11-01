# Resultado actual: 007 corregida instalada correctamente en QA

Actualizacion posterior: el ensayo de Compras fue autorizado y aprobado con rollback e integridad comprobados. Ver [RESULTADOS_COMPRAS_007_QA.md](RESULTADOS_COMPRAS_007_QA.md). La autorizacion de estructura 008 sigue pendiente.

Fecha local: 2026-11-01. Segundo intento expresamente autorizado, ejecutado una sola vez desde ForzaSuplementos_GitHub. El antecedente del primer fallo se conserva mas abajo y no representa el estado actual.

## Despliegue real y controles previos

Se ejecuto scripts/qa/Aplicar-007-Estructura-QA.ps1 -AutorizarEstructura007. La huella normalizada coincidio exactamente con D506BFCDAEF58541FA357FA6B16BE838FB783E55788E86E740BAE137E6978EC0. Pasaron el analisis semantico adicional de CHECK, destino/servidor local esperado, base exacta ForzaSuplementosDB_QA, marca Forza-QA-Aislada-v1, dependencias 005/006, transaccion previa cero, ausencia de otras transacciones incompatibles y ausencia de objetos/residuos de 007.

Se preservaron definiciones con opciones ANSI, columnas, indices, relaciones, restricciones y conteos anteriores en almacenamiento privado ignorado por Git (private/007-despliegue-* y private/007-revision-*). Las huellas de datos solo vivieron en memoria; no se exportaron filas ni contrasenas.

sqlcmd ejecuto exclusivamente el archivo 007 corregido, una sola vez, con salida 0. El SQL mantiene una transaccion entre GO y verifica @@TRANCOUNT=1 antes de COMMIT. El aplicador completo las comprobaciones posteriores y guardo resultado.json exitoso. La conexion de despliegue termino; la inspeccion posterior reporto @@TRANCOUNT=0. No hubo error, reintento ni reversion adicional.

## Objetos realmente instalados

QA contiene 17 tablas (16 dbo y qa.Fixtures), 46 procedimientos, 17 FK, 28 indices y 13 CHECK.

- dbo.Compras y dbo.DetalleCompras creadas y vacias: cero compras y cero detalles.
- sp_Compras_Registrar, sp_Compras_Historial y sp_Compras_Detalle instalados. Sus cuerpos y parametros se compararon con el SQL/DAL previstos y coincidieron.
- Las cuatro FK y cuatro CHECK nuevos estan habilitados y son confiables.
- Se verificaron las dos PK, las dos UNIQUE, el indice IX_Compras_FechaProveedor, sus claves e INCLUDE, y el DEFAULT de fecha SYSDATETIME().
- CK_DetalleCompras_Subtotal fue aceptado efectivamente por SQL Server como restriccion de tabla. Esto verifica su creacion; no equivale a probar compras reales o todas las rutas del SP.

El inventario y el diagrama ER se regeneraron mediante metadatos de QA y reflejan este estado real. No se aplico 008.

## Integridad y limites de prueba

Los conteos de las 15 tablas anteriores y sus huellas agregadas de todas las columnas preexistentes coincidieron antes/despues; incluye Usuarios (con sus valores de contrasena), Productos (precios/stock), Ventas/DetalleVentas, PagosVenta y Caja. Tambien coincidieron las 43 definiciones previas y sus opciones ANSI. PBKDF2 sigue inactivo y CredencialesUsuario vacia.

No se invoco sp_Compras_Registrar, no se registraron compras, no se modificaron stock/precios/credenciales y no se ejecutaron fixtures SQL de escritura. No se escribio sobre otras bases. No hubo push.

## Compilacion y regresion

Se adapto exclusivamente la comprobacion de metadata de Probar-007-Numericos-Lectura.ps1 para reconocer el baseline 006 (15/43 y nombres nuevos ausentes) o 007 (17/46 y sus 13 restricciones presentes); sigue rechazando otros estados y exige que sus lecturas no cambien la estructura. El resto de la regresion ya reconoce Compras habilitado y 008 pendiente. No se modifico VB, estetica, permisos ni conexiones.

La compilacion Debug/AnyCPU termino correctamente. La regresion offline/de lectura aprobo sus 707 comprobaciones y 65 analisis estaticos SQL. Registro: private/regresion-007-instalada.log. La validacion visual humana y las operaciones transaccionales de Compras siguen pendientes.

## Autorizacion independiente para el siguiente ensayo

El archivo tests/qa/Compras_007_Rollback_Preparado.sql NO se ejecuto. Para su proxima etapa se solicita autorizar exclusivamente ese archivo sobre QA/instancia/marca verificadas, una sola vez y con sus comprobaciones de rollback.

El ensayo crea un proveedor y producto exclusivamente ficticios, con precio de venta 99 y stock inicial 0. Registra una compra de 3 unidades a costo 2.50 (total 7.50), repite exactamente el GUID y pedido para comprobar que devuelve el mismo ID sin duplicar cabecera/detalle ni sumar stock otra vez, y consulta historial/detalle. El stock del producto nuevo pasa temporalmente a 3; no debe alterar productos ni usuarios preexistentes. Revierte toda la transaccion y comprueba conteos, ausencia del token/operacion/detalles y @@TRANCOUNT=0. Los contadores IDENTITY pueden avanzar y no se restablecen.

Este permiso futuro no incluye 008, otras suites SQL de escritura, PBKDF2, credenciales, otras bases ni push. Ante error o rollback no comprobable debe detenerse sin reintentar ni reparar. Hasta recibirlo no se ejecuta el ensayo.

Para inspeccionar desde Windows: abrir FORZA SUPLEMENTOS - QA (GITHUB), ingresar como gerente y abrir Compras; el modulo ya puede mostrar su interfaz. No confirmar compras manualmente dentro de la autorizacion estructural. En SSMS, tras verificar servidor/base/marca, consultar metadatos y COUNT_BIG de Compras/DetalleCompras (esperado 0/0). No volver a ejecutar la migracion.

---

## Antecedente historico: primer intento fallido

# Resultado del intento autorizado de 007: fallo estructural, sin reintento

Actualizacion local posterior: CHECK corregido y nueva revision preparada, sin segundo intento SQL. Ver [CORRECCION_007_CHECK_Y_REVISION_008.md](CORRECCION_007_CHECK_Y_REVISION_008.md).

Fecha local: 2026-10-31. Repositorio ForzaSuplementos_GitHub. HEAD de entrada 01f3116, arbol limpio.

## Intento y causa exacta

Se ejecuto una sola vez scripts/qa/Aplicar-007-Estructura-QA.ps1 -AutorizarEstructura007, despues de verificar el aplicador protegido, la huella revisada de 007, servidor local esperado, base ForzaSuplementosDB_QA, marca Forza-QA-Aislada-v1, ausencia de transacciones incompatibles e instalacion parcial, dependencias 005/006 y huellas previas de las 15 tablas. Las definiciones y metadatos se conservaron en private/007-despliegue-* y private/007-revision-*, ignorados por Git.

SQL Server rechazo el primer lote de DDL con errores 8141 y 1750: CK_DetalleCompras_Subtotal se declara como CHECK de la columna subtotal, pero referencia cantidad y costoUnitario. SQL Server exige declarar ese CHECK a nivel de tabla. ScriptDom habia aceptado su sintaxis, pero no comprueba esta restriccion semantica durante la creacion real; por eso los analisis offline anteriores no detectaron el defecto.

sqlcmd termino con error; el aplicador guardo el log privado y consulto el estado mediante lectura. No se reintento, no se corrigio SQL ni se ejecuto una reparacion o reversion adicional. El archivo 007 y su huella revisada permanecen sin cambios. Corregir y revisar nuevamente ese archivo sera una etapa local posterior; su nuevo despliegue requerira autorizacion independiente.

## Estado real comprobado despues del error

QA mantiene 15 tablas, 43 procedimientos, 13 FK, 23 indices y 9 CHECK. Compras, DetalleCompras y los tres procedimientos nuevos estan ausentes. No hay instalacion parcial. sqlcmd finalizo su conexion; la conexion posterior de inspeccion reporto @@TRANCOUNT=0. No se afirma que ese contador de una conexion nueva pruebe por si solo el rollback.

Se compararon los archivos previos con consultas equivalentes de metadata, sin exportar filas de negocio:

- Conteos de las 15 tablas: coinciden.
- Las 43 definiciones y sus opciones ANSI: coinciden.
- Las 87 columnas y tipos/nullable/precision/escala: coinciden.
- Los 23 indices: coinciden.
- Las 54 restricciones (incluidos defaults, PK, UQ, CHECK y FK): coinciden.
- Las 13 relaciones FK: coinciden.

El preparador de lectura de 007 se repitio sin escrituras y confirmo que los 15 contratos de 005/006 permanecen iguales, con 007/008 ausentes. PBKDF2 sigue desactivado y CredencialesUsuario contiene cero filas.

El DDL fallo antes de desplegar las definiciones de Compras. El SQL de despliegue no contiene DML fuera de los cuerpos de SP, y sp_Compras_Registrar nunca fue instalado ni invocado. No se registraron compras ni se modificaron stock, precios, ventas, usuarios o contrasenas por esta operacion. La comparacion criptografica completa posterior no se ejecuto, porque el aplicador aborto tras sqlcmd y las huellas previas solo vivian en memoria. La evidencia posterior es la coincidencia de conteos/metadatos/definiciones y el punto exacto del fallo; no se inventa una comprobacion de contenido fila por fila que no se realizo.

Una primera version de la inspeccion privada no interpreto correctamente Import-Clixml (devuelve filas serializadas, no un DataTable). Se ajusto exclusivamente esa lectura local y la comparacion posterior completa de metadata termino correctamente. No fue un segundo intento de migracion ni implico escrituras SQL.

## Pruebas, Git y siguiente paso

No se repitieron compilacion ni regresion despues del error: se respeto la instruccion de detenerse y limitar la actividad SQL a inspeccion. No se ejecutaron ensayos ficticios de Compras, otras suites SQL de escritura, 008, activacion PBKDF2, cambios de credenciales, modificaciones de otras bases ni push.

Solo se agrega este informe y un enlace desde el documento de preparacion para dejar visible el bloqueo conocido. No se modifican VB, configuraciones, migraciones ni el aplicador.

Proximo paso: corregir localmente la declaracion de CK_DetalleCompras_Subtotal a nivel de tabla, volver a revisar el SQL y actualizar la huella normalizada autorizable, agregar una comprobacion offline que detecte CHECK de columna con referencias cruzadas y preparar un nuevo intento de 007. Ese despliegue necesitara una nueva autorizacion explicita. El ensayo tests/qa/Compras_007_Rollback_Preparado.sql sigue bloqueado hasta instalar 007 correctamente y recibir su permiso independiente.

Para verificar manualmente en SSMS, seleccionar QA y comprobar servidor/base/marca; consultar sys.tables y sys.procedures y la ausencia de los cinco objetos de Compras. No ejecutar 007 ni reparar objetos desde SSMS con la autorizacion ya utilizada. El acceso directo protegido puede seguir usando el estado anterior; Compras debe permanecer deshabilitado.
