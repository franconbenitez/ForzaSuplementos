# Corrección del inicio QA y comprobación visible de buscadores

Fecha: 26/10/2026. Trabajo exclusivo en ForzaSuplementos_GitHub. Sin cambios SQL, migraciones, datos, configuración de conexión, Caja o reglas de autenticación/confirmación. Sin push.

## Diagnóstico antes de modificar

El HEAD era 59fc883 y el árbol estaba limpio. FrmVentas.vb y Designer sí incluían ambos botones y los agregaban directamente al formulario. La inspección del EXE Debug existente antes de recompilar encontró btnBuscarCliente, btnBuscarProducto, FrmBuscador y únicamente el ComboBox de medio de pago. Su hash SHA256 empezaba por 35F1CB03. No existían miembros cboCliente/cboProducto en ese binario.

El acceso FORZA SUPLEMENTOS - QA (GITHUB) apuntaba al CMD del principal; ese CMD iniciaba scripts/qa/Iniciar-App-QA.ps1 con Debug. El otro acceso FORZA SUPLEMENTOS - QA seguía apuntando al respaldo. No había procesos Forza ejecutándose durante el diagnóstico y solo había una salida EXE dentro de bin del principal.

**La vista antigua con dos ComboBox no corresponde al binario inspeccionado.** No se conservaba la ruta/PID/hash del inicio mostrado en la captura, por lo que no se puede atribuir retrospectivamente a un acceso concreto ni afirmar que el usuario abrió el equivocado. La causa comprobada del riesgo de versión era que el lanzador ejecutaba cualquier binario presente en Debug sin recompilar ni registrar qué versión inició. Se corrige esa falta de garantía y trazabilidad, sin inventar una causa histórica no demostrada.

Visible=False al inspeccionar un formulario todavía no mostrado no demuestra un control oculto: depende de su padre. Por eso se añadió una prueba después de Show/Load reales, dentro del MDI, con contención y superposición comprobadas.

La nueva integración modal real detectó además un defecto reproducible: después de cambiar de fila, Seleccionar podía permanecer deshabilitado aunque CurrentRow fuera un producto activo con stock. SelectionChanged puede ocurrir antes de actualizar la celda/fila actual. La lógica ahora escucha también CurrentCellChanged y DataBindingComplete. Se agregó una regresión de fila agotada a fila con stock.

## Correcciones

- INICIAR_FORZA_QA.cmd exige -Compilar antes de lanzar Debug. Si falla, mantiene el error visible y no abre otra compilación como alternativa.
- Iniciar-App-QA.ps1 conserva todas las guardas QA. Comprueba procesos de la misma ruta, pide cerrar la instancia anterior y no termina procesos. Recompila con el script existente y valida la estructura del EXE antes de iniciarlo.
- Nuevo QA.Build.psm1 verifica ensamblado, tipos, campos de búsqueda y ausencia de los ComboBox antiguos. Rechaza ejecutables faltantes o incompatibles. RevisionVisual continúa siendo una alternativa explícita y también pasa la verificación; no se usa como fallback automático.
- Login y Principal muestran QA PRINCIPAL, revisión Git y hash abreviado del EXE, únicamente en entorno QA. Cambia el título, no el procedimiento de autenticación.
- El último inicio queda en private/ultimo-inicio-qa.json, ignorado: ruta real, revisión, hash, MVID, hora, configuración y PID. No contiene contraseñas. La consola también identifica el EXE verificado.
- Los botones tienen nombres explícitos, Visible=True y ubicación/Anchor/Dock definidos; textos Buscar cliente y Buscar producto. Se conserva geometría y tema oscuro. Ventas se identifica como Gestión de Ventas - Buscadores.
- FrmBuscador actualiza correctamente la disponibilidad de selección al cambiar la fila actual; no duplica la implementación de búsquedas existente.

La compilación obligatoria requiere las herramientas de Visual Studio ya necesarias para desarrollar. Si falta MSBuild, hay errores o el binario está bloqueado, el inicio se detiene; no se reemplaza la compilación actual por una vieja.

## Comprobación con formularios reales

Nuevo tests/qa/Probar-Buscadores-Visibles.ps1: carga el EXE de Debug, crea FrmPrincipal y FrmVentas reales y usa sus eventos de menú/botones. **No hereda formularios, no sustituye Load, no reemplaza BuscarCliente/BuscarProducto y no salta ShowDialog.** Un temporizador del propio host de integración opera los controles dentro del bucle modal real, sin automatizar ventanas de autenticación.

Comprueba: ambos botones visibles/habilitados, padre correcto, dentro de ClientRectangle y sin otro control tapándolos; solo ComboBox de pago; apertura real de ambos selectores; filtro, botón Seleccionar y Enter sobre registros QA; selección devuelta a Ventas; ID real conservado; una única ventana MDI; carrito preservado y stock observado sin cambios. Construye el payload real de confirmación pero nunca pulsa Confirmar Venta ni ejecuta ProcesarVenta.

El actor de QA se obtiene en lectura y el host le asigna un nombre de prueba; esto no es una sesión Login probada por el agente ni un modo de ingreso agregado a la aplicación. Las lecturas pasan por las guardas de QA y los SP existentes.

## Resultados finales

Compilación completa Debug / Any CPU aprobada. Pruebas: 205 permisos + 86 navegación + 59 interfaz + 20 Caja/Ventas + 49 buscadores + 4 identidad de binario = **423 offline**. Integración: 8 selección QA de lectura + 17 formularios/modales reales = **25 QA de lectura**. Total: **448 comprobaciones aprobadas**. Las ejecuciones iniciales fallidas del nuevo caso modal llevaron a la corrección de CurrentCellChanged; la regresión final se repitió.

El control de escritorio no pudo inicializarse: falló el runtime con “failed to write kernel assets”. No se afirma haber usado mouse/teclado para una sesión manual. La evidencia generada es un **render DrawToBitmap de formularios reales cargados con QA**, no una captura nativa del escritorio. Se revisaron los renders de Principal/Ventas y ambos buscadores. Los campos personales se ocultan solo al renderizar; no se modifican datos SQL ni modelos. QA puede contener registros personales ingresados por el desarrollador: no se consideran automáticamente fixtures anónimos.

Evidencia local ignorada: tests/artifacts/qa-visible/01_PrincipalVentas.png, 02_BuscadorClientes.png, 03_BuscadorProductos.png, 04_VentasSeleccionadas.png y resultado.json. No se versionan imágenes ni datos privados.

## Cómo ejecutar y verificar la corrección

1. Cerrar por su interfaz las instancias previas de Forza, conservando trabajo pendiente. No usar el acceso sin GITHUB para esta versión. No se modificó el respaldo.
2. Hacer doble clic en **FORZA SUPLEMENTOS - QA (GITHUB)**. La consola debe compilar y luego mostrar QA PRINCIPAL y el EXE del principal. Si falla, leer el error y no abrir directamente el EXE.
3. En Login comprobar el título QA PRINCIPAL con revisión/hash. Ingresar con las credenciales QA habituales; la autenticación no cambió.
4. Abrir Generar Venta / Gestión de Ventas. El hijo debe llamarse Gestión de Ventas - Buscadores. Debe mostrar dos campos de solo lectura, Buscar cliente y Buscar producto; solo queda el desplegable de pago.
5. Abrir cada buscador, escribir un filtro, esperar resultados y seleccionar con botón, doble clic o Enter. Comprobar que el elegido vuelve al campo de Ventas.
6. Agregar una cantidad válida, abrir/cancelar otro buscador y confirmar que el carrito permanece. Probar fila sin stock y luego fila con stock: Seleccionar debe actualizarse inmediatamente. No es necesario confirmar una venta SQL.
7. Si vuelve a verse una interfaz antigua, anotar el título y consultar private/ultimo-inicio-qa.json para obtener ruta/PID/hash reales; no compartir la configuración privada. Ese registro permite identificar el proceso sin suposiciones.

Desde la raíz, Windows PowerShell:

```powershell
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\tests\qa\Probar-Identidad-Binario.ps1
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\tests\qa\Probar-Buscadores-Visibles.ps1
```

Los demás ensayos están en BUSCADORES_VENTAS.md. El nuevo verificador no modifica SQL. No hay migraciones nuevas ni pendientes para esta corrección. Pendiente: validación manual del usuario desde el acceso y, separadamente, diseñador/DPI si corresponde. No se autorizó ni ejecutó push.
