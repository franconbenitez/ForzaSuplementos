# Resultados de reportes — 27/10/2026

Repositorio principal ForzaSuplementos_GitHub. Windows PowerShell / .NET Framework 4.7.2 y MSBuild de Visual Studio Community. Aplicación de 004 y fixtures autorizados expresamente por el usuario para QA.

## Destino y migración

Antes de escribir, Open-QaConnection verificó mediante SELECT la instancia configurada localmente, DB_NAME() exactamente ForzaSuplementosDB_QA y la marca Forza-QA-Aislada-v1. Ninguna conexión de esta ejecución apuntó a la base original.

Los dos SP no existían antes. Se aplicó exclusivamente 004 en una transacción: sp_Reportes_VentasDashboard y sp_Reportes_BackupsDashboard. Se consultaron sus parámetros en sys.parameters y se ejecutaron ambos contratos reales (seis y cuatro resultados). QA tiene ahora **30 procedimientos, 11 tablas, 11 FK, 16 índices y 4 CHECK**. Sin cambios de tablas, usuarios ni archivos de backups. No se ejecutaron otras migraciones ni retiro de procedimientos.

No había definiciones anteriores que restaurar. El aplicador conserva las existentes en private cuando las hay; se corrigió su serialización para que un inventario vacío se guarde como JSON [] en próximas ejecuciones. El baseline y artefactos permanecen privados e ignorados.

## Los 15 ensayos con fixtures

Datos iniciales: período 2099-01 vacío; IDs de referencia ficticios de qa.Fixtures. Dentro de una sola transacción se agregó un producto, dos ventas (350 y 100), tres detalles (cinco unidades) y dos registros sintéticos de auditoría. No se generó ningún archivo de backup ni se ejecutó el registro operativo de ventas.

1. **Aprobado:** contrato comercial devuelve seis tablas.
2. **Aprobado:** factura con dos detalles no duplica cabecera; total 450, dos operaciones y cinco unidades.
3. **Aprobado:** evolución devuelve dos días y un mes con importe 450.
4. **Aprobado:** ranking de dos productos suma cinco unidades.
5. **Aprobado:** ranking de categorías suma cinco unidades.
6. **Aprobado:** comparación distingue dos IDs de vendedor y suma 450.
7. **Aprobado:** vendedor consulta solamente su venta de 350, una operación.
8. **Aprobado:** filtro de producto devuelve 150 y dos unidades, no el total de la factura.
9. **Aprobado:** administrador obtiene cuatro resultados y dos registros ficticios de auditoría.
10. **Aprobado:** auditoría no inventa Estado y devuelve solo el nombre del archivo.
11. **Aprobado:** tras rollback no hay operaciones del período ficticio.
12. **Aprobado:** vendedor solicitando otro vendedor es rechazado en SQL (51404).
13. **Aprobado:** administrador solicitando dashboard comercial es rechazado (51403).
14. **Aprobado:** gerente solicitando auditoría de backups es rechazado (51405).
15. **Aprobado:** actor inactivo es rechazado (51403).

Resultado final: **15 aprobados, 0 fallidos, 0 bloqueados**. El runner se ejecutó dos veces correctamente tras la corrección, cada una con rollback. Los importes anteriores son exclusivamente los esperados/observados de fixtures transitorios, no estadísticas comerciales.

## Incidencia y rollback

El primer intento falló antes del primer assert por el literal de fecha de fixture `20990101T12:00:00`, incompatible con datetime. El finally revirtió la transacción. Se verificó inmediatamente que los conteos de todas las tablas coincidían con el baseline y el período seguía vacío. Se corrigieron los literales a ISO `2099-01-01T12:00:00` y su segundo día; no se modificó el SQL del dashboard.

Se reforzó el runner para comparar los conteos de todas las tablas después del rollback y exigir @@TRANCOUNT=0. También se repitió una comparación independiente contra el baseline previo a la migración: todas las tablas iguales, cero ventas/auditorías ficticias en enero de 2099. El fixture no inserta ni cierra sesiones de Caja; SesionesCaja conserva su conteo y no queda ninguna transacción del runner. Las conexiones se disponen en finally. Los contadores IDENTITY pueden avanzar aun con rollback; no se reseedearon.

## Compilación y regresión ejecutadas

- Compilación Debug / Any CPU: cuatro proyectos, aprobada.
- Permisos: 205 comprobaciones; navegación: 86; interfaz/Login/carrito: 59; Caja offline: 20; buscadores offline: 49; identidad binaria: 5; selección QA lectura: 8; buscadores modales reales QA: 17. **449 aprobadas**.
- Dashboards offline: **37 aprobadas**.
- Dashboards SQL QA lectura: **20 aprobadas, 0 bloqueadas**. Gerente y dos vendedores contrastados con SUM/COUNT/GROUP BY independientes; unidades y contrato completo; administrador con conteo/historial real y estados desconocidos; formularios reales con gráficos y alcance por perfil.
- Fixtures de dashboards: **15 aprobadas**.
- Total de comprobaciones de aplicación de la ejecución final: **521 aprobadas**. No se suman reejecuciones. Validación adicional estática SQL/guardas: aprobada.

No se repitieron los 18 ensayos operativos de escritura de Caja/Ventas: esta autorización se limita a 004 y fixtures de reportes. La regresión de Caja/Ventas de esta etapa es offline y de selección en lectura, sin registrar ventas ni cambiar stock.

## Pendientes y prueba manual

La validación visual interactiva corresponde al usuario: no se declara completada. Se instanciaron formularios reales y se generaron renders DrawToBitmap ignorados; eso no sustituye mouse/teclado, DPI, diseñador ni rendimiento con volumen real.

Cerrar la instancia anterior, abrir **FORZA SUPLEMENTOS - QA (GITHUB)**, iniciar con cada perfil ficticio y entrar a Reportes y Estadísticas. Elegir fechas con datos QA y Actualizar. Gerente: diaria, mensual, productos, categorías y vendedores; filtros ID de producto/vendedor (0=todos). Vendedor: diaria, mensual y productos propios, sin selector de otro vendedor. Administrador: historial/conteo y evolución de registros de backups; si el período no tiene registros, mensaje Sin datos para el período seleccionado. No se inventan estados exitoso/fallido porque el esquema no los registra.

Probar fechas vacías/invertidas y confirmar que cambiar fechas limpia el resultado anterior. El período 2099-01 debe quedar vacío después de los ensayos. No generar un backup físico para probar este dashboard.

No hay push autorizado. Próximo paso: revisión manual de dashboards y, después, publicación de los commits locales con autorización.
