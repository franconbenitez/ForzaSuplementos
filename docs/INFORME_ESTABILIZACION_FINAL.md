# Informe de estabilización final — 31/10/2026

Preparación de la defensa del lunes 2/11/2026. Repositorio principal ForzaSuplementos_GitHub, master, base inicial c86fdee. El árbol inicial estaba limpio; se conservaron todos sus commits. No se trabajó en Desarrollo_Codex.

## Resultado y límites

Compilación completa Debug / Any CPU de las cuatro capas aprobada. Referencia inicial: 583 comprobaciones. Resultado final: **655 aprobadas, 0 fallidas**, incluidas **72 nuevas** (49 adversariales de interfaz/negocio, 6 de catálogos y 17 de criptografía/contratos). Se cuentan una sola vez, no se suman reejecuciones.

Análisis adicional: **65 lotes, procedimientos y fixtures SQL** parseados externa e internamente con ScriptDom. No prueba enlace ni ejecución del motor. SQL QA real sigue con **11 tablas y 30 SP**. No se aplicó 005–008, ni se escribió SQL, modificaron claves, generaron backups físicos o borraron datos. La base original no se conectó ni se modificó.

No hubo interacción gráfica humana de mi parte. Se instanciaron formularios WinForms reales, se dispararon eventos y se verificó geometría/MDI en memoria; los renders y logs están ignorados. La revisión del usuario, teclado/mouse real y DPI continúa pendiente. No se interrumpieron servicios ni procesos.

## Defectos encontrados y corregidos

1. **Login duplicado después del éxito.** La caracterización reprodujo dos aperturas al invocar dos veces el mismo evento. La marca de autenticación solo cubría la ejecución, no la sesión ya abierta. Ahora los eventos posteriores se ignoran hasta cerrar sesión; errores/nulo/fallo de apertura rehabilitan el ingreso. Se limpia la clave después del éxito.
2. **Login oculto conservaba la aplicación abierta.** Principal cerraba sin cerrar el formulario raíz oculto, y cada Cerrar sesión creaba otro Login. Ahora se reutiliza el original; cerrar Principal cierra el raíz. Cancelar el cierre de un hijo conserva ambos. No se usa terminación de procesos.
3. **Precio inválido entraba al carrito.** Se reprodujo aceptación de precio negativo antes de Confirmar (Negocio ya lo rechazaba después). Precio, precisión, importe de línea y cantidad se validan antes de modificar el carrito.
4. **Snapshot de venta compartía detalles.** ToList copiaba únicamente la lista. Ahora cada detalle es independiente; alterar el objeto pendiente no cambia el carrito.
5. **Confirmación reentrante y resultado incierto.** Guardado protegido por estado. Si se pierde respuesta durante ExecuteNonQuery o falta el ID, se informa resultado desconocido y se bloquea reenviar desde ese formulario. El descarte exige confirmar que se revisó historial. No sustituye idempotencia SQL entre reinicios.
6. **Recarga fallida confundida con venta fallida.** Tras confirmación, el carrito se limpia una vez. Si falla el catálogo, el mensaje aclara que la venta ya se confirmó y no debe repetirse. Un rechazo conocido mantiene el carrito.
7. **Borrado por defecto eludía protección del carrito.** Se deshabilitó la eliminación automática de filas. Delete en Ventas conserva su función solo cuando no hay confirmación ni resultado incierto; Compras usa Quitar seleccionado. No hay SQL en esos cambios de memoria.
8. **Resultados obsoletos en Reportes.** Se reprodujo que una consulta heredada conservaba el modelo anterior, que podía reaparecer al cambiar gráfico. Se limpian modelos, grilla y series; también ante error. Una respuesta de un filtro anterior se descarta por versión.
9. **Gráficos densos y MDI pequeño.** Se mantienen todos los puntos, pero se espacia el eje y se evitan etiquetas por barra cuando hay muchos datos. El lienzo aprobado se conserva con scroll y mínimo de ventana reducido: prueba con MDI 800×600 alcanzó los botones inferiores sin rediseñar ni cambiar colores.
10. **Alta repetida de proveedores/marcas.** El alta no devolvía ID a la UI. DAL/SP pendientes de 006 ahora acuerdan un ID confirmado; Guardar posterior modifica el mismo registro. Reentrada protegida; respuesta sin ID o pérdida de transporte bloquea repetir. Fallo de búsqueda limpia resultados anteriores. Validado con DAL sintética, NO en SQL.
11. **Disponibilidad comercial parcial.** El contrato preparado verifica todos los SP necesarios, no solo uno. La búsqueda y edición quedan bloqueadas sin habilitación.
12. **Estado de seguridad ausente degradaba a heredado.** Convert.ToBoolean(Nothing) podía producir False. Se exige un Boolean explícito; estado ausente/incompatible falla cerrado. El fallback por SP inexistente solo mantiene la etapa anterior al despliegue; errores de conexión no lo habilitan.
13. **Claves incompatibles y truncamiento.** No se permite crear claves de solo espacios. Se preservan espacios significativos. El modo heredado limita 100 caracteres, conforme al SP actual, en lugar de aceptar sufijos que SQL podía truncar. PBKDF2 conserva su política de hasta 256.
14. **Cuenta/perfil no admitidos.** Negocio rechaza cuenta inactiva o perfil fuera de la matriz. El mapeo del SP de Login heredado marca activo al usuario que pasó su filtro; se verificó en lectura que QA mantiene ese filtro. No se usaron claves reales ni se declaró autenticación SQL con contraseña probada.
15. **Administración propia y último administrador.** BLL bloquea baja y cambio de perfil de la propia sesión, evitando acceso con permisos obsoletos. En 005 se preparó protección transaccional del último administrador activo, coordinada por applock, en cambio de estado y edición segura. Solo BLL está operativa ahora: SQL pendiente.
16. **Huecos de activación en 005.** Se corrigieron confirmación NULL, pertenencia de rol SQL desconocida, ausencia de administrador provisionado, validación superficial del formato PBKDF2 y carrera provisionamiento/corte. La activación repetida/inconsistente se rechaza. Requiere ejecución QA autorizada para confirmar el comportamiento.
17. **Costo XML redondeado antes de validar.** 007/008 podían convertir un valor con exceso de precisión y después aceptarlo. Se valida formato/longitud/fracción antes de convertir; DAL serializa dos decimales. Se rechaza GUID vacío. Pendiente de ejecución SQL.
18. **CUIT solo validado en BLL.** 006 preparado también comprueba dígito verificador; mantiene índice único filtrado. Sin cambios en datos actuales.
19. **Caja con fechas fuera del tipo SQL.** La BLL rechaza fechas anteriores a 1753 antes de conectar. No se alteró apertura, cierre ni cálculo real de Caja.
20. **Runners de rollback.** Se impide ejecutar fixtures dentro de una transacción ajena. Se revisó cancelación de comando asíncrono y cierre de ambas conexiones del runner de concurrencia; el éxito se anuncia después de limpiar. No se ejecutó ese ensayo.

Los tres defectos caracterizados inicialmente (Login doble, precio negativo en carrito y modelo obsoleto) se reprodujeron en memoria y se corrigieron. Los errores de compilación del host de pruebas y aserciones estáticas dependientes del antiguo forwarder se corrigieron antes de la ejecución final. No se ocultan como pruebas SQL aprobadas.

## Pruebas ejecutadas

- Permisos: 205; navegación: 86; interfaz/Login/carrito: 59; Caja offline: 20; buscadores offline: 49; identidad EXE: 5.
- Selección QA lectura: 8; buscadores modales QA: 17; dashboards QA lectura: 26; módulos pendientes en MDI con QA lectura: 21.
- Dashboards offline: 37; seguridad offline: 16; catálogos offline: 11; compras offline: 12; inventario offline: 11.
- Nuevas suites: 49 adversariales, 6 catálogos con DAL de memoria y 17 seguridad/contratos. Total **655**.

Se probaron reentrada, recuperación tras error/nulo, cierre cancelado de hijo, conservación del carrito, precios/cantidades inválidos, cliente/producto inactivos, snapshots independientes, confirmación desconocida y recarga fallida, cambios rápidos de filtro, 800 puntos, MDI pequeño y administración propia. Las pruebas de red usan dobles: no se cortó SQL Server para simular una pérdida de respuesta.

Evidencia privada: tests/artifacts/estabilizacion/regresion-final.log y resultado.json. Repetir sin escrituras con:

```powershell
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\scripts\Validar-Avance.ps1 -IncluirLecturaQa
```

Sin esa bandera, solo compilación, offline y análisis estático. Los scripts de fixtures no están en esa regresión.

## Bloqueados: siete paquetes de integración SQL

No ejecutados por falta de nueva autorización/despliegue. No se cuentan como asserts aprobados:

- Probar-Seguridad-Preparada.ps1: credenciales sintéticas, estado temporal y restablecimiento con rollback.
- Catalogos_006_Rollback_Preparado.sql: alta/edición/baja lógica, ID y asociación a producto nuevo, rollback.
- Compras_007_Rollback_Preparado.sql: cabecera/detalle, costo, precio de venta intacto y reintento idempotente, rollback.
- Avance_Transaccional_QA.sql: compra, movimiento, ajuste idempotente, mínimo y rollback tras 008.
- Negativos_Compras_Inventario_Preparados.sql: **10 casos** de inactividad, cantidad/costo, overflow, GUID vacío, falta de motivo, stock insuficiente/obsoleto y perfil incorrecto, cada uno con rollback.
- Ventas_Caja_008_Rollback_Preparado.sql: tres sesiones nuevas, tres medios de pago por sesión y diferencias negativa/cero/positiva; ventas, pagos, stock y movimientos; rollback de todo. Se detiene si hay una caja abierta: no cierra una ajena.
- Probar-Concurrencia-Compras-Preparada.ps1: dos conexiones, bloqueo y stock consistente; ambas transacciones se revierten. Requiere proveedor ficticio existente identificado QA y producto de qa.Fixtures.

Las 18 pruebas históricas de Caja/Ventas y las 15 de reportes mantienen sus resultados de tareas anteriores; no se reejecutaron bajo una autorización de solo lectura. Tampoco se afirman pruebas reales de timeout, rollback, concurrencia o última cuenta administradora de los SP nuevos. La revocación de sesiones y las carreras cierre/venta requieren validación específica posterior.

## Funcionalidades reales frente a programadas

Operativas en QA: Login heredado, permisos de la aplicación, navegación, usuarios/productos/clientes existentes, Caja/Ventas/pagos/stock actuales, buscadores y dashboards 004. Se preserva el tema oscuro. La generación de backup existente no se ejecutó ni se valida físicamente aquí.

Programadas, no desplegadas: PBKDF2/corte seguro, proveedores/marcas, compras e inventario avanzado. 005–008 siguen sin aplicar. QA conserva 11 tablas y 30 SP; no se inventaron movimientos históricos, estados de backups ni cifras operativas. En esos módulos el aviso de habilitación y los controles deshabilitados son el resultado esperado.

## Orden de despliegue propuesto (requiere nuevas autorizaciones)

1. Cerrar manualmente la aplicación QA, revisar Git/diff y validar servidor/base/marca con QA.Common. Guardar definiciones previas; el script de lectura conservó **cinco** SP existentes en private ignorado, sin backup físico. Repetirlo antes de cada despliegue; antes de 008 incluirá también Compras_Registrar. Conservar datos y definiciones, no restaurar/borrar tablas automáticamente.
2. Autorizar 005 **solo estructura y contratos**, incluida la protección de cambio de estado del último administrador. No provisionar ni activar el corte. Verificar columnas, modo explícito False y Login QA manual con claves del usuario. Contrastar parámetros y resultados. Ejecutar después el paquete de seguridad ficticia solamente bajo autorización específica; verificar que restaura estado y credenciales.
3. Autorizar 006. Validar tablas/FK/índices y ejecutar Catalogos_006_Rollback_Preparado con autorización: contrato de ID y edición sin duplicado, marca y rollback. Probar CUIT/duplicados/roles adicionales antes de uso cotidiano.
4. Autorizar 007. Validar contratos e índices y ejecutar Compras_007_Rollback_Preparado. No declarar compras listas hasta ver costo, stock y rollback reales. No usar la prueba positiva de 008 para saltarse esta etapa.
5. Autorizar 008 por separado: toca los SP operativos de ventas/compras/productos. Ejecutar Avance_Transaccional, los diez negativos y Ventas_Caja_008_Rollback_Preparado, cada uno expresamente autorizado. Verificar FK/movimientos y que el descuento ocurre una sola vez. Autorizar aparte el runner de concurrencia. No cerrar sesiones ajenas ni limpiar registros previos para forzar un ensayo.
6. Repetir la regresión offline/lectura y revisión humana. Si se autoriza repetir el runner histórico de 18 casos, recordar que conserva datos ficticios para inspección; no tratarlo como un runner completamente reversible. No ejecutarlo con una autorización que permita solamente rollback.
7. Solo después: planificar/provisionar NUEVAS claves, comprobar administrador recuperable, autorizar activación de seguridad y sus ensayos completos. El corte no restaura contraseñas antiguas y no tiene fallback a texto plano; usar recuperación segura autorizada. No hacerlo durante una demostración ni junto con todos los módulos.

Cada archivo exige QA exacta, instancia verificada y marca. SQLCMD debe respetar :on error exit y -b; ejecutar una migración por conexión, sin transacción externa. No reutilizar el aplicador exclusivo de 004 ni ejecutar 010/020 nuevamente. Detenerse ante destino, contrato, rollback o integridad inesperados. Las tablas nuevas no se borran para simular una reversión; restauración de definiciones requiere revisión y autorización.

**Podemos comenzar a autorizar la etapa estructural 005 de forma controlada.** No es certificación de producción ni recomendación de aplicar todo de una vez: faltan los siete paquetes SQL y la revisión humana. Para la defensa se puede conservar la versión QA actual mientras se decide ese despliegue.

## Riesgos pendientes

- Claves recuperables y SP heredados continúan hasta el corte autorizado. La identidad integrada de SQL y un ID de actor enviados por el cliente no equivalen a autenticación independiente del servidor; faltan mínimos privilegios, rate limiting y revocación completa de sesiones.
- Ventas no tiene token de idempotencia SQL. El bloqueo de reintento en UI evita el reenvío desde esa instancia; después de perder respuesta, consultar historial antes de iniciar otra venta o reiniciar. No declarar garantía entre reinicios. Los ABM heredados tampoco tienen idempotencia de servidor para respuesta incierta.
- El resguardo del último administrador en SQL y las carreras de los módulos pendientes requieren sus ensayos reales. La protección de BLL propia ya está aplicada, pero no sustituye restricciones y autorización en servidor.
- Historiales y catálogos tienen los límites documentados de 500/2000; falta paginación y carga de gran volumen real. Los locks serializan stock y podrían afectar rendimiento.
- DPI/proyector, entrada por teclado/mouse real y todas las operaciones nuevas de SQL siguen pendientes. Se verificó geometría 800×600, no todas las escalas de Windows.

## Git y publicación

Se hizo fetch sin tags y fsck completo: sin cambios remotos por integrar ni corrupción. Origin pertenece a franconbenitez/ForzaSuplementos; GitHub confirmó private=true y master. No se hizo push, reset ni reescritura.

Commits de corrección desde c86fdee:

- 02f524b Corregir ciclo de Login, confirmaciones de venta y resultados obsoletos
- 6c4781b Evitar altas repetidas y proteger carritos y consultas de catalogos
- b6f8d25 Endurecer transicion de seguridad y validacion de compras sin desplegar SQL
- 6fb7d32 Permitir desplazar dashboards en contenedores MDI pequenos sin redisenar
- 25ceb89 Validar cuenta activa y perfil admitido antes de entregar la sesion
- fae75bb Rechazar truncamiento de claves del contrato de Login heredado
- a4b4775 Tratar perdida de respuesta de catalogos como guardado incierto
- c0ada4c Proteger administracion propia y preparar resguardo del ultimo administrador

El commit final incorpora este informe, la guía y los ensayos preparados. Al cerrar la tarea quedan **18 commits locales** frente a origin/master: nueve previos y nueve de esta revisión. El chat final informa su hash; el árbol debe quedar limpio. Auditoría final de privacidad incluye archivos e historial y sus límites de detección por patrones.

## Archivos cambiados

- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Datos/ComercialDAL.vb
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Datos/CompraDAL.vb
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Datos/SeguridadDAL.vb
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Datos/UsuarioDAL.vb
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Datos/VentaDAL.vb
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Entidades/ForzaSuplementos.Entidades.vbproj
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Entidades/OperacionInciertaException.vb
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Negocio/CajaBLL.vb
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Negocio/ClaveSegura.vb
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Negocio/ComercialBLL.vb
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Negocio/SeguridadBLL.vb
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Negocio/UsuarioBLL.vb
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Presentacion/FrmCatalogoComercial.vb
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Presentacion/FrmCompras.vb
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Presentacion/FrmLogin.vb
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Presentacion/FrmPrincipal.vb
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Presentacion/FrmReportes.vb
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Presentacion/FrmVentas.vb
- docs/DEMO_DEFENSA.md
- docs/INFORME_ESTABILIZACION_FINAL.md
- scripts/Validar-Avance.ps1
- scripts/qa/Respaldar-Definiciones-Avance-Lectura.ps1
- sql/qa/005_Seguridad_QA.sql
- sql/qa/006_Catalogos_QA.sql
- sql/qa/007_Compras_QA.sql
- sql/qa/008_Inventario_QA.sql
- tests/qa/Avance_Transaccional_QA.sql
- tests/qa/Catalogos_006_Rollback_Preparado.sql
- tests/qa/Compras_007_Rollback_Preparado.sql
- tests/qa/Negativos_Compras_Inventario_Preparados.sql
- tests/qa/Probar-Concurrencia-Compras-Preparada.ps1
- tests/qa/Validar-Avance-SinSql.ps1
- tests/qa/Ventas_Caja_008_Rollback_Preparado.sql
- tests/ui/Adversariales.vb
- tests/ui/Caracterizar-Defectos-SinSql.ps1
- tests/ui/CatalogoAdversarial.vb
- tests/ui/Probar-Adversariales-SinSql.ps1
- tests/ui/Probar-Buscadores-SinSql.ps1
- tests/ui/Probar-Catalogo-Adversarial-SinSql.ps1
- tests/ui/Probar-Interfaz-SinSql.ps1
- tests/ui/Probar-Seguridad-Adversarial-SinSql.ps1
