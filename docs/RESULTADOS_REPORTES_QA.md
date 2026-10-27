# Resultados de reportes — 27/10/2026

Entorno: repositorio principal, VB.NET / .NET Framework 4.7.2, MSBuild de Visual Studio Community, SQL Server QA verificado por nombre de base, instancia esperada y marca. No se modifica la base original ni se aplican migraciones.

## Aprobado

- Compilación Debug / Any CPU de los cuatro proyectos.
- 449 comprobaciones de regresión existentes.
- 37 comprobaciones nuevas offline: fórmulas/fechas, mapeo, permisos y representación.
- 19 comprobaciones nuevas con SQL QA exclusivamente en lectura: resumen y evolución global/personal, separación entre dos vendedores, ID ajeno, vacío y formulario real.
- Sintaxis SQL/guardas del script 004 y compatibilidad estática de los contratos existentes. No equivale a desplegar el procedimiento.

Total de comprobaciones ejecutadas de aplicación: **505 aprobadas**. Los resultados QA detallados (solo estados/conteos, sin filas ni nombres personales) están ignorados en tests/artifacts/dashboards/resultado.json.

## Bloqueado o no ejecutado

- Dashboard comercial completo en servidor: bloqueado por SP nuevo ausente.
- Auditoría de backups en servidor: bloqueada por SP nuevo ausente.
- 15 ensayos del runner transaccional con fixtures: preparados, no ejecutados por falta de autorización SQL/aplicación de 004.
- Pruebas manuales del nuevo dashboard, diseñador/DPI y carga de gran volumen: pendientes.

## Defectos prevenidos/corregidos

- No se suman cabeceras repetidas después del JOIN con detalles: el SQL preparado deduplica por idVenta y el runner futuro verifica una venta de dos productos.
- El alcance de vendedor se deriva del actor en Negocio y se vuelve a verificar en el SP preparado; el formulario no usa un ID editable para ese perfil.
- SP inexistente, período sin filas y error de permisos/servidor son estados distintos; no se dibujan ceros ficticios para una función no desplegada.
- Cambiar filtros limpia resultados anteriores. Fechas inclusivas se aplican como intervalo cerrado/abierto.
- La auditoría no tiene estados: no se inventan éxitos/fallos ni se presentan intentos ausentes como cero.
- El primer host de pruebas requirió Convert.IsDBNull explícito; se corrigió y se repitió la validación.

La sesión anterior PID 11252 se cerró únicamente tras autorización expresa y verificación de ruta. No se ejecutaron ventas, backups ni escrituras para validar reportes. Ver DASHBOARDS_REPORTES.md para comandos y pasos siguientes.
