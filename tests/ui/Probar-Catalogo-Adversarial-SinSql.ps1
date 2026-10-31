$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$out=Join-Path $root 'ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Presentacion/bin/Debug'
Add-Type -AssemblyName System.Windows.Forms,System.Data,System.Drawing
$refs=@('System.dll','System.Core.dll','System.Data.dll','System.Xml.dll','System.Drawing.dll','System.Windows.Forms.dll')
foreach($l in @('Entidades','Datos','Negocio','Presentacion')){$suffix=if($l -eq 'Presentacion'){'exe'}else{'dll'};$p=Join-Path $out "ForzaSuplementos.$l.$suffix";[void][Reflection.Assembly]::LoadFrom($p);$refs+=,$p}
$pr=New-Object Microsoft.VisualBasic.VBCodeProvider;$o=New-Object CodeDom.Compiler.CompilerParameters;$o.GenerateInMemory=$true;foreach($p in $refs){[void]$o.ReferencedAssemblies.Add($p)}
$c=$pr.CompileAssemblyFromFile($o,(Join-Path $PSScriptRoot 'CatalogoAdversarial.vb'));if($c.Errors.HasErrors){throw ($c.Errors|Out-String)}
$flags=[Reflection.BindingFlags]'Instance,NonPublic';$type=[ForzaSuplementos.Presentacion.FrmCatalogoComercial]
function Field($f,$n){return ,$type.GetField($n,$flags).GetValue($f)}
function Invoke-C($f,$n){return $type.GetMethod($n,$flags).Invoke($f,[object[]]@($null,[EventArgs]::Empty))}
function Wait-C([scriptblock]$condition){$w=[Diagnostics.Stopwatch]::StartNew();while(!(&$condition)){[Windows.Forms.Application]::DoEvents();Start-Sleep -Milliseconds 5;if($w.Elapsed.TotalSeconds -gt 10){throw 'Catalogo no termino'}}}
$n=0
function Check($ok,$text){if(!$ok){throw $text};$script:n++;Write-Output "OK: $text"}
$old=$env:FORZA_ENTORNO;$env:FORZA_ENTORNO='CATALOGO_ADVERSARIAL_SIN_SQL'
try{
 $dal=New-Object CatalogoMemoria;$f=New-Object CatalogoAdversarial($dal)
 try{
  $f.ShowInTaskbar=$false;$f.StartPosition='Manual';$f.Location=New-Object Drawing.Point(-30000,-30000);$f.Show();Wait-C {(Field $f '_habilitado')}
  (Field $f '_nombre').Text='QA';(Field $f '_razon').Text='QA'
  $dal.Reentrar=[Action]{Invoke-C $f 'Guardar'|Out-Null}
  Invoke-C $f 'Guardar'|Out-Null;Wait-C {!(Field $f '_guardando')}
  Check ($dal.Ids.Count -eq 1 -and $dal.Ids[0] -eq 0 -and (Field $f '_id') -eq 42) 'Alta conserva ID y evita doble Guardar reentrante'
  $dal.Reentrar=$null;Invoke-C $f 'Guardar'|Out-Null;Wait-C {!(Field $f '_guardando')}
  Check ($dal.Ids.Count -eq 2 -and $dal.Ids[1] -eq 42) 'Guardar posterior modifica registro, no repite alta'
  Check ((Field $f '_grid').Rows.Count -eq 1) 'Listado actualizado despues de guardar'
  $dal.FallarLectura=$true
  $task=$type.GetMethod('Cargar',$flags).Invoke($f,$null);Wait-C {$task.IsCompleted}
  Check ($null -eq (Field $f '_grid').DataSource -and (Field $f '_estado').Text -match 'No se pudo') 'Fallo de busqueda elimina datos anteriores'
 }finally{$f.Dispose()}
 $dal=New-Object CatalogoMemoria;$dal.SinId=$true;$f=New-Object CatalogoAdversarial($dal)
 try{
  $f.ShowInTaskbar=$false;$f.StartPosition='Manual';$f.Location=New-Object Drawing.Point(-30000,-30000);$f.Show();Wait-C {(Field $f '_habilitado')}
  (Field $f '_nombre').Text='QA';(Field $f '_razon').Text='QA';Invoke-C $f 'Guardar'|Out-Null;Wait-C {!(Field $f '_guardando')}
  Check ((Field $f '_resultadoIncierto') -and !(Field $f '_editor').Enabled) 'Respuesta sin ID no se presenta como exito'
  Invoke-C $f 'Guardar'|Out-Null;Check ($dal.Ids.Count -eq 1) 'Alta incierta no se reenvia automaticamente'
 }finally{$f.Dispose()}
 Write-Output "TOTAL CATALOGO ADVERSARIAL: $n aprobadas. DAL sintetica; sin SQL."
}finally{$env:FORZA_ENTORNO=$old}
