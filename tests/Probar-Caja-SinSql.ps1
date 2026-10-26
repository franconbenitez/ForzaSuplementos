# Pruebas de reglas y construcción de formularios. Nunca abre conexiones SQL.
param([string]$Configuration = 'Debug')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$output = Join-Path $projectRoot "ForzaSuplementos\ForzaSuplementos\ForzaSuplementos.Presentacion\bin\$Configuration"
foreach ($name in @('Entidades','Datos','Negocio')) {
    $null = [Reflection.Assembly]::LoadFrom((Join-Path $output "ForzaSuplementos.$name.dll"))
}
$null = [Reflection.Assembly]::LoadFrom((Join-Path $output 'ForzaSuplementos.Presentacion.exe'))
$script:passed = 0
function Assert-Rechaza([string]$name, [scriptblock]$action) {
    $rejected = $false
    try { & $action } catch {
        $cause = $_.Exception
        while ($cause.InnerException) { $cause = $cause.InnerException }
        if ($cause -isnot [ApplicationException]) { throw }
        $rejected = $true
    }
    if (!$rejected) { throw "No se rechazo: $name" }
    $script:passed++
    Write-Output "OK: $name"
}
function Nueva-Venta {
    $v = New-Object ForzaSuplementos.Entidades.Venta
    $v.IdCliente = 1
    $v.IdUsuario = 1
    $v.MedioPago = [ForzaSuplementos.Entidades.MedioPago]::Efectivo
    $d = New-Object ForzaSuplementos.Entidades.DetalleVenta
    $d.IdProducto = 1
    $d.Cantidad = 2
    $d.PrecioUnitario = 12.50D
    $d.Subtotal = 999D
    $v.Detalles.Add($d)
    return $v
}
Assert-Rechaza 'monto negativo' { [ForzaSuplementos.Negocio.CajaBLL]::ValidarImporte(-1D) }
Assert-Rechaza 'precision no admitida' { [ForzaSuplementos.Negocio.CajaBLL]::ValidarImporte(0.001D) }
Assert-Rechaza 'importe fuera de capacidad SQL' { [ForzaSuplementos.Negocio.CajaBLL]::ValidarImporte(100000000D) }
[ForzaSuplementos.Negocio.CajaBLL]::ValidarImporte(0D)
[ForzaSuplementos.Negocio.CajaBLL]::ValidarImporte(99999999.99D)
$script:passed++
Write-Output 'OK: limites monetarios validos'
foreach ($role in @('ADMINISTRADOR','GERENTE','DESCONOCIDO','')) {
    $u = New-Object ForzaSuplementos.Entidades.Usuario
    $u.IdUsuario = 1
    $u.NombrePerfil = $role
    Assert-Rechaza "perfil rechazado: $role" { [ForzaSuplementos.Negocio.CajaBLL]::ValidarVendedor($u) }
}
Assert-Rechaza 'sesion ausente' { [ForzaSuplementos.Negocio.CajaBLL]::ValidarVendedor($null) }
$seller = New-Object ForzaSuplementos.Entidades.Usuario
$seller.IdUsuario = 1
$seller.NombrePerfil = 'VENDEDOR'
[ForzaSuplementos.Negocio.CajaBLL]::ValidarVendedor($seller)
$script:passed++
Write-Output 'OK: vendedor admitido en negocio (SQL verifica activo nuevamente)'
Assert-Rechaza 'venta nula' { [ForzaSuplementos.Negocio.VentaBLL]::ValidarVenta($null) }
$v = Nueva-Venta
$v.Detalles[0].Cantidad = -2
Assert-Rechaza 'cantidad negativa aunque subtotal sea positivo' { [ForzaSuplementos.Negocio.VentaBLL]::ValidarVenta($v) }
$v = Nueva-Venta
$v.Detalles[0].Cantidad = 0
Assert-Rechaza 'cantidad cero' { [ForzaSuplementos.Negocio.VentaBLL]::ValidarVenta($v) }
$v = Nueva-Venta
$v.Detalles.Add($v.Detalles[0])
Assert-Rechaza 'producto repetido' { [ForzaSuplementos.Negocio.VentaBLL]::ValidarVenta($v) }
$v = Nueva-Venta
$v.MedioPago = [ForzaSuplementos.Entidades.MedioPago]::SinSeleccionar
Assert-Rechaza 'pago sin elegir' { [ForzaSuplementos.Negocio.VentaBLL]::ValidarVenta($v) }
$v = Nueva-Venta
$v.MedioPago = [Enum]::ToObject([ForzaSuplementos.Entidades.MedioPago],99)
Assert-Rechaza 'pago desconocido' { [ForzaSuplementos.Negocio.VentaBLL]::ValidarVenta($v) }
$v = Nueva-Venta
$v.Detalles[0].PrecioUnitario = 99999999.99D
Assert-Rechaza 'subtotal excede capacidad' { [ForzaSuplementos.Negocio.VentaBLL]::ValidarVenta($v) }
$v = Nueva-Venta
[ForzaSuplementos.Negocio.VentaBLL]::ValidarVenta($v)
if ($v.Total -ne 25D -or $v.Detalles[0].Subtotal -ne 25D) { throw 'Se confio en un subtotal adulterado.' }
$script:passed++
Write-Output 'OK: subtotal y total recalculados'
$v.IdUsuario = 2
$bll = New-Object ForzaSuplementos.Negocio.VentaBLL
Assert-Rechaza 'vendedor de la venta distinto al autenticado' { $bll.ProcesarVenta($v, $seller) }
Add-Type -AssemblyName System.Windows.Forms
$form = New-Object ForzaSuplementos.Presentacion.FrmCaja
try {
    $flags = [Reflection.BindingFlags]'Instance,NonPublic,Public'
    $grid = $form.GetType().GetProperty('dgvHistorial',$flags).GetValue($form,$null)
    if (!$grid.ReadOnly -or $grid.AllowUserToDeleteRows -or $grid.Columns.Count -ne 8) { throw 'Configuracion incorrecta de historial.' }
    foreach ($name in @('btnAbrir','btnCerrar')) {
        if ($form.GetType().GetProperty($name,$flags).GetValue($form,$null).Enabled) { throw 'Operacion habilitada sin consultar estado.' }
    }
    $script:passed++
    Write-Output 'OK: construccion de FrmCaja e historial sin acceso SQL'
} finally { $form.Dispose() }
Write-Output "TOTAL: $script:passed comprobaciones correctas. No se probo SQL."
