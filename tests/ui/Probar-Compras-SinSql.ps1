param([string]$Configuration='Debug')
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$out=Join-Path $root "ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Presentacion/bin/$Configuration"
Add-Type -AssemblyName System.Windows.Forms,System.Data
foreach($l in @('Entidades','Datos','Negocio','Presentacion')){$suffix=if($l -eq 'Presentacion'){'exe'}else{'dll'};[void][Reflection.Assembly]::LoadFrom((Join-Path $out "ForzaSuplementos.$l.$suffix"))}
$n=0
function Check($ok,$text){if(!$ok){throw $text};$script:n++;Write-Output "OK: $text"}
function Reject($text,[scriptblock]$code){$ok=$false;try{&$code|Out-Null}catch{$e=$_.Exception;while($e.InnerException){$e=$e.InnerException};if($e -isnot [ApplicationException]){throw};$ok=$true};Check $ok $text}
$c=New-Object ForzaSuplementos.Entidades.Compra;$c.IdProveedor=1
$d=New-Object ForzaSuplementos.Entidades.DetalleCompra;$d.IdProducto=2;$d.Cantidad=3;$d.CostoUnitario=12.25;$c.Detalles.Add($d)
[ForzaSuplementos.Negocio.CompraBLL]::Validar($c);Check ($c.Total -eq 36.75) 'Subtotal y total exactos desde costo de compra'
$d.Cantidad=0;Reject 'Cantidad cero rechazada' {[ForzaSuplementos.Negocio.CompraBLL]::Validar($c)};$d.Cantidad=-1;Reject 'Cantidad negativa rechazada' {[ForzaSuplementos.Negocio.CompraBLL]::Validar($c)};$d.Cantidad=3
$d.CostoUnitario=1.001;Reject 'Costo con mas de dos decimales rechazado' {[ForzaSuplementos.Negocio.CompraBLL]::Validar($c)};$d.CostoUnitario=0;Reject 'Costo cero rechazado' {[ForzaSuplementos.Negocio.CompraBLL]::Validar($c)};$d.CostoUnitario=1
$c.Detalles.Add($d);Reject 'Producto duplicado rechazado' {[ForzaSuplementos.Negocio.CompraBLL]::Validar($c)};$c.Detalles.RemoveAt(1)
$c.IdProveedor=0;Reject 'Proveedor obligatorio' {[ForzaSuplementos.Negocio.CompraBLL]::Validar($c)};$c.IdProveedor=1
$c.Operacion=[guid]::Empty;Reject 'Idempotencia requiere identificador' {[ForzaSuplementos.Negocio.CompraBLL]::Validar($c)}
foreach($rol in @('VENDEDOR','ADMINISTRADOR')){$a=New-Object ForzaSuplementos.Entidades.Usuario;$a.IdUsuario=1;$a.NombrePerfil=$rol;$b=New-Object ForzaSuplementos.Negocio.CompraBLL;Reject "$rol no compra antes de SQL" {$b.Registrar($a,$c)}}
Reject 'Fechas invertidas rechazadas' {[ForzaSuplementos.Negocio.CompraBLL]::Fechas([datetime]'2026-02-01',[datetime]'2026-01-01')}
$f=New-Object ForzaSuplementos.Presentacion.FrmCompras;try{Check ($f.Controls.Count -eq 3) 'Compra construye carrito, acciones y estado'}finally{$f.Dispose()}
Write-Output "TOTAL COMPRAS OFFLINE: $n aprobadas. Sin SQL."
