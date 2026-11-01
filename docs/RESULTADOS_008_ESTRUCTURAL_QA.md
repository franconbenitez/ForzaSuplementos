# Resultado real del despliegue estructural 008

Actualizacion posterior: el positivo de Compras/Inventario fue autorizado y aprobado con rollback completo. Ver [RESULTADOS_008_POSITIVO_QA.md](RESULTADOS_008_POSITIVO_QA.md). No se ejecutaron negativos ni ensayos de Ventas/Caja.

Fecha local: 2026-11-01. Repositorio exclusivo ForzaSuplementos_GitHub. HEAD inicial a893183, arbol limpio. Autorizacion expresa limitada a una ejecucion estructural y verificaciones de lectura.

## Resultado exacto

Se ejecuto una sola vez scripts/qa/Aplicar-008-Estructura-QA.ps1 -AutorizarEstructura008. La huella normalizada del SQL coincidio exactamente con AFEBAF6E4B68809B6897313BE876129328CE96186514F342F27E7A2ED09F7486. Antes de escribir se verificaron servidor local esperado, base exacta ForzaSuplementosDB_QA, marca Forza-QA-Aislada-v1, baseline 17/46/17/28/13, los 18 contratos de 005/006/007, firmas compatibles, CHECK semanticos, ausencia de objetos parciales y transacciones incompatibles.

Las definiciones originales completas, parametros/opciones ANSI y metadatos de columnas, indices, restricciones y relaciones quedaron en private/008-despliegue-* ignorado por Git. Las huellas de las tablas solo se compararon en memoria: no se exportaron filas ni valores derivados.

sqlcmd termino con salida 0. Se uso la transaccion prevista entre GO, con XACT_ABORT y comprobacion @@TRANCOUNT=1 antes de COMMIT. La conexion de despliegue termino y la inspeccion posterior reporto @@TRANCOUNT=0. Se completaron todas las comprobaciones del aplicador y se guardo resultado.json exitoso. Sin errores, reparaciones, reversiones adicionales ni reintentos.

## Estructura realmente instalada

QA contiene 18 tablas (17 dbo y qa.Fixtures), 50 procedimientos, 21 FK, 33 indices y 17 CHECK. Inventario y Mermaid se regeneraron a partir de sys.*, no de una proyeccion.

- MovimientosStock creada y vacia: cero filas, sin historia reconstruida.
- Productos.stockMinimo int NOT NULL creada con DEFAULT(0) y CHECK >=0; todos los productos preexistentes tienen minimo cero.
- Cuatro SP creados: sp_Inventario_Stock, sp_Inventario_Historial, sp_Inventario_Minimo, sp_Inventario_Ajustar.
- Cuatro SP actualizados: sp_Compras_Registrar, sp_Ventas_RegistrarConCaja, sp_Productos_Modificar, sp_Productos_Insertar.
- Las cuatro FK y cuatro CHECK agregadas estan habilitadas y son confiables. Se verificaron dos DEFAULT y los cinco indices de MovimientosStock, incluidas claves, unicidad y filtros.
- Los ocho cuerpos, firmas y opciones ANSI coinciden con el SQL revisado. Los cuatro contratos reemplazados mantienen tipos, longitudes, precision/escala, parametros de salida y compatibilidad con DAL.

## Integridad de lo anterior

Coincidieron los conteos y las huellas agregadas de todas las columnas PREEXISTENTES de las 17 tablas anteriores, incluidas Usuarios/contrasenas, Productos/stock/precios, Ventas/DetalleVentas, PagosVenta, SesionesCaja, Compras/DetalleCompras y seguridad. La nueva columna de minimo se comprobo aparte para no confundirla con un cambio de existencias.

La metadata de cada columna anterior (objeto, orden, tipo, longitud, precision, escala y nulabilidad) tambien coincide. Solo se agregaron las 12 columnas de MovimientosStock y stockMinimo. Las 42 definiciones de SP no afectadas y sus opciones ANSI permanecen identicas. Las cuatro anteriores reemplazadas se conservaron privadamente y sus nuevas firmas/cuerpos se verificaron.

No se registraron compras, ventas, ajustes o movimientos; no se invocaron operaciones de apertura/cierre de Caja. No se modificaron precios, existencias, usuarios o credenciales anteriores. PBKDF2 permanece inactivo y CredencialesUsuario vacia. No se ejecutaron otros scripts de migracion, fixtures de escritura, restauraciones ni push, y no se escribio en otras bases.

## Compilacion y regresion

Se adaptaron exclusivamente dos pruebas de lectura para reconocer el estado 008: disponibilidad de formularios (Inventario habilitado para gerente y bloqueado para los otros perfiles, sin accionar guardados) y baseline de comprobaciones numericas/metadata de Compras. No se cambio VB, tema, reglas BLL ni conexiones.

Compilacion Debug/AnyCPU correcta. Regresion offline/de lectura: 749 comprobaciones aprobadas y 66 analisis estaticos SQL correctos. Registro: private/regresion-008-instalada.log. Los fixtures SQL quedaron sin ejecutar. Las pruebas de grillas/MDI son automatizadas y no sustituyen la revision visual humana.

## Riesgos pendientes y siguientes autorizaciones

La creacion del DDL y la verificacion de contratos estan probadas realmente en SQL Server. La atomicidad operativa de nuevos movimientos, la ausencia de doble stock en operaciones reales de prueba, los ajustes/minimos, pagos/cierres tras 008 y concurrencia aun requieren ensayos autorizados; no se declaran aprobados por compilar.

Productos ahora exige stock inicial cero y evita editar existencias directamente: el flujo pasa por Compras o Inventario con motivo. Esto es comportamiento previsto del SQL instalado, pendiente de validacion transaccional/manual de esa ruta. Las ventas historicas conservan su estado sin movimientos retroactivos.

Ver AUTORIZACIONES_ENSAYOS_008.md: cuatro permisos separados por archivo, primero Compra/Inventario positivo, despues negativos de Compra/Inventario, despues Ventas/Caja positivo y finalmente sus negativos. Ninguno se ejecuto con el permiso estructural.

Para consultar desde Windows, abrir FORZA SUPLEMENTOS - QA (GITHUB), ingresar como gerente y abrir Inventario/Stock y alertas. No pulsar Aplicar ajuste, Guardar minimo ni confirmar compras/ventas hasta autorizar los ensayos correspondientes. En SSMS verificar servidor/base/marca y consultar metadata/COUNT_BIG de MovimientosStock (0) y productos con stockMinimo<>0 (0). No reejecutar 008. No usar F5 sin el lanzador QA protegido.
