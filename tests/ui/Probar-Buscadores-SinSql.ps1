param([string]$Configuration='Debug')
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$out=Join-Path $root "ForzaSuplementos\ForzaSuplementos\ForzaSuplementos.Presentacion\bin\$Configuration"
Add-Type -AssemblyName System.Windows.Forms,System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()
$refs=@('System.dll','System.Core.dll','System.Drawing.dll','System.Windows.Forms.dll')
foreach($layer in @('Entidades','Datos','Negocio','Presentacion')){
    $suffix=if($layer -eq 'Presentacion'){'exe'}else{'dll'}
    $path=Join-Path $out "ForzaSuplementos.$layer.$suffix"
    $null=[Reflection.Assembly]::LoadFrom($path);$refs+=,$path
}
$provider=New-Object Microsoft.VisualBasic.VBCodeProvider
$options=New-Object CodeDom.Compiler.CompilerParameters
$options.GenerateInMemory=$true;$options.CompilerOptions='/optionstrict+ /optionexplicit+'
foreach($ref in $refs){$null=$options.ReferencedAssemblies.Add($ref)}
$compiled=$provider.CompileAssemblyFromFile($options,(Join-Path $PSScriptRoot 'BuscadoresSinSql.vb'))
if($compiled.Errors.HasErrors){throw ($compiled.Errors | Out-String)}
$flags=[Reflection.BindingFlags]'Instance,NonPublic,Public'
function Field($form,$name){$t=$form.GetType();while($t){$p=$t.GetProperty($name,$flags);if($p){return ,($p.GetValue($form,$null))};$f=$t.GetField($name,$flags);if($f){return ,($f.GetValue($form))};$t=$t.BaseType};throw "Campo ausente: $name"}
function Invoke-Private($form,$name,$arguments=@()){$t=$form.GetType();while($t){$m=$t.GetMethod($name,$flags);if($m){$raw=New-Object object[] $arguments.Count;for($i=0;$i -lt $arguments.Count;$i++){if($null -ne $arguments[$i]){$raw[$i]=$arguments[$i].PSObject.BaseObject}};return $m.Invoke($form,$raw)};$t=$t.BaseType};throw "Metodo ausente: $name"}
function Show-Test($form){$form.StartPosition='Manual';$form.ShowInTaskbar=$false;$form.Location=New-Object Drawing.Point(-30000,-30000);$form.Show();[Windows.Forms.Application]::DoEvents()}
function Wait-Search($form){$watch=[Diagnostics.Stopwatch]::StartNew();do{[Windows.Forms.Application]::DoEvents();Start-Sleep -Milliseconds 10;if($watch.Elapsed.TotalSeconds -gt 8){throw 'Busqueda no termino'}}while($form.BusquedaEnCurso)}
$script:checks=0
function Assert-Search([bool]$ok,[string]$message){if(!$ok){throw $message};$script:checks++;Write-Output "OK: $message"}
function Reject([string]$message,[scriptblock]$action){try{& $action}catch{$e=$_.Exception;while($e.InnerException){$e=$e.InnerException};if($e -isnot [ApplicationException]){throw};Assert-Search $true $message;return};throw "No rechazo: $message"}
function Save-Preview($form,$name){$dir=Join-Path $root 'tests/artifacts/ui';$null=[IO.Directory]::CreateDirectory($dir);$image=New-Object Drawing.Bitmap($form.Width,$form.Height);try{$form.DrawToBitmap($image,(New-Object Drawing.Rectangle(0,0,$form.Width,$form.Height)));$image.Save((Join-Path $dir "$name.png"))}finally{$image.Dispose()}}
$old=$env:FORZA_ENTORNO;$env:FORZA_ENTORNO='PRUEBA_BUSCADORES_SIN_SQL'
try{
    # Todos los registros son fixtures ficticios en memoria, no lecturas de QA.
    $clients=New-Object 'System.Collections.Generic.List[ForzaSuplementos.Entidades.Cliente]'
    $c1=New-Object ForzaSuplementos.Entidades.Cliente;$c1.IdCliente=101;$c1.Nombre='Ana';$c1.Apellido='García';$c1.Dni='00000001';$c1.Telefono='0000';$c1.Activo=$true;$clients.Add($c1)
    $c2=New-Object ForzaSuplementos.Entidades.Cliente;$c2.IdCliente=509;$c2.Nombre='Ana';$c2.Apellido='Gómez';$c2.Dni='00000002';$c2.Activo=$true;$clients.Add($c2)
    $inactive=New-Object ForzaSuplementos.Entidades.Cliente;$inactive.IdCliente=99;$inactive.Nombre='Inactivo';$inactive.Activo=$false;$clients.Add($inactive);$clients.Add($null)
    $products=New-Object 'System.Collections.Generic.List[ForzaSuplementos.Entidades.Producto]'
    $p1=New-Object ForzaSuplementos.Entidades.Producto;$p1.IdProducto=703;$p1.Nombre='Creatina';$p1.NombreCategoria='Rendimiento';$p1.Precio=100;$p1.Stock=10;$p1.Activo=$true;$products.Add($p1)
    $p2=New-Object ForzaSuplementos.Entidades.Producto;$p2.IdProducto=19;$p2.Nombre='Creatina';$p2.NombreCategoria='Proteínas';$p2.Precio=250;$p2.Stock=3;$p2.Activo=$true;$products.Add($p2)
    $p0=New-Object ForzaSuplementos.Entidades.Producto;$p0.IdProducto=55;$p0.Nombre='Agotado';$p0.Activo=$true;$products.Add($p0)
    $pi=New-Object ForzaSuplementos.Entidades.Producto;$pi.IdProducto=99;$pi.Nombre='Inactivo';$pi.Stock=5;$pi.Activo=$false;$products.Add($pi);$products.Add($null)
    Assert-Search ([ForzaSuplementos.Negocio.BuscadorCatalogo]::Clientes($clients,'garcia').Count -eq 1) 'Clientes ignora mayusculas y acentos'
    Assert-Search ([ForzaSuplementos.Negocio.BuscadorCatalogo]::Clientes($clients,'ANA 509')[0].IdCliente -eq 509) 'Clientes combina nombre e ID'
    Assert-Search ([ForzaSuplementos.Negocio.BuscadorCatalogo]::Clientes($clients,'00000001')[0].IdCliente -eq 101) 'Clientes busca DNI'
    Assert-Search ([ForzaSuplementos.Negocio.BuscadorCatalogo]::Clientes($clients,'').Count -eq 2) 'Clientes excluye nulos e inactivos'
    Assert-Search ([ForzaSuplementos.Negocio.BuscadorCatalogo]::Productos($products,'PROTEINAS')[0].IdProducto -eq 19) 'Productos busca categoria sin acentos'
    Assert-Search ([ForzaSuplementos.Negocio.BuscadorCatalogo]::Productos($products,'crea rend')[0].IdProducto -eq 703) 'Productos combina nombre y categoria'
    Assert-Search ([ForzaSuplementos.Negocio.BuscadorCatalogo]::Productos($products,'703')[0].IdProducto -eq 703) 'Productos utiliza ID disponible sin inventar SKU'
    Assert-Search ([ForzaSuplementos.Negocio.BuscadorCatalogo]::Productos($products,'inactivo').Count -eq 0) 'Productos no ofrece inactivos'
    $cancel=New-Object Threading.CancellationTokenSource;$cancel.Cancel()
    $cancelled=$false;try{$null=[ForzaSuplementos.Negocio.BuscadorCatalogo]::Productos($products,'',$cancel.Token)}catch{$e=$_.Exception;while($e.InnerException){$e=$e.InnerException};if($e -isnot [OperationCanceledException]){throw};$cancelled=$true}finally{$cancel.Dispose()}
    Assert-Search $cancelled 'Filtro admite cancelacion efectiva'
    $selector=New-Object ForzaSuplementos.Presentacion.FrmBuscador -ArgumentList (,$clients)
    try{
        Show-Test $selector;Wait-Search $selector
        $grid=Field $selector 'dgvResultados';$search=Field $selector 'txtBuscar'
        Assert-Search ($grid.Rows.Count -eq 2 -and $grid.ReadOnly -and !$grid.MultiSelect) 'Grilla de clientes con seleccion unica y solo lectura'
        Save-Preview $selector 'BuscadorClientes'
        $search.Text='sin coincidencias'
        $null=Invoke-Private $selector 'SeleccionarActual'
        Assert-Search ($null -eq $selector.ClienteSeleccionado -and !$selector.IsDisposed) 'No selecciona una fila anterior mientras hay filtro pendiente'
        Wait-Search $selector
        (Field $selector 'btnSeleccionar').PerformClick()
        Assert-Search ($grid.Rows.Count -eq 0 -and !(Field $selector 'btnSeleccionar').Enabled -and $null -eq $selector.ClienteSeleccionado) 'Sin resultados no selecciona nulos'
        $search.Text='garcia';$search.Text='509';Wait-Search $selector
        Assert-Search ($grid.Rows.Count -eq 1 -and $grid.Rows[0].DataBoundItem.IdCliente -eq 509) 'Búsqueda nueva reemplaza resultados anteriores'
        $null=Invoke-Private $selector 'dgvResultados_CellDoubleClick' @($grid,(New-Object Windows.Forms.DataGridViewCellEventArgs(0,-1)))
        Assert-Search (!$selector.IsDisposed -and $null -eq $selector.ClienteSeleccionado) 'Doble clic en encabezado no selecciona'
        (Field $selector 'btnSeleccionar').PerformClick();$selectedClient=$selector.ClienteSeleccionado
        Assert-Search ($selectedClient.IdCliente -eq 509 -and $selector.DialogResult -eq 'OK') 'Boton selecciona ID real del DataBoundItem, no indice'
    }finally{$selector.Dispose()}
    foreach($method in @('DobleClic','EnterGrilla','EnterBusqueda')){
        $selector=New-Object ForzaSuplementos.Presentacion.FrmBuscador -ArgumentList (,$products)
        try{
            Show-Test $selector;Wait-Search $selector
            $grid=Field $selector 'dgvResultados';$search=Field $selector 'txtBuscar'
            Assert-Search ($grid.Columns.Contains('NombreCategoria') -and $grid.Columns.Contains('Precio') -and $grid.Columns.Contains('Stock') -and $grid.Columns.Contains('Activo')) "Producto muestra categoria, precio, stock y estado: $method"
            if($method -eq 'DobleClic'){Save-Preview $selector 'BuscadorProductos'}
            $search.Text='55';Wait-Search $selector
            Assert-Search (!(Field $selector 'btnSeleccionar').Enabled) "Stock cero no seleccionable: $method"
            $search.Text='19';Wait-Search $selector
            if($method -eq 'DobleClic'){$null=Invoke-Private $selector 'dgvResultados_CellDoubleClick' @($grid,(New-Object Windows.Forms.DataGridViewCellEventArgs(0,0)))}else{
                $key=New-Object Windows.Forms.KeyEventArgs([Windows.Forms.Keys]::Enter)
                $sender=if($method -eq 'EnterGrilla'){$grid}else{$search}
                $null=Invoke-Private $selector 'Busqueda_KeyDown' @($sender,$key)
                Assert-Search ($key.Handled -and $key.SuppressKeyPress) "Enter no se procesa dos veces: $method"
            }
            $selectedProduct=$selector.ProductoSeleccionado
            Assert-Search ($selectedProduct.IdProducto -eq 19) "Producto seleccionado por $method conserva ID"
        }finally{$selector.Dispose()}
    }
    $selector=New-Object ForzaSuplementos.Presentacion.FrmBuscador -ArgumentList (,$clients)
    try{Show-Test $selector;(Field $selector 'txtBuscar').Text='pendiente';$selector.Close();[Windows.Forms.Application]::DoEvents();Assert-Search $selector.IsDisposed 'Cerrar con filtro pendiente libera formulario y temporizador'}finally{$selector.Dispose()}
    $rowChange=New-Object 'System.Collections.Generic.List[ForzaSuplementos.Entidades.Producto]'
    $rowChange.Add($p0);$rowChange.Add($p1)
    $selector=New-Object ForzaSuplementos.Presentacion.FrmBuscador -ArgumentList (,$rowChange)
    try{
        Show-Test $selector;Wait-Search $selector
        $grid=Field $selector 'dgvResultados'
        $grid.CurrentCell=$grid.Rows[0].Cells[0]
        $grid.CurrentCell=$grid.Rows[1].Cells[0]
        Assert-Search ((Field $selector 'btnSeleccionar').Enabled) 'Cambiar de fila agotada a fila con stock habilita Seleccionar sin repetir clic'
        (Field $selector 'btnSeleccionar').PerformClick()
        Assert-Search ($selector.ProductoSeleccionado.IdProducto -eq 703) 'Seleccion utiliza la nueva fila actual y no el estado anterior'
    }finally{$selector.Dispose()}
    $large=New-Object 'System.Collections.Generic.List[ForzaSuplementos.Entidades.Producto]'
    foreach($id in 10000..14999){$entry=New-Object ForzaSuplementos.Entidades.Producto;$entry.IdProducto=$id;$entry.Nombre="Producto ficticio $id";$entry.NombreCategoria='Categoria ficticia';$entry.Activo=$true;$entry.Stock=1;$entry.Precio=1;$large.Add($entry)}
    $selector=New-Object ForzaSuplementos.Presentacion.FrmBuscador -ArgumentList (,$large)
    try{
        Show-Test $selector;Wait-Search $selector
        Assert-Search ((Field $selector 'dgvResultados').Rows.Count -eq 5000) 'Catalogo de 5000 productos se filtra en segundo plano'
        (Field $selector 'txtBuscar').Text='no coincide';$null=Invoke-Private $selector 'tmrBusqueda_Tick' @($selector,[EventArgs]::Empty)
        (Field $selector 'txtBuscar').Text='14999';Wait-Search $selector
        $grid=Field $selector 'dgvResultados'
        Assert-Search ($grid.Rows.Count -eq 1 -and $grid.Rows[0].DataBoundItem.IdProducto -eq 14999) 'Resultado tardio no reemplaza la ultima busqueda en catalogo grande'
        (Field $selector 'txtBuscar').Text='Producto';$null=Invoke-Private $selector 'tmrBusqueda_Tick' @($selector,[EventArgs]::Empty)
        $selector.Close();[Windows.Forms.Application]::DoEvents()
        Assert-Search $selector.IsDisposed 'Cerrar mientras trabaja el filtro cancela y libera la vista'
    }finally{$selector.Dispose()}
    $ventas=New-Object ForzaPruebasUI.VentasBuscadorVista
    try{
        Show-Test $ventas;$ventas.UsuarioActualId=42
        $ventas.ProximoCliente=$selectedClient;(Field $ventas 'btnBuscarCliente').PerformClick()
        Assert-Search ((Field $ventas 'txtClienteSeleccionado').Text.Contains('#509')) 'Ventas muestra cliente seleccionado e ID'
        $ventas.ProximoProducto=$selectedProduct;$ventas.Reentrar=$true;(Field $ventas 'btnBuscarProducto').PerformClick()
        Assert-Search ($ventas.AperturasProducto -eq 1) 'Reentrada no abre buscadores duplicados'
        Assert-Search ((Field $ventas 'lblPrecioSeleccionado').Text.Contains('250') -and (Field $ventas 'txtProductoSeleccionado').Text.Contains('#19')) 'Ventas muestra precio y producto elegido'
        $ventas.ProximoProducto=$null;(Field $ventas 'btnBuscarProducto').PerformClick()
        Assert-Search ((Field $ventas 'txtProductoSeleccionado').Text.Contains('#19')) 'Cancelar selector conserva seleccion previa'
        Reject 'Cantidad cero rechazada' {$ventas.Agregar(0)}
        Reject 'Cantidad negativa rechazada' {$ventas.Agregar(-1)}
        Reject 'Stock insuficiente rechazado antes de agregar' {$ventas.Agregar(4)}
        (Field $ventas 'txtCantidad').Text='2';(Field $ventas 'btnAgregar').PerformClick()
        $cart=Field $ventas '_carrito'
        Assert-Search ($cart.Count -eq 1 -and $cart[0].IdProducto -eq 19 -and $cart[0].Cantidad -eq 2 -and $cart[0].PrecioUnitario -eq 250) 'Agregar usa ID y precio de grilla y no modifica stock'
        $ventas.ProximoCliente=$null;(Field $ventas 'btnBuscarCliente').PerformClick()
        Assert-Search ($cart.Count -eq 1 -and (Field $ventas 'txtClienteSeleccionado').Text.Contains('#509')) 'Buscar y cancelar no pierde cliente ni carrito'
        $ventas.ElegirProducto($p2);Reject 'Stock acumulado rechazado sin cambiar carrito' {$ventas.Agregar(2)}
        Assert-Search ($cart[0].Cantidad -eq 2 -and $p2.Stock -eq 3) 'Rechazo conserva cantidad y stock'
        $p2.Activo=$false;Reject 'Producto desactivado despues de seleccionar se rechaza' {$ventas.Agregar(1)};$p2.Activo=$true
        (Field $ventas 'cboMedioPago').DataSource=[string[]]@('Seleccionar','Efectivo','Transferencia','Tarjeta');(Field $ventas 'cboMedioPago').SelectedIndex=1
        $sale=$ventas.PrepararVenta()
        Assert-Search ($sale.IdCliente -eq 509 -and $sale.IdUsuario -eq 42 -and $sale.Detalles[0].IdProducto -eq 19 -and $sale.MedioPago -eq 'Efectivo') 'Payload de Confirmar Venta conserva IDs reales seleccionados y pago'
        (Field $ventas 'dgvCarrito').DataSource=$cart;$null=Invoke-Private $ventas 'ConfigurarGrilla';Save-Preview $ventas 'VentasBuscadores'
        (Field $ventas 'btnCancelar').PerformClick()
        Assert-Search ($cart.Count -eq 0 -and !(Field $ventas 'btnCancelar').Enabled -and $p2.Stock -eq 3) 'Vaciar carrito conserva stock y deshabilita boton'
        Reject 'Confirmacion sin cliente/carrito se rechaza' {$ventas.PrepararVenta()}
    }finally{$ventas.Dispose()}
    $source=[IO.File]::ReadAllText((Join-Path $root 'ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Presentacion/FrmVentas.vb'))
    Assert-Search ($source -match 'Dim nuevaVenta = CrearVentaPendiente\(\)' -and $source -match 'RegistrarVenta\(nuevaVenta\)' -and $source -match '_ventaBLL.ProcesarVenta\(venta, UsuarioActual\)') 'Confirmar utiliza el mismo payload comprobado'
    Assert-Search ($source -notmatch 'cboCliente|cboProducto|SqlConnection|SqlCommand') 'Ventas sin combos extensos ni SQL directo'
    Write-Output "TOTAL BUSCADORES: $script:checks comprobaciones aprobadas. Sin SQL."
}finally{$env:FORZA_ENTORNO=$old;$provider.Dispose()}
