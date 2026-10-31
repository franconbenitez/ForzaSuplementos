param([string]$Configuration='Debug')
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$out=Join-Path $root "ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Presentacion/bin/$Configuration"
Add-Type -AssemblyName System.Windows.Forms,System.Drawing,System.Data,System.Windows.Forms.DataVisualization
$refs=@('System.dll','System.Core.dll','System.Data.dll','System.Xml.dll','System.Drawing.dll','System.Windows.Forms.dll','System.Windows.Forms.DataVisualization.dll')
foreach($l in @('Entidades','Datos','Negocio','Presentacion')){$suffix=if($l -eq 'Presentacion'){'exe'}else{'dll'};$path=Join-Path $out "ForzaSuplementos.$l.$suffix";[void][Reflection.Assembly]::LoadFrom($path);$refs+=,$path}
$provider=New-Object Microsoft.VisualBasic.VBCodeProvider;$opts=New-Object CodeDom.Compiler.CompilerParameters;$opts.GenerateInMemory=$true;$opts.CompilerOptions='/optionstrict+ /optionexplicit+'
foreach($p in $refs){[void]$opts.ReferencedAssemblies.Add($p)}
$c=$provider.CompileAssemblyFromFile($opts,(Join-Path $PSScriptRoot 'Adversariales.vb'));if($c.Errors.HasErrors){throw ($c.Errors|Out-String)}
$n=0
function Check($ok,$text){if(!$ok){throw $text};$script:n++;Write-Output "OK: $text"}
function Reject($text,[scriptblock]$code){$ok=$false;try{&$code|Out-Null}catch{$e=$_.Exception;while($e.InnerException){$e=$e.InnerException};if($e -isnot [ApplicationException]){throw};$ok=$true};Check $ok $text}
$flags=[Reflection.BindingFlags]'Instance,Public,NonPublic'
function Field($form,$name){$t=$form.GetType();while($t){$p=$t.GetProperty($name,$flags);if($p){return ,$p.GetValue($form,$null)};$f=$t.GetField($name,$flags);if($f){return ,$f.GetValue($form)};$t=$t.BaseType};throw $name}
function Show-Test($f){$f.ShowInTaskbar=$false;$f.StartPosition='Manual';$f.Location=New-Object Drawing.Point(-30000,-30000);$f.Show()}
function Wait-Test($task){$w=[Diagnostics.Stopwatch]::StartNew();while(!$task.IsCompleted){[Windows.Forms.Application]::DoEvents();Start-Sleep -Milliseconds 5;if($w.Elapsed.TotalSeconds -gt 8){throw 'Timeout prueba'}};[void]$task.GetAwaiter().GetResult()}
function Venta-Test(){
 $f=New-Object VentasAdversarial;$cl=New-Object ForzaSuplementos.Entidades.Cliente;$cl.IdCliente=10;$cl.Activo=$true;$f.Cliente($cl)
 $p=New-Object ForzaSuplementos.Entidades.Producto;$p.IdProducto=20;$p.Activo=$true;$p.Stock=10;$p.Precio=5;$f.Producto($p);$f.Agregar(2);return $f
}
$old=$env:FORZA_ENTORNO;$env:FORZA_ENTORNO='ADVERSARIAL_SIN_SQL'
try{
 $l=New-Object LoginAdversarial
 try{
  $l.Reentrar=$true;$l.Ingresar();$l.Ingresar();Check ($l.Intentos -eq 1 -and $l.Aperturas -eq 1) 'Login no reentra ni duplica sesion despues del exito'
  $l.PrepararNuevoIngreso();$l.Ingresar();Check ($l.Intentos -eq 2 -and $l.Aperturas -eq 2) 'Cerrar sesion habilita un nuevo intento'
 }finally{$l.Dispose()}
 foreach($flag in @('Fallar','Nulo','FallarApertura')){
  $l=New-Object LoginAdversarial;try{$l.$flag=$true;$l.Ingresar();Check ((Field $l 'btnIngresar').Enabled -and $l.Errores -eq 1) "Login recupera interfaz ante $flag";$l.$flag=$false;$l.Ingresar();Check ($l.Aperturas -eq 1) "Login permite recuperar luego de $flag"}finally{$l.Dispose()}
 }
 $rootLogin=New-Object LoginAdversarial
 try{
  Show-Test $rootLogin
  $u=New-Object ForzaSuplementos.Entidades.Usuario;$u.IdUsuario=37;$u.NombrePerfil='VENDEDOR'
  $main=New-Object ForzaSuplementos.Presentacion.FrmPrincipal($u)
  try{
   $main.LoginOrigen=$rootLogin;Show-Test $main;$rootLogin.Hide()
   [void][ForzaSuplementos.Presentacion.FrmPrincipal].GetMethod('MenuCerrarSesion_Click',$flags).Invoke($main,[object[]]@($null,[EventArgs]::Empty))
   Check (!$rootLogin.IsDisposed -and $rootLogin.Visible) 'Cerrar sesion reutiliza Login original sin acumular ocultos'
   Check ($main.IsDisposed) 'Cerrar sesion libera Principal anterior'
  }finally{$main.Dispose()}
  $main=New-Object ForzaSuplementos.Presentacion.FrmPrincipal($u)
  try{
   $main.LoginOrigen=$rootLogin;Show-Test $main;$rootLogin.Hide()
   $child=New-Object Windows.Forms.Form;$child.MdiParent=$main;$child.Show()
   $cancel=[Windows.Forms.FormClosingEventHandler]{param($sender,$e) $e.Cancel=$true}
   $child.add_FormClosing($cancel);$main.Close()
   Check (!$main.IsDisposed -and !$rootLogin.IsDisposed) 'Cancelacion de cierre hijo conserva Principal y Login'
   $child.remove_FormClosing($cancel);$main.Close()
   Check ($rootLogin.IsDisposed -and $main.IsDisposed) 'Cerrar Principal cierra Login oculto y libera aplicacion'
  }finally{$main.Dispose()}
 }finally{$rootLogin.Dispose()}
 $service=New-Object ForzaSuplementos.Negocio.UsuarioBLL
 Reject 'Login vacio rechaza antes de SQL' {$service.IniciarSesion('','')}
 $f=Venta-Test
 try{
  $v=$f.Pendiente();$v.Detalles[0].Cantidad=999;Check ((Field $f '_carrito')[0].Cantidad -eq 2) 'Snapshot de venta no comparte detalles con carrito'
  $p=New-Object ForzaSuplementos.Entidades.Producto;$p.IdProducto=30;$p.Stock=10;$p.Activo=$true
  foreach($precio in @(-1,0,1.001,100000000)){$p.Precio=$precio;$f.Producto($p);Reject "Carrito rechaza precio $precio" {$f.Agregar(1)}}
  $p.Precio=1;$f.Producto($p);foreach($q in @(0,-1,11)){Reject "Carrito rechaza cantidad $q" {$f.Agregar($q)}}
  $p.Activo=$false;Reject 'Producto inactivo rechazado' {$f.Producto($p)}
  $cl=New-Object ForzaSuplementos.Entidades.Cliente;$cl.IdCliente=99;$cl.Activo=$false;Reject 'Cliente inactivo rechazado' {$f.Cliente($cl)}
 }finally{$f.Dispose()}
 $f=Venta-Test;try{$f.Reentrar=$true;$f.Confirmar();Check ($f.Registros -eq 1 -and (Field $f '_carrito').Count -eq 0) 'Doble confirmacion reentrante solo registra una vez'}finally{$f.Dispose()}
 $f=Venta-Test;try{$f.FallarRecarga=$true;$f.Confirmar();Check ($f.Registros -eq 1 -and (Field $f '_carrito').Count -eq 0) 'Recarga fallida no restaura carrito confirmado';Check (($f.Avisos -join ' ') -match 'ya fue confirmada' -and !(Field $f 'btnConfirmar').Enabled) 'Recarga fallida identifica venta confirmada y bloquea catalogo'}finally{$f.Dispose()}
 $f=Venta-Test;try{$f.Incierta=$true;$f.Confirmar();$f.Confirmar();Check ($f.Registros -eq 1 -and (Field $f '_carrito').Count -eq 1 -and !(Field $f 'btnConfirmar').Enabled) 'Resultado incierto conserva carrito y bloquea reintento';$f.Vaciar();Check ((Field $f '_carrito').Count -eq 1) 'No descarta venta incierta sin confirmacion';$f.Descartar=$true;$f.Vaciar();Check ((Field $f '_carrito').Count -eq 0) 'Descarte incierto autorizado es solo memoria'}finally{$f.Dispose()}
 $f=Venta-Test;try{$f.Fallar=$true;$f.Confirmar();Check ((Field $f '_carrito').Count -eq 1 -and !(Field $f '_resultadoIncierto')) 'Rechazo conocido conserva carrito sin marcar confirmacion'}finally{$f.Dispose()}
 $f=New-Object VentasAdversarial;try{Reject 'Carrito vacio no crea venta' {$f.Pendiente()}}finally{$f.Dispose()}
 $r=New-Object ReportesAdversarial
 try{
  Show-Test $r;Wait-Test ($r.Actualizar());Check ($null -ne (Field $r '_ventas')) 'Dashboard sintetico carga'
  $r.Heredada($false);Check ($null -eq (Field $r '_ventas') -and !(Field $r 'grafico').Visible) 'Consulta heredada elimina modelo anterior'
  (Field $r 'cboGrafico').SelectedIndex=1;Check (!(Field $r 'grafico').Visible) 'Cambiar grafico no resucita consulta previa'
  $r.Heredada($true);Check ($null -eq (Field $r 'dgvReportes').DataSource -and (Field $r 'lblEstado').Text -match 'Error') 'Error de consulta limpia grilla anterior'
  $r.Fallar=$true;Wait-Test ($r.Actualizar());Check ($null -eq (Field $r '_ventas') -and !(Field $r 'grafico').Visible) 'Excepcion de dashboard no deja cifras anteriores'
 }finally{$r.Dispose()}
 $r=New-Object ReportesAdversarial
 try{
  Show-Test $r;$r.UsarDemora=$true;$task=$r.Actualizar();(Field $r 'dtpHasta').Value=(Field $r 'dtpHasta').Value.AddDays(-1);$r.Demora.SetResult([ReportesAdversarial]::Modelo());Wait-Test $task
  Check ($null -eq (Field $r '_ventas') -and !(Field $r 'grafico').Visible) 'Respuesta de filtro obsoleto descartada'
  Check ((Field $r 'btnActualizar').Enabled) 'Consulta obsoleta libera estado ocupado'
 }finally{$r.Dispose()}
 $r=New-Object ReportesAdversarial
 try{
  $r.CantidadPuntos=800;Show-Test $r;Wait-Test ($r.Actualizar())
  Check ((Field $r 'grafico').Series[0].Points.Count -eq 800) 'Grafico grande conserva todos los puntos sin inventar ni descartar'
  Check (!(Field $r 'grafico').Series[0].IsValueShownAsLabel -and (Field $r 'grafico').ChartAreas[0].AxisX.Interval -gt 1) 'Grafico grande reduce solapamiento de etiquetas'
 }finally{$r.Dispose()}
 $hostMdi=New-Object Windows.Forms.Form;$r=New-Object ReportesAdversarial
 try{
  $hostMdi.IsMdiContainer=$true;$hostMdi.Size=New-Object Drawing.Size(800,600);Show-Test $hostMdi
  $r.MdiParent=$hostMdi;$r.WindowState='Maximized';$r.Show();[Windows.Forms.Application]::DoEvents()
  Check ($r.ClientSize.Width -le $hostMdi.ClientSize.Width -and $r.ClientSize.Height -le $hostMdi.ClientSize.Height) 'Dashboard se adapta a MDI de 800x600 sin imponer minimo fuera del contenedor'
  Check ($r.AutoScroll -and $r.HorizontalScroll.Visible -and $r.VerticalScroll.Visible) 'Lienzo conserva layout con desplazamiento en viewport pequeno'
  $boton=Field $r 'btnHistorial';$r.ScrollControlIntoView($boton);[Windows.Forms.Application]::DoEvents()
  Check ($boton.Top -ge 0 -and $boton.Bottom -le $r.ClientSize.Height) 'Botones inferiores alcanzables mediante scroll'
 }finally{$r.Dispose();$hostMdi.Dispose()}
 $actor=New-Object ForzaSuplementos.Entidades.Usuario;$actor.IdUsuario=1;$actor.NombrePerfil='VENDEDOR';$caja=New-Object ForzaSuplementos.Negocio.CajaBLL
 Reject 'Caja rechaza fechas fuera del rango SQL antes de conectar' {$caja.Historial($actor,[datetime]'1700-01-01',[datetime]'2026-01-01')}
 Write-Output "TOTAL ADVERSARIALES OFFLINE: $n aprobadas. Sin SQL."
}finally{$env:FORZA_ENTORNO=$old}
