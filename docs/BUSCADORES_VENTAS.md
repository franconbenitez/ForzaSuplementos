# Buscadores de Ventas y QA del repositorio principal

Fecha: 26/10/2026. Rama master del repositorio principal ForzaSuplementos_GitHub. Desarrollo_Codex queda como respaldo: solo se leyeron los cuatro atributos permitidos de su configuración privada QA para crear la configuración local del principal, sin escribir en el respaldo. No se realizaron pushes ni modificaciones SQL.

## Funcionalidad

FrmVentas reemplaza los dos ComboBox extensos por campos de selección de solo lectura y botones Buscar cliente/Buscar producto. El ComboBox de medio de pago se conserva. FrmBuscador es un selector modal reutilizable; no es otro módulo MDI, no altera la navegación y no escribe en el carrito. Un indicador de apertura impide reentradas de los botones.

Clientes: nombre, apellido, DNI o ID, admitiendo varias palabras, mayúsculas/minúsculas y acentos. Grilla con ID, DNI, apellido, nombre y teléfono para distinguir homónimos. Productos: nombre, categoría o ID numérico disponible; no se inventa un SKU inexistente en el modelo. Grilla con ID, producto, categoría, precio, stock del catálogo y estado. Se excluyen registros nulos, inválidos e inactivos; los productos sin stock se muestran pero no permiten seleccionar.

Seleccionar con botón, doble clic o Enter desde el campo/grilla; Esc/Cancelar vuelve sin perder la selección anterior ni el carrito. Mientras se filtra se deshabilita la selección para impedir usar una fila obsoleta. Sin resultados se informa claramente y no se selecciona Nothing. Los encabezados de la grilla no seleccionan registros.

La fila devuelve su DataBoundItem con el ID original, no su índice ni el texto mostrado. Ventas conserva Cliente y Producto seleccionados y muestra su identificación y precio. Agregar vuelve a validar activo, cantidad positiva, stock por línea y acumulado; no descuenta stock SQL. Confirmar usa CrearVentaPendiente, que toma el IdCliente y los IdProducto originales. VentaBLL y el SP transaccional existente siguen validando y registrando la operación. No se cambia Caja ni la sesión al buscar o navegar.

## Arquitectura y rendimiento

UI -> BLL -> DAL -> SP existentes: sp_Clientes_ListarPorEstado y sp_Productos_ListarPorEstado, con activo=True y actor vendedor autorizado. Producto ya incluye NombreCategoria, Precio, Stock y Activo. No se añaden SP, tablas, índices ni migraciones.

La carga inicial y recarga tras una venta confirmada se hacen en segundo plano. Cada selector trabaja sobre una copia local del catálogo cargado, con debounce de 180 ms, Task.Run, CancellationToken y número de versión: una búsqueda anterior no puede sobrescribir la última. El cierre cancela el trabajo y el temporizador se dispone con el formulario. BuscadorCatalogo en Negocio realiza solo filtrado puro, sin conexiones. Los formularios no contienen SQL.

Se probó un catálogo sintético de 5000 productos. No se garantiza rendimiento ilimitado: cargar/bindear catálogos enormes puede requerir paginación y SP de búsqueda futura. El stock mostrado es una instantánea del catálogo, no una reserva; otra venta puede cambiarlo. Se conserva la validación acumulada del carrito y la comprobación transaccional de stock en SQL al confirmar. No se descontó stock durante los ensayos de esta entrega.

## QA local y acceso directo

Se creó config/qa.config local utilizando únicamente servidor, servidorEsperado, base y marca de aislamiento de la configuración ya verificada del equipo. No se copiaron contraseñas ni se cambió Conexion.vb. El archivo permanece ignorado y no versionado. Las validaciones de servidor esperado, base ForzaSuplementosDB_QA y marca se mantienen; cualquier fallo detiene el inicio, sin volver a la conexión habitual.

Se creó en el Escritorio el acceso directo **FORZA SUPLEMENTOS - QA (GITHUB)** hacia INICIAR_FORZA_QA.cmd del principal. El CMD indica QA (GITHUB), usa su propia ubicación y llama al lanzador protegido con Debug. Se verificó el destino del acceso directo y SoloVerificar consultó la QA en lectura con éxito. El acceso anterior conserva su destino de respaldo y no debe usarse para estos cambios.

En otra PC crear su propia configuración desde qa.example.config, verificar su instancia y preparar su QA separadamente con autorización. No copiar configuraciones ni accesos directos de otra computadora.

## Pruebas ejecutadas

Solución completa Debug / Any CPU, salida habitual bin/Debug: cuatro proyectos compilados sin errores.

Pruebas offline: 205 de permisos, 86 de navegación, 59 de interfaz, 20 de reglas Caja/Ventas y **47 nuevas de buscadores**. Total: **417 comprobaciones aprobadas**. Los nuevos casos incluyen búsqueda por campos/acentos/tokens, activo/nulos, 5000 filas, cancelación, resultados obsoletos, selección con botón/doble clic/Enter, stock cero/acumulado, reentrada, carrito y payload de confirmación. La regresión de interfaz se adaptó a los nuevos controles, sin conservar combos invisibles.

Prueba QA exclusivamente de lectura: **8 comprobaciones aprobadas**. Utilizó los SP reales de catálogo, seleccionó filas en el selector, comprobó IDs originales y precio en el payload usado por Confirmar, verificó la carga asíncrona real de Ventas y observó el mismo stock al volver a consultar. No llamó ProcesarVenta ni ejecutó INSERT/UPDATE/DELETE. El actor de prueba se obtuvo mediante consulta de id/perfil activo: no es una prueba del Login. No se imprimieron datos personales ni credenciales.

Total de la ejecución final: **425 comprobaciones aprobadas**, separando 417 offline y 8 QA de lectura. Las primeras ejecuciones de los hosts requirieron desempaquetar PSObject antes de invocar métodos por reflexión; se corrigió el host y se repitieron los ensayos. No hubo que modificar SP ni datos para corregir esas pruebas.

Se renderizaron y revisaron capturas sintéticas de ambos selectores y Ventas, sin superposiciones evidentes, conservando TemaForza. Los PNG están ignorados en tests/artifacts/ui. No se completó una sesión de uso manual del nuevo buscador, una venta SQL de extremo a extremo ni pruebas de DPI/diseñador de Visual Studio. La aprobación visual anterior del usuario corresponde a la estética/navegación previa y se conserva como antecedente.

## Repetir la validación

Cerrar la aplicación antes de recompilar. Desde la raíz del repositorio principal:

```powershell
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\scripts\compilar.ps1 -Configuration Debug
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\tests\ui\Probar-Permisos-SinSql.ps1
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\tests\ui\Probar-Navegacion-SinSql.ps1
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\tests\ui\Probar-Interfaz-SinSql.ps1
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\tests\Probar-Caja-SinSql.ps1
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\tests\ui\Probar-Buscadores-SinSql.ps1
# Opcional, solo lectura sobre QA preparada y configurada:
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\tests\qa\Probar-Seleccion-Lectura.ps1
```

En Visual Studio abrir la solución del principal, Debug / Any CPU; revisar FrmVentas y FrmBuscador con Ver diseñador. Ambos tienen Designer y entradas explícitas en vbproj. No abrir el EXE directamente para QA; para depurar iniciar con el CMD protegido y asociar Visual Studio al proceso.

## Prueba manual desde el acceso QA (GITHUB)

1. Abrir el acceso nuevo, ingresar como vendedor de QA y abrir Ventas. Esperar la carga del catálogo.
2. Buscar un cliente por apellido/DNI/ID, esperar resultados y seleccionar con Enter. Comprobar el ID y descripción visibles.
3. Buscar un producto por nombre/categoría/ID. Revisar precio y stock; seleccionar con doble clic. Repetir con botón Seleccionar. Un producto agotado no debe seleccionarse.
4. Agregar cantidad válida y comprobar carrito/total. Abrir otro buscador, escribir sin resultados y cancelar: el carrito debe permanecer intacto. Probar cantidades cero, negativas y mayores al stock, incluyendo acumulación del mismo producto.
5. Comprobar que los inactivos no aparecen, que el encabezado no selecciona y que Enter durante una búsqueda pendiente no usa una fila anterior.
6. Vaciar carrito y verificar total cero. Navegar entre módulos y probar No/Sí ante un carrito pendiente. Caja debe seguir abierta hasta su cierre explícito.
7. Si se autoriza una prueba de venta ficticia completa, confirmar una venta y, en SSMS conectado exclusivamente a QA, comparar Ventas.idCliente y DetalleVentas.idProducto con los IDs seleccionados. Esa escritura no se ejecutó en esta entrega. La prueba incluida ya compara esos IDs con el payload, sin guardar la venta.

## Archivos y pendientes

Nuevos: Negocio/BuscadorCatalogo.vb; Presentacion/FrmBuscador.vb y Designer; tests/ui/BuscadoresSinSql.vb y Probar-Buscadores-SinSql.ps1; tests/qa/Probar-Seleccion-Lectura.ps1; este documento. Modificados: los dos vbproj, FrmVentas y su Designer, regresión de interfaz, CMD y README. Cambios privados locales: qa.config y acceso directo del Escritorio, excluidos del commit.

No hay migraciones pendientes para estos buscadores. Los límites de autorización SQL previos siguen documentados en PERMISOS_Y_VALIDACION.md y no se amplía aquí su alcance. La siguiente tarea es revisión manual del buscador y después reportes según prioridad del usuario. El commit local requiere autorización antes del push.

## Corrección posterior del inicio y selección

Ver [inicio verificado y prueba modal real](CORRECCION_INICIO_Y_BUSCADORES_VISIBLES.md). El acceso QA (GITHUB) ahora recompila antes de iniciar, identifica la versión y rechaza binarios sin buscadores. Se corrigió la actualización de Seleccionar al cambiar de fila y se añadieron pruebas de visibilidad y diálogos reales.
