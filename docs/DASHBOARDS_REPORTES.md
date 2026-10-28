# Dashboards de reportes por perfil

Fecha: 27/10/2026. Repositorio principal ForzaSuplementos_GitHub; sin modificar el respaldo, credenciales ni conexión habitual. El usuario autorizó aplicar exclusivamente 004 y los fixtures con rollback en QA. La única instancia cerrada fue PID 11252, tras verificar la ruta y recibir autorización expresa del usuario.

## Esquema auditado

La conexión QA verificada consultó sys.* en lectura: **11 tablas** (10 de aplicación + qa.Fixtures), 11 FK, 16 índices, 4 CHECK y 30 SP existentes después de aplicar 004. Inventario completo: INVENTARIO_BASE_DATOS.md. Relaciones reales: DIAGRAMA_ER.md. No se exportaron filas, contraseñas, rutas de backup ni el identificador del equipo a los documentos.

## Funcionalidades habilitadas en QA

004 ya está aplicada y sus contratos fueron ejecutados y contrastados. Gerente: totales, operaciones, unidades, evolución diaria/mensual, productos, categorías, comparación de vendedores y filtros fecha/ID. Vendedor: totales, operaciones, unidades, evolución y productos propios; ID ajeno rechazado también en SQL. Administrador: historial, cantidad y evolución de registros de auditoría de backups. Estados exitosos/fallidos siguen desconocidos porque no están registrados; no se inventan ni se ejecutan backups físicos.

Se conservan los botones heredados, el tema oscuro y la navegación centralizada. Esta aplicación QA no instala 004 en otra computadora: cada base independiente requiere revisión y autorización propias.

## Arquitectura y fórmulas

Entidades: DashboardVentas, DashboardBackups, PuntoReporte y RegistroBackupReporte, sin conexiones. Negocio: DashboardBLL valida actor/perfil, fechas e IDs, deriva vendedor y calcula el resumen básico cuando únicamente falta el SP nuevo. Datos: DashboardDAL usa exclusivamente comandos StoredProcedure parametrizados. Presentación: FrmReportes muestra métricas, fechas, filtros permitidos, grillas y Chart de System.Windows.Forms.DataVisualization, incluido en .NET Framework/WinForms; no incorpora paquetes de otro framework.

El dashboard comercial completo admite solo gerente/vendedor, y el administrativo solo administrador. Tanto BLL como DAL rechazan alcance ajeno; el SP preparado consulta perfil/activo en Usuarios/Perfiles. Se valida el ID del actor; no se autoriza con RolActual ni UsuarioActualId heredados. Un objeto Usuario manipulado en un cliente modificado no es identidad criptográfica: siguen pendientes las garantías de identidad SQL/permisos mínimos documentadas en PERMISOS_Y_VALIDACION.md.

El fallback ocurre **solo** por SqlException 2812 (SP inexistente), envuelta en una excepción tipada. Errores de permisos, servidor, contrato o ejecución no degradan a una consulta más permisiva. El gerente recibe el historial existente; el vendedor consulta solo su ID por DAL/SP. Esos SP devuelven una fila por venta, suficiente para contar operaciones y sumar totales por fecha. Unidades/rankings permanecen desconocidos hasta habilitar el contrato completo.

- Desde incluye las 00:00:00 y hasta incluye todo su día: SQL usa `fecha >= @desde AND fecha < DATEADD(day,1,@hasta)`; Negocio replica ese intervalo en el fallback. No hay conversión horaria: se usa la fecha almacenada. Se rechaza rango invertido o incompatible con datetime SQL.
- Sin filtro de producto: SUM(Ventas.total) una sola vez por idVenta. El JOIN a detalles nunca multiplica cabeceras. Las ventas históricas sin sesión se conservan.
- Con filtro de producto: importe de las líneas seleccionadas (DetalleVentas.subtotal), operaciones distintas que las contienen y unidades de esas líneas. No se atribuye a un producto el importe completo de toda la factura.
- Unidades: SUM(cantidad) registrada. Se informa cantidad de ventas sin detalle; no se estiman unidades que no se guardaron.
- Ranking de productos/categorías: unidades e importes de detalles, sin excluir productos hoy inactivos. Top 10, orden determinista. Categoría/nombre son los actuales: no existe snapshot histórico.
- Comparación por vendedor: agrupa por idUsuario, no por nombre; se muestra un identificador para distinguir homónimos.
- Los gráficos usan Decimal/Long calculados y convierten a Double únicamente al representar. No se precargan series de ejemplo. Solo se dibujan grupos con registros; ausencia de filas muestra exactamente “Sin datos para el período seleccionado”. Un SP ausente se distingue de un período vacío.

Al cambiar filtros se eliminan los resultados anteriores y se solicita Actualizar; no se rotulan números viejos con fechas nuevas. La carga es asíncrona y los controles se bloquean mientras consulta. El cierre de la vista no escribe ni cierra Caja.

Los SP completos materializan una sola lectura y derivan todos sus resultados de esa base temporal. HOLDLOCK y transacción corta protegen las lecturas; solo se hace rollback de la transacción propia. Pueden bloquear escritores durante la materialización: evaluar planes/rangos con volumen real después de autorizar QA. No se añadieron índices especulativos; el inventario conserva los 16 reales.

## Migración aplicada exclusivamente a QA

`sql/qa/004_Reportes_Dashboards_QA.sql` crea/actualiza dos SP: dbo.sp_Reportes_VentasDashboard y dbo.sp_Reportes_BackupsDashboard. No cambia tablas ni datos. Es idempotente; cada lote exige base exacta QA, instancia configurada localmente y marca de aislamiento. No incluye USE, nombres reales de equipos ni rutas físicas.

El aplicador scripts/qa/Aplicar-Reportes-QA.ps1 exige -AutorizarMigracion antes de conectar, vuelve a verificar destino y aplica los lotes en una transacción. Guarda definiciones previas de esos SP en private (ignorado). El rollback de primera instalación solo retira los SP nuevos, con otra autorización; una actualización de SP preexistentes debe restaurar las definiciones respaldadas.

**Solo tras autorización expresa del usuario:**

```powershell
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\scripts\qa\Aplicar-Reportes-QA.ps1 -AutorizarMigracion
```

Ese comando se ejecutó el 27/10/2026 con autorización. Los dos SP no existían, se crearon sin cambios de tablas ni datos; el inventario actualizado registra 30 SP. No volver a aplicarlo como paso de inicio de la aplicación.

## Pruebas realizadas y pendientes

Compilación Debug/AnyCPU aprobada. Regresión existente: 449; dashboards offline: 37; lectura SQL y formularios reales: 20; fixtures con rollback: 15. Total final 521 aprobadas, sin bloqueos SQL. Detalle individual, incidencia del formato datetime corregida y controles de rollback en RESULTADOS_REPORTES_QA.md.

Los renders de los tres perfiles provienen de formularios y consultas QA reales, guardados ignorados en tests/artifacts/dashboards. No son validación interactiva. Pendientes: prueba del usuario desde el acceso, diseñador/DPI y rendimiento con volumen real.

## Cómo probar desde el acceso QA (GITHUB)

1. Cerrar la instancia anterior y hacer doble clic en FORZA SUPLEMENTOS - QA (GITHUB). El lanzador recompila y verifica el EXE; no abrirlo directamente ni usar F5 sin entorno QA.
2. Ingresar con cada perfil ficticio y abrir Reportes y Estadísticas. Gerente/vendedor: seleccionar desde/hasta, Actualizar y cambiar entre evolución diaria/mensual. Comparar importes/operaciones de la grilla y gráfico.
3. Con vendedor, verificar que no existe filtro de vendedor ni gráfico de vendedores. Los valores deben ser personales. Administrador: consultar historial y conteos reales; si no hay registros en el período, debe indicarlo.
4. Con 004 ya aplicada: gerente prueba unidades, productos, categorías, vendedores y filtros ID; vendedor su ranking; administrador historial/conteos. No interpretar registros de auditoría como estado exitoso/fallido.
5. Probar un período vacío y otro invertido. Al modificar fechas no deben quedar cifras anteriores. El carrito y la sesión Caja no se alteran al consultar o navegar.

Repetir validaciones sin escrituras:

```powershell
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\tests\ui\Probar-Dashboards-SinSql.ps1
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\tests\qa\Probar-Dashboards-Lectura.ps1
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\tests\qa\Validar-Preparacion-SinSql.ps1
```

La prueba con fixtures NO se incluye en ese bloque. Tras aplicar la migración y con nueva autorización para datos ficticios: `powershell -NoProfile -ExecutionPolicy RemoteSigned -File tests/qa/Probar-Dashboards-Preparados.ps1 -AutorizarFixtures`.

## Archivos de esta etapa

- Inventario/ER: docs/INVENTARIO_BASE_DATOS.md, docs/DIAGRAMA_ER.md y scripts QA de extracción/generación.
- SQL QA aplicado: 004, rollback protegido, aplicador con bandera, fixture SQL y runner transaccional; README de SQL actualizado.
- Código: Dashboard.vb, DashboardDAL.vb, DashboardBLL.vb, FrmReportes y Designer, y referencias de los cuatro proyectos.
- Pruebas: DashboardsSinSql.vb, Probar-Dashboards-SinSql.ps1, Probar-Dashboards-Lectura.ps1.
- Entrega: este documento, RESULTADOS_REPORTES_QA.md y README principal.

No hay push autorizado. El siguiente paso es la prueba manual de los dashboards completos desde Windows; los contratos SQL autorizados ya están validados.
