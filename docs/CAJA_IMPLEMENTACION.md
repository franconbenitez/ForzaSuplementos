# Caja e integración con Ventas

Preparación posterior a ddebb25: consultar `sql/qa/README.md`. Se agregó un perfil de conexión QA por proceso, conservando la cadena habitual; reemplaza para ensayos la indicación histórica de editar una copia de Conexion.vb. SQL QA y las pruebas funcionales aún requieren autorización y ejecución.

## Estado de la entrega

Implementación VB.NET en las cuatro capas, con migraciones preparadas y sin ejecutarlas. Rebuild Debug/AnyCPU con MSBuild completado con código 0. Las 20 comprobaciones de reglas/construcción del formulario pasaron sin conectar SQL; ScriptDom aceptó la sintaxis de los tres scripts. Esto no prueba operaciones SQL, integridad bajo concurrencia ni funcionamiento completo contra la base.

La auditoría inicial conserva su valor histórico: el bloqueo por FrmCaja fue corregido después de esa auditoría; ahora el formulario existe y el código temporal #If False se retiró.

## Archivos

Todos los archivos VB están bajo `ForzaSuplementos/ForzaSuplementos/`:

- Nuevos en Entidades: SesionCaja.vb (tipos y nulos del esquema, resumen de ventas) y MedioPago.vb (opciones explícitas).
- Nuevo en Datos: CajaDAL.vb (SP, parámetros tipados y mapeo de sesión/reporte).
- Nuevo en Negocio: CajaBLL.vb (permisos, importes, estado e historial).
- Nuevos en Presentación: FrmCaja.vb y FrmCaja.Designer.vb (estética oscura, estado, apertura, cierre, filtro por fecha de apertura, historial y reporte).
- Modificados: Venta.vb (sesión nullable y medio de pago), VentaBLL.vb (actor, detalle/total y caja abierta), VentaDAL.vb (venta atómica en un SP), FrmPrincipal.vb (eventos e inyección del usuario), FrmVentas.vb y su Designer (elección de medio y confirmación).
- Modificados los cuatro VBPROJ para incluir archivos explícitamente; no se agregaron dependencias ni se cambiaron referencias entre capas.
- Nuevos SQL: tres migraciones, un ensayo manual de integración y sql/README.md, con orden, restricciones y reversión.
- Nuevos tests: Probar-Caja-SinSql.ps1 y Validar-Sintaxis-Sql.ps1.
- Modificado .gitignore para excluir artefactos visuales locales de tests. Conexión, credenciales, login, tablas históricas y módulos ajenos no fueron modificados.

## Funcionalidad implementada

El menú de Caja está conectado con Handles y visible solo para vendedor. Se pasa el usuario autenticado al formulario y a Ventas. BLL rechaza perfiles distintos y SQL verifica nuevamente perfil/activo por ID. Caja permite abrir con importe inicial, ver estado, cerrar con contado y mostrar esperado/diferencia. El historial y reporte quedan limitados al vendedor y tienen filtro de fecha de apertura inclusivo desde/hasta.

La nueva venta necesita caja propia abierta y medio de pago. La BLL valida todas las líneas, rechaza duplicados y recalcula subtotales. SQL vuelve a validar caja, cliente, productos activos, cantidades, precio vigente y total. Una transacción guarda venta, detalles, pago y stock. El ID solo se entrega al objeto VB tras el éxito del SP. Los procedimientos coordinan apertura/cierre/venta con el mismo bloqueo y conservan los históricos con idSesion NULL.

Cada venta usa un solo medio por el importe completo. Solo Efectivo se suma al inicial para el esperado; Tarjeta y Transferencia no alteran el efectivo. El cierre persistido y su reporte incluyen los responsables, fechas, inicial, ventas, importe vendido, efectivo, contado y diferencia. La pantalla muestra un reporte consultable/copiable; no genera PDF ni impresión fiscal.

## Verificación ejecutada

- Catálogo SQL real inspeccionado solo para metadatos y definiciones. No se seleccionaron filas de usuarios, ventas ni otros datos privados. No se ejecutaron los SP de negocio.
- Rebuild de los cuatro proyectos Debug/AnyCPU: exitoso con MSBuild 18.11.1.
- 20 comprobaciones sin SQL: importes negativos/precisión/límites; rechazo de administrador, gerente, rol desconocido y sesión ausente; vendedor; venta nula; cantidad negativa/cero; producto repetido; medio ausente/desconocido; overflow monetario; recálculo de subtotal alterado; actor inconsistente; construcción del formulario y grilla de solo lectura con operaciones inicialmente deshabilitadas.
- Análisis de sintaxis de las tres migraciones con Microsoft ScriptDom. No valida ejecución ni enlace con objetos del servidor.
- Revisión de referencias Compile, eventos Handles y diff. No se requiere un RESX nuevo porque el formulario no usa recursos externos.

Los PS1 se pueden ejecutar si la política del entorno lo permite. Aquí se ejecutó su contenido como bloque en memoria ajustando solo la raíz del proyecto, sin modificar la política de PowerShell.

## Pasos exactos de prueba

1. En Visual Studio, abrir `ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.slnx`, seleccionar Debug/Any CPU y **Compilar > Recompilar solución**. Los cuatro proyectos deben compilar.
2. En SSMS, preparar una base/instancia **aislada**, con esquema equivalente y datos ficticios. Verificar el destino con `SELECT @@SERVERNAME, DB_NAME();`. No ejecutar migraciones en la base real.
3. En esa base, activar **Consulta > Modo SQLCMD** y ejecutar archivos completos 001, 002 y 003, en ese orden, según sql/README.md. Verificar que no hay errores y que la reejecución tampoco duplica objetos.
4. Con el destino aislado ya verificado, usar una copia de pruebas del proyecto y ajustar únicamente allí su conexión para apuntar a ese destino. La conexión de esta entrega se conserva intacta. No iniciar F5 contra la base real para ensayar operaciones.
5. Iniciar la copia aislada como Presentación con un usuario vendedor ficticio. Ir a **Control de Caja**, indicar inicial 500 y abrir. Actualizar y comprobar sesión, responsable y fecha. Intentar segunda apertura desde otro proceso/vendedor: debe rechazarse.
6. En Ventas, registrar tres ventas de 100, una con cada medio. Sin medio elegido debe rechazarse. Si la caja está cerrada o el stock no alcanza, la venta debe rechazarse sin datos parciales. Actualizar Caja: importe vendido 300, ventas en efectivo 100 y esperado 600.
7. Cerrar con contado 590. El reporte debe mostrar esperado 600, real 590 y diferencia -10; la sesión debe quedar cerrada con fecha y responsable. Otro cierre/venta sobre esa sesión debe rechazarse.
8. Filtrar historial por fecha de apertura, seleccionar sesión y **Ver reporte**. Comparar con vw_Caja_Resumen en la base aislada. Vendedor no debe acceder al historial ajeno; administrador y gerente no deben operar Caja ni vender.
9. Ejecutar opcionalmente `sql/tests/Caja_Integracion_Manual.sql` con IDs ficticios y sin caja abierta; conserva sus registros de ensayo. Completar las pruebas concurrentes y de rollback detalladas en sql/README.md.

## Pendientes y límites

El módulo requiere aplicar y probar SQL en el entorno aislado antes de declararlo operativo. Sin los SP nuevos, Caja y la confirmación de ventas fallan de forma explícita; no se permite vender eludiendo el control de caja. No se modificó la base real para evitar ese estado intermedio: la nueva versión debe desplegarse coordinadamente con las migraciones cuando corresponda.

No se implementaron pagos mixtos, devolución/vuelto por importe recibido, retiros/ingresos de efectivo, relevo de responsable ni cajas múltiples. Las ventas anteriores sin medio conocido no se convierten a efectivo. Sesiones antiguas con ventas sin pago requieren conciliación manual; un vendedor desactivado con caja abierta también requiere una política de relevo aún no implementada.

Si se pierde la conexión justo después de COMMIT, el cliente podría no recibir confirmación. No se implementó una clave de idempotencia para reintento automático: comprobar el historial antes de repetir una operación con resultado ambiguo. Los bloqueos de la caja única favorecen integridad sobre paralelismo; evaluar otro alcance si el negocio necesita varias cajas.

La próxima tarea es probar estas migraciones y operaciones en una base aislada y completar las pruebas concurrentes, antes de avanzar hacia otros módulos. Los problemas de autenticación y reportes generales de la auditoría inicial siguen fuera de esta etapa.
