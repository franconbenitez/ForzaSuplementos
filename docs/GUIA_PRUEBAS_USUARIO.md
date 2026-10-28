# Revisión del usuario — avance intensivo

Abrir exclusivamente **FORZA SUPLEMENTOS - QA (GITHUB)**. El CMD recompila la salida Debug del repositorio principal y valida servidor, base QA y marca. Cerrar la instancia anterior por su interfaz antes de iniciar otra. No abrir el EXE directamente.

## Reportes disponibles ahora

Usar las claves QA ya configuradas por el usuario; no se distribuyen ni se recuperan contraseñas. Cuentas ficticias: qa_gerente, qa_vendedor, qa_vendedor2 y qa_admin.

- [ ] qa_gerente → Reportes y Estadísticas → desde 01/01/2000 hasta 31/12/2030 → Actualizar. Revisar facturación, operaciones, unidades, diaria, mensual, productos, categorías y vendedores.
- [ ] Con gerente, filtrar por un ID real de producto o vendedor que figure en los resultados; 0 significa todos. El importe filtrado por producto corresponde a sus líneas, no a toda la factura.
- [ ] qa_vendedor y qa_vendedor2 → mismo rango → revisar ventas y productos personales; no debe existir selector de otro vendedor.
- [ ] qa_admin → mismo módulo/rango → historial y evolución de registros de backups. Puede estar vacío; no generar backups para llenar una gráfica. No hay estados exitoso/fallido registrados.
- [ ] Desde 01/01/1753 hasta 02/01/1753 → Sin datos para el período seleccionado.
- [ ] Invertir fechas → debe rechazar el rango. Cambiar fechas debe limpiar resultados anteriores hasta Actualizar.
- [ ] Comparar grilla y gráfico, maximizar y probar escala de Windows habitual. Revisar etiquetas, contraste, ejes y ausencia de controles superpuestos.

Enero de 2099 se usó únicamente para fixtures con rollback y debe quedar vacío. Los gráficos operativos consultan datos QA reales. El contraste independiente de rankings/productos/categorías de los tres actores pasó en 26 comprobaciones de lectura.

No ejecutar migraciones, establecer claves, confirmar compras, ajustar inventario ni generar backups durante esta revisión sin autorización específica. Login, Caja, Ventas y buscadores existentes conservan su comportamiento; las nuevas propuestas de esquema se detallan en ENTREGA_AVANCE_INTENSIVO.md.

Para informar observaciones: indicar cuenta ficticia/perfil, módulo, rango/filtros, pasos, resultado esperado y observado, y captura sin claves ni información personal. La validación visual interactiva sigue pendiente del usuario.
