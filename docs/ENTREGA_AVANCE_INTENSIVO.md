# Entrega de avance intensivo — 28/10/2026

Repositorio principal ForzaSuplementos_GitHub, rama master. Se trabajó secuencialmente desde 7365b78. Desarrollo_Codex no se modificó. No hubo push, nuevas migraciones, escrituras SQL, cierres de procesos ni backups físicos durante esta sesión.

## Disponible y probado ahora

- Dashboards completos ya desplegados por 004: gerente (totales, operaciones, unidades, diaria/mensual, productos/categorías/vendedores), vendedor (su propio alcance) y administrador (registros de auditoría de backups). No hay estados de backup almacenados: no se inventan éxitos/fallos.
- Se contrastaron totales, evolución, unidades y rankings de productos/categorías mediante consultas SQL independientes para gerente y dos vendedores ficticios. Se probaron permisos, períodos vacíos y representación de formularios reales.
- Login, Caja, Ventas, buscadores, navegación centralizada y tema oscuro pasaron las regresiones existentes. No se registraron ventas ni se operó Caja en SQL para esta revisión.
- Se confirmó el destino del acceso directo FORZA SUPLEMENTOS - QA (GITHUB), su CMD con compilación obligatoria y las validaciones QA del lanzador. No se inició una sesión interactiva para el usuario ni se recuperaron sus claves.

## Desarrollado, pero pendiente de desplegar y probar SQL

**Seguridad (005):** servicio PBKDF2-HMAC-SHA256 con salt individual, parámetros/versiones y comparación completa de bytes. Login elige modo seguro únicamente cuando el contrato del servidor está activado. Alta/edición segura, cambio propio, reset de administrador y recuperación por operador SQL preparados. Edición con clave vacía conserva la existente; no se precarga en el formulario ni se envían hashes a las grillas. El flujo QA heredado sigue operativo hasta el corte autorizado. Se preservan espacios de contraseñas y se validan longitudes para evitar truncamiento. Ver SEGURIDAD_CONTRASENAS.md.

**Proveedores y marcas (006):** entidades, DAL parametrizada, BLL y formularios con grilla/búsqueda, CUIT opcional con checksum, activo/inactivo, cambios pendientes y asociación de marca a producto activo. Solo gerente. Buscar devuelve hasta 500 registros; filtrar en el ABM para acotar. El selector de proveedor de Compras filtra el subconjunto de hasta 500 resultados: ampliar paginación/búsqueda remota antes de uso con un catálogo mayor.

**Compras (007):** buscador de proveedor/producto, carrito con cantidades y costos, quitar/vaciar, total, protección al salir, confirmación transaccional propuesta, historial filtrable y detalle. XML parametrizado desde DAL; nunca SQL en formulario. Costo de compra separado de precio de venta. Token de operación y huella para reintentos; no se limpia el carrito ante respuesta incierta. El SP preparado incrementa stock junto con cabecera/detalles, valida proveedor/productos activos y overflow.

**Inventario (008):** stock mínimo, alertas Agotado/Bajo/Disponible, historial filtrado, ajustes con motivo y stock esperado, idempotencia y responsable. OUTPUT captura antes/después del mismo UPDATE. El SP de ventas conserva su firma y un único descuento; compra/venta y movimiento quedan en su misma transacción. No se generan movimientos históricos. Tras desplegar 008, Productos deja de editar stock directo: se crea con cero y se ingresa mediante compra/ajuste con motivo.

Estos módulos **no están operativos contra SQL todavía**. El gerente puede abrir Proveedores/Marcas/Compras/Inventario y comprobar el aviso Requiere habilitación QA y la edición deshabilitada. Mi contraseña informa el requisito de 005 sin escribir. Ninguno muestra una operación exitosa al faltar el contrato SQL. Administrador y vendedor son rechazados antes de abrir los nuevos módulos comerciales, además de las validaciones BLL/SP.

## Esquema real y proyectado

QA mantiene **11 tablas, 30 SP**, 11 FK, 16 índices y 4 CHECK del inventario anterior. No se añadió ningún objeto en esta sesión.

Siete tablas propuestas: SeguridadEstado (corte singleton), CredencialesUsuario (hash versionado), Proveedores, Marcas, Compras, DetalleCompras y MovimientosStock. Columnas propuestas: Perfiles.activo, Productos.idMarca nullable y Productos.stockMinimo. Justificación y relaciones: DIAGRAMA_ER_PROYECTADO.md. El diagrama real DIAGRAMA_ER.md no se alteró para fingir despliegue.

## Migraciones pendientes, en orden

1. 005_Seguridad_QA.sql: estructura/contratos de seguridad; NO activa el corte ni cambia claves existentes por sí sola.
2. 006_Catalogos_QA.sql: proveedores, marcas, relación nullable y SP comerciales. Requiere estructura 005, no su activación.
3. 007_Compras_QA.sql: compras/detalles y SP. Requiere 006.
4. 008_Inventario_QA.sql: movimientos/mínimos y adaptación de SP de compras, ventas y productos. Requiere 007.
5. Provisionamiento y activación de seguridad son operaciones adicionales que requieren autorización específica. No se incluyen automáticamente en el despliegue estructural.

Cada lote verifica base QA exacta, instancia suministrada desde configuración local y marca de aislamiento. SQLCMD :on error exit y -b son obligatorios. Cada migración mantiene una sola transacción desde el DDL hasta sus contratos completos; exige no tener transacción externa y confirma únicamente al final. No usar el aplicador de 004 para estos archivos ni ejecutar 010/020 otra vez.

Antes de cualquier autorización futura: revisar nuevamente destino, diff, dependencias y definiciones desplegadas. scripts/qa/Respaldar-Definiciones-Avance-Lectura.ps1 conservó cuatro definiciones existentes en private ignorado (Login, venta atómica y dos SP de productos). Repetirlo inmediatamente antes de cada despliegue: antes de 008 debe conservar también Compras_Registrar ya desplegado. No es un backup físico ni sustituye una política de recuperación.

Reversión: un error de despliegue debe cerrar la conexión SQLCMD y revertir toda su transacción. Después de un despliegue confirmado, preparar restauración de definiciones con revisión expresa y conservar datos/tablas nuevas; no hay un script que borre tablas para simular reversión. El corte de contraseñas inutiliza claves recuperables: recuperación segura con nueva credencial de administrador, nunca volver a texto plano. Enlace de SP con tablas y comportamiento transaccional aún no probados para 005–008.

## Pruebas realmente ejecutadas

Compilación completa Debug / Any CPU de cuatro proyectos: aprobada.

- 205 permisos; 86 navegación; 59 interfaz/Login/carrito; 20 Caja offline; 49 buscadores offline; 5 identidad del EXE; 8 selección QA lectura; 17 buscadores modales reales QA: 449.
- Dashboards offline: 37.
- Dashboards QA lectura, con contraste independiente de rankings: 26.
- Seguridad offline: 16.
- Catálogos offline: 11.
- Compras offline: 12.
- Inventario offline: 11.
- Nuevos módulos pendientes, instanciados realmente en MDI con QA en lectura: 21 (bloqueo de edición, ausencia de duplicados y rechazo de perfiles).

**Total: 583 comprobaciones aprobadas; 0 fallidas en la ejecución final.** No se cuentan las reejecuciones. Los 15 ensayos SQL de reportes pertenecen a la tarea anterior y no se repitieron ni se sumaron a este total. La regresión operativa de escritura de Caja/Ventas no se reejecutó porque no está autorizada en esta sesión.

Además: 59 lotes/procedimientos/fixture analizados con ScriptDom, guardas revisadas, sintaxis PowerShell de runners futuros y rechazo previo a conexión sin autorización. Análisis sintáctico no prueba enlace ni corrección SQL.

**Bloqueados por falta de autorización/despliegue: tres paquetes preparados**: Probar-Seguridad-Preparada.ps1, Avance_Transaccional_QA.sql (catálogos/compras/ajustes y rollback) y Probar-Concurrencia-Compras-Preparada.ps1 (dos conexiones, bloqueo/rollback). No se asigna un número de asserts SQL aprobados a scripts no ejecutados. La concurrencia requiere proveedor ficticio activo de nombre QA y producto de referencia de qa.Fixtures, sin generar fixtures persistentes automáticamente. El runner de seguridad solo admite las cuentas ficticias exactas referenciadas. Faltan ensayos de integración negativos ampliados: perfil inactivo, cambio concurrente de credencial, error intermedio de compra/venta con movimientos y carreras ajuste/venta.

Pruebas visuales humanas pendientes: todos los dashboards y los formularios nuevos, DPI, teclado, distribución al redimensionar y diseñador. Se revisaron renders DrawToBitmap de formularios reales; no equivalen a interacción por una persona. Artefactos y datos de QA permanecen ignorados en tests/artifacts.

## Repetir sin escrituras SQL

Desde la raíz del repositorio:

```powershell
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\scripts\Validar-Avance.ps1
# Incluye consultas protegidas QA y formularios reales; no aplica migraciones ni fixtures:
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\scripts\Validar-Avance.ps1 -IncluirLecturaQa
```

Los runners de fixtures NO forman parte de esta regresión. No ejecutarlos con banderas de autorización durante la revisión manual.

## Commits y estado Git

Commits de esta sesión por etapa:

- 1be1891: contraste de reportes y guía.
- 29f99ee: PBKDF2 y transición de seguridad.
- f49d5f4: proveedores y marcas.
- 37a180c: compras.
- 012f349: inventario.
- Commit de cierre: verificaciones integrales, scripts protegidos y esta documentación; consultar git log -1 para su hash.

Además siguen pendientes de publicación dae2de6, 205a2bc y 7365b78 de la etapa anterior. Al finalizar el cierre, master queda con nueve commits locales respecto de la referencia local origin/master, sin push ni reescritura. No se hizo fetch para afirmar el estado remoto en vivo. Usar git status y git log origin/master..HEAD antes de cualquier publicación autorizada. La entrega final del chat informa el HEAD exacto y la auditoría posterior al commit.

## Riesgos y próximos pasos

- La prioridad es la revisión humana de dashboards mediante GUIA_PRUEBAS_USUARIO.md; después, autorizar por nombre y alcance las migraciones y fixtures pendientes, una etapa por vez.
- El modo heredado de claves continúa hasta desplegar/provisionar/activar seguridad. No es una declaración de seguridad de producción. Permanecen pendientes mínimos privilegios SQL, rate limiting/bloqueo progresivo y endurecimiento de SP heredados de administración.
- Los locks de stock reutilizan el recurso de Caja para orden consistente: también serializan compras/ajustes y pueden afectar rendimiento; medir con volumen real y concurrencia antes de habilitar.
- Los historiales tienen límites explícitos (500 catálogos, 2000 historial/stock/movimientos). Aún falta paginación para grandes volúmenes y escenarios de pérdida de respuesta más amplios.
- No se eliminan funciones existentes; los cambios de flujo de stock directo se activarán únicamente con 008. Conservar las definiciones previas antes de desplegar.
- Compila no significa que los módulos pendientes funcionen completamente con SQL. No hay nuevas cifras operativas inventadas ni confirmaciones falsas.

## Archivos creados/modificados

- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Datos/ComercialDAL.vb
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Datos/CompraDAL.vb
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Datos/ForzaSuplementos.Datos.vbproj
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Datos/InventarioDAL.vb
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Datos/SeguridadDAL.vb
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Datos/UsuarioDAL.vb
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Entidades/Comercial.vb
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Entidades/Compra.vb
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Entidades/CredencialAcceso.vb
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Entidades/ForzaSuplementos.Entidades.vbproj
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Entidades/MovimientoStock.vb
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Negocio/ClaveSegura.vb
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Negocio/ComercialBLL.vb
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Negocio/CompraBLL.vb
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Negocio/ForzaSuplementos.Negocio.vbproj
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Negocio/InventarioBLL.vb
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Negocio/SeguridadBLL.vb
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Negocio/UsuarioBLL.vb
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Presentacion/ForzaSuplementos.Presentacion.vbproj
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Presentacion/FrmCatalogoComercial.vb
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Presentacion/FrmClave.vb
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Presentacion/FrmCompras.vb
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Presentacion/FrmInventario.vb
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Presentacion/FrmLogin.vb
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Presentacion/FrmPrincipal.vb
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Presentacion/FrmUsuarios.vb
- ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Presentacion/ProtectorCambios.vb
- docs/DIAGRAMA_ER_PROYECTADO.md
- docs/ENTREGA_AVANCE_INTENSIVO.md
- docs/GUIA_PRUEBAS_USUARIO.md
- docs/SEGURIDAD_CONTRASENAS.md
- scripts/Validar-Avance.ps1
- scripts/qa/Respaldar-Definiciones-Avance-Lectura.ps1
- sql/qa/005_Seguridad_QA.sql
- sql/qa/006_Catalogos_QA.sql
- sql/qa/007_Compras_QA.sql
- sql/qa/008_Inventario_QA.sql
- tests/qa/Avance_Transaccional_QA.sql
- tests/qa/Probar-Concurrencia-Compras-Preparada.ps1
- tests/qa/Probar-Dashboards-Lectura.ps1
- tests/qa/Probar-Modulos-Pendientes-Lectura.ps1
- tests/qa/Probar-Seguridad-Preparada.ps1
- tests/qa/Validar-Avance-SinSql.ps1
- tests/ui/Probar-Catalogos-SinSql.ps1
- tests/ui/Probar-Compras-SinSql.ps1
- tests/ui/Probar-Inventario-SinSql.ps1
- tests/ui/Probar-Seguridad-SinSql.ps1
