# Demostración breve — Taller de Programación II, 2/11/2026

## Preparación

Cerrar la instancia anterior por su interfaz. Abrir **FORZA SUPLEMENTOS - QA (GITHUB)**; el lanzador recompila y verifica QA. Revisar que el título indique QA PRINCIPAL y el HEAD actual. No usar el EXE directamente ni F5 sin configuración QA. Las claves las conoce el usuario; no se incluyen aquí ni se deben mostrar.

No aplicar migraciones, generar backups físicos ni alterar usuarios/datos durante esta guía. Por defecto la demostración usa consultas y carritos en memoria. Si se quiere confirmar una venta o abrir/cerrar Caja como ensayo SQL, acordar antes esa operación y su alcance sobre QA.

## Administrador — 1 minuto

- Ingresar con qa_admin. Mostrar Gestión de Usuarios como consulta: contraseña vacía/oculta al editar; no guardar ni dar bajas para demostrar.
- Abrir Reportes y Estadísticas, desde 01/01/2000 hasta 31/12/2030, Actualizar. Mostrar historial/conteo de registros de backup. Si está vacío, explicarlo; no inventar exitosos/fallidos porque no se registran.
- Mostrar que Ventas/Caja y nuevos catálogos comerciales no están autorizados.
- Cerrar sesión: volver al mismo Login, contraseña limpia y botón disponible.

## Gerente — 2 minutos

- Ingresar con qa_gerente. Consultar Productos sin editar stock.
- Abrir Reportes, mismo rango y Actualizar. Cambiar entre diaria, mensual, productos, categorías y vendedores. Mostrar unidades/importe y la grilla. Filtrar usando un ID real visible; 0 significa todos. El filtro por producto suma sus líneas, no la factura completa.
- Mostrar período vacío (01/01/1753–02/01/1753) y rango invertido. Al cambiar filtro no deben quedar cifras anteriores como actuales.
- Si el proyector es pequeño, maximizar el hijo y usar scroll para llegar a filtros y botones; el lienzo y la paleta son los aprobados.
- Proveedores/Marcas/Compras/Inventario: mostrar aviso Requiere habilitación QA y guardado bloqueado. Presentarlos como código preparado, no como módulos ya operativos con SQL.

## Vendedor — 2 minutos

- Ingresar con qa_vendedor; opcionalmente comparar luego qa_vendedor2.
- Ventas: buscar un cliente y un producto reales de QA, seleccionar y agregar una cantidad válida. Explicar que agregar/vaciar es solo memoria y no modifica stock.
- Intentar cambiar de módulo con carrito: responder No y verificar que permanece; luego Sí para descartarlo. Carrito vacío no advierte.
- Consultar Caja e historial sin Abrir/Cerrar. Cambiar de pantalla no cierra ninguna sesión.
- Reportes con el mismo rango: totales/evolución/productos propios, sin selector de otro vendedor. No debe administrar usuarios/productos/backups.

## Cierre técnico — 1 minuto

Explicar UI → BLL → DAL → procedimientos parametrizados, entidades sin conexiones, transacciones del servidor y separación por sesión/medio de pago. Indicar con honestidad que 005–008 no se aplicaron y la seguridad avanzada/módulos nuevos requieren ensayos SQL autorizados.

Comentar las correcciones demostrables: Login sin duplicados y cierre del raíz oculto; resultado incierto no reenviado; grilla sin datos obsoletos; ID de altas conservado; validaciones antes de modificar carrito. Si se quiere demostrar fallos sin tocar SQL, ejecutar las suites adversariales con dobles de prueba.

Cerrar Principal mediante X y comprobar manualmente que desaparece la aplicación. La revisión humana de DPI, foco, teclado y todas las operaciones pendientes todavía corresponde al usuario. Ante un error, registrar perfil ficticio, HEAD del título, pasos, fechas/filtros y mensaje, sin contraseñas ni datos privados.
