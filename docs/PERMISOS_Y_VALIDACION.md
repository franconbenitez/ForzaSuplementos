# Permisos corregidos — 26/10/2026

Este documento actualiza la observación histórica de NAVEGACION_CENTRALIZADA.md: el gerente ya no tiene acceso a Usuarios. Trabajo funcional en Desarrollo_Codex, con posterior copia revisada de contenido a ForzaSuplementos_GitHub. No se modifican SQL Server, migraciones, credenciales, conexiones ni datos reales.

## Matriz implementada

- Administrador: Usuarios, Backups y Reportes generales existentes. Sin acceso a Productos, Clientes, Ventas o Caja.
- Gerente: Productos, consulta de categorías para ese ABM y Reportes generales. Sin Usuarios, Clientes, Backups, Ventas o Caja.
- Vendedor: Clientes, Ventas, Caja y exclusivamente reportes de ventas propias. Accede al catálogo de productos activos para facturar, pero no al ABM de productos, inactivos o categorías. Sin Usuarios ni Backups.
- Sesión ausente, identificador inválido, perfil desconocido o permiso desconocido: rechazo por defecto. Normalización de mayúsculas/minúsculas y espacios del perfil.

Los reportes existentes de historial y bajo stock se mantienen disponibles para administrador/gerente como consultas generales. No se presenta una pantalla nueva de auditoría de backups ni un ABM nuevo de categorías: esas funcionalidades completas no existían y siguen pendientes. Existe la tabla de auditoría y consulta de categorías, pero eso no equivale a implementar sus pantallas y operaciones faltantes.

## Controles y archivos

Negocio/Permisos.vb centraliza la matriz. FrmPrincipal usa esa política para menús, para AbrirModulo antes de cerrar el hijo actual y para su fábrica. Alterar Available del menú o invocar directamente el método de navegación no evita la validación. Se conservan el único hijo MDI, cancelación por cambios pendientes, reutilización del módulo y tema oscuro.

La fábrica propaga UsuarioActual a los siete formularios. Presentacion/AccesoFormulario.vb verifica el permiso al cargar cada módulo, incluyendo Ventas y Caja: una apertura sin actor o con perfil restringido muestra acceso denegado y cierra la vista antes de cargar datos. Es una protección adicional a la autorización en negocio, no su sustituto.

UsuarioBLL, ProductoBLL, ClienteBLL y BackupBLL exigen actor obligatorio en cada operación de datos. Ya no hay sobrecargas ABM sin actor. Login sigue siendo el punto de autenticación previo y conserva sus validaciones y procedimiento. CajaBLL utiliza la misma política de vendedor; VentaBLL conserva su validación de vendedor y coincidencia del id de venta con la sesión. El vendedor solo puede listar productos activos para su catálogo, sin adquirir permisos de gestión.

ReporteBLL requiere sesión para todas las consultas. ObtenerMisVentas(actor) deriva el identificador del actor; la variante con identificador explícito rechaza cualquier diferencia antes de DAL. FrmReportes autoriza con UsuarioActual, no con sus campos heredados RolActual/UsuarioActualId, conservados para compatibilidad de presentación. Ambos campos no conceden permisos.

ReporteDAL verifica también perfil/id antes de construir los comandos. MisVentas recibe actor, no un identificador independiente; crea un parámetro Int @idUsuario con el id de sesión y conserva sp_Reporte_MisVentas. Los nombres de SP y contratos SQL no cambian. Ejecutar es un punto protegido sustituible para capturar el comando antes de abrir SQL en pruebas. ReporteBLL admite inyección explícita de DAL para ese ensayo, con constructor normal para producción.

Archivos de producción modificados: ReporteDAL; BackupBLL, CajaBLL, ClienteBLL, ProductoBLL, ReporteBLL, UsuarioBLL y proyecto Negocio; FrmPrincipal, FrmUsuarios, FrmProductos, FrmClientes, FrmBackup, FrmReportes, FrmVentas, FrmCaja y proyecto Presentacion. Nuevos: Permisos y AccesoFormulario. No cambian Entidades ni archivos Designer.

Pruebas: tests/ui/Probar-Permisos-SinSql.ps1 y ReporteSinSql.vb nuevos; VistasSinSql.vb y la matriz de Probar-Navegacion-SinSql.ps1 actualizados. Este documento describe el cambio y los límites; TRABAJO_DOS_EQUIPOS.md conserva los comandos de publicación y configuración de cada equipo.

## Resultados realmente ejecutados

- Solución completa Debug / Any CPU, salida habitual bin/Debug: cuatro proyectos compilados sin errores.
- Permisos: **205 comprobaciones aprobadas**. Matriz de cuatro perfiles, ausencia de sesión, rechazo de operaciones ABM/backup/venta/caja/reporte, fábrica real, usuario propagado y navegación indirecta con menús forzados visibles.
- Reportes: se captura el comando real de DAL antes de conectar. Se comprueba StoredProcedure, nombre de SP y @idUsuario=actor.IdUsuario. Un identificador ajeno se rechaza antes de ejecutar DAL; vendedores no ejecutan reportes globales.
- Navegación: **86 aprobadas** con la matriz nueva.
- Interfaz: **59 aprobadas**, incluyendo Login, carrito y tema de los nueve formularios.
- Reglas de Caja/Ventas: **20 aprobadas**.
- Total funcional: **370 comprobaciones aprobadas**, sin fallos en la ejecución final. Las primeras ejecuciones del nuevo host de pruebas requirieron corregir el tipo string[] y referencias System.Xml; no eran errores de la aplicación.

Las pruebas usan fixtures en memoria, Load de producción suprimido y entorno no admitido por Conexion para impedir conexiones accidentales. Los resultados comprueban autorización del código de aplicación, no seguridad SQL ni comportamiento con registros reales. No se ejecutaron pruebas de integración contra QA en esta tarea.

Repetir desde la raíz:

```powershell
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\scripts\compilar.ps1 -Configuration Debug
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\tests\ui\Probar-Permisos-SinSql.ps1
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\tests\ui\Probar-Navegacion-SinSql.ps1
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\tests\ui\Probar-Interfaz-SinSql.ps1
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\tests\Probar-Caja-SinSql.ps1
```

## Límite SQL y cambios pendientes de autorización

La revisión fue estática sobre los archivos del proyecto. sp_Caja_ValidarVendedor y los SP de Caja/Venta con sesión validan perfil/activo y pertenencia por idUsuario en las migraciones existentes; no se volvió a comprobar su despliegue real. sp_Reporte_MisVentas tiene WHERE v.idUsuario=@idUsuario, pero no autentica al solicitante. Los procedimientos de historial global y bajo stock no reciben actor. Los SP de ABM y backup conservan sus contratos previos sin autorización del usuario de aplicación.

Por lo tanto, la cuenta Windows con permisos SQL suficientes todavía podría llamar directamente procedimientos/tablas fuera de la aplicación. Además, un objeto Usuario construido o manipulado dentro de un proceso alterado no es una identidad criptográficamente autenticada. Los controles de aplicación no garantizan aislamiento ante un cliente modificado, revocación inmediata de un perfil ya cargado ni frente a acceso SQL directo. Las DAL de ABM no sustituyen los controles de Negocio; su endurecimiento efectivo necesita autorización SQL del lado servidor.

Antes de afirmar seguridad completa hace falta diseñar y autorizar una migración independiente, compatible y protegida para QA que:

1. Incorpore identidad de actor verificable y validación de perfil/activo para ABM, backup y reportes; el id de actor no debe equivaler por sí solo a autenticación.
2. Derive el alcance propio en servidor y rechace identificadores ajenos; mantenga la política de Caja/Ventas y sus transacciones.
3. Defina permisos mínimos para la identidad SQL de la aplicación y acceso directo a tablas/procedimientos antiguos, sin alterar credenciales ni conceder roles amplios automáticamente.
4. Actualice contratos DAL/SP coordinadamente y pruebe positivos/negativos con dos vendedores ficticios distintos, administrador y gerente, además de acceso directo y cambios de rol/activo.
5. Incluya auditoría de backups y ABM de categorías en tareas funcionales separadas, sin confundir la existencia de tablas con funcionalidades terminadas.

No se generó ni ejecutó una migración en esta entrega. Aplicar cambios o ejecutar ensayos SQL de escritura requiere autorización expresa nueva, exclusiva para QA. La base original no es un destino de pruebas.

## Revisión manual pendiente

Cerrar la versión anterior y abrir FORZA SUPLEMENTOS - QA del Escritorio (CMD protegido de Desarrollo_Codex). Con credenciales ficticias ya existentes, verificar los menús de los tres perfiles según la matriz anterior. Con vendedor, revisar que Reportes solo presente Mis ventas; con gerente, que no aparezca Usuarios; con administrador, que no haya Ventas/Caja. Confirmar navegación única, carrito pendiente y estilo oscuro. El código actualizado de apertura directa debe cerrar el formulario restringido mostrando acceso denegado. No confirmar ventas ni ejecutar backups solo para comprobar visibilidad.

Para probar el aislamiento real con dos vendedores y operaciones rechazadas por servidor se necesita la etapa SQL autorizada anterior. No se afirma haber completado esa prueba ni una revisión interactiva completa de WinForms.

## Sincronización y publicación futura

La última copia saneada previa terminaba en el cierre documental de la sincronización inicial. Los cambios pendientes eran la navegación centralizada y esta corrección. Se trasladan solo blobs de archivos revisados de cada etapa y se crean commits independientes, sin cherry-pick, fetch del original, copia de .git, bundles, configuraciones privadas o referencias originales.

La copia debe conservar como ancestros los ocho commits saneados originales y sus tres mejoras ya sincronizadas, añadir navegación y permisos, compilar y ejecutar los ensayos offline. Repetir scripts/auditar_git.py sobre todos los objetos, metadatos, ramas/referencias y árbol actual antes de publicar. La auditoría por patrones no garantiza ausencia absoluta de secretos futuros.

No hay publicación autorizada. Consultar TRABAJO_DOS_EQUIPOS.md para los comandos exactos: instalar/autenticar GitHub CLI, verificar cuenta franconbenitez, crear/verificar ForzaSuplementos privado, revisar origin y únicamente entonces, con autorización, enviar master. En cada PC usar un clon local independiente y qa.config privada ignorada, con una QA propia preparada por separado. Nunca publicar desde Desarrollo_Codex ni transferir bases o configuraciones entre equipos. En esta entrega no se ejecuta push ni se crea un repositorio remoto.
