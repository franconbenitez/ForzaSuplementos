param([switch]$AutorizarEscrituras)
$ErrorActionPreference='Stop'
if(!$AutorizarEscrituras){throw 'Esta prueba usa solo datos ficticios pero requiere autorizacion de escritura QA.'}
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Import-Module (Join-Path $root 'scripts\qa\QA.Common.psm1') -Force
$cfg=Get-QaConfig
$cn=Open-QaConnection
$oldEnv=$env:FORZA_ENTORNO;$oldConfig=$env:FORZA_QA_CONFIG
try {
    $env:FORZA_ENTORNO='QA';$env:FORZA_QA_CONFIG=$cfg.Path
    $folder=Join-Path $root 'ForzaSuplementos\ForzaSuplementos\ForzaSuplementos.Presentacion\bin\Debug'
    foreach($layer in @('Entidades','Datos','Negocio')){$null=[Reflection.Assembly]::LoadFrom((Join-Path $folder "ForzaSuplementos.$layer.dll"))}
    $f=(Invoke-QaQuery $cn 'SELECT vendedor,cliente,categoria FROM qa.Fixtures;').Rows[0]
    $actor=New-Object ForzaSuplementos.Entidades.Usuario
    $actor.IdUsuario=[int]$f.vendedor;$actor.NombrePerfil='VENDEDOR'
    $caja=New-Object ForzaSuplementos.Negocio.CajaBLL
    if($null -ne $caja.ObtenerAbierta($actor)){throw 'Se requiere comenzar sin caja abierta.'}
    $table=Invoke-QaQuery $cn 'INSERT dbo.Productos(idCategoria,nombre,descripcion,precio,stock,activo) VALUES(@c,@n,@d,100,3,1); SELECT CONVERT(int,SCOPE_IDENTITY()) AS id;' @{'@c'=[int]$f.categoria;'@n'=('QA Capas '+[Guid]::NewGuid().ToString('N'));'@d'='Ensayo de DLL VB con SQL QA'}
    $product=[int]$table.Rows[0].id
    $session=$caja.Abrir($actor,500D)
    $bll=New-Object ForzaSuplementos.Negocio.VentaBLL
    foreach($method in @('Efectivo','Transferencia','Tarjeta')){
        $v=New-Object ForzaSuplementos.Entidades.Venta
        $v.IdUsuario=$actor.IdUsuario;$v.IdCliente=[int]$f.cliente
        $v.MedioPago=[Enum]::Parse([ForzaSuplementos.Entidades.MedioPago],$method)
        $d=New-Object ForzaSuplementos.Entidades.DetalleVenta
        $d.IdProducto=$product;$d.Cantidad=1;$d.PrecioUnitario=100D
        $v.Detalles.Add($d)
        $bll.ProcesarVenta($v,$actor)
        if($v.IdVenta -le 0 -or $v.IdSesion -ne $session -or $v.Total -ne 100D){throw 'Identidad/sesion/total no actualizado tras la venta.'}
    }
    $open=$caja.ObtenerAbierta($actor)
    if($open.MontoFinalEsperado -ne 600D -or $open.VentasEfectivo -ne 100D -or $open.ImporteVentas -ne 300D -or $open.CantidadVentas -ne 3){throw 'Mapeo de resumen abierto incorrecto.'}
    $caja.Cerrar($actor,$session,590D)
    $report=$caja.Reporte($actor,$session)
    # PowerShell desempaqueta Nullable(Of DateTime) a DateTime: no expone HasValue.
    if($report.EstaAbierta -or $null -eq $report.FechaCierre -or $report.Diferencia -ne -10D -or $report.MontoFinalReal -ne 590D){throw 'Mapeo de reporte cerrado incorrecto.'}
    $history=$caja.Historial($actor,(Get-Date).Date.AddDays(-1),(Get-Date).Date.AddDays(1))
    if(!(@($history | ForEach-Object IdSesion) -contains $session)){throw 'El historial VB no devuelve la sesion.'}
    if($null -ne $caja.ObtenerAbierta($actor)){throw 'El cierre dejo caja abierta.'}
    $stock=(Invoke-QaQuery $cn 'SELECT stock FROM dbo.Productos WHERE idProducto=@p' @{'@p'=$product}).Rows[0].stock
    if([int]$stock -ne 0){throw 'Stock final incorrecto.'}
    Write-Output 'OK integracion VB BLL/DAL -> SQL QA: apertura, tres medios, serializacion XML, stock, resumen, cierre, nulos e historial.'
} finally {$env:FORZA_ENTORNO=$oldEnv;$env:FORZA_QA_CONFIG=$oldConfig;$cn.Dispose()}
