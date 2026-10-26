# Plan reproducible de pruebas Caja QA

Todos los resultados SQL están pendientes de autorización. Ejecutar con el runner protegido; sus resultados incluyen los IDs para sustituir los parámetros de las consultas. No usar estas consultas de operación sobre la base original.

## 1. Apertura por vendedor

- Datos iniciales: Vendedor ficticio activo; sin caja abierta; inicial 500.
- Operación: sp_Caja_Abrir(vendedor,500)
- Resultado esperado: Una sesión Abierta del vendedor con inicial 500.
- Consulta de verificación: `SELECT idSesion,idUsuarioApertura,montoInicial,estado FROM dbo.SesionesCaja WHERE idSesion=@sesion1;`
- Resultado real: NO EJECUTADA: pendiente de autorización SQL

## 2. Apertura duplicada

- Datos iniciales: Sesión1 abierta; otro vendedor activo.
- Operación: sp_Caja_Abrir(otroVendedor,500)
- Resultado esperado: Error 51005; exactamente una sesión abierta.
- Consulta de verificación: `SELECT COUNT(*) AS abiertas FROM dbo.SesionesCaja WHERE estado='Abierta';`
- Resultado real: NO EJECUTADA: pendiente de autorización SQL

## 3. Importes negativos

- Datos iniciales: Sin sesión abierta; sin escrituras previas del ensayo.
- Operación: Abrir con -1; cerrar con -1; vender cantidad -1.
- Resultado esperado: Errores 51003 y 51011; ninguna sesión/venta creada.
- Consulta de verificación: `SELECT COUNT(*) AS abiertas FROM dbo.SesionesCaja WHERE estado='Abierta'; SELECT stock FROM dbo.Productos WHERE idProducto=@producto;`
- Resultado real: NO EJECUTADA: pendiente de autorización SQL

## 4. Venta sin caja

- Datos iniciales: Producto nuevo del ensayo: stock100, precio100; sesión0 inexistente.
- Operación: sp_Ventas_RegistrarConCaja con sesión0
- Resultado esperado: Error51006; stock100; no cabecera/detalle/pago.
- Consulta de verificación: `SELECT stock FROM dbo.Productos WHERE idProducto=@producto; SELECT COUNT(*) FROM dbo.DetalleVentas WHERE idProducto=@producto;`
- Resultado real: NO EJECUTADA: pendiente de autorización SQL

## 5. Venta en efectivo

- Datos iniciales: Sesión1 inicial500; producto100 con stock100.
- Operación: Una unidad, Efectivo, total100.
- Resultado esperado: Venta vinculada; pagoEfectivo100.
- Consulta de verificación: `SELECT v.idVenta,v.idSesion,p.medioPago,p.importe FROM dbo.Ventas v JOIN dbo.PagosVenta p ON p.idVenta=v.idVenta WHERE v.idSesion=@sesion1;`
- Resultado real: NO EJECUTADA: pendiente de autorización SQL

## 6. Venta por transferencia

- Datos iniciales: Sesión1 con una venta previa.
- Operación: Una unidad, Transferencia, total100.
- Resultado esperado: PagoTransferencia100; efectivo esperado sigue600.
- Consulta de verificación: `SELECT montoFinalEsperado,ventasEfectivo FROM dbo.vw_Caja_Resumen WHERE idSesion=@sesion1;`
- Resultado real: NO EJECUTADA: pendiente de autorización SQL

## 7. Venta con tarjeta

- Datos iniciales: Sesión1 con dos ventas previas.
- Operación: Una unidad, Tarjeta, total100.
- Resultado esperado: PagoTarjeta100; efectivo esperado sigue600.
- Consulta de verificación: `SELECT medioPago,importe FROM dbo.PagosVenta p JOIN dbo.Ventas v ON v.idVenta=p.idVenta WHERE v.idSesion=@sesion1;`
- Resultado real: NO EJECUTADA: pendiente de autorización SQL

## 8. Asociación venta y sesión

- Datos iniciales: Tres ventas nuevas registradas.
- Operación: Consultar cabeceras.
- Resultado esperado: Tres ventas del vendedor con sesión1.
- Consulta de verificación: `SELECT COUNT(*) FROM dbo.Ventas WHERE idSesion=@sesion1 AND idUsuario=@vendedor AND total=100;`
- Resultado real: NO EJECUTADA: pendiente de autorización SQL

## 9. Descuento de stock

- Datos iniciales: Stock inicial100; tres ventas de una unidad.
- Operación: Consultar producto y detalles.
- Resultado esperado: Stock97; cantidad vendida3.
- Consulta de verificación: `SELECT stock FROM dbo.Productos WHERE idProducto=@producto; SELECT SUM(cantidad) FROM dbo.DetalleVentas WHERE idProducto=@producto;`
- Resultado real: NO EJECUTADA: pendiente de autorización SQL

## 10. Stock insuficiente

- Datos iniciales: Stock97; sesión1 abierta.
- Operación: Intentar vender98 unidades.
- Resultado esperado: Error51013; snapshot de cantidades/stock intacto.
- Consulta de verificación: `SELECT stock FROM dbo.Productos WHERE idProducto=@producto; SELECT COUNT(*) FROM dbo.Ventas; SELECT COUNT(*) FROM dbo.DetalleVentas; SELECT COUNT(*) FROM dbo.PagosVenta;`
- Resultado real: NO EJECUTADA: pendiente de autorización SQL

## 11. Rollback después de descontar stock

- Datos iniciales: Sesión1 abierta; trigger QA inerte que falla solo con SESSION_CONTEXT de prueba.
- Operación: Activar fallo de pago en esa conexión; vender una unidad; desactivar el fallo.
- Resultado esperado: Error51211 durante inserción del pago; reversión de stock, cabecera, detalle y pago; snapshot idéntico.
- Consulta de verificación: `SELECT COUNT(*) FROM dbo.Ventas; SELECT COUNT(*) FROM dbo.DetalleVentas; SELECT COUNT(*) FROM dbo.PagosVenta; SELECT stock FROM dbo.Productos WHERE idProducto=@producto;`
- Resultado real: NO EJECUTADA: pendiente de autorización SQL

## 12. Cierre con efectivo correcto

- Datos iniciales: Inicial500; efectivo100; transferencia100; tarjeta100.
- Operación: Cerrar con contado600.
- Resultado esperado: Esperado600, real600, diferencia0, Cerrada.
- Consulta de verificación: `SELECT montoFinalEsperado,montoFinalReal,diferencia,estado,fechaCierre,idUsuarioCierre FROM dbo.SesionesCaja WHERE idSesion=@sesion1;`
- Resultado real: NO EJECUTADA: pendiente de autorización SQL

## 13. Diferencias positiva y negativa

- Datos iniciales: Dos sesiones nuevas, cada una inicial500 y ventaEfectivo100.
- Operación: Cerrar sesión2 con610 y sesión3 con590.
- Resultado esperado: Diferencias+10 y-10, respectivamente.
- Consulta de verificación: `SELECT idSesion,montoFinalEsperado,montoFinalReal,diferencia FROM dbo.SesionesCaja WHERE idSesion IN (@sesion2,@sesion3);`
- Resultado real: NO EJECUTADA: pendiente de autorización SQL

## 14. Cierre duplicado

- Datos iniciales: Sesión1 cerrada.
- Operación: Repetir cierre de sesión1.
- Resultado esperado: Error51006; no cambia el cierre persistido.
- Consulta de verificación: `SELECT estado,fechaCierre,montoFinalReal,diferencia FROM dbo.SesionesCaja WHERE idSesion=@sesion1;`
- Resultado real: NO EJECUTADA: pendiente de autorización SQL

## 15. Historial por fecha y vendedor

- Datos iniciales: Sesión1 abierta; fechas del día ±1.
- Operación: sp_Caja_Historial del vendedor.
- Resultado esperado: Incluye sesión1; ningún responsable ajeno.
- Consulta de verificación: `EXEC dbo.sp_Caja_Historial @vendedor,@desde,@hasta;`
- Resultado real: NO EJECUTADA: pendiente de autorización SQL

## 16. Separación entre sesiones e históricos

- Datos iniciales: Sesión1 con3 ventas, sesión2 con1, sesión3 con1; histórico ficticio sin sesión.
- Operación: Consultar conteos y snapshot del histórico.
- Resultado esperado: Conteos3/1/1; total, fecha e idSesion NULL del histórico intactos.
- Consulta de verificación: `SELECT idSesion,COUNT(*) FROM dbo.Ventas WHERE idSesion IN (@sesion1,@sesion2,@sesion3) GROUP BY idSesion; SELECT total,fecha,idSesion FROM dbo.Ventas WHERE idVenta=@ventaHistorica;`
- Resultado real: NO EJECUTADA: pendiente de autorización SQL

## 17. Dos ventas simultáneas de última unidad

- Datos iniciales: Producto separado stock1/precio100; sesión nueva; dos conexiones independientes.
- Operación: Enviar dos ventas asíncronas tras una barrera de bloqueo transaccional; liberar barrera.
- Resultado esperado: Una venta exitosa, un rechazo51013, stock0, una cabecera; cerrar sesión con600.
- Consulta de verificación: `SELECT stock FROM dbo.Productos WHERE idProducto=@productoConcurrente; SELECT COUNT(*) FROM dbo.Ventas WHERE idSesion=@sesionConcurrente;`
- Resultado real: NO EJECUTADA: pendiente de autorización SQL

## 18. Permisos por perfil y sesión ajena

- Datos iniciales: Administrador, gerente e inactivo ficticios; segundo vendedor activo; sesión1 de primer vendedor.
- Operación: Intentar abrir/vender/cerrar/historial con actores no autorizados; consultar/vender sesión ajena.
- Resultado esperado: 51001 para perfiles/inactivo; reporte ajeno vacío; venta ajena51006.
- Consulta de verificación: `EXEC dbo.sp_Caja_Reporte @otroVendedor,@sesion1; EXEC dbo.sp_Caja_Historial @administrador,@desde,@hasta;`
- Resultado real: NO EJECUTADA: pendiente de autorización SQL

