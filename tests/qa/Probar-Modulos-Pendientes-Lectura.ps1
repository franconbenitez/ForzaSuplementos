param([string]$Configuration='Debug')
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Import-Module (Join-Path $root 'scripts/qa/QA.Common.psm1') -Force
$cfg=Get-QaConfig;$cn=Open-QaConnection
try{
 $ids=(Invoke-QaQuery $cn 'SELECT TOP(1) gerente,administrador,vendedor FROM qa.Fixtures;').Rows[0]
 $state=(Invoke-QaQuery $cn "SELECT (SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped=0) tablas,(SELECT COUNT(*) FROM sys.procedures WHERE is_ms_shipped=0) procedimientos,CASE WHEN OBJECT_ID('dbo.sp_Comercial_Estado','P') IS NULL THEN 1 ELSE 0 END pendientes,CASE WHEN OBJECT_ID('dbo.sp_Seguridad_Estado','P') IS NOT NULL THEN 1 ELSE 0 END seguridad;").Rows[0]
 $base004=$state.tablas -eq 11 -and $state.procedimientos -eq 30 -and !$state.seguridad
 $base005=$state.tablas -eq 13 -and $state.procedimientos -eq 37 -and $state.seguridad
 if((!$base004 -and !$base005) -or !$state.pendientes){throw 'Estado de despliegue distinto; revisar antes de probar pendientes.'}
 if($base005){
  $modo=Invoke-QaQuery $cn 'EXEC dbo.sp_Seguridad_Estado;'
  if($modo.Rows.Count -ne 1 -or [bool]$modo.Rows[0].activa){throw 'Esta suite requiere modo seguro inactivo.'}
 }
}finally{$cn.Dispose()}
Add-Type -AssemblyName System.Windows.Forms,System.Drawing,System.Data
$out=Join-Path $root "ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Presentacion/bin/$Configuration"
$refs=@('System.dll','System.Core.dll','System.Data.dll','System.Drawing.dll','System.Windows.Forms.dll')
foreach($l in @('Entidades','Datos','Negocio','Presentacion')){$suffix=if($l -eq 'Presentacion'){'exe'}else{'dll'};$path=Join-Path $out "ForzaSuplementos.$l.$suffix";[void][Reflection.Assembly]::LoadFrom($path);$refs+=,$path}
$vb=@"
Imports System
Imports ForzaSuplementos.Entidades
Imports ForzaSuplementos.Presentacion
Public Class PrincipalRevision
    Inherits FrmPrincipal
    Public Sub New(u As Usuario)
        MyBase.New(u)
    End Sub
    Public Sub Abrir(t As Type)
        AbrirModulo(t)
    End Sub
End Class
"@
$provider=New-Object Microsoft.VisualBasic.VBCodeProvider;$opts=New-Object CodeDom.Compiler.CompilerParameters;$opts.GenerateInMemory=$true
foreach($ref in $refs){[void]$opts.ReferencedAssemblies.Add($ref)}
$c=$provider.CompileAssemblyFromSource($opts,$vb);if($c.Errors.HasErrors){throw ($c.Errors|Out-String)}
$n=0
function Check($ok,$text){if(!$ok){throw $text};$script:n++;Write-Output "OK: $text"}
function Actor($role,$id){$u=New-Object ForzaSuplementos.Entidades.Usuario;$u.IdUsuario=$id;$u.NombrePerfil=$role;return $u}
$types=@('FrmProveedores','FrmMarcas','FrmCompras','FrmInventario')
$old=$env:FORZA_ENTORNO;$oldcfg=$env:FORZA_QA_CONFIG;$env:FORZA_ENTORNO='QA';$env:FORZA_QA_CONFIG=$cfg.Path
$dir=Join-Path $root 'tests/artifacts/intensivo';[void][IO.Directory]::CreateDirectory($dir)
try{
 foreach($role in @('GERENTE','ADMINISTRADOR','VENDEDOR')){
  $id=if($role -eq 'GERENTE'){$ids.gerente}elseif($role -eq 'ADMINISTRADOR'){$ids.administrador}else{$ids.vendedor}
  $main=New-Object PrincipalRevision((Actor $role $id))
  try{
   $main.ShowInTaskbar=$false;$main.StartPosition='Manual';$main.Location=New-Object Drawing.Point(-30000,-30000);$main.Show()
   foreach($name in $types){
    $type=[ForzaSuplementos.Presentacion.FrmPrincipal].Assembly.GetType('ForzaSuplementos.Presentacion.'+$name)
    $main.Abrir($type)
    if($role -ne 'GERENTE'){Check ($main.MdiChildren.Count -eq 0) "$role no abre $name por acceso directo";continue}
    $clock=[Diagnostics.Stopwatch]::StartNew()
    do{[Windows.Forms.Application]::DoEvents();Start-Sleep -Milliseconds 10;$f=$main.ActiveMdiChild;$flags=[Reflection.BindingFlags]'Instance,NonPublic';$base=if($name -in @('FrmProveedores','FrmMarcas')){$f.GetType().BaseType}else{$f.GetType()};$field=$base.GetField('_estado',$flags);$label=$field.GetValue($f);if($clock.Elapsed.TotalSeconds -gt 10){throw 'Modulo no termino de validar disponibilidad'}}while($label.Text -notmatch 'Requiere habilitaci')
    Check ($main.MdiChildren.Count -eq 1 -and $type.IsInstanceOfType($f)) "$name conserva un unico MDI"
    $editorName=if($name -in @('FrmProveedores','FrmMarcas')){'_editor'}elseif($name -eq 'FrmCompras'){'_edicion'}else{'_acciones'}
    Check (!$base.GetField($editorName,$flags).GetValue($f).Enabled) "$name bloquea escrituras sin migracion"
    $main.Abrir($type);Check ($main.MdiChildren.Count -eq 1 -and [object]::ReferenceEquals($f,$main.ActiveMdiChild)) "$name no crea duplicado"
    $bitmap=New-Object Drawing.Bitmap($f.Width,$f.Height);try{$f.DrawToBitmap($bitmap,(New-Object Drawing.Rectangle(0,0,$f.Width,$f.Height)));$bitmap.Save((Join-Path $dir ($name+'.png')))}finally{$bitmap.Dispose()}
   }
  }finally{$main.Dispose()}
 }
 Check ($base004 -or $base005) 'QA reconoce baseline de reportes o 005 estructural; 006-008 no aplicadas'
 Write-Output "TOTAL MODULOS PENDIENTES QA LECTURA: $n aprobadas. Sin escrituras SQL."
}finally{$env:FORZA_ENTORNO=$old;$env:FORZA_QA_CONFIG=$oldcfg}
