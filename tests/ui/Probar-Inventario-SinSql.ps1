param([string]$Configuration='Debug')
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$out=Join-Path $root "ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Presentacion/bin/$Configuration"
Add-Type -AssemblyName System.Windows.Forms,System.Data
foreach($l in @('Entidades','Datos','Negocio','Presentacion')){$suffix=if($l -eq 'Presentacion'){'exe'}else{'dll'};[void][Reflection.Assembly]::LoadFrom((Join-Path $out "ForzaSuplementos.$l.$suffix"))}
$n=0
function Check($ok,$text){if(!$ok){throw $text};$script:n++;Write-Output "OK: $text"}
function Reject($text,[scriptblock]$code){$ok=$false;try{&$code|Out-Null}catch{$e=$_.Exception;while($e.InnerException){$e=$e.InnerException};if($e -isnot [ApplicationException]){throw};$ok=$true};Check $ok $text}
$a=New-Object ForzaSuplementos.Entidades.AjusteStock;$a.IdProducto=1;$a.StockEsperado=3;$a.Cantidad=-2;$a.Motivo='QA sintetico'
[ForzaSuplementos.Negocio.InventarioBLL]::Validar($a);Check $true 'Salida valida conserva stock no negativo'
$a.Cantidad=-4;Reject 'Salida con stock negativo rechazada' {[ForzaSuplementos.Negocio.InventarioBLL]::Validar($a)}
$a.Cantidad=0;Reject 'Ajuste cero rechazado' {[ForzaSuplementos.Negocio.InventarioBLL]::Validar($a)}
$a.Cantidad=1;$a.StockEsperado=[int]::MaxValue;Reject 'Overflow de stock rechazado' {[ForzaSuplementos.Negocio.InventarioBLL]::Validar($a)}
$a.StockEsperado=3;$a.Motivo='';Reject 'Motivo obligatorio' {[ForzaSuplementos.Negocio.InventarioBLL]::Validar($a)}
$a.Motivo='x'*251;Reject 'Motivo extenso rechazado' {[ForzaSuplementos.Negocio.InventarioBLL]::Validar($a)}
foreach($rol in @('ADMINISTRADOR','VENDEDOR')){$actor=New-Object ForzaSuplementos.Entidades.Usuario;$actor.IdUsuario=1;$actor.NombrePerfil=$rol;$b=New-Object ForzaSuplementos.Negocio.InventarioBLL;Reject "$rol no ajusta antes de SQL" {$b.Ajustar($actor,$a)}}
$f=New-Object ForzaSuplementos.Presentacion.FrmInventario;try{Check ($f.Controls.Count -eq 3) 'Inventario construye vista y editor protegido'}finally{$f.Dispose()}
$s=[IO.File]::ReadAllText((Join-Path $root 'sql/qa/008_Inventario_QA.sql'))
Check (($s.Split(@('UPDATE p SET stock=p.stock-i.cantidad'),[StringSplitOptions]::None)).Count -eq 2) 'Venta conserva un unico descuento de stock en SQL preparado'
Check ($s.Contains('OUTPUT inserted.idProducto,deleted.stock,inserted.stock')) 'Movimientos capturan stock antes y despues del mismo UPDATE'
Write-Output "TOTAL INVENTARIO OFFLINE: $n aprobadas. Sin SQL."
