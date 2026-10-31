param([string]$Configuration='Debug')
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$out=Join-Path $root "ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Presentacion/bin/$Configuration"
Add-Type -AssemblyName System.Data
foreach($l in @('Entidades','Datos','Negocio')){[void][Reflection.Assembly]::LoadFrom((Join-Path $out "ForzaSuplementos.$l.dll"))}
$n=0
function Check($ok,$text){if(!$ok){throw $text};$script:n++;Write-Output "OK: $text"}
function Reject($text,[scriptblock]$code){$ok=$false;try{&$code|Out-Null}catch{$e=$_.Exception;while($e.InnerException){$e=$e.InnerException};if($e -isnot [ApplicationException]){throw};$ok=$true};Check $ok $text}
$old=$env:FORZA_ENTORNO;$env:FORZA_ENTORNO='SEGURIDAD_ADVERSARIAL_SIN_SQL'
try{
Check ([ForzaSuplementos.Datos.SeguridadDAL]::InterpretarEstado($true)) 'Estado activo se interpreta sin fallback'
Check (![ForzaSuplementos.Datos.SeguridadDAL]::InterpretarEstado($false)) 'Estado previo al corte explicito conserva compatibilidad'
foreach($v in @($null,[DBNull]::Value,'False',0)){Reject 'Estado ausente o incompatible falla cerrado' {[ForzaSuplementos.Datos.SeguridadDAL]::InterpretarEstado($v)}}
Reject 'Clave de solo espacios no crea cuenta imposible de autenticar' {[ForzaSuplementos.Negocio.ClaveSegura]::Crear(' '*16)}
$clave='  Clave sintetica exacta 2026!  ';$hash=[ForzaSuplementos.Negocio.ClaveSegura]::Crear($clave)
Check ([ForzaSuplementos.Negocio.ClaveSegura]::Verificar($clave,$hash)) 'Clave valida conserva espacios significativos'
Check (![ForzaSuplementos.Negocio.ClaveSegura]::Verificar($clave.Trim(),$hash)) 'No autentica una clave diferente por normalizacion'
Check ($hash.Length -eq 92 -and $hash.Substring(23,24).EndsWith('==') -and $hash[47] -eq '$' -and $hash.EndsWith('=')) 'Longitudes y posiciones SQL coinciden con PBKDF2 real'
$s=[IO.File]::ReadAllText((Join-Path $root 'sql/qa/005_Seguridad_QA.sql'))
Check ($s.Contains('@confirmacion IS NULL OR')) 'Confirmacion nula rechazada en migracion preparada'
Check ($s.Contains('Provisionar al menos un administrador activo')) 'Corte preparado requiere administrador recuperable'
Check ($s.Contains("ISNULL(IS_MEMBER(''db_owner''),0)")) 'Pertenencia de rol SQL desconocida no concede privilegio'
foreach($file in @('007_Compras_QA.sql','008_Inventario_QA.sql')){
 $text=[IO.File]::ReadAllText((Join-Path $root ('sql/qa/'+$file)))
 Check ($text.IndexOf('no se redondea') -lt $text.IndexOf('DECLARE @raw TABLE')) "$file valida lexical antes de conversion decimal"
}
$legacy=New-Object ForzaSuplementos.Datos.UsuarioDAL
foreach($inputKey in @('',('x'*101))){
 $rejected=$false;try{$legacy.Login('qa',$inputKey)|Out-Null}catch{$e=$_.Exception;while($e.InnerException){$e=$e.InnerException};$rejected=$e -is [ApplicationException] -and $e.Message -match '100'}
 Check $rejected 'Login heredado rechaza vacio/truncamiento antes de conectar'
}
Write-Output "TOTAL SEGURIDAD ADVERSARIAL: $n aprobadas. Criptografia y contratos estaticos; sin SQL."

}finally{$env:FORZA_ENTORNO=$old}
