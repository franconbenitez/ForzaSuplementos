# Dashboards de reportes por perfil

Fecha: 27/10/2026. Repositorio principal ForzaSuplementos_GitHub; sin modificar el respaldo, credenciales, conexión habitual ni SQL Server. La única instancia cerrada fue PID 11252, tras verificar la ruta y recibir autorización expresa del usuario.

## Esquema auditado

La conexión QA verificada consultó sys.* en lectura: **11 tablas** (10 de aplicación + qa.Fixtures), 11 FK, 16 índices, 4 CHECK y 28 SP existentes. Inventario completo: INVENTARIO_BASE_DATOS.md. Relaciones reales: DIAGRAMA_ER.md. No se exportaron filas, contraseñas, rutas de backup ni el identificador del equipo a los documentos.

## Qué funciona ahora y qué está preparado

- **Gerente:** facturación, operaciones y columnas de evolución diaria/mensual ya funcionan con los SP existentes y filtros desde/hasta. Unidades registradas, ranking de productos/categorías, comparación por ID de vendedor y filtros adicionales están implementados en las cuatro capas, pero requieren aplicar el nuevo SP comercial de 004. Mientras falta, se indica pendiente y se deshabilitan filtros no soportados; no se ignoran silenciosamente.
- **Vendedor:** totales personales, operaciones y evolución diaria/mensual funcionan con sp_Reporte_MisVentas y el id de sesión. Ranking de sus productos y unidades requieren el SP nuevo, que vuelve a derivar alcance en servidor. La UI no ofrece ID de vendedor ni comparaciones ajenas.
- **Administrador:** historial de backups, cantidad en el período y gráficos diario/mensual implementados, pendientes de sp_Reportes_BackupsDashboard. El SP de generación de backups no sirve para consultar y no se invoca. No hay fallback a una consulta de ventas para simular auditoría.
- **Estados de backup:** no existen en AuditoriaBackups; exitosos/fallidos son desconocidos (Nothing), no ceros. No se dibujan gráficos de estados inventados. Se cuentan registros, no se afirma que los archivos existan o sean restaurables.

Se mantienen los botones de consultas anteriores (historial, bajo stock y ventas propias) y sus permisos. Son consultas heredadas sin los filtros nuevos, identificadas como tales. La vista principal del dashboard depende del perfil. No se alteró la navegación centralizada ni el tema oscuro compartido.

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

## Migración preparada — NO EJECUTADA

`sql/qa/004_Reportes_Dashboards_QA.sql` crea/actualiza dos SP: dbo.sp_Reportes_VentasDashboard y dbo.sp_Reportes_BackupsDashboard. No cambia tablas ni datos. Es idempotente; cada lote exige base exacta QA, instancia configurada localmente y marca de aislamiento. No incluye USE, nombres reales de equipos ni rutas físicas.

El aplicador scripts/qa/Aplicar-Reportes-QA.ps1 exige -AutorizarMigracion antes de conectar, vuelve a verificar destino y aplica los lotes en una transacción. Guarda definiciones previas de esos SP en private (ignorado). El rollback de primera instalación solo retira los SP nuevos, con otra autorización; una actualización de SP preexistentes debe restaurar las definiciones respaldadas.

**Solo tras autorización expresa del usuario:**

```powershell
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\scripts\qa\Aplicar-Reportes-QA.ps1 -AutorizarMigracion
```

No se ejecutó ese comando. No se modificó ninguna base. Después de aplicar, el dashboard detecta el SP automáticamente; no hace falta reimplementar la UI. Regenerar el inventario para registrar los dos SP nuevos y contrastar su contrato real.

## Pruebas realizadas y pendientes

- Compilación completa Debug / Any CPU: aprobada, cuatro proyectos.
- Regresión existente: 449 comprobaciones (Caja, Ventas, buscadores, Login, permisos, navegación, identidad y selección QA); sin escrituras en esta entrega.
- Dashboards offline: **37 aprobadas**, con fechas límite, agrupación, permisos, ID ajeno, no fallback ante errores, mapeo completo simulado, estados de backup desconocidos, gráfico vacío y geometría mínima.
- Dashboards QA de lectura: **19 aprobadas**. Dos vendedores distintos y gerente se compararon con consultas independientes SUM/COUNT/GROUP BY; se verificaron alcance personal, período vacío y gráficos en formularios reales.
- **2 verificaciones SQL bloqueadas:** contratos completos de ventas y backups, porque 004 no está aplicada. No se afirma que rankings/unidades/auditoría pasaron contra servidor.
- **15 ensayos ficticios preparados, no ejecutados:** runner Probar-Dashboards-Preparados.ps1. Incluye una factura con dos productos (control contra duplicación), otra de otro vendedor, fechas, unidades/rankings, filtro por producto, auditoría, alcance/roles/activo y rollback. Requiere autorización separada -AutorizarFixtures y ambos SP desplegados. El período de prueba 2099-01 se rechaza si ya tiene datos. Todas las altas nuevas se revierten; no se genera un archivo de backup.

Los renders de gerente/vendedor provienen de datos QA reales; el de administrador muestra el bloqueo honesto por migración. Son DrawToBitmap de formularios, no una sesión interactiva del escritorio. Se guardan ignorados en tests/artifacts/dashboards; no se versionan cifras ni imágenes. La estética y navegación previas aprobadas se mantienen. Pendientes: revisión manual desde el acceso, diseñador/DPI, SP completos y evaluación de rendimiento con volumen real.

## Cómo probar desde el acceso QA (GITHUB)

1. Cerrar la instancia anterior y hacer doble clic en FORZA SUPLEMENTOS - QA (GITHUB). El lanzador recompila y verifica el EXE; no abrirlo directamente ni usar F5 sin entorno QA.
2. Ingresar con cada perfil ficticio y abrir Reportes y Estadísticas. Gerente/vendedor: seleccionar desde/hasta, Actualizar y cambiar entre evolución diaria/mensual. Comparar importes/operaciones de la grilla y gráfico.
3. Con vendedor, verificar que no existe filtro de vendedor ni gráfico de vendedores. Los valores deben ser personales. Administrador: por ahora debe indicar pendiente de actualización, no cero backups.
4. Después de autorizar/aplicar 004: gerente prueba unidades, productos, categorías, vendedores y filtros ID; vendedor su ranking; administrador historial/conteos. No interpretar registros de auditoría como estado exitoso/fallido.
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
- SQL pendiente: 004, rollback protegido, aplicador con bandera, fixture SQL y runner transaccional; README de SQL actualizado.
- Código: Dashboard.vb, DashboardDAL.vb, DashboardBLL.vb, FrmReportes y Designer, y referencias de los cuatro proyectos.
- Pruebas: DashboardsSinSql.vb, Probar-Dashboards-SinSql.ps1, Probar-Dashboards-Lectura.ps1.
- Entrega: este documento, RESULTADOS_REPORTES_QA.md y README principal.

No hay push autorizado. El siguiente paso necesario para completar los indicadores es revisar y autorizar la aplicación de 004 y sus pruebas QA; no avanzar a otra funcionalidad antes de validar estos contratos completos.
