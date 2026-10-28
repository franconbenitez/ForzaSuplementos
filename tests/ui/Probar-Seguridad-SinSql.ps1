param([string]$Configuration='Debug')
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$out=Join-Path $root "ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Presentacion/bin/$Configuration"
foreach($n in @('Entidades','Datos','Negocio')){[void][Reflection.Assembly]::LoadFrom((Join-Path $out "ForzaSuplementos.$n.dll"))}
$n=0
function Check($ok,$text){if(!$ok){throw $text};$script:n++;Write-Output "OK: $text"}
# Sintetica, no corresponde a ninguna cuenta.
$key='Prueba offline sintetica 2026!'
$a=[ForzaSuplementos.Negocio.ClaveSegura]::Crear($key)
$b=[ForzaSuplementos.Negocio.ClaveSegura]::Crear($key)
Check ($a -ne $b) 'Salt individual produce hashes diferentes'
Check ([ForzaSuplementos.Negocio.ClaveSegura]::Verificar($key,$a)) 'Clave correcta verificada'
Check (![ForzaSuplementos.Negocio.ClaveSegura]::Verificar('incorrecta',$a)) 'Clave incorrecta rechazada'
foreach($bad in @('', 'plaintext', $a.Replace('$1$','$2$'),$a.Replace('$600000$','$999999999$'),$a.Replace('$600000$','$1$'), $a.Substring(0,20))){Check (![ForzaSuplementos.Negocio.ClaveSegura]::Verificar($key,$bad)) 'Formato/version/limites invalidos rechazados'}
$rejected=$false;try{[void][ForzaSuplementos.Negocio.ClaveSegura]::Crear('corta')}catch{$rejected=$true};Check $rejected 'Politica minima rechazada'
$u=New-Object ForzaSuplementos.Entidades.Usuario
$u.IdUsuario=9;$u.Nombre='QA';$u.Apellido='QA';$u.NombreUsuario='qa';$u.Calle='QA';$u.Altura='0';$u.Telefono='000';$u.IdPerfil=1;$u.Dni='00000001';$u.Email='qa@example.invalid';$u.FechaNacimiento=[datetime]'2000-01-01';$u.Contrasena=''
$bll=New-Object ForzaSuplementos.Negocio.UsuarioBLL
$method=$bll.GetType().GetMethod('ValidarDatosUsuario',[Reflection.BindingFlags]'NonPublic,Instance')
$method.Invoke($bll,[object[]]@($u.PSObject.BaseObject))|Out-Null;Check $true 'Edicion sin clave supera validacion y no exige reemplazarla'
$u.IdUsuario=0;$rejected=$false;try{$method.Invoke($bll,[object[]]@($u.PSObject.BaseObject))|Out-Null}catch{$rejected=$true};Check $rejected 'Alta requiere clave'
$sql=[IO.File]::ReadAllText((Join-Path $root 'sql/qa/005_Seguridad_QA.sql'))
Check ($sql.Contains('IF @formato IS NOT NULL')) 'Contrato SQL conserva hash cuando no hay cambio de clave'
Check ($sql.Contains('Login heredado deshabilitado.')) 'Corte bloquea autenticacion heredada'
$ui=[IO.File]::ReadAllText((Join-Path $root 'ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Presentacion/FrmUsuarios.vb'))
Check (!$ui.Contains('txtContrasena.Text = fila.Cells')) 'Edicion no muestra credenciales'
Check ($a.StartsWith('PBKDF2-SHA256$1$600000$')) 'Parametros versionados persistibles'
Write-Output "TOTAL SEGURIDAD OFFLINE: $n aprobadas. Sin conexiones SQL ni cambios de claves."
