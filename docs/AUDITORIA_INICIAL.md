# Auditoría inicial de Forza Suplementos

Fecha: 26/10/2026. Alcance: copia local, cuatro capas, preparación de Git y compilación. No se ejecutó la aplicación, no se abrió una conexión SQL y no se modificó ninguna base de datos.

## Resultado

La solución SLNX es reconocida por MSBuild. Entidades, Datos y Negocio compilan en Debug/AnyCPU. Presentación falla con BC30002 en FrmPrincipal.vb, líneas 49 y 55: FrmCaja no existe. No se implementó un sustituto ni se quitaron referencias funcionales para ocultar el problema.

AGENTS.md se leyó cuando estuvo disponible durante el relevamiento. Sus notas SQL son antecedentes aportados por el proyecto; no equivalen a una inspección de la base actual. La afirmación de que MenuCaja está oculto no coincide completamente con esta copia: el diseñador crea el menú y el código lo oculta para administrador/gerente, pero no para vendedor.

## Entorno y recuperación

- Git 2.56.0.windows.1. Repositorio inicializado en la raíz de este proyecto, sin remotos. Commit inicial: a77eaf4. Recupera el código fuente original; excluye deliberadamente datos privados, backups y salidas generadas.
- .gitignore excluye bin, obj, .vs, preferencias personales, ZIP, backups, archivos de base de datos, reportes SQL locales y formatos habituales de secretos. Las exclusiones no sustituyen la revisión del diff antes de cada commit.
- Visual Studio Community instalado en la ruta de versión 18; MSBuild 18.11.1.51303 en MSBuild/Current/Bin. También hay una copia de MSBuild en SSMS y versiones antiguas del Framework, que no se eligieron.
- Los cuatro VBPROJ apuntan a .NET Framework 4.7.2. Referencias de compilación v4.7.2 disponibles; runtime instalado 4.8.09221, Release 533509. Runtime y framework objetivo son conceptos distintos.
- SDK de .NET 8.0.423 y 10.0.403 disponibles. Para esta solución clásica de VB/WinForms se verificó MSBuild de Visual Studio.
- SSMS 22 y sqlcmd disponibles. No se comprobó el estado del servicio SQL ni el contrato de los procedimientos con una conexión real.
- La conexión actual usa autenticación integrada. No se cambió la cadena ni se encontraron contraseñas SQL literales en ella.

## Inventario de las cuatro capas

Rutas relativas a ForzaSuplementos/ForzaSuplementos:

- Presentación: FrmLogin, FrmPrincipal, FrmUsuarios, FrmProductos, FrmClientes, FrmVentas, FrmReportes y FrmBackup, con sus diseñadores. FrmUsuarios tiene además su RESX. Inicio en FrmLogin. FrmPrincipal incluye dos clases privadas para renderizado del menú.
- Entidades: Categoria, Cliente, DetalleVenta, Perfil, Producto, Usuario y Venta. Class1 es una clase vacía y no está incluida en el VBPROJ.
- Negocio: BackupBLL, ClienteBLL, ProductoBLL, ReporteBLL, UsuarioBLL y VentaBLL.
- Datos: Conexion, BackupDAL, ClienteDAL, ProductoDAL, ReporteDAL, UsuarioDAL y VentaDAL.
- Referencias: Presentación -> Negocio y Entidades; Negocio -> Datos y Entidades; Datos -> Entidades. No se encontraron referencias de proyecto rotas ni archivos Compile faltantes, salvo el tipo de Caja ausente usado desde código.
- Los comandos SQL de los DAL son procedimientos almacenados parametrizados. Using gestiona conexiones y comandos. VentaDAL ya engloba cabecera y detalles en una transacción.

## Hallazgos por prioridad

### P0: compilación bloqueada

FrmPrincipal usa el tipo inexistente FrmCaja. MenuCaja existe en el diseñador, pero MenuCaja_Click no tiene Handles ni se encontró otro enlace al evento. Es un módulo pendiente, no solamente un problema visual. Antes de otra entrega debe resolverse de forma explícita y verificable. La presente auditoría conserva el código funcional original.

### P1: integridad de Ventas y futura Caja

VentaBLL solo verifica cliente, vendedor, carrito no vacío y total positivo. No valida cada cantidad/precio/identificador, no recalcula cada subtotal y no maneja objetos o listas nulos. El stock se valida con la copia de productos cargada en la interfaz: eso no garantiza disponibilidad ante ventas simultáneas.

VentaDAL usa transacción para cabecera y detalles, lo cual es una buena base. El descuento efectivo de stock depende del SP: no puede verificarse sin sus definiciones. AGENTS.md advierte que el SP exportado carecía del control suficiente. Es un antecedente de riesgo alto, pendiente de confirmar en una exportación de solo esquema. El ID de venta se asigna al objeto antes del commit; un rollback puede dejar el objeto con un ID no persistido. El manejo de errores pierde la excepción original y un fallo de Rollback puede ocultar el error inicial.

No existen FrmCaja, SesionCaja, CajaBLL ni CajaDAL. Venta no tiene IdSesion; el DAL no envía ese parámetro ni comprueba caja abierta. Faltan apertura, consulta de sesión activa, cierre, saldo esperado/contado, diferencia y vinculación de ventas a la sesión. AGENTS.md informa que existen tablas relacionadas con caja y backups, pero los scripts no están en esta copia. No crear nuevas tablas sin revisar primero ese esquema.

La integración futura debe garantizar en una misma operación atómica: sesión abierta del vendedor, stock suficiente, cabecera, detalles y asociación de la venta a caja. El cierre debe coordinarse con ventas concurrentes. Si hay varios medios de pago, el efectivo debe separarse para calcular el saldo de caja. Todo SQL se prepara para revisión y prueba en base aislada; no se ejecuta automáticamente.

### P1: seguridad de usuarios y permisos

Los permisos se aplican ocultando controles en FrmPrincipal/FrmReportes. BLL y DAL no verifican el rol del actor; ObtenerMisVentas acepta un ID recibido del llamador. Un rol desconocido deja visibles opciones por defecto. Se requiere autorización en negocio y consultas limitadas al usuario autenticado, conservando la matriz de AGENTS.md.

UsuarioDAL recupera el campo de contraseña y FrmUsuarios lo vuelve a colocar en el editor. No se observa hashing en VB; sin SQL no puede afirmarse cómo se almacena en la base. La recuperación de ese valor es incompatible con un diseño de contraseña no recuperable. Requiere revisión específica del contrato y una transición planificada; no se modificaron credenciales ni autenticación.

### P2: módulos parciales y estabilidad

- Reportes tiene historial, bajo stock y ventas propias, pero faltan fechas desde/hasta y filtros globales por vendedor/producto requeridos por AGENTS.md. Sus SP actuales no reciben esos filtros desde VB.
- Backup llama al SP de generación; no hay un flujo explícito en VB de auditoría/consulta de respaldos. La auditoría podría estar dentro del SP: queda sin verificar. La ruta elegida por el cliente es interpretada por SQL Server; permisos y acceso deben probarse en entorno aislado.
- FrmVentas carga clientes/productos sin manejo de excepción en Load. FrmClientes no maneja fallos de DAL en baja/reactivación. Pueden producir errores no controlados.
- FrmProductos ignora el resultado de TryParse para stock: un texto inválido termina convertido en cero y pasa la validación de negocio.
- Clientes solo valida campos obligatorios; faltan reglas equivalentes para formatos y límites. Varios DAL usan AddWithValue sin tipos/tamaños/precisión explícitos.
- FrmLogin se oculta y cada cierre de sesión crea otro login. Revisar ciclo de vida y salida: el formulario principal de la aplicación sigue siendo el login original oculto.
- OptionStrict está desactivado en todos los proyectos. Conviene endurecerlo gradualmente; no activarlo globalmente sin revisar conversiones.
- No hay proyectos de pruebas ni scripts SQL versionados. El HTML de generación SQL es un reporte local excluido; no sustituye las definiciones del esquema.

## Cambios realizados

- .gitignore: protección inicial de archivos locales, generados y sensibles.
- scripts/compilar.ps1: compilación reproducible que localiza MSBuild y devuelve su código de salida; no inicia la aplicación ni accede a SQL.
- docs/AUDITORIA_INICIAL.md: diagnóstico, inventario, evidencia y pasos siguientes.
- AGENTS.md: leído y conservado sin cambios; incorporado al seguimiento para futuras tareas.

No se cambiaron archivos VB, diseñadores, proyectos ni conexión SQL. No se crearon scripts SQL ni módulos nuevos.

## Verificación y reproducción

Se ejecutó Rebuild Debug/AnyCPU con MSBuild de Visual Studio y compilador compartido desactivado: tres bibliotecas compiladas y dos BC30002 en Presentación. Una primera ejecución lenta se solapó con un segundo intento y produjo errores de copia transitorios; se repitió secuencialmente para aislar el resultado. No confundir esos errores de copia con el bloqueo reproducible por FrmCaja.

1. En PowerShell, desde la raíz del proyecto: `powershell -NoProfile -File .\scripts\compilar.ps1`. La política local bloqueó ejecutar archivos PS1; no se cambió esa política. Se verificó el contenido del script como bloque en memoria, ajustando únicamente la resolución de la raíz. Como alternativa reproducible sin cambiar políticas, ejecutar directamente: `& "$env:ProgramFiles\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe" .\ForzaSuplementos\ForzaSuplementos\ForzaSuplementos.slnx /t:Rebuild /p:Configuration=Debug /nologo /v:minimal /nr:false /p:UseSharedCompilation=false`. Debe devolver error mientras falte FrmCaja.
2. En Visual Studio Community, abrir ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.slnx; seleccionar Debug y Any CPU; Compilar > Recompilar solución. Confirmar los dos BC30002 en FrmPrincipal. No usar un EXE anterior de bin como evidencia de compilación actual.
3. En SSMS, sin ejecutar scripts sobre la base real, exportar solo esquema a una carpeta privada: tablas, restricciones y SP. Revisar sp_Ventas_Registrar, sp_DetalleVentas_Insertar, SesionesCaja y AuditoriaBackups. Excluir datos e información personal. No se hizo este paso durante la auditoría.
4. Para futuras pruebas funcionales, preparar una instancia/base aislada con datos ficticios y conexión verificada expresamente. Probar stock concurrente, rollback de detalle, permisos por rol y apertura/cierre de sesión antes de cualquier uso real.

Siguiente trabajo recomendado: estabilizar la compilación y confirmar el contrato SQL de Ventas/stock; luego implementar Caja e integración con Ventas en las cuatro capas. Es el siguiente módulo de mayor impacto. Reportes filtrados queda después de esa base transaccional.
