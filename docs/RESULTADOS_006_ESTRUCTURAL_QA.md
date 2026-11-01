# Intento de despliegue 006: detenido antes de escribir

Fecha local: 2026-10-31. Repositorio: ForzaSuplementos_GitHub.

## Resultado exacto

Se invoco el aplicador autorizado con -AutorizarEstructura006. El preflight comprobo servidor local esperado, base exacta ForzaSuplementosDB_QA, marca de aislamiento, transaccion previa cero, nueve contratos de 005 coincidentes, PBKDF2 inactivo y CredencialesUsuario vacia. Conservo las definiciones anteriores en almacenamiento privado. No encontro objetos de 006 ni instalacion parcial.

El aplicador se detuvo al comparar la integridad previa de una tabla vacia: HASHBYTES recibia NULL desde la serializacion XML y ToBase64String no acepta DBNull. El error ocurrio ANTES de la llamada a sqlcmd, antes de BEGIN TRANSACTION de la migracion y antes de cualquier DDL/DML. No se ejecuto 006. No hubo rollback de despliegue que efectuar, ni reversion ni segundo intento.

Se repitio exclusivamente el preparador de lectura para conocer el estado posterior: QA continua con 13 tablas y 37 procedimientos, sin objetos 006, con las nueve definiciones de 005 conservadas y seguridad inactiva. No se escribio en usuarios, contrasenas, productos, precios o stock. No se completa ni se afirma una comparacion integral antes/despues de despliegue, porque la fase previa aborto y el despliegue no tuvo lugar.

## Correccion local y verificacion

El aplicador incorpora ahora una comparacion en memoria de todas las columnas preexistentes de cada tabla, excluyendo la futura columna nueva. La expresion normaliza la serializacion vacia a varbinary vacio antes de HASHBYTES; no exporta filas ni huellas. No se altero el archivo SQL 006 ni se ampliaron sus efectos.

Probar-Integridad006-Lectura.ps1 verifico realmente las huellas de las 13 tablas actuales, su comparabilidad en lecturas consecutivas y un resultado explicitamente vacio. No ejecuto migraciones ni fixtures. Se verifico tambien sintaxis PowerShell del aplicador corregido. Estas lecturas no equivalen a ensayos de alta, baja o asociacion de catalogos.

La compilacion Debug/AnyCPU termino correctamente y las 655 comprobaciones de regresion offline/QA de lectura fueron aprobadas, junto con 65 analisis estaticos SQL. Los resultados se registran en private/regresion-006-detenida.log. No se ejecutaron los 17 ensayos ficticios. No se aplicaron 007-008, no se activo PBKDF2 y no se hizo push ni operaciones sobre otras bases.

## Siguiente autorizacion necesaria

Antes de autorizar los 17 ensayos es necesario renovar expresamente la autorizacion de despliegue 006 mediante el aplicador corregido. Por la instruccion de detenerse ante cualquier error y no reintentar sin permiso, el permiso anterior no se utilizo para un segundo intento. Los 17 ensayos siguen pendientes de autorizacion independiente y de despliegue exitoso.

La proxima confirmacion solicitada es: autorizo reintentar exclusivamente sql/qa/006_Catalogos_QA.sql mediante scripts/qa/Aplicar-006-Estructura-QA.ps1 -AutorizarEstructura006 en QA verificada, con el tratamiento de tablas vacias corregido, verificaciones posteriores de lectura y sin ejecutar fixtures. No autoriza 007-008, PBKDF2, push ni reversion posterior al COMMIT.
