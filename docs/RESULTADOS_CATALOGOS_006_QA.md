# Resultados reales: 17 ensayos de Catalogos 006

Fecha local: 2026-10-31. Repositorio ForzaSuplementos_GitHub. Autorizacion expresa limitada al archivo tests/qa/Catalogos_006_Rollback_Preparado.sql y sus datos ficticios con rollback.

## Ejecucion y seguridad

El archivo SQL autorizado se ejecuto una sola vez, sin modificar sus casos ni agregar escrituras SQL. El nuevo wrapper scripts/qa/Ejecutar-006-Ensayos.ps1 requiere -AutorizarEnsayos006, valida destino y dependencias, resuelve las variables SQLCMD y elimina solo la directiva de cliente :on error exit para ejecutar el mismo lote mediante SqlCommand en una conexion controlada. Nunca ejecuta otros archivos SQL de escritura ni reintenta. La evidencia detallada permanece en private/006-ensayos-*, ignorada por Git.

Antes de ejecutar se comprobaron servidor local esperado, base exacta ForzaSuplementosDB_QA, marca Forza-QA-Aislada-v1, 15 tablas/43 procedimientos, FK confiable, columna nullable, defaults, tres CHECK y cinco indices propios de 006. Los seis cuerpos de SP coincidieron con fuente. Se comprobo @@TRANCOUNT=0 y ausencia de otras transacciones de usuario sobre QA, sin procesos de la aplicacion del repositorio abiertos.

## Resultado individual

**17 aprobados, 0 fallidos, 0 bloqueados.** Los siguientes estados provienen de las 17 filas emitidas por el runner tras verificar sus condiciones; no son resultados estimados.

- Caso 1: Alta proveedor devuelve ID. **APROBADO**.
- Caso 2: Modificacion y baja logica proveedor sin duplicar. **APROBADO**.
- Caso 3: Reactivacion proveedor. **APROBADO**.
- Caso 4: Alta marca devuelve ID. **APROBADO**.
- Caso 5: Modificacion baja y reactivacion marca sin duplicar. **APROBADO**.
- Caso 6: Asociacion conserva ID precio y stock. **APROBADO**.
- Caso 7: Busquedas y contratos de columnas. **APROBADO**.
- Caso 8: Administrador no guarda proveedores. **APROBADO**.
- Caso 9: Vendedor no guarda marcas. **APROBADO**.
- Caso 10: Administrador no consulta proveedores. **APROBADO**.
- Caso 11: Vendedor no consulta marcas. **APROBADO**.
- Caso 12: Marca inactiva rechazada. **APROBADO**.
- Caso 13: Producto inactivo rechazado. **APROBADO**.
- Caso 14: Marca duplicada rechazada. **APROBADO**.
- Caso 15: CUIT invalido rechazado. **APROBADO**.
- Caso 16: Modificacion de ID inexistente rechazada. **APROBADO**.
- Caso 17: Actor nulo no asocia. **APROBADO**.

El SQL exacto y sus consultas de verificacion se conservan sin cambios en tests/qa/Catalogos_006_Rollback_Preparado.sql. Los rechazos comprobaron los numeros esperados de error (51603 permisos, 51604 marca inactiva, 51605 producto inactivo, 2627 duplicado, 51606 CUIT invalido y 51602 registro inexistente).

## Rollback e integridad

Se verificaron los 11 bloques transaccionales: uno agrupa los siete casos positivos y diez corresponden a los rechazos. El runner revierte cada bloque, exige conteos originales de Productos/Proveedores/Marcas, ausencia de su token unico y @@TRANCOUNT=0. El wrapper comprobo ademas cero registros con prefijo QA006 en esas tablas, conteos iguales y huellas agregadas iguales de las 15 tablas completas antes/despues, en la misma conexion. No se exportaron filas ni valores de las huellas.

No quedaron productos, proveedores ni marcas ficticios del runner, diferencias inesperadas ni transacciones de prueba abiertas. No se tocaron usuarios o contrasenas. Los IDENTITY pueden avanzar pese al rollback; se acepto ese efecto y no se ejecutaron DBCC CHECKIDENT ni reseeds.

Estado final: 15 tablas, 43 SP, 13 FK, 23 indices y 9 CHECK. PBKDF2 permanece inactivo, CredencialesUsuario vacia, 007-008 no aplicadas. No hubo fallos, reparaciones, reversiones adicionales ni reintentos; no se modificaron otras bases ni se hizo push.

## Compilacion, regresion y siguiente paso

Compilacion Debug/AnyCPU correcta y 655 comprobaciones de regresion aprobadas, mas 65 analisis estaticos SQL correctos; registro privado private/regresion-006-ensayos.log. No ejecutan otras suites de escritura. La validacion visual humana de Proveedores/Marcas no se declara completada.

La revision de 007 esta documentada en PREPARACION_007_COMPRAS_QA.md y su preflight de lectura preservo las definiciones existentes. El siguiente paso es autorizar por separado el despliegue estructural 007; los ensayos de compras requieren otra autorizacion.

Para ver los catalogos vacios, iniciar FORZA SUPLEMENTOS - QA (GITHUB), ingresar como gerente y abrir Proveedores/Marcas. No repetir automaticamente estos ensayos ni guardar registros manuales dentro de esta autorizacion. En SSMS, tras comprobar servidor/base/marca, consultar los metadatos y los conteos de Productos/Proveedores/Marcas sin ejecutar nuevas escrituras.
