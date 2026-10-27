param([ValidateSet('Debug','UIRevision')][string]$BuildFolder='Debug')
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$out=Join-Path $root "ForzaSuplementos\ForzaSuplementos\ForzaSuplementos.Presentacion\bin\$BuildFolder"
Add-Type -AssemblyName System.Windows.Forms,System.Drawing
$refs=@('System.dll','System.Core.dll','System.Drawing.dll','System.Windows.Forms.dll')
foreach($layer in @('Entidades','Datos','Negocio','Presentacion')){
    $suffix=if($layer -eq 'Presentacion'){'exe'}else{'dll'}
    $file=Join-Path $out "ForzaSuplementos.$layer.$suffix"
    $null=[Reflection.Assembly]::LoadFrom($file);$refs+=,$file
}
$provider=New-Object Microsoft.VisualBasic.VBCodeProvider
$parameters=New-Object CodeDom.Compiler.CompilerParameters
$parameters.GenerateInMemory=$true;$parameters.CompilerOptions='/optionstrict+ /optionexplicit+'
foreach($ref in $refs){$null=$parameters.ReferencedAssemblies.Add($ref)}
$hostCode=$provider.CompileAssemblyFromFile($parameters,(Join-Path $PSScriptRoot 'VistasSinSql.vb'))
if($hostCode.Errors.HasErrors){throw ($hostCode.Errors | Out-String)}
$flags=[Reflection.BindingFlags]'Instance,NonPublic,Public'
function Field($form,$name){
    $t=$form.GetType()
    while($t){
        $p=$t.GetProperty($name,$flags);if($p){return ,($p.GetValue($form,$null))}
        $f=$t.GetField($name,$flags);if($f){return ,($f.GetValue($form))}
        $t=$t.BaseType
    };throw "Campo inexistente: $name"
}
function Invoke-Private($form,$name,$arguments=@()){
    $t=$form.GetType()
    while($t){$m=$t.GetMethod($name,$flags);if($m){return $m.Invoke($form,$arguments)};$t=$t.BaseType}
    throw "Metodo inexistente: $name"
}
function Select-Module($form,$name){(Field $form "Menu$name").PerformClick();[Windows.Forms.Application]::DoEvents()}
$script:checks=0
function Assert-Nav([bool]$condition,[string]$message){if(!$condition){throw $message};$script:checks++;Write-Output "OK: $message"}
$script:prompts=0;$script:answer=$false;$script:message=''
$consult=[Func[Windows.Forms.IWin32Window,string,bool]]{
    param($owner,$message)
    $script:prompts++;$script:message=$message;return $script:answer
}
function Protect($form){(Field $form '_protector').Consultar=$consult}
function Show-Test($form){$form.ShowInTaskbar=$false;$form.StartPosition='Manual';$form.Location=New-Object Drawing.Point(-30000,-30000);$form.Show();[Windows.Forms.Application]::DoEvents()}
$old=$env:FORZA_ENTORNO
# Cualquier intento accidental de entrar a datos falla antes de conectarse.
$env:FORZA_ENTORNO='PRUEBA_NAVEGACION_SIN_SQL'
try{
    $principal=New-Object ForzaPruebasUI.PrincipalNavegacion('VENDEDOR')
    try{
        Show-Test $principal
        Select-Module $principal 'Ventas';$ventas=$principal.MdiChildren[0];Protect $ventas
        Assert-Nav ($principal.MdiChildren.Count -eq 1) 'Primer modulo: un solo hijo MDI'
        $creadas=$principal.Creaciones
        $ventas.WindowState='Minimized';Select-Module $principal 'Ventas'
        Assert-Nav ($principal.Creaciones -eq $creadas -and [object]::ReferenceEquals($ventas,$principal.MdiChildren[0]) -and $ventas.WindowState -ne 'Minimized') 'Mismo modulo reutiliza instancia y restaura ventana minimizada'
        Select-Module $principal 'Caja';$caja=$principal.MdiChildren[0]
        Assert-Nav ($ventas.IsDisposed -and $principal.MdiChildren.Count -eq 1 -and $script:prompts -eq 0) 'Carrito vacio cambia sin advertir y dispone Ventas'
        # Simular sesion cargada solo en memoria; cerrar la vista no debe llamar CajaBLL.Cerrar.
        $session=New-Object ForzaSuplementos.Entidades.SesionCaja
        $session.IdSesion=123;$session.Estado='Abierta'
        $field=$caja.GetType().BaseType.GetField('_sesion',$flags);$field.SetValue($caja,$session)
        Select-Module $principal 'Ventas';$ventas=$principal.MdiChildren[0];Protect $ventas
        Assert-Nav ($caja.IsDisposed -and $session.IdSesion -eq 123 -and $session.EstaAbierta -and $null -eq $session.FechaCierre) 'Salir de Caja dispone la vista y conserva la sesion en memoria sin SQL'
        $cart=Field $ventas '_carrito';$line=New-Object ForzaSuplementos.Entidades.DetalleVenta
        $line.IdProducto=1;$line.Cantidad=2;$line.PrecioUnitario=100;$line.CalcularSubtotal();$cart.Add($line)
        $script:answer=$false;$before=$principal.Creaciones
        Select-Module $principal 'Clientes'
        Assert-Nav ($cart.Count -eq 1 -and !$ventas.IsDisposed -and $principal.Creaciones -eq $before -and $principal.MdiChildren.Count -eq 1) 'No conserva carrito, instancia y total sin construir destino'
        Assert-Nav ($script:prompts -eq 1 -and $script:message -ceq 'Tenés productos en el carrito. Si salís, se perderá la venta sin confirmar. ¿Querés continuar?') 'Confirmacion de carrito usa exactamente el mensaje solicitado'
        Assert-Nav ((Field $ventas 'lblTotal').Text -match '200') 'No conserva total pendiente'
        Select-Module $principal 'Ventas'
        Assert-Nav ($script:prompts -eq 1) 'Reelegir Ventas con carrito no pregunta'
        (Field $principal 'MenuCerrarSesion').PerformClick()
        Assert-Nav (!$principal.IsDisposed -and $cart.Count -eq 1 -and @([Windows.Forms.Application]::OpenForms | Where-Object {$_ -is [ForzaSuplementos.Presentacion.FrmLogin]}).Count -eq 0) 'Cerrar sesion cancelado no abre Login ni pierde carrito'
        $principal.Close()
        Assert-Nav (!$principal.IsDisposed -and $cart.Count -eq 1) 'Cerrar principal con No conserva ventana y carrito'
        $script:answer=$true;Select-Module $principal 'Clientes'
        Assert-Nav ($ventas.IsDisposed -and $cart.Count -eq 0 -and $principal.MdiChildren.Count -eq 1) 'Si descarta solo carrito en memoria y deja un hijo'
        $clientes=$principal.MdiChildren[0];Protect $clientes
        $baselinePrompts=$script:prompts
        Select-Module $principal 'Reportes'
        Assert-Nav ($clientes.IsDisposed -and $script:prompts -eq $baselinePrompts) 'ABM sin cambios no pregunta'
        # Repeticion detecta referencias/eventos acumulados y ventanas escondidas.
        foreach($n in 1..15){Select-Module $principal 'Caja';Select-Module $principal 'Reportes';Assert-Nav ($principal.MdiChildren.Count -eq 1) "Alternancia $n mantiene un solo hijo"}
        $principal.FallarCreacion=$true
        try{Select-Module $principal 'Caja';throw 'Faltaba error de fabrica'}catch{if($_.Exception.ToString() -notmatch 'Fallo simulado'){throw}}
        $principal.FallarCreacion=$false;Select-Module $principal 'Caja'
        Assert-Nav ($principal.MdiChildren.Count -eq 1) 'Error de apertura libera bloqueo de navegacion'
    }finally{$principal.Dispose()}

    $ventas=New-Object ForzaPruebasUI.VentasVista
    try{
        Show-Test $ventas;Protect $ventas
        $cart=Field $ventas '_carrito';$cart.Add((New-Object ForzaSuplementos.Entidades.DetalleVenta))
        $script:answer=$true
        $cancel=[Windows.Forms.FormClosingEventHandler]{param($sender,$e) $e.Cancel=$true}
        $ventas.add_FormClosing($cancel);$ventas.Close()
        Assert-Nav (!$ventas.IsDisposed -and $cart.Count -eq 1) 'Si seguido de otra cancelacion de cierre no descarta anticipadamente'
        $ventas.remove_FormClosing($cancel);$ventas.Close()
        Assert-Nav ($ventas.IsDisposed -and $cart.Count -eq 0) 'Cierre efectivo descarta y desuscribe eventos del carrito'
    }finally{$ventas.Dispose()}

    foreach($name in @('Clientes','Productos','Usuarios')){
        $type=$hostCode.CompiledAssembly.GetType("ForzaPruebasUI.${name}Vista")
        $form=[Activator]::CreateInstance($type)
        try{
            Show-Test $form;Protect $form
            Invoke-Private $form $(if($name -eq 'Clientes'){'Limpiar'}else{'LimpiarCampos'})
            $text=Field $form 'txtNombre';$text.Text='Edicion ficticia'
            $script:answer=$false;$before=$script:prompts;$form.Close()
            Assert-Nav (!$form.IsDisposed -and $script:prompts -eq $before+1 -and $text.Text -eq 'Edicion ficticia') "$name detecta edicion y No conserva campos"
            $text.Text='';$before=$script:prompts;$form.Close()
            Assert-Nav ($form.IsDisposed -and $script:prompts -eq $before) "$name revertido cierra sin advertencia"
        }finally{$form.Dispose()}
        $form=[Activator]::CreateInstance($type)
        try{
            Show-Test $form;Protect $form
            Invoke-Private $form $(if($name -eq 'Clientes'){'Limpiar'}else{'LimpiarCampos'})
            (Field $form 'txtNombre').Text='Registro cargado'
            (Field $form '_protector').EstablecerBase()
            $before=$script:prompts;$form.Close()
            Assert-Nav ($form.IsDisposed -and $script:prompts -eq $before) "$name seleccion cargada sin editar no pregunta"
        }finally{$form.Dispose()}
        $form=[Activator]::CreateInstance($type)
        try{
            Show-Test $form;Protect $form;(Field $form 'txtNombre').Text='Descartar'
            $script:answer=$true;$form.Close()
            Assert-Nav $form.IsDisposed "$name Si cierra cambios locales sin SQL"
        }finally{$form.Dispose()}
    }
    $expected=@{ADMINISTRADOR=@('Usuarios','Productos','Clientes','Backup','Reportes');GERENTE=@('Usuarios','Productos','Reportes');VENDEDOR=@('Clientes','Ventas','Caja','Reportes')}
    foreach($role in @('ADMINISTRADOR','GERENTE','VENDEDOR')){
        $form=New-Object ForzaPruebasUI.PrincipalNavegacion($role)
        try{
            Show-Test $form
            foreach($module in @('Usuarios','Productos','Clientes','Ventas','Caja','Backup','Reportes')){
                $allowed=$expected[$role] -contains $module;$before=$form.Creaciones
                Assert-Nav ((Field $form "Menu$module").Available -eq $allowed) "$role visibilidad conservada: $module"
                Select-Module $form $module
                Assert-Nav (($form.Creaciones -gt $before) -eq $allowed -and $form.MdiChildren.Count -le 1) "$role navegacion autorizada y un solo hijo: $module"
            }
        }finally{$form.Dispose()}
    }
    $presentation=Join-Path $root 'ForzaSuplementos\ForzaSuplementos\ForzaSuplementos.Presentacion'
    $principalSource=[IO.File]::ReadAllText((Join-Path $presentation 'FrmPrincipal.vb'))
    $protectionSource=[IO.File]::ReadAllText((Join-Path $presentation 'ProtectorCambios.vb'))
    Assert-Nav ($principalSource -notmatch '\.Hide\(' -and ([regex]::Matches($principalSource,'\.MdiParent\s*=')).Count -eq 1) 'Navegacion central sin Hide y unico punto de asignacion MDI'
    Assert-Nav ($principalSource -notmatch 'SqlConnection|SqlCommand|\b_bll\.' -and $protectionSource -notmatch 'SqlConnection|SqlCommand|\b_bll\.') 'Navegacion y proteccion sin operaciones SQL'
    Write-Output "TOTAL NAVEGACION: $script:checks comprobaciones aprobadas; sin SQL, confirmaciones simuladas."
}finally{$env:FORZA_ENTORNO=$old;$provider.Dispose()}
