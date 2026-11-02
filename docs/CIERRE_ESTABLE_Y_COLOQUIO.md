# Cierre funcional para el coloquio del 02/11/2026

Fecha local de cierre: 01/11/2026. Desarrollo funcional congelado por instruccion del usuario. No se agregan modulos, migraciones, credenciales ni operaciones SQL. Solo documentacion, pruebas autorizadas y preparacion de entrega. Repo principal: ForzaSuplementos_GitHub, master; Desarrollo_Codex es respaldo y no se modifica.

## Estado demostrado

- Login Enter/clic, navegacion MDI unica, advertencias de carrito/cambios y tema oscuro: revision manual aprobada por el usuario en etapas anteriores. Buscadores tambien aprobados manualmente; regresion automatizada repetida.
- Permisos: administrador usuarios/backup/auditoria; gerente catalogos, productos, compras, inventario y reportes comerciales; vendedor clientes, Caja, ventas y reportes propios. Comprobaciones automatizadas en UI/BLL y contratos SQL; no equivale a una auditoria completa de privilegios del servidor.
- Reportes por perfil con datos QA reales y consultas independientes de control; 15 ensayos SQL de reportes previos. No se atribuyen backups fisicos ni pruebas nuevas de restauracion a esta entrega.
- Catalogos 006: 17 ensayos y 11 bloques de rollback aprobados; Compras 007: compra 3 x 2,50, total 7,50, GUID idempotente, precio conservado, historial/detalle y rollback aprobados.
- Inventario 008: compra, movimiento, ajuste, GUID repetido y minimo probados con rollback; diez negativos de Compras/Inventario aprobados. Precision: el rechazo de administrador de esa suite pasa por Compras, no es una prueba directa adicional de Ajustar.
- Ventas/Caja 008: nueve ventas/pagos/movimientos y tres cierres con diferencias -1/0/+1 aprobados; ocho negativos aprobados con rollback individual. Ver ambos documentos de resultados para limites exactos de cobertura de DetalleVentas.
- QA real: 18 tablas, 50 SP, 21 FK, 33 indices y 17 CHECK. Huellas de las 18 tablas conservadas en el ultimo ensayo; cero Cajas abiertas y transacciones. Las migraciones 005-008 estan instaladas solo en QA.

## Riesgos y limites pendientes

PBKDF2 esta preparado, pero INACTIVO; Login heredado sigue disponible. No provisionar, activar ni cambiar claves durante la congelacion. No presentar autenticacion como seguridad de produccion. El usuario integrado SQL tiene privilegios independientes del perfil de aplicacion; un ID de actor no es identidad criptografica. Minimos privilegios SQL, endurecimiento de accesos heredados y pruebas de corte/recuperacion son trabajo futuro autorizado por separado.

Concurrencia real simultanea de Compras tras 008 no se ejecuta implicitamente; requiere fixture y permiso propios. Rollback permite avanzar IDENTITY. Revision visual final, resolucion/escalado y funcionamiento real en netbook siguen pendientes. Los historicos pueden no tener medio de pago/sesion/trazabilidad anterior: no inventar movimientos retrospectivos. No ejecutar los viejos documentos como instrucciones de despliegue automatico: consultar este cierre y resultados posteriores; documentos historicos pueden describir etapas antes de aplicar 005-008.

## Checklist visual final (pendiente de revision humana final)

- Todos: Login por Enter/clic, cerrar sesion y reingresar; ventana completa y textos legibles; un unico hijo MDI, sin ventanas duplicadas. En netbook probar 100% y escalado habitual, desplazamiento de dashboards y botones accesibles.
- Administrador: Usuarios y reportes administrativos accesibles; Ventas/Caja/catalogos comerciales denegados. Consultar historial de backup; no crear backup fisico sin decidirlo separadamente.
- Gerente: productos/categorias, proveedores/marcas, Compras/Inventario y dashboards accesibles; Usuarios, Backup y Caja/Ventas denegados. Revisar grillas vacias y filtros sin resultados sin guardar registros.
- Vendedor: Caja, Ventas, clientes y reportes propios; Usuarios/Productos/Backup denegados. Buscar cliente/producto, seleccionar por Enter/doble clic, conservar carrito, Vaciar carrito y advertencia Si/No al navegar. No confirmar ventas ni abrir/cerrar Caja durante una revision de solo lectura.
- Reportes: desde/hasta validos, periodo vacio con mensaje, vendedor sin estadisticas ajenas. Validar categorias/productos y etiquetas legibles.

Las acciones manuales que escriben datos requieren una decision/autorizacion independiente; este cierre no es permiso para una nueva suite SQL.

## Netbook: version estable y arranque seguro

1. Usar un clon local separado del remoto privado; no copiar .git entre equipos ni usar Desarrollo_Codex. El GitHub actual aun NO contiene todos los commits locales: no clonar esperando las ultimas funciones antes de publicar con autorizacion independiente.
2. Instalar Git, Visual Studio Community con Desarrollo de escritorio .NET, VB y targeting pack .NET Framework 4.7.2; una version de MSBuild que soporte la solucion .slnx. Windows PowerShell 5.1. Si la netbook no soporta estas herramientas, no improvisar conversion de solucion durante la congelacion; usar el equipo validado como alternativa.
3. Cuando la version estable haya sido publicada, clonar https://github.com/franconbenitez/ForzaSuplementos.git, rama master, en una carpeta local. Comparar git rev-parse HEAD con el commit de cierre anunciado. No hacer push ni pull sobre cambios locales sin revisarlos.
4. Copiar config/qa.example.config como config/qa.config (ignorado). Configurar solo servidor QA local verificado y servidorEsperado obtenido de SERVERPROPERTY('ServerName'); mantener base ForzaSuplementosDB_QA y marca Forza-QA-Aislada-v1. No copiar contrasenas, datos personales ni archivos MDF/LDF/BAK.
5. Si no existe una QA equivalente en la netbook, DETENER el inicio. La configuracion no crea la base y Git no transporta SQL Server. Preparar estructura/datos ficticios en una tarea autorizada separada; no ejecutar migraciones ni restaurar bases como parte de esta guia.
6. En la raiz del clon ejecutar: powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\scripts\qa\Iniciar-App-QA.ps1 -SoloVerificar. Debe confirmar QA; ante error detenerse, sin abrir el EXE directamente ni usar la conexion habitual.
7. Cerrar cualquier instancia anterior y hacer doble clic en INICIAR_FORZA_QA.cmd. Compila Debug, valida binario y destino, asigna entorno QA solo al proceso hijo y deja el error visible si falla. El acceso directo local FORZA SUPLEMENTOS - QA (GITHUB) debe apuntar a ese CMD del clon, nunca al respaldo. En la netbook puede crearse manualmente desde Enviar a Escritorio.
8. En Visual Studio abrir ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.slnx y compilar Debug/Any CPU. Para ejecutar QA usar el CMD protegido; F5 sin configurar el entorno no sustituye al lanzador. Conservar la clave QA conocida por el usuario fuera del repo; no ejecutar scripts de cambio de claves.

## GitHub privado y trabajo diario

Consulta real git ls-remote origin refs/heads/master: 72514c8b3e5021b447b6ae630d6ad97469f24aab, coincidente con origin/master local. Antes del commit de cierre habia 34 commits locales posteriores; este cierre agrega uno mas. No se hizo push. Origin sigue apuntando a franconbenitez/ForzaSuplementos. La privacidad y cuenta autenticada deben volver a comprobarse antes de una publicacion autorizada; esta consulta de HEAD no comprueba por si sola private=true.

Tras autorizar publicacion: comprobar cuenta/privacidad, arbol limpio y divergencia; publicar sin force y verificar HEAD remoto. Al empezar en otra PC: git status, git pull --ff-only (solo despues de integrar los commits autorizados). Al terminar: revisar diff, compilar, commit; push solo segun autorizacion del usuario. No desarrollar simultaneamente el mismo cambio en ambos equipos. No almacenar config/qa.config, private, backups o credenciales en Git.

## Estudio del codigo con el companero

Las rutas siguientes parten de ForzaSuplementos/ForzaSuplementos. Abrir cada archivo real y recorrer el flujo con F12; repartir la explicacion y luego intercambiar roles.

1. Presentacion/FrmLogin.vb: constructor, btnIngresar_Click, Autenticar, MostrarPrincipal, PrepararNuevoIngreso. Explicar AcceptButton, prevencion de doble inicio y sesion. Negocio/SeguridadBLL.vb: Login y Activa; diferenciar modo heredado actual de PBKDF2 preparado.
2. Presentacion/FrmPrincipal.vb: ConfigurarPermisos, PermisoDelModulo, AbrirModulo, CerrarModulos y CrearModulo. Explicar por que cerrar puede cancelarse y por que cambiar de pantalla no cierra la Caja SQL.
3. Negocio/Permisos.vb: Puede y Exigir. Explicar control de autorizacion en negocio ademas del menu, actor autenticado y limitacion de la identidad SQL integrada.
4. Presentacion/FrmVentas.vb: CargarCatalogosAsync, BuscarCliente, BuscarProducto, DescartarCarritoAlCerrar y btnCancelar_Click; recorrer el evento de confirmar. Negocio/VentaBLL.vb: ProcesarVenta y ValidarVenta; Datos/VentaDAL.vb: RegistrarVenta. Entidades: Venta/DetalleVenta. Seguir IDs reales, precios, cantidades y sesion hasta los parametros del SP.
5. Negocio/CajaBLL.vb: RequerirAbierta, Abrir, Cerrar, Historial y Reporte. Leer los SP Caja de sql/qa/002_Caja_Procedimientos_QA.sql: esperado = inicial + efectivo, sin sumar tarjeta/transferencia. Explicar diferencias y persistencia de la sesion.
6. Negocio/CompraBLL.vb: Registrar, Historial, Detalle; Datos/CompraDAL.vb y sql/qa/007_Compras_QA.sql. Luego leer su reemplazo vigente en 008: GUID/idempotencia, transaccion, costo de compra frente a precio de venta y unico movimiento.
7. Negocio/InventarioBLL.vb y sql/qa/008_Inventario_QA.sql: ajuste, stock esperado, minimo, movimiento y rollback. Explicar bloqueo/concurrencia sin afirmar pruebas simultaneas que no se ejecutaron.
8. Negocio/DashboardBLL.vb: ValidarFechas, Ventas y Backups; Datos/DashboardDAL.vb. Explicar filtros por perfil y por que vendedor no controla ID ajeno. Relacionar con docs/INVENTARIO_BASE_DATOS.md y docs/DIAGRAMA_ER.md (relaciones reales).
9. Ensayos: leer tests/qa/Negativos_Ventas_Caja_008_Preparados.sql SIN ejecutarlo. Identificar error esperado, TRY/CATCH, ROLLBACK, conteos y mensajes por caso. Distinguir pruebas offline, SQL real, lectura y revision visual humana.

Ensayar una explicacion breve del recorrido UI -> BLL -> DAL -> SP -> tablas -> resultado; justificar cuatro capas, parametros, Decimal, claves foraneas, transaccion, idempotencia y permisos. Mostrar evidencia de resultados en vez de reejecutar fixtures durante la defensa. No exponer claves ni configuracion privada en pantalla.

## Verificacion final de esta entrega

Compilacion Debug/AnyCPU aprobada; regresion offline y QA de lectura finalizada con codigo 0: 749 comprobaciones aprobadas y 66 lotes/procedimientos analizados estaticamente. Evidencia privada: private/regresion-cierre-final.log. No se detectaron defectos funcionales nuevos ni se cambio VB, Designer, conexiones o esquema.
