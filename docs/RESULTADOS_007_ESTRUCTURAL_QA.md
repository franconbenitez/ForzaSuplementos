# Resultado del intento autorizado de 007: fallo estructural, sin reintento

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
