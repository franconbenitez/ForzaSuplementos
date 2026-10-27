# Mejoras de interfaz — 26/10/2026

Trabajo realizado sobre Desarrollo_Codex. No se ejecutó SQL, ninguna migración ni publicación. Las conexiones, credenciales, procedimientos y capas Entidades/Negocio/Datos no se modificaron.

## Cambios

- `FrmLogin.vb` y `.Designer.vb`: AcceptButton apunta a Ingresar. Enter y clic recorren el mismo evento y la misma UsuarioBLL. Una bandera y la deshabilitación temporal evitan reentradas; Finally restablece el botón. Las validaciones y mensajes existentes se conservan.
- `FrmVentas.vb` y `.Designer.vb`: «Vaciar carrito» queda deshabilitado cuando no hay líneas. ListChanged actualiza total y disponibilidad. El evento sigue llamando solamente a LimpiarVenta: vacía la lista en memoria y restablece selecciones, cantidad y total. No registra ventas ni modifica stock. Confirmar Venta conserva su flujo. Se amplió el área del total para evitar recortes.
- `TemaForza.vb`: paleta compartida, botones primarios/secundarios/peligro, estados deshabilitados, campos, combos con dibujo propio respetando DisplayMember, grillas, menús, pestañas y etiquetas. Aplicación idempotente sin cambiar Enabled/Visible ni permisos. No introduce una nueva clase base para los formularios y omite el tema en modo diseñador.
- `FrmLogin`, `FrmCaja`, `FrmVentas`, `FrmPrincipal`, `FrmUsuarios`, `FrmProductos`, `FrmClientes`, `FrmBackup`, `FrmReportes`: tema aplicado después de InitializeComponent. Principal utiliza el mismo renderer compartido; se retiró su renderer anterior duplicado.
- `ForzaSuplementos.Presentacion.vbproj`: incluye TemaForza explícitamente.
- `scripts/qa/Iniciar-App-QA.ps1`: opción adicional `-RevisionVisual` elige bin/UIRevision; conserva exactamente las comprobaciones y variables QA del iniciador existente. Sin el parámetro conserva su comportamiento anterior.
- `tests/ui/VistasSinSql.vb` y `tests/ui/Probar-Interfaz-SinSql.ps1`: host de formularios con Load de producción suprimido, autenticación simulada y datos ficticios en memoria; verifican eventos reales sin SQL. Capturas generadas en tests/artifacts/ui, excluidas de Git.

Colores: fondo #1F2428, panel #2B3237, primario #24A889, texto #E8ECEF, peligro #D75B5B. Se conserva el editor de fechas nativo claro con texto oscuro para asegurar contraste: Windows puede ignorar sus colores. Bordes, flechas, barras de desplazamiento y partes del área de pestañas conservan el renderizado nativo.

## Validación ejecutada

- Solución completa, cuatro proyectos: MSBuild de Visual Studio Community 18, Debug / Any CPU, salida bin/UIRevision: **compilación aprobada, sin errores**.
- Rebuild en bin/Debug: **bloqueado**, MSB3021 por archivos en uso por la aplicación abierta. No se terminó ese proceso ni se reemplazaron sus binarios bloqueados. La salida UIRevision contiene la versión actualizada.
- Pruebas de interfaz: **59 comprobaciones aprobadas**. AcceptButton desde usuario/contraseña, clic, reentrada, vaciado repetido, total cero, stock ficticio intacto, nueve formularios, idempotencia del tema, grillas y disponibilidad de Caja. Inspección estática adicional de los cuatro métodos de vaciado sin llamadas BLL/DAL/SQL.
- Regresión tests/Probar-Caja-SinSql.ps1: **20 comprobaciones aprobadas**, incluidas reglas de montos, permisos, detalles/pagos y construcción de Caja.
- Revisión visual de nueve capturas sintéticas: sin nuevas superposiciones ni texto ilegible observados. No equivale a probar consultas, ventas confirmadas o datos reales de QA.
- Los formularios y archivos Designer compilaron y se instanciaron; no se abrió el diseñador de Visual Studio. Pendiente validar allí y con escalado 125 % / 150 %, navegación de teclado y datos cargados desde QA.

## Repetir las pruebas offline

Desde la raíz del proyecto, en Windows PowerShell:

```powershell
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\tests\ui\Probar-Interfaz-SinSql.ps1 -BuildFolder UIRevision
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\tests\Probar-Caja-SinSql.ps1 -Configuration UIRevision
```

Para recompilar la salida independiente, desde Developer PowerShell de Visual Studio:

```powershell
MSBuild.exe .\ForzaSuplementos\ForzaSuplementos\ForzaSuplementos.slnx /t:Rebuild /p:Configuration=Debug '/p:Platform=Any CPU' /p:OutputPath=bin\UIRevision\ /nr:false /p:UseSharedCompilation=false
```

## Abrir la versión actualizada contra QA

1. Cerrar la instancia anterior por su interfaz, conservando primero cualquier trabajo pendiente.
2. Desde la raíz Desarrollo_Codex ejecutar:

```powershell
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\scripts\qa\Iniciar-App-QA.ps1 -RevisionVisual
```

El iniciador usa la configuración QA privada existente, verifica destino y procedimientos en lectura y configura únicamente el proceso hijo. No inicia la aplicación si la verificación falla. No abrir el EXE directamente ni usar F5 sin preparar el entorno QA.

Alternativa, después de cerrar la aplicación anterior: compilar la salida habitual y usar el iniciador sin RevisionVisual:

```powershell
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\scripts\compilar.ps1 -Configuration Debug
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\scripts\qa\Iniciar-App-QA.ps1 -Configuration Debug
```

## Verificación manual pendiente

En QA: comprobar Enter desde ambos campos y clic; intentar datos inválidos y luego válidos; verificar un solo ingreso por acción. Con vendedor y caja abierta, agregar productos, verificar el total y vaciar: grilla vacía, total cero, botón deshabilitado. Verificar con herramientas QA existentes que vaciar no añade registros ni cambia stock. Agregar otra vez y confirmar una venta ficticia para revisar el flujo completo conservado. Abrir cada formulario con el perfil correspondiente y revisar desplegables, filas seleccionadas, botones deshabilitados, menús y redimensionamiento.

En Visual Studio: abrir la solución, seleccionar Debug / Any CPU y revisar los nueve formularios con Ver diseñador, especialmente Login y Ventas. El tema se aplica en ejecución; el diseñador conserva parte de los colores originales. No se modificaron archivos resx ni referencias entre capas.

No se crearon scripts SQL. La próxima tarea de mayor impacto es completar esta revisión manual contra QA antes de incorporar módulos nuevos. Los cambios previos de preparación para GitHub quedan fuera del commit de interfaz.
