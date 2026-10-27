# Navegación centralizada — 26/10/2026

## Implementación

Trabajo exclusivo en Desarrollo_Codex. No se modifican SQL Server, migraciones, conexiones QA, capas de datos/negocio/entidades, tema oscuro, archivos Designer ni la copia saneada para GitHub.

FrmPrincipal concentra los siete eventos del menú en AbrirModulo. Si el módulo ya existe se activa la misma instancia, restaurándola si estaba minimizada. Al cambiar de módulo llama Close en el hijo actual y comprueba si realmente se cerró antes de construir el destino. Un cierre cancelado mantiene la vista y evita incluso construir el formulario nuevo. La fábrica conserva la inyección de usuario, identificador y perfil en Caja, Ventas y Reportes. Una bandera evita reentradas y se libera mediante Finally, incluso si falla la apertura. Una apertura fallida dispone la nueva instancia. No utiliza Hide para los módulos.

Los eventos mantienen sus Handles y usan la disponibilidad de cada menú (Available), sin modificar ConfigurarPermisos. Visible en un elemento de un desplegable también depende de que el desplegable esté abierto: por eso no corresponde usarlo como condición de navegación. La protección también actúa al cerrar el hijo mediante X y al cerrar FrmPrincipal. Cerrar sesión no abre Login si el hijo cancela el cierre. El mecanismo anterior de ocultar Login al autenticar no se modifica: no es un módulo MDI.

ProtectorCambios es una utilidad exclusivamente de Presentación que escucha FormClosing y FormClosed, con No como opción predeterminada. En Ventas detecta líneas del carrito y utiliza exactamente:

> Tenés productos en el carrito. Si salís, se perderá la venta sin confirmar. ¿Querés continuar?

No conserva el carrito y total; Sí permite cerrar. El descarte ocurre solo en FormClosed, de modo que una cancelación posterior de otro manejador no pierda datos. Al cerrarse se desuscribe ListChanged antes de limpiar la colección, sin actualizar controles cerrados ni llamar BLL/DAL. Vaciar carrito y Confirmar Venta conservan su comportamiento anterior.

Clientes, Productos y Usuarios toman una instantánea en memoria de sus campos editables. EstablecerBase se ejecuta tras limpiar el formulario y cargar un registro para edición. Guardar correctamente utiliza la limpieza existente, por lo que también restablece la base. Un guardado fallido no borra el estado pendiente. Se comparan los valores actuales: seleccionar un registro sin editar, volver a los valores originales o limpiar/cancelar no produce advertencias. Las instantáneas no se escriben en archivos ni se muestran en resultados.

Caja no tiene cierres SQL asociados a FormClosing/FormClosed: cerrar la vista no cierra la sesión. Solo el botón explícito existente realiza ese cierre. Sus importes sin ejecutar una acción son entradas transitorias, no cambios persistidos. Los filtros/reportes y la ruta elegida de Backup tampoco se consideran edición de registros sin guardar. No se añaden confirmaciones por navegar entre esas vistas. Los Load existentes pueden hacer consultas de lectura al abrir módulos; no se añaden escrituras SQL por navegar.

## Archivos

- FrmPrincipal.vb: navegación, fábrica y cancelación de cierre de sesión.
- FrmVentas.vb: protección y descarte local tras cierre efectivo.
- FrmClientes.vb, FrmProductos.vb, FrmUsuarios.vb: puntos de referencia de edición.
- ProtectorCambios.vb: confirmación reutilizable y comparación de campos.
- ForzaSuplementos.Presentacion.vbproj: inclusión explícita de la utilidad.
- tests/ui/VistasSinSql.vb: contenedor MDI con fábrica de vistas sin Load SQL para ensayos.
- tests/ui/Probar-Navegacion-SinSql.ps1: casos reproducibles de navegación y cierre.
- Este documento: resultados y verificación manual.

## Pruebas ejecutadas

Solución completa: MSBuild de Visual Studio Community 18, Debug / Any CPU, salida habitual bin/Debug, cuatro proyectos compilados sin errores. No había procesos de Forza abiertos al comenzar; no se finalizaron procesos.

86 comprobaciones nuevas de navegación aprobadas: un hijo, activación/reutilización, minimizado, carrito vacío, No conserva carrito/total, Sí descarta en memoria, texto exacto, cierre de principal cancelado, cierre de sesión cancelado sin Login extra, cancelación posterior al Sí, descarte al cierre efectivo, edición/reversión de los tres ABM, 15 alternancias repetidas, recuperación tras fallo simulado de fábrica y navegación de los tres perfiles.

59 comprobaciones existentes de interfaz y 20 de reglas/constructor de Caja aprobadas. Total: **165 comprobaciones aprobadas; ninguna fallida en la ejecución final**. El ensayo inicial detectó la condición incorrecta basada en Visible para los submenús; se corrigió con Available y se repitió toda la regresión.

Los tests construyen formularios y ejecutan eventos reales en Windows, pero suprimen los Load de producción y simulan las respuestas de confirmación y datos. FORZA_ENTORNO se establece temporalmente a un valor no admitido por Conexion, de modo que cualquier entrada accidental a datos falla antes de conectarse. No se autenticó contra SQL ni se confirmó una venta. La prueba de Caja utiliza una sesión ficticia abierta en memoria y comprueba que salir no cierra esa sesión ni llega a SQL; no constituye una comprobación del estado de una sesión real en el servidor.

Repetir desde la raíz del proyecto:

```powershell
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\scripts\compilar.ps1 -Configuration Debug
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\tests\ui\Probar-Navegacion-SinSql.ps1
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\tests\ui\Probar-Interfaz-SinSql.ps1
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\tests\Probar-Caja-SinSql.ps1
```

## Verificación interactiva pendiente

1. Cerrar cualquier instancia anterior por su interfaz y hacer doble clic en FORZA SUPLEMENTOS - QA del Escritorio. Apunta al CMD protegido de Desarrollo_Codex y a Debug actualizado. Verificar el indicador QA en el título de Principal; no abrir directamente el EXE ni usar F5 sin entorno QA.
2. Con vendedor, alternar Ventas, Clientes, Caja y Reportes. Debe quedar un único hijo. Reelegir el actual debe conservar su estado sin abrir otro. Minimizarlo y reelegirlo debe restaurarlo.
3. Con carrito vacío, cambiar de módulo: no debe preguntar. Agregar un producto ficticio y cambiar: responder No debe conservar producto y total. Repetir y responder Sí: debe abrir el destino; volver a Ventas debe mostrar un carrito vacío. No confirmar una venta para este ensayo.
4. Repetir con la X de Ventas, la X de Principal y Cerrar sesión. No debe conservar el formulario; Sí debe permitir el cierre sin registrar venta. No en Cerrar sesión no debe abrir Login adicional.
5. Editar un campo en Clientes, Productos o Usuarios según el perfil. Cambiar de módulo y responder No debe conservar el valor; Sí debe permitir descartarlo. Cargar un registro sin editarlo, limpiar/cancelar o revertir el valor no debe preguntar. Verificar guardado y validación fallida con fixtures QA si se autoriza una prueba de escritura separada.
6. Con una sesión QA ya abierta, anotar su idSesion, alternar Caja/Ventas/Reportes y volver a Caja. Debe seguir abierta. No pulsar Cerrar caja durante esta comprobación. En SSMS, seleccionar explícitamente ForzaSuplementosDB_QA y consultar, en lectura, antes y después:

```sql
IF DB_NAME() <> N'ForzaSuplementosDB_QA'
    THROW 51000, N'Seleccionar exclusivamente la base QA.', 1;
SELECT idSesion, estado, fechaCierre
FROM dbo.SesionesCaja
WHERE idSesion = 123; -- Sustituir solo por el identificador ficticio anotado.
```

7. Repetir navegación con administrador y gerente, revisar menús y tema oscuro, distribución, maximizado y escalado 125/150 %. La matriz existente se conserva. Observación previa: ConfigurarPermisos permite el menú Usuarios al gerente; no se cambia aquí por la restricción de preservar permisos. Su revisión funcional corresponde a otra tarea.

No se realizaron estas interacciones manuales ni consultas SSMS en esta entrega. No hay scripts SQL nuevos. La siguiente tarea de mayor impacto es completar la revisión manual de navegación con fixtures QA y los tres perfiles antes de agregar módulos.
