# Integración de SOLO LECTURA: SP de catálogos y construcción local del payload. Nunca registra venta.
param([string]$Configuration='Debug')
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Import-Module (Join-Path $root 'scripts/qa/QA.Common.psm1') -Force
$cfg=Get-QaConfig
$cn=Open-QaConnection
try{
    $actorTable=Invoke-QaQuery $cn "SELECT TOP(1) u.idUsuario FROM dbo.Usuarios u INNER JOIN dbo.Perfiles p ON p.idPerfil=u.idPerfil WHERE u.activo=1 AND UPPER(p.nombrePerfil)='VENDEDOR' ORDER BY u.idUsuario;"
    if($actorTable.Rows.Count -ne 1){throw 'Bloqueado: falta vendedor QA ficticio activo. No se crean datos.'}
    $actorId=[int]$actorTable.Rows[0].idUsuario
}finally{$cn.Dispose()}
$out=Join-Path $root "ForzaSuplementos\ForzaSuplementos\ForzaSuplementos.Presentacion\bin\$Configuration"
Add-Type -AssemblyName System.Windows.Forms,System.Drawing
$refs=@('System.dll','System.Core.dll','System.Drawing.dll','System.Windows.Forms.dll')
foreach($layer in @('Entidades','Datos','Negocio','Presentacion')){
    $suffix=if($layer -eq 'Presentacion'){'exe'}else{'dll'}
    $file=Join-Path $out "ForzaSuplementos.$layer.$suffix"
    $null=[Reflection.Assembly]::LoadFrom($file);$refs+=,$file
}
$provider=New-Object Microsoft.VisualBasic.VBCodeProvider
$options=New-Object CodeDom.Compiler.CompilerParameters
$options.GenerateInMemory=$true;$options.CompilerOptions='/optionstrict+ /optionexplicit+'
foreach($ref in $refs){$null=$options.ReferencedAssemblies.Add($ref)}
$hostCode=$provider.CompileAssemblyFromFile($options,(Join-Path $root 'tests/ui/BuscadoresSinSql.vb'))
if($hostCode.Errors.HasErrors){throw ($hostCode.Errors | Out-String)}
$flags=[Reflection.BindingFlags]'Instance,NonPublic,Public'
function Field($form,$name){$t=$form.GetType();while($t){$p=$t.GetProperty($name,$flags);if($p){return ,($p.GetValue($form,$null))};$t=$t.BaseType};throw 'Control no encontrado'}
function Wait-Search($form){$clock=[Diagnostics.Stopwatch]::StartNew();do{[Windows.Forms.Application]::DoEvents();Start-Sleep -Milliseconds 10;if($clock.Elapsed.TotalSeconds -gt 8){throw 'Busqueda no termino'}}while($form.BusquedaEnCurso)}
function Show-Test($form){$form.StartPosition='Manual';$form.ShowInTaskbar=$false;$form.Location=New-Object Drawing.Point(-30000,-30000);$form.Show();[Windows.Forms.Application]::DoEvents()}
$script:checks=0
function Assert-Read([bool]$ok,[string]$message){if(!$ok){throw $message};$script:checks++;Write-Output "OK: $message"}
$oldEnv=$env:FORZA_ENTORNO;$oldConfig=$env:FORZA_QA_CONFIG
$env:FORZA_ENTORNO='QA';$env:FORZA_QA_CONFIG=$cfg.Path
try{
    # Contexto de prueba elegido en lectura; no es una prueba del Login.
    $actor=New-Object ForzaSuplementos.Entidades.Usuario;$actor.IdUsuario=$actorId;$actor.NombrePerfil='VENDEDOR'
    $clients=(New-Object ForzaSuplementos.Negocio.ClienteBLL).ObtenerClientes($true,$actor)
    $products=(New-Object ForzaSuplementos.Negocio.ProductoBLL).ObtenerProductos($true,$actor)
    if($clients.Count -eq 0 -or @($products | Where-Object {$_.Stock -gt 0 -and $_.Precio -gt 0}).Count -eq 0){throw 'Bloqueado: faltan cliente y producto QA activo con precio/stock. No se crean datos.'}
    Assert-Read (@($clients | Where-Object {!$_.Activo -or $_.IdCliente -le 0}).Count -eq 0) 'SP real devuelve clientes activos con ID valido'
    Assert-Read (@($products | Where-Object {!$_.Activo -or $_.IdProducto -le 0}).Count -eq 0) 'SP real devuelve productos activos con ID valido'
    $selector=New-Object ForzaSuplementos.Presentacion.FrmBuscador -ArgumentList (,$clients)
    try{
        Show-Test $selector;Wait-Search $selector
        $expectedClient=(Field $selector 'dgvResultados').Rows[0].DataBoundItem.IdCliente
        (Field $selector 'btnSeleccionar').PerformClick();$client=$selector.ClienteSeleccionado
        Assert-Read ($client.IdCliente -eq $expectedClient) 'Seleccion de cliente conserva ID real del SP'
    }finally{$selector.Dispose()}
    $available=New-Object 'System.Collections.Generic.List[ForzaSuplementos.Entidades.Producto]'
    foreach($product in $products){if($product.Stock -gt 0 -and $product.Precio -gt 0){$available.Add($product)}}
    $selector=New-Object ForzaSuplementos.Presentacion.FrmBuscador -ArgumentList (,$available)
    try{
        Show-Test $selector;Wait-Search $selector
        $expectedProduct=(Field $selector 'dgvResultados').Rows[0].DataBoundItem.IdProducto
        (Field $selector 'btnSeleccionar').PerformClick();$product=$selector.ProductoSeleccionado
        Assert-Read ($product.IdProducto -eq $expectedProduct) 'Seleccion de producto conserva ID real del SP'
    }finally{$selector.Dispose()}
    $real=New-Object ForzaSuplementos.Presentacion.FrmVentas
    try{
        $real.UsuarioActual=$actor;$real.UsuarioActualId=$actorId
        Show-Test $real
        $clock=[Diagnostics.Stopwatch]::StartNew()
        while(!(Field $real 'btnBuscarCliente').Enabled){[Windows.Forms.Application]::DoEvents();Start-Sleep -Milliseconds 10;if($clock.Elapsed.TotalSeconds -gt 12){throw 'Carga asincrona de catalogos no termino'}}
        Assert-Read ((Field $real 'btnBuscarProducto').Enabled -and (Field $real 'btnAgregar').Enabled -and (Field $real 'btnConfirmar').Enabled) 'Load real de Ventas carga catalogos en segundo plano y habilita controles'
    }finally{$real.Dispose()}
    $ventas=New-Object ForzaPruebasUI.VentasBuscadorVista
    try{
        Show-Test $ventas;$ventas.UsuarioActual=$actor;$ventas.UsuarioActualId=$actorId
        $ventas.ProximoCliente=$client;$ventas.ProximoProducto=$product
        (Field $ventas 'btnBuscarCliente').PerformClick();(Field $ventas 'btnBuscarProducto').PerformClick()
        $ventas.Agregar(1)
        (Field $ventas 'cboMedioPago').DataSource=[string[]]@('Seleccionar','Efectivo','Transferencia','Tarjeta');(Field $ventas 'cboMedioPago').SelectedIndex=1
        $sale=$ventas.PrepararVenta()
        Assert-Read ($sale.IdCliente -eq $expectedClient -and $sale.Detalles[0].IdProducto -eq $expectedProduct) 'Payload usado por Confirmar conserva los dos IDs reales'
        Assert-Read ($sale.Detalles[0].PrecioUnitario -eq $product.Precio) 'Payload conserva precio real del catalogo'
        $refreshed=(New-Object ForzaSuplementos.Negocio.ProductoBLL).ObtenerProductos($true,$actor) | Where-Object {$_.IdProducto -eq $expectedProduct}
        Assert-Read ($null -ne $refreshed -and $refreshed.Stock -eq $product.Stock) 'Stock observado igual tras seleccion y carrito local, sin registrar venta'
    }finally{$ventas.Dispose()}
    Write-Output "TOTAL SELECCION QA LECTURA: $script:checks comprobaciones aprobadas. No se ejecuto ProcesarVenta ni escrituras SQL."
}finally{$env:FORZA_ENTORNO=$oldEnv;$env:FORZA_QA_CONFIG=$oldConfig;$provider.Dispose()}
