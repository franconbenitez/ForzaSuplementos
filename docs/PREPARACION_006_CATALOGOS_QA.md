# Preparacion de 006 Catalogos QA

Fecha: 2026-10-31. Trabajo exclusivo en ForzaSuplementos_GitHub. Migracion y ensayos de escritura NO ejecutados.

## Estado comprobado mediante lectura

scripts/qa/Preparar-006-Lectura.ps1 verifico servidor local esperado, base exacta ForzaSuplementosDB_QA, marca Forza-QA-Aislada-v1, ausencia de transaccion previa y baseline de 13 tablas/37 SP. Comparo las nueve definiciones de 005 con el script: coinciden. Perfiles.activo existe, PBKDF2 esta inactivo y CredencialesUsuario vacia. No existen Proveedores, Marcas, Productos.idMarca ni los seis contratos de 006. El usuario confirmo ingreso manual con qa_admin y cierre de sesion correctos despues de 005.

Las definiciones actuales y sus opciones ANSI, metadatos de columnas y resultado del preflight quedaron en private/006-preparacion-* ignorado por Git. El registro de contratos 006 previos esta vacio: no hay definiciones que reemplazar. No se exportaron filas de usuarios ni credenciales.

## Efectos exactos de 006

- Crea Proveedores: ID identity/PK, nombre, razonSocial, CUIT opcional y activo con default 1. CHECK de nombres no vacios y formato numerico CUIT; indice unico filtrado para CUIT informado. El SP tambien comprueba digito verificador.
- Crea Marcas: ID identity/PK, nombre unico, activo con default 1 y CHECK de nombre no vacio.
- Agrega Productos.idMarca nullable, FK a Marcas e indice IX_Productos_Marca. Los productos existentes conservan sus datos y quedan sin marca asignada. No cambia precios, stock ni ventas historicas.
- Crea seis SP: sp_Comercial_Estado, sp_Proveedores_Buscar, sp_Proveedores_Guardar, sp_Marcas_Buscar, sp_Marcas_Guardar y sp_Marcas_AsociarProducto. No reemplaza contratos preexistentes en el baseline verificado.
- Resultado previsto: 15 tablas y 43 SP. Agrega una FK, tres CHECK, dos defaults y cinco indices contando PK/UQ.

Dependencias: estructura 005, Usuarios/Perfiles activos, Productos y fixtures QA para ensayos. No requiere 007 ni 008. Cada lote verifica servidor/base/marca. No hay USE, rutas fisicas, nombres de tres partes hacia otra base, DROP ni borrado de filas. La migracion usa una sola transaccion entre GO, XACT_ABORT y sqlcmd -b/:on error exit. Las comprobaciones IF NOT EXISTS evitan duplicar objetos, pero no reparan esquemas parciales arbitrarios: el preflight rechaza cualquier instalacion parcial.

## Contratos y permisos revisados

FrmProveedores y FrmMarcas reutilizan FrmCatalogoComercial: alta con ID 0, guardado devuelve Id positivo, siguientes guardados modifican ese mismo ID. Doble clic carga Id/Nombre/Activo y RazonSocial/Cuit en proveedores. La casilla Activo permite baja logica y reactivacion, sin DELETE. Las busquedas devuelven hasta 500 filas y mantienen los inactivos visibles para reactivarlos. Asociar exige marca y producto activos, preserva ID real, precio y stock; no existe desasociacion a NULL desde la UI actual.

ComercialBLL exige Permiso.Productos (solo gerente) y valida nombres, longitudes, IDs y CUIT. ComercialDAL usa StoredProcedure y parametros coincidentes con SQL: Buscar(@idActor,@filtro), Proveedores_Guardar(@idActor,@id,@nombre,@razonSocial,@cuit,@activo), Marcas_Guardar(@idActor,@id,@nombre,@activo), AsociarProducto(@idActor,@idProducto,@idMarca). Los SP Guardar devuelven una fila Id; la DAL bloquea reintentos automaticos ante respuesta incierta. Las columnas de Buscar coinciden con la UI.

FrmPrincipal y AccesoFormulario impiden abrir estos modulos a administrador/vendedor. Los cinco SP de operaciones consultan el rol GERENTE y estado activo de usuario/perfil almacenados. sp_Comercial_Estado solo expone disponibilidad, no filas comerciales ni modificaciones. El ID actor procede de la sesion de la aplicacion; no es autenticacion independiente frente a alguien con acceso SQL directo a la misma cuenta integrada. No se afirma seguridad SQL de operaciones nuevas hasta ejecutar los ensayos autorizados.

## Pruebas realizadas y pendientes

Compilacion Debug/AnyCPU y regresion scripts/Validar-Avance.ps1 -IncluirLecturaQa: 655 comprobaciones aprobadas, sin fixtures de escritura. Adicionalmente 65 lotes/procedimientos analizados estaticamente con ScriptDom. La sintaxis del fixture ampliado se analizo despues de editarlo. El preparador de lectura se ejecuto realmente; el aplicador se verifico sintacticamente y su bloqueo sin autorizacion se comprueba offline. No se ejecuto el despliegue ni ningun caso de integracion nuevo. No hubo cambios de codigo VB ni estetica.

Catalogos_006_Rollback_Preparado.sql contiene 17 casos: (1) alta proveedor con ID, (2) edicion/baja sin duplicar, (3) reactivacion proveedor, (4) alta marca con ID, (5) edicion/baja/reactivacion marca, (6) asociacion con precio/stock conservados, (7) busquedas y columnas/IDs, (8-11) rechazos administrador/vendedor en guardar/buscar, (12) marca inactiva, (13) producto inactivo, (14) nombre de marca duplicado, (15) CUIT invalido, (16) ID inexistente y (17) actor nulo.

Los siete casos positivos comparten una transaccion exterior que se revierte. Cada rechazo usa transaccion independiente porque un SP con XACT_ABORT puede revertir toda la transaccion externa. Se verifica el numero esperado de error, conteos de Productos/Proveedores/Marcas, ausencia del token ficticio y @@TRANCOUNT=0. Solo se insertan o modifican registros ficticios nuevos, nunca usuarios existentes. Los contadores IDENTITY pueden avanzar pese al rollback; no se reseedean. Los resultados APROBADO se emiten exclusivamente despues de ejecutar y verificar cada caso. Su estado actual es PENDIENTE, no aprobado.

## Ejecucion futura y recuperacion

NO ejecutar estos comandos sin las autorizaciones especificas correspondientes. Usar Windows PowerShell, desde la raiz del repositorio:

```powershell
# Solo lectura; se puede repetir antes de pedir autorizacion.
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File scripts/qa/Preparar-006-Lectura.ps1
# Solo despues de autorizar exclusivamente el despliegue 006:
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File scripts/qa/Aplicar-006-Estructura-QA.ps1 -AutorizarEstructura006
```

El aplicador vuelve a verificar baseline/destino, conserva conteos y definiciones, no cierra procesos, ejecuta unicamente 006 y verifica 15 tablas/43 SP, los seis cuerpos SQL, FK confiable, cinco indices, tres CHECK, tablas nuevas vacias y productos sin asociaciones. Comprueba que los SP previos y conteos existentes se conservaron. No ejecuta fixtures.

Ante error antes del COMMIT, sqlcmd se detiene y cierra su conexion; la transaccion SQL pendiente se revierte por el motor. Se debe comprobar ese resultado mediante lecturas, no asumirlo. Ante error despues de COMMIT, detener y conservar evidencia. No se ejecuta automaticamente DROP, restauracion, reintento ni una migracion inversa. Cualquier reversion posterior al COMMIT requiere inspeccion y autorizacion separada; las definiciones previas estan preservadas, pero eso no equivale a restaurar tablas.

Los ensayos requieren una segunda autorizacion explicita; despues de concedida, pueden lanzarse con el script fijo mediante sqlcmd -E -C -b, servidor esperado tomado de config/qa.config, base fija ForzaSuplementosDB_QA y variables QaExpectedServer y AutorizarEnsayo=SOLO_FIXTURES_ROLLBACK. No introducir una base configurable ni ejecutar otros scripts. Despues de desplegar, las pruebas de disponibilidad deben reconocer catalogos habilitados y Compras/Inventario aun pendientes; la prueba actual de modulos pendientes esta deliberadamente ligada al baseline anterior.

En Visual Studio no iniciar F5 sin el entorno protegido. Tras desplegar y autorizar las operaciones ficticias, abrir FORZA SUPLEMENTOS - QA (GITHUB), ingresar como gerente y probar Proveedores/Marcas; confirmar denegacion para los otros perfiles. La aprobacion visual de estos modulos sigue pendiente.

## Autorizacion solicitada

Autorizar exclusivamente sql/qa/006_Catalogos_QA.sql mediante scripts/qa/Aplicar-006-Estructura-QA.ps1 -AutorizarEstructura006 en ForzaSuplementosDB_QA de la instancia local verificada, con los efectos estructurales enumerados, conservacion privada previa y verificaciones posteriores solo de lectura. No incluye ensayos SQL de escritura, 007-008, activacion PBKDF2 ni modificaciones de otras bases. Ante fallo se detendra para comprobar el estado; ninguna reversion adicional posterior al COMMIT esta autorizada.
