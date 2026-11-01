# Correccion local de 007 y revision estructural de 008

Fecha local: 2026-10-31. Repositorio exclusivo ForzaSuplementos_GitHub. Esta etapa NO ejecuto 007, 008, DDL, DML, procedimientos de registro ni fixtures de escritura. Solo cambios locales, pruebas offline y SELECT sobre QA verificada.

## Error, correccion y alcance

En el primer intento, subtotal incluia CK_DetalleCompras_Subtotal en su propia definicion de columna y referenciaba cantidad/costoUnitario. SQL Server rechaza esa referencia cruzada con 8141/1750. La regla documentada limita el CHECK de columna a esa columna; para varias columnas se usa un CHECK de tabla. [CREATE TABLE, Microsoft Learn](https://learn.microsoft.com/en-us/sql/t-sql/statements/create-table-transact-sql?view=sql-server-ver16).

En sql/qa/007_Compras_QA.sql:31, subtotal queda declarado decimal(18,2) NOT NULL y, despues de la coma que termina esa columna, se declara:

```sql
CONSTRAINT CK_DetalleCompras_Subtotal
 CHECK(subtotal=CONVERT(decimal(10,0),cantidad)*costoUnitario)
```

Es una restriccion de tabla. Conserva la igualdad exacta subtotal = cantidad por costo, sin permitir NULL ni modificar la regla de negocio. Tambien se hicieron explicitas las conversiones de costo y subtotal al insertar el detalle (linea 80); se mantienen las validaciones previas de dos decimales y limite de total. Se formatearon las dos tablas para poder distinguir columnas de restricciones.

No cambian tablas previstas, columnas, parametros ni resultados publicos: exclusivamente Compras, DetalleCompras y sp_Compras_Registrar/Historial/Detalle. Se conservan cuatro FK, cuatro CHECK, dos PK, dos UNIQUE, un DEFAULT y cinco indices contando los asociados a PK/UNIQUE. No hay DML fuera de las definiciones de los procedimientos. El despliegue sigue sin registrar compras ni cambiar stock/precios.

## Revision de todas las restricciones e indices de 007

- PK_Compras: idCompra int IDENTITY, clave unica no nula; un unico indice clustered por defecto en esa tabla.
- PK_DetalleCompras: idDetalleCompra int IDENTITY, igual criterio en su propia tabla. No se exige que ambas tablas compartan una clave.
- FK_Compras_Proveedor: idProveedor int NOT NULL hacia dbo.Proveedores.idProveedor. Lectura de sys.* confirma destino int no nulo y clave unica no filtrada.
- FK_Compras_Usuario: idUsuario int NOT NULL hacia dbo.Usuarios.idUsuario. Mismo control real de metadata.
- FK_DetalleCompras_Producto: idProducto int NOT NULL hacia dbo.Productos.idProducto. Mismo control real de metadata.
- FK_DetalleCompras_Compra: idCompra int NOT NULL hacia Compras.idCompra. Ambos extremos int, con PK destino definida antes de crear DetalleCompras. Esta dependencia nueva se reviso estaticamente; aun no existe en QA.
- DF_Compras_Fecha: SYSDATETIME() sin referencias a columnas, asignado a datetime2 NOT NULL. Un SELECT real confirma tipo datetime2 de esa funcion.
- CK_Compras_Total: CHECK(total>0), de columna; solo usa total decimal(18,2) NOT NULL.
- CK_DetalleCompras_Cantidad: CHECK(cantidad>0), de columna; solo usa cantidad int NOT NULL.
- CK_DetalleCompras_Costo: CHECK(costoUnitario>0), de columna; solo usa costoUnitario decimal(18,2) NOT NULL.
- CK_DetalleCompras_Subtotal: ahora de tabla; las tres columnas referidas existen en DetalleCompras y son no nulas. No hay subconsultas, funciones de usuario ni referencias a otras tablas.
- UQ_Compras_Operacion: GUID NOT NULL unico; mantiene la clave de idempotencia.
- UQ_DetalleCompras_Producto: UNIQUE(idCompra,idProducto), dos int existentes; evita repetir producto dentro de una compra.
- IX_Compras_FechaProveedor: claves (fecha,idProveedor), INCLUDE(total,idUsuario), sin repetir columnas de clave como incluidas. Tipos datetime2/int/decimal admitidos. Sus claves y las de PK/UNIQUE quedan ampliamente dentro de los limites de tamano; no se usa varchar(max), XML ni un tipo no indexable.

Los nombres de las 13 restricciones no colisionan con objetos del esquema dbo actual; se comprobo con SELECT. Las dos PK, las dos UNIQUE y el indice explicito explican los cinco indices nuevos. Se mantiene NO ACTION por defecto en FK: no se agregan cascadas ni ciclos de borrado. Las opciones ANSI requeridas permanecen en cada lote; no se modifico el control de transaccion entre GO.

Esta revision combina reglas de SQL Server documentadas, referencias/tipos reales consultados y analisis del DDL. No es una creacion de prueba: no se afirma que SQL Server ya haya enlazado o creado las restricciones corregidas. El parser aislado no puede demostrarlo.

## Revision estatica de 008

008 no se modifico ni se ejecuto. Se examinaron todos sus objetos estructurales:

- Productos.stockMinimo: int NOT NULL, DF_Productos_StockMinimo DEFAULT(0) y CK_Productos_StockMinimo CHECK(stockMinimo>=0). El CHECK solo referencia su columna; el DEFAULT es constante. La carga del default sobre filas previas correspondera a su despliegue futuro, no a esta etapa.
- MovimientosStock: PK_MovimientosStock en idMovimiento int IDENTITY; DF_Movimientos_Fecha con SYSDATETIME() hacia datetime2.
- FK_Movimientos_Producto/Usuario/Compra/Venta: columnas int y destinos PK int. Compra depende de la tabla futura de 007; no se simula su existencia ni se despliega una FK para probarla. idCompra/idVenta nullable permiten los distintos origenes sin exigir una compra y una venta simultaneas.
- CK_Movimientos_Stock, CK_Movimientos_Motivo y CK_Movimientos_Tipo ya son restricciones de tabla. Sus referencias existen en esa tabla. Stock convierte a bigint antes de sumar; extremos int y cantidad int no desbordan bigint. Los estados anterior/posterior no negativos acotan tambien la diferencia posterior-anterior a un valor int representable.
- UX_Movimientos_Ajuste: operacion GUID unica donde no es NULL; UX_Movimientos_Compra y UX_Movimientos_Venta: pares de ID origen/producto, filtrados por origen no nulo. Los predicados simples IS NOT NULL y los tipos clave son compatibles; las condiciones del CHECK separan los origenes.
- IX_Movimientos_FechaProducto: fecha datetime2 e idProducto int. No repite columnas ni introduce un segundo clustered. Se mantienen las opciones SET del script para indices filtrados.

No se encontraron otros errores estructurales semejantes en esta revision. Los INSERT/UPDATE de 008 siguen dentro de los cuerpos SP y no son operaciones ejecutadas por este analisis. Su ruta de Compras mantiene costos validados con dos decimales antes de calcular: la reduccion de escala del intermediario decimal amplio no elimina centavos ya validados. La aceptacion real del DDL/SP de 008 y sus operaciones permanece pendiente; no esta autorizada.

## Precision y overflow

La multiplicacion explicita decimal(10,0) por decimal(18,2) produce decimal(29,2); esa regla y el limite de precision 38 se contrastaron con [Precision, scale, and length, Microsoft Learn](https://learn.microsoft.com/en-us/sql/t-sql/data-types/precision-scale-and-length-transact-sql?view=sql-server-ver16). Un SELECT de SQL_VARIANT_PROPERTY en QA confirmo precision 29 y escala 2 para la expresion utilizada.

Los limites de entrada permanecen: cantidad int positiva, costo hasta 9999999999.99 y dos decimales, 1-500 detalles. SUM usa decimal(38,2); los productos extremos y la suma maxima de 500 lineas caben en sus intermediarios. Antes de reducir subtotal a decimal(18,2), la regla de total <=9999999999999999.99 y todos los sumandos positivos garantiza que cada subtotal admitido tambien cabe. Una entrada fuera del limite se rechaza antes de escribir, no se trunca. No se cambia ese limite de negocio.

Se ejecutaron 11 comprobaciones reales SOLO SELECT: claves FK existentes, ausencia de colisiones de nombres, precision/escala, 3 por 2.50, extremos, suma maxima, TRY_CONVERT de valor excedido, frontera del total, tipo de SYSDATETIME, suma bigint de stock y estado 15/43. No se llamo al SP Registrar ni se modificaron filas para comprobar estos numeros.

## Nueva regresion contra la causa original

scripts/qa/Validar-Restricciones.psm1 usa el AST de ScriptDom para realizar una comprobacion adicional propia: para cada CHECK de ColumnDefinition recorre las referencias de columnas y rechaza cualquier nombre distinto de la columna que lo contiene. Tambien inspecciona cuerpos SQL dinamicos preparados. No se limita a comprobar que el parser acepte el texto.

La prueba primero reprodujo el defecto sobre la migracion sin corregir: rechazo las referencias cruzadas de subtotal. Despues de corregirla, paso. Sus 13 casos incluyen reproduccion original, CHECK anonimo, identificadores delimitados, funciones/conversiones, ALTER ADD, tabla variable, DDL dinamico, CHECK validos de columna/tabla y las dos migraciones reales. Esta validacion se ejecuta en el aplicador antes de conectar y esta integrada a la regresion.

Este mecanismo bloquea nuevamente la misma clase de defecto incluso si alguien actualizara una huella tras una edicion incorrecta. No es un validador exhaustivo de todas las reglas semanticas de SQL Server ni reemplaza el despliegue autorizado y los ensayos posteriores.

Huella SHA-256 normalizada nueva, sin BOM y con LF/CRLF equivalentes:

`D506BFCDAEF58541FA357FA6B16BE838FB783E55788E86E740BAE137E6978EC0`

La allowlist sigue exigiendo coincidencia exacta del SQL revisado; no se retiraron los controles de servidor, base, marca, instalacion parcial, transacciones, snapshots o integridad. La rama de despliegue no se ejecuto.

## Estado, pruebas y archivos

El aplicador se ejecuto con -VerificarSoloLectura: servidor local esperado, ForzaSuplementosDB_QA y marca Forza-QA-Aislada-v1 correctos; 15 contratos de 005/006 coinciden; 15 tablas, 43 SP, 13 FK, 23 indices y 9 CHECK; sin objetos de 007/008 ni transacciones incompatibles; PBKDF2 inactivo y credenciales derivadas vacias. Las huellas de las 15 tablas (incluidas las vacias) coincidieron entre dos lecturas. Evidencia y metadata preservadas en private/007-preflight-* y private/007-revision-*, ignorados por Git. No se exportan filas, contrasenas ni huellas de tablas.

Compilacion Debug/AnyCPU y regresion completa en private/regresion-correccion-007.log. Total real de la ejecucion completa: 707 comprobaciones aprobadas (683 anteriores, 13 nuevas offline y 11 nuevas de lectura), mas 65 analisis estaticos SQL. Las comprobaciones nuevas se integraron en scripts/Validar-Avance.ps1. No se ejecutaron fixtures de escritura ni pruebas visuales humanas.

Archivos funcionales locales modificados: sql/qa/007_Compras_QA.sql (CHECK y conversiones), scripts/qa/007.Validacion.psm1 (huella), scripts/qa/Aplicar-007-Estructura-QA.ps1 (nuevo control semantico), scripts/Validar-Avance.ps1 (nuevas suites). Nuevos: scripts/qa/Validar-Restricciones.psm1, tests/qa/Probar-Restricciones-SinSql.ps1 y tests/qa/Probar-007-Numericos-Lectura.ps1. Documentacion: este informe y enlace de estado desde RESULTADOS_007_ESTRUCTURAL_QA.md. Sin cambios en VB, configuraciones, 008 ni datos SQL.

## Verificacion manual y autorizacion propuesta

Permitido en Windows PowerShell desde la raiz del repositorio:

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File scripts/qa/Aplicar-007-Estructura-QA.ps1 -VerificarSoloLectura
```

En SSMS, verificar servidor/base/marca y consultar metadata: QA debe continuar 15 tablas/43 SP y sin objetos de Compras. El acceso directo QA protegido mantiene Compras deshabilitado. No usar F5 ni aplicar scripts para verificar esta correccion.

Autorizacion necesaria, aun NO concedida: autorizo un unico segundo intento exclusivamente de sql/qa/007_Compras_QA.sql corregido, con la huella normalizada D506BFCDAEF58541FA357FA6B16BE838FB783E55788E86E740BAE137E6978EC0, mediante scripts/qa/Aplicar-007-Estructura-QA.ps1 -AutorizarEstructura007, solo en ForzaSuplementosDB_QA de la instancia local verificada con marca Forza-QA-Aislada-v1. Permite crear Compras, DetalleCompras y los tres SP previstos con sus restricciones/indices, preservar metadata y verificar estructura/integridad solo mediante lecturas. No permite ensayos, registros de compras, cambios de stock/precios/credenciales, 008, PBKDF2, otras bases ni push. Ante error detenerse y consultar el estado, sin reparaciones, reversiones ni reintentos adicionales.
