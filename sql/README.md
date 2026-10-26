# SQL de Caja: despliegue manual

No se ejecutó ninguna migración. La única conexión usada por el agente fue de lectura de catálogos y definiciones de SP, sin consultar filas de personas.

## Esquema comprobado

La inspección de sys.columns confirmó dbo.SesionesCaja: idSesion int IDENTITY; idUsuarioApertura int; idUsuarioCierre int NULL; fechaApertura datetime; fechaCierre datetime NULL; montoInicial decimal(10,2); montoFinalEsperado, montoFinalReal y diferencia decimal(10,2) NULL; estado varchar(20), default Abierta. Ventas.idSesion es int NULL y tiene FK a SesionesCaja. Productos.stock es int y los importes de Productos, Ventas y DetalleVentas son decimal(10,2). No se encontraron triggers en esas cuatro tablas ni procedimientos de Caja. Los dos SP de escritura antiguos fueron inspeccionados y no validan caja ni stock suficiente.

No es necesario enviar un script para esta versión: se pudo consultar la estructura real. Para futuras exportaciones, colocar **solo esquema** en `sql/private/esquema_actual.sql`; `private/` está excluido de Git. No exportar datos ni credenciales.

## Orden de ejecución

1. `migrations/001_Caja_Pagos.sql`: valida contrato y datos incompatibles sin corregirlos; agrega PagosVenta, índices y CHECK de stock no negativo. No recrea SesionesCaja ni Ventas, no rellena históricos.
2. `migrations/002_Caja_Procedimientos.sql`: validador de vendedor activo, vista de resumen y SP de apertura, consulta, historial, reporte y cierre.
3. `migrations/003_Ventas_Caja_Stock.sql`: SP atómico de venta completa, asociación de sesión, pago y descuento condicional de stock. Conserva las firmas de los SP antiguos pero rechaza su uso parcial para impedir eludir las reglas nuevas.

Requiere SQL Server 2016 SP1 o posterior (CREATE OR ALTER), base con el esquema auditado y permisos DDL en la base de prueba. Las migraciones usan transacciones y directiva `:on error exit`; en SSMS activar **Consulta > Modo SQLCMD**. Ejecutar cada archivo completo, en orden y comprobar éxito antes del siguiente. No seleccionar únicamente partes del archivo. Si se produce un error, detenerse: no corregir registros automáticamente ni continuar con el archivo siguiente.

Como alternativa, desde la raíz del proyecto y reemplazando `INSTANCIA_DE_PRUEBA` por la instancia aislada real:

```powershell
sqlcmd -S INSTANCIA_DE_PRUEBA -d ForzaSuplementos_Pruebas -E -C -b -i .\sql\migrations\001_Caja_Pagos.sql
sqlcmd -S INSTANCIA_DE_PRUEBA -d ForzaSuplementos_Pruebas -E -C -b -i .\sql\migrations\002_Caja_Procedimientos.sql
sqlcmd -S INSTANCIA_DE_PRUEBA -d ForzaSuplementos_Pruebas -E -C -b -i .\sql\migrations\003_Ventas_Caja_Stock.sql
```

Estos comandos son instrucciones para la base aislada. No ejecutarlos contra la base real sin una autorización y un despliegue coordinado. Reejecutar 001–003 no debe duplicar objetos ni modificar datos históricos; una tabla PagosVenta preexistente con contrato incompatible detiene la migración.

**Compatibilidad de despliegue:** la aplicación nueva requiere las tres migraciones. No hay fallback silencioso al flujo anterior. Tras 003, un ejecutable viejo ya no puede registrar ventas por los dos SP parciales. Deben actualizarse juntos SQL y ejecutables con todos los clientes detenidos. Usuarios, productos, clientes y reportes existentes conservan sus SP.

## Decisiones operativas

- Una única caja física abierta globalmente; solo su vendedor responsable puede vender/cerrar y consultar su historial. No hay relevo de responsable, cajas múltiples ni cierre por gerente/administrador.
- Una venta tiene un único pago por el importe completo: Efectivo, Transferencia o Tarjeta, elegido expresamente en pantalla. La PK de PagosVenta es idVenta; no se implementaron pagos divididos. El catálogo fijo está en el enum de VB y el CHECK de SQL.
- Efectivo esperado = monto inicial + pagos Efectivo de ventas asociadas. Diferencia = monto real contado − esperado. Transferencia/Tarjeta se incluyen en importe vendido, pero no en efectivo. No se registran ingresos/egresos ajenos a ventas ni devoluciones; no están incluidos en este cierre.
- Una sesión previa con ventas asociadas sin pago identificado no se puede cerrar automáticamente. Los históricos sin sesión quedan fuera de las cajas nuevas y permanecen intactos. No se infiere efectivo a partir del total de ventas. En sesiones ya cerradas se conserva el esperado persistido y el reporte muestra cuántas ventas carecen de pago conocido.
- Apertura, venta y cierre adquieren el mismo bloqueo transaccional de aplicación. Se serializan para esta única caja. Además se retienen bloqueos de actualización de productos y se descuenta stock con condición `stock >= cantidad`. Los precios y el total se comprueban contra el catálogo, y el servidor calcula subtotales y total. Si cambió el precio, se rechaza para que el vendedor actualice.
- La identidad de usuario procede del login de la aplicación y se revalida su perfil/activo en SQL. Un usuario con acceso SQL directo privilegiado puede eludir reglas de aplicación; no se alteraron permisos de servidor ni autenticación existente.

## Pruebas SQL pendientes

Crear una base/instancia aislada con el esquema y datos ficticios. Abrir `tests/Caja_Integracion_Manual.sql`, configurar los cuatro IDs ficticios y ejecutarlo solo en una base terminada en `_Pruebas`. El script verifica ventas rechazadas sin escrituras parciales, tres medios, efectivo esperado, diferencia, doble cierre e históricos. Conserva sus ventas/sesión de prueba para inspección. **No fue ejecutado por el agente.**

También faltan pruebas en conexiones simultáneas:

1. Dos vendedores intentan abrir: solo uno obtiene sesión; el otro recibe 51005.
2. Dos ventas simultáneas del último stock disponible: solo la cantidad permitida debe confirmarse; stock nunca negativo.
3. Venta concurrente con cierre de la misma sesión: la venta se confirma antes del cierre y queda incluida, o se rechaza si el cierre ganó el bloqueo. Nunca se agrega después del cierre.
4. En una base desechable, provocar un fallo de inserción de pago con un trigger de prueba y verificar que también revierten stock, cabecera y detalles; retirar únicamente el trigger de prueba después. No hacer este ensayo sobre datos reales.
5. Suspender/desactivar al vendedor o cambiarle el rol mientras tiene una pantalla abierta: el SP debe rechazar operaciones nuevas. Verificar acceso a reporte de una sesión ajena: no retorna datos.

## Reversión sin pérdida de datos

Antes de aplicar en cualquier entorno autorizado, guardar la definición previa de los dos SP antiguos en `sql/private/contrato_anterior.sql` y un respaldo según el procedimiento del entorno. La reversión se hace con clientes detenidos: restaurar esas definiciones revisadas y el ejecutable del commit `48aaa74`. No borrar PagosVenta, sesiones ni ventas nuevas: los objetos agregados pueden permanecer sin uso. La definición original tenía el riesgo de stock advertido en la auditoría; no habilitar ventas reales tras una reversión sin resolverlo. No se entrega un script que borre tablas o restaure una base automáticamente. Tras nuevas ventas, restaurar un backup completo perdería operaciones posteriores y no es una reversión aceptable sin conciliación.
