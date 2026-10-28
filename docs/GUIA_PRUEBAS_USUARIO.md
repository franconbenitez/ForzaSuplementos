# Revisión del usuario — avance intensivo

Abrir exclusivamente **FORZA SUPLEMENTOS - QA (GITHUB)**. El CMD recompila la salida Debug del repositorio principal y valida servidor, base QA y marca. Cerrar la instancia anterior por su interfaz antes de iniciar otra. No abrir el EXE directamente.

## Reportes disponibles ahora

Usar las claves QA ya configuradas por el usuario; no se distribuyen ni se recuperan contraseñas. Cuentas ficticias: qa_gerente, qa_vendedor, qa_vendedor2 y qa_admin.

- [ ] qa_gerente → Reportes y Estadísticas → desde 01/01/2000 hasta 31/12/2030 → Actualizar. Revisar facturación, operaciones, unidades, diaria, mensual, productos, categorías y vendedores.
- [ ] Con gerente, filtrar por un ID real de producto o vendedor que figure en los resultados; 0 significa todos. El importe filtrado por producto corresponde a sus líneas, no a toda la factura.
- [ ] qa_vendedor y qa_vendedor2 â†’ mismo rango â†’ revisar ventas y productos personales; no debe existir selector de otro vendedor.
- [ ] qa_admin → mismo módulo/rango → historial y evolución de registros de backups. Puede estar vacío; no generar backups para llenar una gráfica. No hay estados exitoso/fallido registrados.
- [ ] Desde 01/01/1753 hasta 02/01/1753 → Sin datos para el período seleccionado.
- [ ] Invertir fechas â†’ debe rechazar el rango. Cambiar fechas debe limpiar resultados anteriores hasta Actualizar.
- [ ] Comparar grilla y gráfico, maximizar y probar escala de Windows habitual. Revisar etiquetas, contraste, ejes y ausencia de controles superpuestos.

Enero de 2099 se usó únicamente para fixtures con rollback y debe quedar vacío. Los gráficos operativos consultan datos QA reales. El contraste independiente de rankings/productos/categorías de los tres actores pasó en 26 comprobaciones de lectura.

No ejecutar migraciones, establecer claves, confirmar compras, ajustar inventario ni generar backups durante esta revisión sin autorización específica. Login, Caja, Ventas y buscadores existentes conservan su comportamiento; las nuevas propuestas de esquema se detallan en ENTREGA_AVANCE_INTENSIVO.md.

Para informar observaciones: indicar cuenta ficticia/perfil, módulo, rango/filtros, pasos, resultado esperado y observado, y captura sin claves ni información personal. La validación visual interactiva sigue pendiente del usuario.

## Formularios nuevos visibles, pendientes de habilitación

Con qa_gerente → Gestión → Proveedores, Marcas, Compras e Inventario. En esta entrega debe verse **Requiere habilitación QA** y las operaciones de edición/confirmación deshabilitadas. Cambiar entre ellos debe conservar un solo formulario de trabajo. Administrador y vendedor no deben tener esos accesos ni poder abrirlos indirectamente.

Mi contraseña abre un diálogo oscuro para cambio propio. Mientras 005 no esté activada, Guardar informa que falta habilitar seguridad y no modifica claves. En Gestión de Usuarios, el menú contextual de un usuario activo ofrece Restablecer contraseña bajo la misma condición. Al editar un usuario, la clave aparece vacía: significa conservarla, nunca recuperar la anterior.

No uses ABM de usuarios para probar escrituras durante esta revisión de lectura. Las cuentas y contraseñas QA existentes siguen operativas; no se desplegó seguridad ni se activó el corte.

## Cuando se autorice y valide SQL (todavía no)

- 006: alta/modificación/baja lógica de proveedor, filtro por nombre/razón social/CUIT, marcas y asignación a producto activo.
- 007: seleccionar proveedor/producto, cantidades/costos, agregar/quitar/vaciar y confirmar compra. Consultar historial y doble clic para detalle. Costos no deben cambiar precios de venta.
- 008: consultar Stock y alertas, seleccionar producto, indicar cantidad signada y motivo; confirmar ajuste. Consultar movimientos y configurar mínimo. Los productos nuevos se crean con stock cero; entradas mediante compra o ajuste con motivo.
- 005 activada en etapa separada: probar clave correcta/incorrecta, cambio propio con clave actual, reset por administrador y edición sin cambio de clave.

Estas operaciones aún NO están habilitadas ni validadas con SQL. No ejecutar los scripts por tu cuenta como parte del doble clic.
