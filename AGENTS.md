# Instrucciones para agentes — Forza Suplementos

## Entorno real
- Proyecto académico de Taller de Programación II, UNNE.
- Visual Basic .NET, Windows Forms, .NET Framework 4.7.2, Visual Studio Community.
- SQL Server local administrado desde SSMS; acceso mediante ADO.NET / System.Data.SqlClient.
- Solución: `ForzaSuplementos.slnx`; proyectos/capas: `ForzaSuplementos.Presentacion`, `ForzaSuplementos.Entidades`, `ForzaSuplementos.Negocio`, `ForzaSuplementos.Datos`.
- Cadena actual encontrada en `Datos/Conexion.vb`: `Server=localhost;Database=ForzaSuplementosDB;Integrated Security=True;TrustServerCertificate=True;`. No cambiarla sin comprobar la instancia que usa el desarrollador.
- El proyecto fue ejecutado y probado por el usuario. Preservar una versión que funcione.

## Reglas de implementación
1. Mantener VB.NET, WinForms, .NET Framework 4.7.2 y la arquitectura de cuatro capas. No migrar a C#, ASP.NET, Entity Framework ni otro framework.
2. Los formularios no ejecutan SQL ni instancian SqlConnection. UI -> BLL -> DAL; las entidades son modelos sin acceso a datos.
3. Operaciones de datos de aplicación mediante procedimientos almacenados parametrizados (`CommandType.StoredProcedure`). No usar SQL concatenado en la aplicación.
4. Mantener nombres existentes y compatibilidad con archivos `.Designer.vb`, `.resx` y referencias `.vbproj`. Asegurar que todo formulario nuevo figure en el proyecto si el formato no incluye archivos automáticamente.
5. Trabajar en tareas pequeñas. Antes de editar: inspeccionar dependencias, resumir plan y riesgos. Después: revisar diff, compilar cuando sea posible, probar o detallar pasos manuales y archivos modificados.
6. No ejecutar scripts de creación completos sobre `ForzaSuplementosDB` existente, ni borrar tablas, ni truncar datos, ni restaurar backup sin autorización expresa. Preparar migraciones idempotentes y reversibles, respaldar y probar sobre base clonada.
7. No modificar credenciales ni datos reales; no subir contraseñas, backups `.bak` ni datos personales a repositorios compartidos. No imprimir secretos en reportes.
8. Nunca afirmar que algo está probado si no se compiló/ejecutó realmente; explicar limitaciones del entorno Windows/SQL Server.
9. Priorizar integridad y seguridad: transacciones atómicas, control de stock suficiente, validaciones del lado servidor, controles de rol en negocio, manejo de errores, y evitar contraseñas en texto plano como objetivo de corrección.
10. No añadir tablas por cantidad; cada relación, índice, restricción y entidad debe tener justificación funcional.

## Requisitos y permisos de referencia
- Administrador: ABM usuarios, respaldo y auditoría de backups. No realiza ventas ni opera caja.
- Gerente: productos y reportes globales con filtros fecha desde/hasta, vendedor y producto. No vende ni opera caja.
- Vendedor: ventas, ABM clientes, caja y reporte de ventas propias con fechas desde/hasta.
- Vendedor solo puede ver sus propios resultados, enforced por BLL/DAL, no solo menú.
- Completar apertura/cierre de caja asociando ventas a sesiones y, si se implementan varios medios de pago, distinguiendo efectivo de otros medios.
- Para muchos productos/clientes, usar DataGridView con búsqueda/filtro/selección, evitando ComboBox enormes.

## Estado conocido al recibir el proyecto
- En la copia de preentrega no existe `FrmCaja` ni `CajaBLL`, `CajaDAL`, `SesionCaja` aunque resúmenes anteriores los mencionaban. `MenuCaja` quedó temporalmente oculto para preservar la estabilidad.
- SQL exportado por el usuario (25/10/2026): 9 tablas, 10 FKs y 20 procedimientos; `Ventas.idSesion` nullable; `sp_Ventas_Registrar` no recibe `idSesion`; `sp_DetalleVentas_Insertar` descuenta stock sin control suficiente; existen `SesionesCaja` y `AuditoriaBackups`, sin los SP operativos completos de caja.
- Prioridad inmediata: auditoría de compilación y SQL, corrección de stock/transacciones, módulo Caja funcional y reportes requeridos. No modificar producción directamente.

## Informe obligatorio tras cada tarea
- Archivos cambiados y motivo.
- Scripts SQL nuevos (sin ejecutarlos salvo autorización explícita).
- Pruebas realmente ejecutadas y resultado.
- Pasos exactos que el estudiante debe realizar en Visual Studio y SSMS para verificar.
- Riesgos o pendientes, y cuál sería la próxima tarea de mayor impacto.
