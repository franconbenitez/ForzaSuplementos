# Preparación aislada de ForzaSuplementosDB_QA

## Portabilidad y privacidad de esta copia

El identificador del equipo de validación fue anonimizado en la documentación y la evidencia publicable. La evidencia original y el historial previo se conservan únicamente en copias locales excluidas de Git. `source-schema.json` conserva la estructura sin filas, con el servidor anonimizado; por eso su hash actual no es el hash del snapshot local original registrado durante QA.

Antes de usar las herramientas en otra computadora, copiar `config/qa.example.config` como `config/qa.config`, verificar la instancia mediante lectura y completar `servidor`/`servidorEsperado`. La copia privada no se versiona. Los SQL QA exigen la variable SQLCMD `QaExpectedServer`; el preparador la obtiene de esa configuración, la valida y no elimina guardas. Sin un destino configurado, la ejecución debe fallar de forma segura. No se realizaron operaciones SQL al preparar esta publicación.

Estado actualizado al 26/10/2026: QA fue creada y las migraciones se aplicaron con autorización expresa. Los 18 ensayos automáticos aprobaron, al igual que la prueba adicional de las DLL VB contra SQL QA. Ver `docs/RESULTADOS_QA.md` y `docs/INICIAR_QA_WINDOWS.md`. Los apartados de preparación siguientes conservan el procedimiento reproducible; no volver a crear una QA existente.

## Destino comprobado en lectura

- Alias de conexión: `localhost`.
- Servidor: `SERVIDOR_QA_VERIFICADO`; instancia predeterminada: `MSSQLSERVER`.
- Versión detectada: `17.0.1000.7`; collation de origen: `Modern_Spanish_CI_AS`.
- Antes de preparar, `DB_ID('ForzaSuplementosDB_QA')` devolvió NULL. Después se creó únicamente QA. El snapshot de metadatos del origen permanece idéntico; no se ejecutó DML/DDL sobre el origen.
- Se consultaron exclusivamente `SERVERPROPERTY`, `DB_NAME`, `DB_ID` y catálogos/definiciones; no se seleccionaron filas de negocio ni contraseñas.

La separación es por base de datos independiente en la instancia detectada: no es una instancia física distinta. No hay sinónimos, enlaces ni referencias entre las tablas QA y la base original. Los recursos del motor son compartidos.

## Revisión de migraciones

001–003 conservan las columnas auditadas: importes decimal(10,2), IDs int, fechas datetime y nulos de sesión/cierre. El DAL coincide con los seis contratos publicados en `tests/qa/contratos.json`: nombres, tipos, tamaños, precisión, escala y OUTPUT. Las pruebas comprobarán además esos contratos mediante DeriveParameters una vez que QA exista.

No hay DELETE, TRUNCATE, recreación de tablas originales ni actualización de ventas históricas. 001 agrega PagosVenta e índices; 002 crea SP/vista; 003 cambia dos SP antiguos para rechazar escrituras parciales y publica la venta atómica. Esto obliga a coordinar ejecutable y SQL; no se debe probar 003 directamente sobre la base habitual.

Se corrigió la dependencia de opciones implícitas del cliente agregando SET explícitos a 001–003 y sus copias: ANSI_NULLS, QUOTED_IDENTIFIER, ANSI_PADDING, ANSI_WARNINGS, ARITHABORT y CONCAT_NULL_YIELDS_NULL ON; NUMERIC_ROUNDABORT OFF. Son las [opciones requeridas para índices filtrados](https://learn.microsoft.com/en-us/sql/t-sql/statements/create-index-transact-sql?view=sql-server-ver17#filtered-indexes). No se modificaron opciones de servidor ni de la base original.

Se revisaron transacciones, manejo de errores, bloqueo común de apertura/venta/cierre, actualización condicional de stock, precio vigente, pago único y asociación de sesión. No se detectaron nuevas incompatibilidades de firma ni escrituras a históricos. Estas conclusiones son de revisión y sintaxis; no equivalen a pruebas transaccionales ejecutadas.

El SP original `sp_Backup_Generar` contiene una referencia fija a la base original y `WITH INIT`. En la estructura QA se reemplaza por un rechazo explícito: no realiza backups ni escribe archivos. Los demás SP exportados se verifican para rechazar referencias a otras bases, BACKUP/RESTORE, rutas o acceso externo. Las migraciones originales no contienen referencias fijas a la base habitual ni rutas físicas; las copias QA agregan su destino obligatorio.

## Archivos y orden

1. `000_CrearBase_QA.sql`: requiere master en el servidor auditado y que QA no exista. No usa rutas, ATTACH, REPLACE, MDF/LDF/BAK proporcionados ni elimina bases. Un conflicto de archivo hace fallar CREATE, nunca sobrescribe archivos.
2. `010_EstructuraOriginal_QA.sql`: nueve tablas, diez FK y veintiún SP de negocio obtenidos de metadatos, sin filas ni diagramas. Requiere QA vacía; crea una marca de entorno y no sobreescribe un esquema existente. Backup físico deshabilitado.
3. `020_DatosFicticios_QA.sql`: perfiles y usuarios sintéticos, cliente/categoría/producto ficticios y una venta histórica sintética con idSesion NULL. `qa.Fixtures` guarda solamente sus IDs. Las claves iniciales se generan aleatoriamente en QA y nunca se copian ni se imprimen.
4. `001_Caja_Pagos_QA.sql`.
5. `002_Caja_Procedimientos_QA.sql`.
6. `003_Ventas_Caja_Stock_QA.sql`.

Las copias se generan offline con `Generar-Archivos-QA.ps1` y llevan hash SHA256 de su migración fuente. Cada lote verifica servidor/base **antes** de cambiar objetos. Los CREATE OR ALTER se ejecutan dinámicamente después de la guarda, respetando su requisito de primera instrucción del lote. No hay USE en los scripts. Ejecutar archivos completos, nunca fragmentos que omitan guardas.

Las tres migraciones QA exigen además la marca de entorno en cada lote. La inspección adicional no encontró índices de negocio fuera de PK/UQ, triggers ni vistas que requirieran exportación; la única función adicional era interna de diagramas y se excluyó. Los SP transaccionales se llaman sin una transacción externa: su CATCH puede revertir una transacción ambiente completa; el runner no envuelve sus llamadas en una transacción global.

`source-schema.json` es un snapshot anonimizado de definiciones, no de datos; contiene la definición original de backup solo para trazabilidad. No es un script ejecutable. `Exportar-Metadatos.ps1` lee exclusivamente catálogos de la instancia indicada con -SourceServer y guarda su salida solo en `sql/qa/private/source-schema.local.json`, ignorado. No sobrescribe el snapshot publicable ni se usa al preparar o probar QA.

## Comandos exactos, desde la raíz del proyecto

La opción ExecutionPolicy RemoteSigned se limita al proceso hijo, para ejecutar estos archivos locales; no establece una política permanente ni evita políticas de grupo.

Verificación predeterminada, sin escrituras:

```powershell
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\scripts\qa\Preparar-QA.ps1
```

**Solo después de autorización**, creación + estructura + datos ficticios + migraciones:

```powershell
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\scripts\qa\Preparar-QA.ps1 -AutorizarEscrituras
```

El orquestador comprueba identidad del servidor/base mediante lectura antes de cada archivo, usa `sqlcmd -b` y detiene la secuencia al primer error. Si QA ya existe, rechaza recrearla. `-Reanudar -AutorizarEscrituras` solo admite una QA ya marcada y permite reejecutar datos iniciales/migraciones sin reemplazar fixtures. No repara automáticamente una creación de esquema fallida.

Equivalentes SQLCMD, **también pendientes de autorización**, en este orden:

```powershell
Import-Module .\scripts\qa\QA.Common.psm1
$qa = Get-QaConfig
sqlcmd -S $qa.Server -v "QaExpectedServer=$($qa.ExpectedServer)" -d master -E -C -b -i .\sql\qa\000_CrearBase_QA.sql
sqlcmd -S $qa.Server -v "QaExpectedServer=$($qa.ExpectedServer)" -d ForzaSuplementosDB_QA -E -C -b -i .\sql\qa\010_EstructuraOriginal_QA.sql
sqlcmd -S $qa.Server -v "QaExpectedServer=$($qa.ExpectedServer)" -d ForzaSuplementosDB_QA -E -C -b -i .\sql\qa\020_DatosFicticios_QA.sql
sqlcmd -S $qa.Server -v "QaExpectedServer=$($qa.ExpectedServer)" -d ForzaSuplementosDB_QA -E -C -b -i .\sql\qa\001_Caja_Pagos_QA.sql
sqlcmd -S $qa.Server -v "QaExpectedServer=$($qa.ExpectedServer)" -d ForzaSuplementosDB_QA -E -C -b -i .\sql\qa\002_Caja_Procedimientos_QA.sql
sqlcmd -S $qa.Server -v "QaExpectedServer=$($qa.ExpectedServer)" -d ForzaSuplementosDB_QA -E -C -b -i .\sql\qa\003_Ventas_Caja_Stock_QA.sql
```

En SSMS, seleccionar expresamente master solo para 000 y QA para el resto; activar **Consulta > Modo SQLCMD**. Ejecutar primero `SELECT SERVERPROPERTY('ServerName'), SERVERPROPERTY('InstanceName'), DB_NAME();` y confirmar el destino. Los scripts vuelven a comprobarlo y fallan en cualquier otra base. El orquestador es preferible porque ya incorpora la comprobación previa de lectura.

## Pruebas reproducibles

Sin SQL:

```powershell
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\tests\qa\Validar-Preparacion-SinSql.ps1
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\tests\Probar-Caja-SinSql.ps1
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\tests\qa\Invoke-Caja-QA.ps1
```

El primer comando analiza SQL exterior e interior dinámico, PowerShell, guardas, hashes, seis contratos DAL y conexión habitual/casos QA inválidos sin abrir SQL. El último solo lista los 18 casos y no abre conexiones.

Después de aplicar SQL en QA y **con autorización de escritura**, ejecutar:

```powershell
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\tests\qa\Invoke-Caja-QA.ps1 -Ejecutar -AutorizarEscrituras
```

Los 18 casos están en `tests/qa/PLAN_PRUEBAS.md` y `casos.json`, con estado inicial, operación, esperado, SQL de comprobación y resultado real pendiente. El runner comprobará contratos del servidor, creará productos separados por ejecución y conservará registros para inspección. No borra ni resetea datos. Requiere empezar sin caja abierta; en caso de fallo conserva el estado para diagnosticarlo y no cierra sesiones ajenas automáticamente.

La prueba de rollback crea solo en QA un trigger inerte salvo por SESSION_CONTEXT de esa conexión de ensayo, provoca el error después del descuento de stock y compara snapshots. Limpia esa bandera en finally; el trigger no bloquea otras conexiones. La carrera usa dos conexiones asíncronas retenidas tras una barrera transaccional: exige una venta y un rechazo, stock final cero y una sola cabecera. No es una prueba de carga.

Los resultados reales, IDs de contexto y consultas se guardan en `tests/artifacts/qa/resultado-*.json`, excluido de Git. Los 18 casos se ejecutaron dos veces con éxito y una copia de la última evidencia está versionada en `docs/qa/EVIDENCIA_18_CASOS.json`. No copiar al origen datos, triggers ni fixtures de QA.

## Windows Forms y credenciales ficticias

Las pruebas automáticas validarán SQL, pero la interacción visual sigue siendo manual. Antes de probar, compilar la solución, preparar QA y terminar el runner automático sin sesiones abiertas. Luego, solo con autorización para escribir claves ficticias:

```powershell
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\scripts\qa\Establecer-Clave-QA.ps1 -AutorizarEscrituras
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\scripts\qa\Iniciar-App-QA.ps1
```

La clave se introduce como SecureString, no aparece en argumentos/salida ni se guarda en archivos. Solo actualiza los cuatro usuarios activos ficticios referenciados por qa.Fixtures. Usuarios de prueba: `qa_vendedor`, `qa_vendedor2`, `qa_admin`, `qa_gerente`. No son identidades reales.

El lanzador fija FORZA_ENTORNO y FORZA_QA_CONFIG únicamente en el proceso hijo. `config/qa.config` no contiene secretos. Conexion.vb conserva la cadena habitual intacta; solo usa QA si el modo está seleccionado expresamente, verifica servidor/base/marca antes de entregar conexiones y nunca vuelve al origen si la configuración QA falla. FrmPrincipal identifica QA en el título. No usar F5 normal para ensayos: usar el lanzador y, si hace falta depurar, **Depurar > Asociar al proceso** desde Visual Studio al PID informado.

Comprobar manualmente: visibilidad de Caja/Ventas por perfil, botones según estado, selector obligatorio de medio, grilla de carrito, filtros de fecha, selección y reporte, formato decimal local, confirmación de cierre, actualización después de vender y mensajes de error. Validar inicial500 + una venta100 por cada medio = esperado600, cerrar con590 = diferencia-10. Verificar desde SSMS QA con las consultas del plan. No usar ni modificar la conexión habitual.

## Límites de la preparación

Las pruebas SQL de los 18 casos y la integración VB ya se ejecutaron. La doble apertura se probó secuencialmente y la concurrencia de última unidad con dos conexiones; siguen fuera del alcance ejecutado la doble apertura simultánea y la carrera simultánea cierre/venta. La interacción visual requiere el ensayo manual indicado. La autenticación original con contraseña recuperable y ausencia de idempotencia de ventas siguen pendientes de otra tarea. Si una escritura pierde su respuesta, consultar el historial antes de repetirla. El aislamiento protege del destino accidental, no de un administrador que edite guardas o ejecute comandos distintos.
