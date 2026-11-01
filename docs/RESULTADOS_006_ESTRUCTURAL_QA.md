# Resultado actual: 006 aplicada correctamente en QA

Actualizacion posterior: los 17 ensayos fueron autorizados y ejecutados correctamente. Ver [resultados individuales y rollback](RESULTADOS_CATALOGOS_006_QA.md). El resto de este documento conserva el informe del despliegue y sus pendientes en aquel momento.

Fecha local: 2026-10-31. Nuevo intento expresamente autorizado, ejecutado una sola vez desde ForzaSuplementos_GitHub. La incidencia del intento anterior queda registrada mas abajo como antecedente, no como estado actual.

## Despliegue y estructura real

El aplicador corregido confirmo el tratamiento de tablas vacias, destino exacto ForzaSuplementosDB_QA en el servidor local esperado, marca Forza-QA-Aislada-v1, transaccion previa cero, nueve contratos de 005 coincidentes y ausencia total de objetos 006. Conservo definiciones y conteos previos en private/006-preparacion-* y private/006-despliegue-*, ignorados por Git.

sqlcmd ejecuto exclusivamente 006, termino con codigo 0 y el aplicador completo todas sus comprobaciones posteriores. El script posee una unica transaccion entre GO y exige @@TRANCOUNT=1 antes de COMMIT. La conexion de despliegue termino; la comprobacion posterior de lectura devolvio @@TRANCOUNT=0. No se ejecuto rollback, reversion adicional ni un segundo intento en esta autorizacion.

QA contiene realmente 15 tablas (14 dbo y qa.Fixtures), 43 procedimientos, 13 claves foraneas, 23 indices y 9 restricciones CHECK.

- Proveedores: PK identity, nombre/razonSocial obligatorios, CUIT opcional con formato y unicidad filtrada, activo con default 1.
- Marcas: PK identity, nombre unico/no vacio, activo con default 1.
- Productos.idMarca: int nullable, FK confiable y habilitada hacia Marcas.idMarca e indice IX_Productos_Marca.
- Seis contratos nuevos instalados y cuerpos comparados con fuente: sp_Comercial_Estado, sp_Proveedores_Buscar, sp_Proveedores_Guardar, sp_Marcas_Buscar, sp_Marcas_Guardar, sp_Marcas_AsociarProducto.
- Cinco indices nuevos y tres CHECK nuevos comprobados. Defaults de ambas tablas verificados como 1.

Proveedores y Marcas permanecen vacias y los productos existentes sin marca asignada. Las 37 definiciones de SP previos se conservaron sin cambios. Los conteos y las huellas agregadas de todas las columnas preexistentes de las 13 tablas previas coincidieron antes/despues; incluye usuarios, contrasenas, productos, precios, stock, ventas y detalles. Las huellas solo vivieron en memoria: no se exportaron filas ni valores derivados. La nueva columna nullable se excluyo intencionalmente de la comparacion del esquema anterior.

PBKDF2 sigue desactivado y CredencialesUsuario vacia. No se aplicaron 007-008, no se modificaron otras bases ni se hizo push.

## Verificaciones y pruebas

Verificar-006-Lectura.ps1 comprobo estructura, FK, defaults, seguridad inactiva y transaccion previa cero. Ejecuto solo los SP de disponibilidad y busqueda: Catalogos disponible; Compras/Inventario no disponibles; busquedas de Proveedores/Marcas para gerente devuelven cero filas sin errores. No ejecuto Guardar ni Asociar.

La prueba de disponibilidad se adapto unicamente para reconocer 006 desplegada: debe habilitar editores de catalogos para gerente y mantener Compras/Inventario bloqueados; administrador y vendedor no abren estos formularios. No se invocan botones de guardado. Compilacion Debug/AnyCPU correcta; 655 comprobaciones de regresion aprobadas y 65 analisis estaticos SQL correctos. Registro privado: regresion-006-aplicada.log.

Inventario y diagrama ER actualizados mediante metadatos reales. Sin anomalias en este intento. La validacion visual humana y la integracion de escritura aun no se consideran aprobadas.

## Proxima autorizacion separada

Los 17 casos de tests/qa/Catalogos_006_Rollback_Preparado.sql NO se ejecutaron. Requieren autorizacion expresa para ejecutar unicamente ese archivo en QA verificada, con datos ficticios nuevos, usando al gerente/otros perfiles fixture sin modificar usuarios existentes. Cubren altas, ediciones, bajas logicas, reactivacion, asociacion, busquedas, perfiles no autorizados y rechazos por inactividad, duplicados, CUIT e ID invalidos.

El runner verifica servidor/base/marca y ausencia de transaccion previa; revierte el bloque positivo y cada caso negativo, verifica errores esperados, conteos, ausencia del token ficticio y @@TRANCOUNT=0. Los contadores IDENTITY pueden avanzar pese al rollback; no se reseedean. Ante error o rollback no comprobable debe detenerse, sin reintentos ni reversiones adicionales. No incluye 007-008, PBKDF2, cambios de credenciales, otras bases ni push.

Para inspeccion manual, abrir el acceso directo FORZA SUPLEMENTOS - QA (GITHUB) y consultar como gerente los catalogos vacios. No guardar registros hasta autorizar los ensayos. En SSMS verificar servidor/base/marca y consultar sys.tables, sys.procedures, sys.foreign_keys, sys.indexes y sys.check_constraints; no ejecutar las migraciones otra vez.

---

## Antecedente: primer intento detenido antes de escribir

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
