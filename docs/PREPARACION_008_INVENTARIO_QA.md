# Preparacion protegida de 008 Inventario: NO desplegada

Fecha local: 2026-11-01. Solo analisis offline y SELECT. Complementa la revision estructural previa de CORRECCION_007_CHECK_Y_REVISION_008.md.

## Destino y punto de partida reales

Aplicar-008-Estructura-QA.ps1 -VerificarSoloLectura se ejecuto correctamente: servidor local esperado, ForzaSuplementosDB_QA, marca Forza-QA-Aislada-v1, sin transacciones previas/incompatibles; 17 tablas, 46 procedimientos, 17 FK, 28 indices y 13 CHECK. Coinciden los 18 contratos de 005/006/007; 008 ausente, PBKDF2 inactivo y credenciales derivadas vacias. Compras/DetalleCompras siguen vacias tras el ensayo con rollback.

Se conservaron las 46 definiciones con opciones ANSI, conteos, columnas/tipos, indices, restricciones y relaciones en private/008-preflight-* ignorado por Git. El preflight comparo dos lecturas de las huellas de las 17 tablas y admite tablas vacias. No guarda filas ni huellas de tablas en archivos. No hubo SQL de despliegue.

## Alcance de SQL 008, sin cambios en esta etapa

- Crea dbo.MovimientosStock: producto, usuario, fecha, tipo, cantidad con signo, stock anterior/posterior, motivo y origen opcional (compra/venta/GUID de ajuste). Tabla inicialmente vacia, sin movimientos historicos inventados.
- Agrega Productos.stockMinimo int NOT NULL con DEFAULT(0) y CHECK >=0. Ese atributo nuevo quedara en cero para los productos existentes; no cambia Productos.stock ni precio.
- Crea cuatro SP: sp_Inventario_Stock, sp_Inventario_Historial, sp_Inventario_Minimo y sp_Inventario_Ajustar.
- ACTUALIZA cuatro SP existentes: sp_Compras_Registrar, sp_Ventas_RegistrarConCaja, sp_Productos_Modificar y sp_Productos_Insertar. Por eso se preservan sus definiciones anteriores y no se afirma que los ocho sean nuevos.
- Resultado previsto: 18 tablas, 50 SP, 21 FK, 33 indices y 17 CHECK. Incrementos: una tabla, cuatro SP nuevos, cuatro FK, cinco indices incluyendo PK y cuatro CHECK. Dos DEFAULT nuevos (minimo y fecha de movimiento).

Los SP de Compras/Ventas capturan el unico UPDATE existente mediante OUTPUT para registrar movimiento dentro de su transaccion, sin aplicar un segundo incremento/descuento. Productos_Insertar exigira stock cero y Productos_Modificar rechazara editar stock directamente: se debera usar compra o ajuste con motivo. Esto altera el comportamiento futuro de esos SP y debe incluirse expresamente en la autorizacion estructural; no se aplico ahora.

## Restricciones, contratos y permisos revisados

Los CHECK multicolumna de MovimientosStock son de tabla; stockMinimo solo referencia su propia columna. Los cuatro destinos FK (Productos, Usuarios, Compras y Ventas) existen en QA con IDs int y PK correspondientes. Los indices unicos filtrados separan ajustes por GUID, compras/producto y ventas/producto. El indice de fecha/producto permite ordenar consultas. Se conservaron las opciones SET necesarias para indices filtrados.

InventarioBLL exige gerente para Stock/Historial/Ajustar/Minimo; valida cantidades con signo, motivo, GUID, stock esperado y resultado no negativo ni fuera de int. InventarioDAL envia los parametros coincidentes: Stock(@idActor); Historial(@idActor,@desde,@hasta,@idProducto opcional); Minimo(@idActor,@idProducto,@minimo); Ajustar(@idActor,@idProducto,@cantidad,@stockEsperado,@motivo nvarchar(250),@operacion uniqueidentifier). Los cuatro SP nuevos validan usuario/perfil activos y rol GERENTE. FrmInventario sigue bloqueado mientras falte 008.

El ajuste exige coincidencia del stock esperado y usa bigint antes de sumar, bloqueo transaccional compartido e idempotencia por GUID/contenido. Las consultas limitan sus resultados a 2000 filas; no se presentan como paginacion completa. No se modifico VB ni el tema aprobado. Los SP de Productos conservan sus firmas anteriores sin ID de actor: la autorizacion gerente procede de las capas de aplicacion, no constituye autenticacion independiente contra acceso SQL directo.

## Aplicador y seguridad preparados

scripts/qa/Aplicar-008-Estructura-QA.ps1 tiene modos mutuamente excluyentes: -VerificarSoloLectura o -AutorizarEstructura008. Sin ninguno rechaza antes de conectar. El modo lectura retorna antes de llamar sqlcmd; fue el unico modo ejecutado. Bloquea objetos, columna, indices o restricciones parciales de 008, baseline diferente, procesos del EXE abiertos y transacciones incompatibles. No termina procesos.

008.Validacion.psm1 fija la huella normalizada exacta del SQL revisado:

`AFEBAF6E4B68809B6897313BE876129328CE96186514F342F27E7A2ED09F7486`

Exige servidor/base/marca en cada lote y los ocho nombres de SP previstos. Validar-Restricciones.psm1 comprueba referencias cruzadas de CHECK antes de conectar. No permite DML exterior a los cuerpos de SP, borrar objetos, otras bases ni ejecutar otros archivos. La unica escritura de negocio estructural prevista es el backfill de la columna nueva por DEFAULT del ALTER, no cambios de stock/precios ni movimientos retroactivos.

Futuro despliegue: una llamada a sqlcmd con archivo fijo, base QA fija, -E -C -b y comprobacion de hash; el SQL usa XACT_ABORT, una transaccion entre GO y @@TRANCOUNT=1 antes de COMMIT. No se reintenta. Ante fallo conserva log e inspecciona objetos mediante lectura; no repara ni revierte automaticamente. @@TRANCOUNT=0 de una conexion nueva no demuestra por si solo rollback; se deben contrastar datos/objetos. Cualquier reversion posterior a COMMIT necesita autorizacion separada.

La verificacion futura tests/qa/Verificar-008-Lectura.ps1 exige 18/50/21/33/17, MovimientosStock vacia, minimos cero, columna no nula, cuatro FK/CHECK habilitados y confiables, dos defaults, cinco indices con claves/unicidad/filtros correctos y ocho cuerpos de SP coincidentes. Comprueba parametros de los cuatro SP de Inventario. El aplicador compara tambien las columnas PREEXISTENTES de las 17 tablas, conteos y las 42 definiciones no afectadas. Las cuatro reemplazadas se preservan privadamente y se comparan contra sus cuerpos nuevos.

No se ejecuto esa verificacion posterior ni se afirma que el DDL/SP 008 funcione en SQL Server: solo hay analisis estatico, pruebas offline y preflight real de lectura. sql/qa/008_Inventario_QA.sql permanece sin modificar.

## Pruebas y limites

Probar-Aplicador008-SinSql.ps1 agrega 29 comprobaciones offline de alcance/hash, destinos incorrectos, baseline parcial (incluida stockMinimo ya existente), transacciones incompatibles, sintaxis PowerShell y rechazo sin autorizacion. Hubo inicialmente un defecto de la propia prueba: intentaba reemplazar un nombre de SP que no existe en 008; se corrigio para mutar sp_Inventario_Stock y la prueba paso. No fue un error SQL ni motivo para reejecutar el ensayo de Compras.

Se integro esa suite en scripts/Validar-Avance.ps1; la compilacion Debug/AnyCPU y la regresion completa finalizaron correctamente: 736 comprobaciones aprobadas y 65 analisis estaticos SQL, registradas en private/regresion-ensayo-007-preparacion-008.log. Las 13 pruebas semanticas de CHECK ya analizan tanto 007 como 008; ScriptDom revisa lotes y cuerpos preparados. Ninguna suite invoca escritura SQL fuera del unico ensayo 007 autorizado al inicio de esta tarea.

## Proximo paso y permiso separado

Permitido ahora, desde Windows PowerShell en la raiz:

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File scripts/qa/Aplicar-008-Estructura-QA.ps1 -VerificarSoloLectura
```

NO ejecutar sin nueva autorizacion:

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File scripts/qa/Aplicar-008-Estructura-QA.ps1 -AutorizarEstructura008
```

La proxima autorizacion debe limitarse a estructura 008 en QA verificada: crear MovimientosStock y stockMinimo/default cero, cuatro SP nuevos y cuatro actualizados con sus restricciones/indices; conservar metadatos/definiciones anteriores y verificar integridad mediante lecturas. No incluye ajustes, compras/ventas nuevas, fixtures de escritura, PBKDF2, cambios de credenciales, otras bases ni push. Ante error se detendra sin reintentos ni reversiones adicionales. Despues se solicitaran por separado ensayos de movimientos/inventario con datos ficticios y rollback.
