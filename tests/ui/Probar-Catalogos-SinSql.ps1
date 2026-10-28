param([string]$Configuration='Debug')
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$out=Join-Path $root "ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Presentacion/bin/$Configuration"
Add-Type -AssemblyName System.Windows.Forms,System.Data
foreach($layer in @('Entidades','Datos','Negocio','Presentacion')){$suffix=if($layer -eq 'Presentacion'){'exe'}else{'dll'};[void][Reflection.Assembly]::LoadFrom((Join-Path $out "ForzaSuplementos.$layer.$suffix"))}
$n=0
function Check($ok,$text){if(!$ok){throw $text};$script:n++;Write-Output "OK: $text"}
function Reject($text,[scriptblock]$action){$ok=$false;try{&$action|Out-Null}catch{$e=$_.Exception;while($e.InnerException){$e=$e.InnerException};if($e -isnot [ApplicationException]){throw};$ok=$true};Check $ok $text}
$old=$env:FORZA_ENTORNO;$env:FORZA_ENTORNO='SIN_SQL'
try{
 Check ([ForzaSuplementos.Negocio.ComercialBLL]::CuitValido('20000000001')) 'CUIT sintetico con digito valido'
 foreach($c in @('20000000002','20-00000000-1','abc','123')){Check (![ForzaSuplementos.Negocio.ComercialBLL]::CuitValido($c)) 'CUIT formato o checksum rechazado'}
 $p=New-Object ForzaSuplementos.Entidades.Proveedor;$p.Nombre='QA';$p.RazonSocial='QA';[ForzaSuplementos.Negocio.ComercialBLL]::Validar($p);Check $true 'Proveedor sin CUIT opcional valido'
 $p.Nombre='';Reject 'Nombre obligatorio' {[ForzaSuplementos.Negocio.ComercialBLL]::Validar($p)}
 foreach($role in @('ADMINISTRADOR','VENDEDOR')){
  $actor=New-Object ForzaSuplementos.Entidades.Usuario;$actor.IdUsuario=7;$actor.NombrePerfil=$role
  $service=New-Object ForzaSuplementos.Negocio.ComercialBLL
  Reject "$role no accede al catalogo antes de SQL" {$service.Buscar($actor,'Marcas','')}
 }
 foreach($name in @('FrmProveedores','FrmMarcas')){
  $form=New-Object ('ForzaSuplementos.Presentacion.'+$name)
  try{Check ($form.Controls.Count -eq 4) "$name construye grilla, estado, busqueda y editor"}finally{$form.Dispose()}
 }
 Write-Output "TOTAL CATALOGOS OFFLINE: $n aprobadas. Sin SQL."
}finally{$env:FORZA_ENTORNO=$old}
