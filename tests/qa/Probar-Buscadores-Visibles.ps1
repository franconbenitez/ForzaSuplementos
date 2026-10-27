# Integracion WinForms REAL en proceso: sin subclases, sin sustituir Load/buscadores y sin registrar ventas.
param([string]$Configuration='Debug')
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Import-Module (Join-Path $root 'scripts/qa/QA.Common.psm1') -Force
$cfg=Get-QaConfig;$cn=Open-QaConnection
try{
    $rows=Invoke-QaQuery $cn "SELECT TOP(1) u.idUsuario FROM dbo.Usuarios u JOIN dbo.Perfiles p ON p.idPerfil=u.idPerfil WHERE u.activo=1 AND UPPER(p.nombrePerfil)='VENDEDOR' ORDER BY u.idUsuario;"
    if($rows.Rows.Count -ne 1){throw 'Falta un vendedor QA. No se crean datos.'}
    $actorId=[int]$rows.Rows[0].idUsuario
}finally{$cn.Dispose()}
Add-Type -AssemblyName System.Windows.Forms,System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()
$out=Join-Path $root "ForzaSuplementos\ForzaSuplementos\ForzaSuplementos.Presentacion\bin\$Configuration"
foreach($layer in @('Entidades','Datos','Negocio','Presentacion')){
    $suffix=if($layer -eq 'Presentacion'){'exe'}else{'dll'}
    $null=[Reflection.Assembly]::LoadFrom((Join-Path $out "ForzaSuplementos.$layer.$suffix"))
}
$flags=[Reflection.BindingFlags]'Instance,Public,NonPublic'
function Member($object,$name){$t=$object.GetType();while($t){$p=$t.GetProperty($name,$flags);if($p){return ,($p.GetValue($object,$null))};$f=$t.GetField($name,$flags);if($f){return ,($f.GetValue($object))};$t=$t.BaseType};throw "Miembro ausente: $name"}
$script:checks=0
function Assert-Visible([bool]$ok,[string]$message){if(!$ok){throw $message};$script:checks++;Write-Output "OK: $message"}
function Wait-Ready($form){$clock=[Diagnostics.Stopwatch]::StartNew();do{[Windows.Forms.Application]::DoEvents();Start-Sleep -Milliseconds 10;if($clock.Elapsed.TotalSeconds -gt 15){throw 'Ventas no habilito los buscadores'}}until((Member $form 'btnBuscarCliente').Enabled -and (Member $form 'btnBuscarProducto').Enabled)}
$evidence=Join-Path $root 'tests/artifacts/qa-visible';$null=[IO.Directory]::CreateDirectory($evidence)
function Save-Frame($form,$name){
    # QA puede contener datos personales introducidos por el desarrollador: ocultarlos solo al renderizar.
    $grid=$null;$selectedBox=$null;$originalText=$null
    $mask=[Windows.Forms.DataGridViewCellFormattingEventHandler]{param($sender,$e)
        if($sender.Columns[$e.ColumnIndex].DataPropertyName -in @('Nombre','Apellido','Dni','Telefono','Email')){$e.Value='[oculto]';$e.FormattingApplied=$true}
    }
    if($form -is [ForzaSuplementos.Presentacion.FrmBuscador]){
        $grid=Member $form 'dgvResultados';$grid.add_CellFormatting($mask)
    }elseif($form -is [ForzaSuplementos.Presentacion.FrmPrincipal] -and $form.MdiChildren.Count){
        $selectedBox=Member $form.MdiChildren[0] 'txtClienteSeleccionado';$originalText=$selectedBox.Text
        if($originalText -ne 'Sin cliente seleccionado'){$selectedBox.Text='Cliente QA seleccionado [datos ocultos]'}
    }
    $bitmap=New-Object Drawing.Bitmap($form.Width,$form.Height)
    try{
        if($grid){$grid.Refresh()}
        $form.DrawToBitmap($bitmap,(New-Object Drawing.Rectangle(0,0,$form.Width,$form.Height)))
        $bitmap.Save((Join-Path $evidence "$name.png"))
    }finally{
        $bitmap.Dispose()
        if($grid){$grid.remove_CellFormatting($mask);$grid.Invalidate()}
        if($selectedBox){$selectedBox.Text=$originalText}
    }
}
function Choose-Modal($sales,$buttonName,$property,$expectedId,$query,$imageName){
    $script:modalPhase=0;$script:modalError=$null;$script:modalSelected=$false;$script:modalObserved=$false
    $script:modalProperty=$property;$script:modalId=$expectedId;$script:modalQuery=$query;$script:modalImage=$imageName
    $script:modalClock=[Diagnostics.Stopwatch]::StartNew()
    $timer=New-Object Windows.Forms.Timer;$timer.Interval=40
    $tick=[EventHandler]{
        param($sender,$event)
        $dialog=$null
        try{
            $open=@([Windows.Forms.Application]::OpenForms | Where-Object {$_ -is [ForzaSuplementos.Presentacion.FrmBuscador]})
            if($open.Count -gt 1){throw 'Se abrieron selectores duplicados'}
            if($open.Count -eq 1){$dialog=$open[0]}
            if($script:modalClock.Elapsed.TotalSeconds -gt 15){throw 'El selector no completo la busqueda'}
            if(!$dialog -or !$dialog.Visible -or $dialog.BusquedaEnCurso){return}
            if($script:modalPhase -eq 0){
                if($null -ne $dialog.MdiParent){throw 'El selector no debe ser hijo MDI'}
                $script:modalObserved=$true
                (Member $dialog 'txtBuscar').Text=$script:modalQuery
                $script:modalPhase=1;return
            }
            $grid=Member $dialog 'dgvResultados'
            $target=@($grid.Rows | Where-Object {$_.DataBoundItem -and $_.DataBoundItem.($script:modalProperty) -eq $script:modalId})
            if($target.Count -ne 1){throw 'No se encontro la fila real esperada de QA'}
            $grid.CurrentCell=$target[0].Cells[0]
            if(!(Member $dialog 'btnSeleccionar').Enabled){throw ('Seleccionar deshabilitado: modoProducto='+ (Member $dialog '_esProducto') + '; filtrando='+$dialog.BusquedaEnCurso+'; activo='+$grid.CurrentRow.DataBoundItem.Activo+'; stock='+$grid.CurrentRow.DataBoundItem.Stock+'; tipo='+$grid.CurrentRow.DataBoundItem.GetType().Name)}
            Save-Frame $dialog $script:modalImage
            $sender.Stop()
            if($script:modalProperty -eq 'IdProducto'){
                $key=New-Object Windows.Forms.KeyEventArgs([Windows.Forms.Keys]::Enter)
                $grid.GetType().GetMethod('OnKeyDown',$flags).Invoke($grid,[object[]]@($key.PSObject.BaseObject)) | Out-Null
                if(!$key.Handled){throw 'Enter no fue atendido por el selector'}
            }else{(Member $dialog 'btnSeleccionar').PerformClick()}
            $script:modalSelected=$true
        }catch{
            $script:modalError=$_.Exception.Message
            $sender.Stop()
            if($dialog -and !$dialog.IsDisposed){$dialog.DialogResult='Cancel';$dialog.Close()}
        }
    }
    $timer.add_Tick($tick)
    try{
        $timer.Start()
        (Member $sales $buttonName).PerformClick() # Entra al ShowDialog REAL y a su message loop.
        if($script:modalError){throw $script:modalError}
        Assert-Visible ($script:modalObserved -and $script:modalSelected) "$buttonName vinculado: abre dialogo real, filtra y selecciona"
    }finally{$timer.Stop();$timer.remove_Tick($tick);$timer.Dispose()}
}
$oldEnv=$env:FORZA_ENTORNO;$oldConfig=$env:FORZA_QA_CONFIG;$oldVersion=$env:FORZA_QA_BUILD_ID
$env:FORZA_ENTORNO='QA';$env:FORZA_QA_CONFIG=$cfg.Path;$env:FORZA_QA_BUILD_ID='INTEGRACION VISIBLE - SOLO LECTURA'
$principal=$null
try{
    $actor=New-Object ForzaSuplementos.Entidades.Usuario;$actor.IdUsuario=$actorId;$actor.NombrePerfil='VENDEDOR';$actor.Nombre='Prueba QA'
    $clients=(New-Object ForzaSuplementos.Negocio.ClienteBLL).ObtenerClientes($true,$actor)
    $products=(New-Object ForzaSuplementos.Negocio.ProductoBLL).ObtenerProductos($true,$actor)
    $client=@($clients | Where-Object {$_.Activo}) | Select-Object -First 1
    $product=@($products | Where-Object {$_.Activo -and $_.Stock -gt 0 -and $_.Precio -gt 0}) | Select-Object -First 1
    if(!$client -or !$product){throw 'Faltan fixtures activos con stock/precio. No se crean datos.'}
    $principal=New-Object ForzaSuplementos.Presentacion.FrmPrincipal($actor)
    $principal.WindowState='Normal';$principal.StartPosition='Manual';$principal.Bounds=[Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $principal.Show();[Windows.Forms.Application]::DoEvents()
    (Member $principal 'MenuVentas').PerformClick()
    Assert-Visible ($principal.MdiChildren.Count -eq 1 -and $principal.MdiChildren[0].GetType() -eq [ForzaSuplementos.Presentacion.FrmVentas]) 'MenuVentas abre exactamente una instancia REAL de FrmVentas'
    $sales=$principal.MdiChildren[0];Wait-Ready $sales
    Assert-Visible ($sales.GetType().Assembly.Location -eq (Join-Path $out 'ForzaSuplementos.Presentacion.exe')) 'Ventas proviene del EXE Debug inspeccionado'
    foreach($name in @('btnBuscarCliente','btnBuscarProducto')){
        $b=Member $sales $name
        Assert-Visible ($b.Visible -and $b.Enabled -and $b.Parent -eq $sales -and $sales.ClientRectangle.Contains($b.Bounds)) "$name visible, habilitado, en el contenedor y dentro de sus limites"
        $center=New-Object Drawing.Point(($b.Left+[int]($b.Width/2)),($b.Top+[int]($b.Height/2)))
        Assert-Visible ([object]::ReferenceEquals($sales.GetChildAtPoint($center),$b)) "$name no esta tapado por otro control"
    }
    $combos=@($sales.Controls | Where-Object {$_ -is [Windows.Forms.ComboBox]})
    Assert-Visible ($combos.Count -eq 1 -and [object]::ReferenceEquals($combos[0],(Member $sales 'cboMedioPago'))) 'El unico ComboBox visible de Ventas es medio de pago'
    Save-Frame $principal '01_PrincipalVentas'
    Choose-Modal $sales 'btnBuscarCliente' 'IdCliente' $client.IdCliente ([string]$client.IdCliente) '02_BuscadorClientes'
    Assert-Visible ((Member $sales '_clienteSeleccionado').IdCliente -eq $client.IdCliente -and (Member $sales 'txtClienteSeleccionado').Text.Contains('#'+$client.IdCliente)) 'Cliente real seleccionado vuelve a Ventas con su ID'
    Choose-Modal $sales 'btnBuscarProducto' 'IdProducto' $product.IdProducto ([string]$product.IdProducto) '03_BuscadorProductos'
    Assert-Visible ((Member $sales '_productoSeleccionado').IdProducto -eq $product.IdProducto -and (Member $sales 'txtProductoSeleccionado').Text.Contains('#'+$product.IdProducto)) 'Enter devuelve producto real a Ventas con su ID'
    Assert-Visible ($principal.MdiChildren.Count -eq 1) 'Abrir ambos buscadores no agrega ventanas MDI'
    (Member $sales 'txtCantidad').Text='1';(Member $sales 'btnAgregar').PerformClick()
    $cart=Member $sales '_carrito'
    Assert-Visible ($cart.Count -eq 1 -and $cart[0].IdProducto -eq $product.IdProducto) 'Agregar conserva ID del producto seleccionado sin SQL'
    Choose-Modal $sales 'btnBuscarCliente' 'IdCliente' $client.IdCliente ([string]$client.IdCliente) '02_BuscadorClientes'
    Assert-Visible ($cart.Count -eq 1) 'Buscar con carrito cargado no pierde sus productos'
    (Member $sales 'cboMedioPago').SelectedIndex=1
    $payload=$sales.GetType().GetMethod('CrearVentaPendiente',$flags).Invoke($sales,@())
    Assert-Visible ($payload.IdCliente -eq $client.IdCliente -and $payload.Detalles[0].IdProducto -eq $product.IdProducto) 'Payload de confirmacion conserva los dos IDs reales; no se ejecuta Confirmar'
    Save-Frame $principal '04_VentasSeleccionadas'
    $stock=(New-Object ForzaSuplementos.Negocio.ProductoBLL).ObtenerProductos($true,$actor) | Where-Object {$_.IdProducto -eq $product.IdProducto}
    Assert-Visible ($stock.Stock -eq $product.Stock) 'Stock observado sin cambios tras busqueda y carrito local'
    [pscustomobject]@{Tipo='Render de formularios WinForms reales; no captura del escritorio';Pruebas=$script:checks;SQL='Solo lectura';Subclases=$false;LoadSustituido=$false;Seleccion='Eventos de boton y Enter en dialogos modales reales';SHA256=(Get-FileHash (Join-Path $out 'ForzaSuplementos.Presentacion.exe')).Hash} | ConvertTo-Json | Set-Content (Join-Path $evidence 'resultado.json') -Encoding UTF8
    (Member $sales 'btnCancelar').PerformClick()
    Write-Output "TOTAL VISIBLE QA: $script:checks comprobaciones aprobadas con formularios reales y dialogos modales. No se registraron ventas."
}finally{if($principal){$principal.Dispose()};$env:FORZA_ENTORNO=$oldEnv;$env:FORZA_QA_CONFIG=$oldConfig;$env:FORZA_QA_BUILD_ID=$oldVersion}
