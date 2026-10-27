param([ValidateSet('Debug','UIRevision')][string]$BuildFolder='Debug',[switch]$SoloInicial)
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$out=Join-Path $root "ForzaSuplementos\ForzaSuplementos\ForzaSuplementos.Presentacion\bin\$BuildFolder"
$artifacts=Join-Path $root 'tests\artifacts\ui'
$null=[IO.Directory]::CreateDirectory($artifacts)
Add-Type -AssemblyName System.Windows.Forms,System.Drawing
$references=@('System.dll','System.Core.dll','System.Drawing.dll','System.Windows.Forms.dll')
foreach($layer in @('Entidades','Datos','Negocio')){
    $path=Join-Path $out "ForzaSuplementos.$layer.dll"
    $null=[Reflection.Assembly]::LoadFrom($path);$references+=,$path
}
$exe=Join-Path $out 'ForzaSuplementos.Presentacion.exe'
$null=[Reflection.Assembly]::LoadFrom($exe);$references+=,$exe
$provider=New-Object Microsoft.VisualBasic.VBCodeProvider
$options=New-Object CodeDom.Compiler.CompilerParameters
$options.GenerateInMemory=$true
$options.CompilerOptions='/optionexplicit+ /optionstrict+'
foreach($ref in $references){$null=$options.ReferencedAssemblies.Add($ref)}
$compilation=$provider.CompileAssemblyFromFile($options,(Join-Path $PSScriptRoot 'VistasSinSql.vb'))
if($compilation.Errors.HasErrors){$compilation.Errors | Format-List;throw 'No compila el host visual de pruebas.'}
$flags=[Reflection.BindingFlags]'Instance,NonPublic,Public'
$script:checks=0
function Assert-UI([bool]$ok,[string]$message){if(!$ok){throw $message};$script:checks++;Write-Output "OK: $message"}
function Control-Of($form,[string]$name){
    $type=$form.GetType()
    while($type){
        $property=$type.GetProperty($name,$flags)
        if($property){return ,($property.GetValue($form,$null))}
        $field=$type.GetField($name,$flags)
        if($field){return ,($field.GetValue($form))}
        $type=$type.BaseType
    }
    throw "Control/campo ausente: $name"
}
function Method-Of($form,[string]$name){
    $type=$form.GetType()
    while($type){$method=$type.GetMethod($name,$flags);if($method){return $method};$type=$type.BaseType}
    throw "Metodo ausente: $name"
}
function New-Preview([string]$name){
    $form=$compilation.CompiledAssembly.CreateInstance('ForzaPruebasUI.'+$name+'Vista')
    $form.StartPosition=[Windows.Forms.FormStartPosition]::Manual
    $form.Location=New-Object Drawing.Point(-30000,-30000)
    $form.ShowInTaskbar=$false
    if($name -eq 'Reportes'){
        # Maqueta de gerente: en la aplicacion esto lo decide ConfigurarPermisos durante Load.
        (Control-Of $form 'btnMisVentas').Visible=$false
    }
    if($name -eq 'Principal'){$null=(Method-Of $form 'ConfigurarPermisos').Invoke($form,@())}
    $form.Show();$form.PerformLayout()
    return $form
}
function Save-Preview($form,[string]$name){
    $image=New-Object Drawing.Bitmap($form.Width,$form.Height)
    try{$form.DrawToBitmap($image,(New-Object Drawing.Rectangle(0,0,$form.Width,$form.Height)));$image.Save((Join-Path $artifacts ($name+'.png')))}finally{$image.Dispose()}
}
$oldEnv=$env:FORZA_ENTORNO
# Defensa adicional: cualquier ruta SQL accidental falla antes de abrir una conexión.
$env:FORZA_ENTORNO='PRUEBA_UI_SIN_SQL'
try {
    [Windows.Forms.Application]::EnableVisualStyles()
    foreach($pair in @(@('Fondo','#1F2428'),@('Panel','#2B3237'),@('Primario','#24A889'),@('Texto','#E8ECEF'),@('Peligro','#D75B5B'))){
        $actual=[ForzaSuplementos.Presentacion.TemaForza].GetField($pair[0]).GetValue($null)
        Assert-UI ($actual.ToArgb() -eq [Drawing.ColorTranslator]::FromHtml($pair[1]).ToArgb()) ('Paleta exacta: '+$pair[0])
    }
    $login=New-Preview 'Login'
    try{
        $button=Control-Of $login 'btnIngresar'
        Assert-UI ([object]::ReferenceEquals($login.AcceptButton,$button)) 'Enter usa el mismo boton Ingresar'
        (Control-Of $login 'txtUsuario').Select()
        $login.Reentrar=$true
        $null=$login.PulsarEnter()
        Assert-UI ($login.Intentos -eq 1 -and $login.Aperturas -eq 1) 'Enter ejecuta un unico intento aun ante reentrada'
        (Control-Of $login 'txtContrasena').Select()
        $null=$login.PulsarEnter()
        Assert-UI ($login.Intentos -eq 2 -and $login.Aperturas -eq 2) 'Enter tambien funciona desde Contrasena'
        $button.PerformClick()
        Assert-UI ($login.Intentos -eq 3 -and $login.Aperturas -eq 3) 'Clic conserva la misma autenticacion y navegacion'
        Assert-UI $button.Enabled 'Ingresar vuelve a habilitarse al finalizar'
        Save-Preview $login 'Login'
    }finally{$login.Dispose()}
    $ventas=New-Preview 'Ventas'
    try{
        $cart=Control-Of $ventas '_carrito'
        $empty=Control-Of $ventas 'btnCancelar'
        $confirm=Control-Of $ventas 'btnConfirmar'
        Assert-UI ($empty.Text -eq 'Vaciar carrito' -and !$empty.Enabled) 'Vaciar carrito deshabilitado al iniciar vacio'
        $product=New-Object ForzaSuplementos.Entidades.Producto
        $product.IdProducto=1;$product.Nombre='Producto de muestra';$product.Stock=10;$product.Precio=100D
        $catalog=New-Object 'System.Collections.Generic.List[ForzaSuplementos.Entidades.Producto]'
        $catalog.Add($product)
        $combo=Control-Of $ventas 'cboProducto'
        $combo.DisplayMember='Nombre';$combo.ValueMember='IdProducto';$combo.DataSource=$catalog
        (Control-Of $ventas 'txtCantidad').Text='2'
        (Control-Of $ventas 'btnAgregar').PerformClick()
        $d=$cart[0]
        Assert-UI ($cart.Count -eq 1 -and $d.Cantidad -eq 2) 'Agregar al Carrito mantiene su evento y cantidad'
        Assert-UI ($empty.Enabled -and (Control-Of $ventas 'lblTotal').Text.Contains('200')) 'Agregar lineas actualiza total y habilita vaciado'
        $beforeConfirm=$confirm.Enabled
        $empty.PerformClick()
        Assert-UI ($cart.Count -eq 0 -and !$empty.Enabled) 'Clic vacia productos sin entrar a SQL'
        $expected='TOTAL: $ '+(0D).ToString('N2')
        Assert-UI ((Control-Of $ventas 'lblTotal').Text -eq $expected) 'Vaciar reinicia total a cero'
        Assert-UI ($product.Stock -eq 10) 'Vaciar no modifica siquiera el stock del catalogo en memoria'
        Assert-UI ($confirm.Enabled -eq $beforeConfirm) 'Vaciar no altera la disponibilidad de Confirmar Venta'
        $null=(Method-Of $ventas 'btnCancelar_Click').Invoke($ventas,@($empty,[EventArgs]::Empty))
        Assert-UI ($cart.Count -eq 0) 'Repetir vaciado sobre carrito vacio es seguro'
        $cart.Add($d)
        (Control-Of $ventas 'dgvCarrito').DataSource=$cart
        $null=(Method-Of $ventas 'ConfigurarGrilla').Invoke($ventas,@())
        Save-Preview $ventas 'Ventas'
        $total=Control-Of $ventas 'lblTotal'
        Assert-UI ($total.Bounds.Right -le $ventas.ClientSize.Width -and $total.Width -ge 400) 'Total tiene espacio para importes grandes sin salirse del formulario'
    }finally{$ventas.Dispose()}
    $names=@('Login','Caja','Ventas')
    if(!$SoloInicial){$names+=@('Principal','Usuarios','Productos','Clientes','Backup','Reportes')}
    foreach($name in $names){
        $form=New-Preview $name
        try{
            Assert-UI ($form.BackColor.ToArgb() -eq [ForzaSuplementos.Presentacion.TemaForza]::Fondo.ToArgb()) "Tema oscuro aplicado a $name"
            $buttons=@();$grids=@();$stack=New-Object Collections.Generic.Stack[Windows.Forms.Control]
            foreach($c in $form.Controls){$stack.Push($c)}
            while($stack.Count){$c=$stack.Pop();if($c -is [Windows.Forms.Button]){$buttons+=,$c};if($c -is [Windows.Forms.DataGridView]){$grids+=,$c};foreach($child in $c.Controls){$stack.Push($child)}}
            $enabledBefore=@($buttons|ForEach-Object Enabled)
            [ForzaSuplementos.Presentacion.TemaForza]::Aplicar($form)
            Assert-UI ((@($buttons|ForEach-Object Enabled) -join ',') -eq ($enabledBefore -join ',')) "Reaplicar tema no cambia permisos/Enabled de $name"
            foreach($g in $grids){Assert-UI ($g.ReadOnly -and !$g.EnableHeadersVisualStyles -and $g.DefaultCellStyle.ForeColor.ToArgb() -eq [ForzaSuplementos.Presentacion.TemaForza]::Texto.ToArgb()) "Grilla de $name conserva solo lectura y contraste"}
            if($buttons.Count){
                $button=$buttons[0];$wasEnabled=$button.Enabled
                $button.Enabled=$false
                Assert-UI ($button.ForeColor.ToArgb() -eq [ForzaSuplementos.Presentacion.TemaForza]::TextoSecundario.ToArgb()) "Estado deshabilitado legible en $name"
                $button.Enabled=$wasEnabled
            }
            if($name -eq 'Caja'){
                Assert-UI (!(Control-Of $form 'btnAbrir').Enabled -and !(Control-Of $form 'btnCerrar').Enabled) 'Tema no habilita operaciones de Caja sin consultar estado'
            }
            if($name -ne 'Login' -and $name -ne 'Ventas'){Save-Preview $form $name}
        }finally{$form.Dispose()}
    }
    $source=Get-Content (Join-Path $root 'ForzaSuplementos\ForzaSuplementos\ForzaSuplementos.Presentacion\FrmVentas.vb') -Raw -Encoding UTF8
    foreach($method in @('btnCancelar_Click','LimpiarVenta','CarritoCambiado','ActualizarTotal')){
        $body=[regex]::Match($source,'(?is)Private Sub '+$method+'\b.*?End Sub').Value
        Assert-UI ($body.Length -gt 0 -and $body -notmatch '(?i)SqlConnection|SqlCommand|_\w*BLL\.|_\w*DAL\.|ProcesarVenta|RegistrarVenta') "Ruta local de vaciado sin llamadas a negocio/datos: $method"
    }
    Write-Output "TOTAL UI: $script:checks comprobaciones aprobadas. Vistas sintéticas renderizadas; no se ejecuto SQL."
}finally{$env:FORZA_ENTORNO=$oldEnv;$provider.Dispose()}
