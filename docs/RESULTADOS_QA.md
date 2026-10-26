# Resultados reales QA — Forza Suplementos

Fecha: 26/10/2026. Zona horaria: America/Buenos_Aires (UTC-03:00). Base de partida del código: 81db955.

## Resultado final

- Ensayos automáticos del plan: **18 aprobados, 0 fallidos, 0 bloqueados**.
- Dos ejecuciones completas del runner finalizaron correctamente. La última es la evidencia de referencia; no se suman sus repeticiones para inflar el conteo.
- Caja y Ventas están listas para **pruebas manuales contra QA**, usando únicamente el lanzador protegido. La interacción visual y el ingreso por contraseña no se declaran probados.
- Rebuild de la solución completa con MSBuild 18.11.1, Debug/AnyCPU: código de salida 0.

## Entorno y operaciones ejecutadas

- Servidor SERVIDOR_QA_VERIFICADO, instancia predeterminada MSSQLSERVER, acceso localhost; destino exclusivo de escrituras: ForzaSuplementosDB_QA.
- Antes de escribir, el preparador verificó servidor/base en lectura y confirmó que QA no existía. Se contó con autorización expresa del usuario.
- Se ejecutaron, en orden: 000_CrearBase_QA.sql, 010_EstructuraOriginal_QA.sql, 020_DatosFicticios_QA.sql, 001_Caja_Pagos_QA.sql, 002_Caja_Procedimientos_QA.sql y 003_Ventas_Caja_Stock_QA.sql.
- Se crearon únicamente estructura y datos ficticios. No se borraron/restauraron bases ni se usaron archivos de backup.
- Las pruebas crearon el trigger dbo.tr_QA_FalloPago solamente en QA. Queda inerte sin la bandera de SESSION_CONTEXT de la conexión de ensayo; la bandera se limpió al terminar la prueba.
- No se modificaron ni deshabilitaron las protecciones QA ni la conexión habitual.

## Evidencia de referencia

- Registro local final: tests/artifacts/qa/resultado-20261026-173841.json
- Copia versionada, sin secretos ni datos reales: docs/qa/EVIDENCIA_18_CASOS.json.
- Sesiones de la última ejecución: 7, 8, 9; concurrencia: 10.
- Los identificadores de esta evidencia corresponden exclusivamente a fixtures ficticias QA.

## Casos del plan

### 1. Apertura por vendedor

- Datos iniciales: Vendedor ficticio activo; sin caja abierta; inicial 500.
- Operación: sp_Caja_Abrir(vendedor,500)
- Esperado: Una sesión Abierta del vendedor con inicial 500.
- Observado: Se abrió una sesión propia con monto inicial 500 y se devolvió su identificador.
- Estado: **APROBADO**.
- Consulta de verificación: `SELECT idSesion,idUsuarioApertura,montoInicial,estado FROM dbo.SesionesCaja WHERE idSesion=@sesion1;`

### 2. Apertura duplicada

- Datos iniciales: Sesión1 abierta; otro vendedor activo.
- Operación: sp_Caja_Abrir(otroVendedor,500)
- Esperado: Error 51005; exactamente una sesión abierta.
- Observado: El segundo vendedor recibió 51005; permaneció exactamente una caja abierta.
- Estado: **APROBADO**.
- Consulta de verificación: `SELECT COUNT(*) AS abiertas FROM dbo.SesionesCaja WHERE estado='Abierta';`

### 3. Importes negativos

- Datos iniciales: Sin sesión abierta; sin escrituras previas del ensayo.
- Operación: Abrir con -1; cerrar con -1; vender cantidad -1.
- Esperado: Errores 51003 y 51011; ninguna sesión/venta creada.
- Observado: Apertura y cierre negativos devolvieron 51003; cantidad negativa devolvió 51011; no se abrió una caja.
- Estado: **APROBADO**.
- Consulta de verificación: `SELECT COUNT(*) AS abiertas FROM dbo.SesionesCaja WHERE estado='Abierta'; SELECT stock FROM dbo.Productos WHERE idProducto=@producto;`

### 4. Venta sin caja

- Datos iniciales: Producto nuevo del ensayo: stock100, precio100; sesión0 inexistente.
- Operación: sp_Ventas_RegistrarConCaja con sesión0
- Esperado: Error51006; stock100; no cabecera/detalle/pago.
- Observado: Se recibió 51006 por sesión inexistente; el stock permaneció en 100.
- Estado: **APROBADO**.
- Consulta de verificación: `SELECT stock FROM dbo.Productos WHERE idProducto=@producto; SELECT COUNT(*) FROM dbo.DetalleVentas WHERE idProducto=@producto;`

### 5. Venta en efectivo

- Datos iniciales: Sesión1 inicial500; producto100 con stock100.
- Operación: Una unidad, Efectivo, total100.
- Esperado: Venta vinculada; pagoEfectivo100.
- Observado: Venta confirmada con pago Efectivo asociado; importe de cabecera 100.
- Estado: **APROBADO**.
- Consulta de verificación: `SELECT v.idVenta,v.idSesion,p.medioPago,p.importe FROM dbo.Ventas v JOIN dbo.PagosVenta p ON p.idVenta=v.idVenta WHERE v.idSesion=@sesion1;`

### 6. Venta por transferencia

- Datos iniciales: Sesión1 con una venta previa.
- Operación: Una unidad, Transferencia, total100.
- Esperado: PagoTransferencia100; efectivo esperado sigue600.
- Observado: Venta confirmada con pago Transferencia; no incrementó el efectivo esperado.
- Estado: **APROBADO**.
- Consulta de verificación: `SELECT montoFinalEsperado,ventasEfectivo FROM dbo.vw_Caja_Resumen WHERE idSesion=@sesion1;`

### 7. Venta con tarjeta

- Datos iniciales: Sesión1 con dos ventas previas.
- Operación: Una unidad, Tarjeta, total100.
- Esperado: PagoTarjeta100; efectivo esperado sigue600.
- Observado: Venta confirmada con pago Tarjeta; no incrementó el efectivo esperado.
- Estado: **APROBADO**.
- Consulta de verificación: `SELECT medioPago,importe FROM dbo.PagosVenta p JOIN dbo.Ventas v ON v.idVenta=p.idVenta WHERE v.idSesion=@sesion1;`

### 8. Asociación venta y sesión

- Datos iniciales: Tres ventas nuevas registradas.
- Operación: Consultar cabeceras.
- Esperado: Tres ventas del vendedor con sesión1.
- Observado: Las tres cabeceras quedaron asociadas a la sesión y al vendedor esperados, por 100 cada una.
- Estado: **APROBADO**.
- Consulta de verificación: `SELECT COUNT(*) FROM dbo.Ventas WHERE idSesion=@sesion1 AND idUsuario=@vendedor AND total=100;`

### 9. Descuento de stock

- Datos iniciales: Stock inicial100; tres ventas de una unidad.
- Operación: Consultar producto y detalles.
- Esperado: Stock97; cantidad vendida3.
- Observado: El stock bajó de 100 a 97 después de las tres unidades vendidas.
- Estado: **APROBADO**.
- Consulta de verificación: `SELECT stock FROM dbo.Productos WHERE idProducto=@producto; SELECT SUM(cantidad) FROM dbo.DetalleVentas WHERE idProducto=@producto;`

### 10. Stock insuficiente

- Datos iniciales: Stock97; sesión1 abierta.
- Operación: Intentar vender98 unidades.
- Esperado: Error51013; snapshot de cantidades/stock intacto.
- Observado: Intentar 98 unidades con stock 97 devolvió 51013; snapshot de cabeceras, detalles, pagos y stock idéntico.
- Estado: **APROBADO**.
- Consulta de verificación: `SELECT stock FROM dbo.Productos WHERE idProducto=@producto; SELECT COUNT(*) FROM dbo.Ventas; SELECT COUNT(*) FROM dbo.DetalleVentas; SELECT COUNT(*) FROM dbo.PagosVenta;`

### 11. Rollback después de descontar stock

- Datos iniciales: Sesión1 abierta; trigger QA inerte que falla solo con SESSION_CONTEXT de prueba.
- Operación: Activar fallo de pago en esa conexión; vender una unidad; desactivar el fallo.
- Esperado: Error51211 durante inserción del pago; reversión de stock, cabecera, detalle y pago; snapshot idéntico.
- Observado: El trigger de prueba produjo 51211 al insertar el pago; se revirtieron cabecera, detalle, pago y descuento de stock. Snapshot idéntico antes/después.
- Estado: **APROBADO**.
- Consulta de verificación: `SELECT COUNT(*) FROM dbo.Ventas; SELECT COUNT(*) FROM dbo.DetalleVentas; SELECT COUNT(*) FROM dbo.PagosVenta; SELECT stock FROM dbo.Productos WHERE idProducto=@producto;`

### 12. Cierre con efectivo correcto

- Datos iniciales: Inicial500; efectivo100; transferencia100; tarjeta100.
- Operación: Cerrar con contado600.
- Esperado: Esperado600, real600, diferencia0, Cerrada.
- Observado: Cierre persistido: esperado 600, contado 600, diferencia 0 y estado Cerrada.
- Estado: **APROBADO**.
- Consulta de verificación: `SELECT montoFinalEsperado,montoFinalReal,diferencia,estado,fechaCierre,idUsuarioCierre FROM dbo.SesionesCaja WHERE idSesion=@sesion1;`

### 13. Diferencias positiva y negativa

- Datos iniciales: Dos sesiones nuevas, cada una inicial500 y ventaEfectivo100.
- Operación: Cerrar sesión2 con610 y sesión3 con590.
- Esperado: Diferencias+10 y-10, respectivamente.
- Observado: Dos sesiones distintas cerraron con diferencias +10 y -10, respectivamente; esperado 600 en cada una.
- Estado: **APROBADO**.
- Consulta de verificación: `SELECT idSesion,montoFinalEsperado,montoFinalReal,diferencia FROM dbo.SesionesCaja WHERE idSesion IN (@sesion2,@sesion3);`

### 14. Cierre duplicado

- Datos iniciales: Sesión1 cerrada.
- Operación: Repetir cierre de sesión1.
- Esperado: Error51006; no cambia el cierre persistido.
- Observado: El cierre repetido devolvió 51006.
- Estado: **APROBADO**.
- Consulta de verificación: `SELECT estado,fechaCierre,montoFinalReal,diferencia FROM dbo.SesionesCaja WHERE idSesion=@sesion1;`

### 15. Historial por fecha y vendedor

- Datos iniciales: Sesión1 abierta; fechas del día ±1.
- Operación: sp_Caja_Historial del vendedor.
- Esperado: Incluye sesión1; ningún responsable ajeno.
- Observado: El historial incluyó la sesión actual una sola vez y no incluyó responsables ajenos.
- Estado: **APROBADO**.
- Consulta de verificación: `EXEC dbo.sp_Caja_Historial @vendedor,@desde,@hasta;`

### 16. Separación entre sesiones e históricos

- Datos iniciales: Sesión1 con3 ventas, sesión2 con1, sesión3 con1; histórico ficticio sin sesión.
- Operación: Consultar conteos y snapshot del histórico.
- Esperado: Conteos3/1/1; total, fecha e idSesion NULL del histórico intactos.
- Observado: Conteos por sesión: 3, 1 y 1 ventas; snapshot de total/fecha/idSesion NULL del histórico ficticio intacto.
- Estado: **APROBADO**.
- Consulta de verificación: `SELECT idSesion,COUNT(*) FROM dbo.Ventas WHERE idSesion IN (@sesion1,@sesion2,@sesion3) GROUP BY idSesion; SELECT total,fecha,idSesion FROM dbo.Ventas WHERE idVenta=@ventaHistorica;`

### 17. Dos ventas simultáneas de última unidad

- Datos iniciales: Producto separado stock1/precio100; sesión nueva; dos conexiones independientes.
- Operación: Enviar dos ventas asíncronas tras una barrera de bloqueo transaccional; liberar barrera.
- Esperado: Una venta exitosa, un rechazo51013, stock0, una cabecera; cerrar sesión con600.
- Observado: Dos conexiones enviaron ventas retenidas por una barrera transaccional: una confirmó y otra recibió 51013. Stock final 0 y una sola cabecera.
- Estado: **APROBADO**.
- Consulta de verificación: `SELECT stock FROM dbo.Productos WHERE idProducto=@productoConcurrente; SELECT COUNT(*) FROM dbo.Ventas WHERE idSesion=@sesionConcurrente;`

### 18. Permisos por perfil y sesión ajena

- Datos iniciales: Administrador, gerente e inactivo ficticios; segundo vendedor activo; sesión1 de primer vendedor.
- Operación: Intentar abrir/vender/cerrar/historial con actores no autorizados; consultar/vender sesión ajena.
- Esperado: 51001 para perfiles/inactivo; reporte ajeno vacío; venta ajena51006.
- Observado: Administrador, gerente e inactivo recibieron 51001 en apertura/venta/cierre/historial. Otro vendedor no obtuvo el reporte ajeno y recibió 51006 al intentar vender en esa sesión.
- Estado: **APROBADO**.
- Consulta de verificación: `EXEC dbo.sp_Caja_Reporte @otroVendedor,@sesion1; EXEC dbo.sp_Caja_Historial @administrador,@desde,@hasta;`

## Defectos de pruebas corregidos

1. **OUTPUT en DeriveParameters:** el primer intento del runner se detuvo en preflight con dirección incompatible de idSesion, antes de ejecutar los 18 casos. SqlClient informa esos OUTPUT de T-SQL como InputOutput. Se corrigió la comprobación para admitir Output/InputOutput cuando el contrato exige salida. La repetición completa aprobó los 18 casos.
2. **Nullable en PowerShell:** la primera prueba adicional BLL/DAL señaló incorrectamente el reporte cerrado porque PowerShell desempaqueta Nullable(Of DateTime) a DateTime y no expone HasValue. Se cambió la aserción a una comparación con null. La prueba adicional repetida aprobó y después se volvió a ejecutar el plan completo (18/18).

Estos fueron defectos del código de ensayo, no fallos funcionales observados en los procedimientos o clases VB. No fue necesario modificar VB ni aplicar una migración correctiva. El primer preflight interrumpido y el fallo de la prueba adicional se conservan como antecedentes; no se ocultan ni se confunden con fallos finales de los 18 casos.

## Verificaciones adicionales realmente ejecutadas

- Prueba tests/qa/Probar-Capas-QA.ps1 con las DLL compiladas: CajaBLL/VentaBLL -> DAL -> SQL QA; apertura inicial 500, venta 100 con cada uno de los tres medios, esperado 600, cierre contado 590, diferencia -10, lectura de campos anulables e historial y stock final 0. Aprobada después de corregir la aserción indicada.
- QA tiene 11 tablas (9 originales + PagosVenta + qa.Fixtures), 11 FK, 4 CHECK y 28 SP. Ninguna FK/CHECK está deshabilitada o sin confianza.
- Verificados y habilitados: UX_SesionesCaja_UnicaAbierta (único/filtrado), IX_Ventas_SesionCaja, IX_SesionesCaja_UsuarioFecha y PK_PagosVenta.
- Comprobaciones finales: 0 cajas abiertas, 0 ventas nuevas con pago ausente/inconsistente, 0 detalles con cantidad/precio/subtotal inválidos y 0 productos con stock negativo. El histórico ficticio inicial continúa sin sesión y con importe/fecha originales.
- Validar-Preparacion-SinSql.ps1: sintaxis SQL y PowerShell, guardas, hashes, seis contratos DAL y fallos seguros de configuración, aprobado.
- Probar-Caja-SinSql.ps1: 20 comprobaciones locales adicionales aprobadas. No se cuentan como ensayos SQL del plan.
- Iniciar-App-QA.ps1 -SoloVerificar: aprobado; no se inició una ventana ni se modificaron claves.

## Protección de la base original

No se ejecutó DDL/DML sobre ForzaSuplementosDB ni se seleccionaron sus filas de personas/ventas. Se volvió a exportar exclusivamente el catálogo/definiciones y su hash coincide con el snapshot anterior a crear QA:
`87710911993CA3A3D4656684D6E71813C8D9D482343FF474D45547ADD8F09704`

Esto verifica que los metadatos auditados del origen no cambiaron. No se leyó ni se calculó un hash del contenido de sus filas; no se afirma una comparación de datos personales. La conexión habitual permanece sin cambios.

## Archivos modificados y creados

- Modificado tests/qa/Invoke-Caja-QA.ps1: interpretación correcta de parámetros de salida.
- Nuevo tests/qa/Probar-Capas-QA.ps1: ensayo real adicional con las DLL VB y la configuración QA.
- Nuevos docs/RESULTADOS_QA.md y docs/qa/EVIDENCIA_18_CASOS.json: resultados y evidencia final.
- Nuevo docs/INICIAR_QA_WINDOWS.md: inicio protegido, clave ficticia interactiva y depuración sin usar F5 normal.
- Actualizados sql/qa/README.md, docs/CAJA_IMPLEMENTACION.md y tests/qa/PLAN_PRUEBAS.md para enlazar el estado real.
- No hay nuevos scripts de migración ni cambios de código VB en esta tarea. Todos los cambios SQL fueron los scripts QA autorizados y los datos/trigger de ensayo.

## Iniciar y probar manualmente

Seguir docs/INICIAR_QA_WINDOWS.md. Primero establecer una clave nueva ficticia con Establecer-Clave-QA.ps1 (interactivo, no guarda/imprime contraseñas) y luego usar Iniciar-App-QA.ps1. El lanzador fija el perfil únicamente en el proceso hijo y el título principal identifica QA. Para depurar: recompilar en Visual Studio y asociarse al PID del proceso ya iniciado por el lanzador; no usar F5 normal. En SSMS verificar servidor y DB_NAME antes de consultar exclusivamente QA.

## Pendientes y límites

- Pendiente la prueba visual de login, permisos de menú, botones, grillas, filtros, mensajes y formatos regionales; el código compiló y sus capas sí se probaron contra SQL.
- No se ensayaron una doble apertura simultánea ni la carrera simultánea cierre/venta; se probó apertura duplicada secuencial y venta concurrente sobre última unidad. No son pruebas de carga.
- No se probó restauración ni backup físico; ese SP está bloqueado en QA.
- Permanecen los límites ya documentados: pago único por venta, sin idempotencia de reintento automático, relevo de caja ni operaciones de efectivo ajenas a ventas. No se agregaron módulos nuevos.
- Siguiente tarea: completar el ensayo manual documentado contra QA antes de ampliar funcionalidades.
