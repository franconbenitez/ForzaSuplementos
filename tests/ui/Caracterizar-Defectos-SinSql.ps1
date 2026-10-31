$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$out=Join-Path $root 'ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Presentacion/bin/Debug'
Add-Type -AssemblyName System.Windows.Forms,System.Drawing,System.Data,System.Windows.Forms.DataVisualization
$refs=@('System.dll','System.Core.dll','System.Data.dll','System.Drawing.dll','System.Windows.Forms.dll','System.Windows.Forms.DataVisualization.dll')
foreach($l in @('Entidades','Datos','Negocio','Presentacion')){$s=if($l -eq 'Presentacion'){'exe'}else{'dll'};$p=Join-Path $out "ForzaSuplementos.$l.$s";[void][Reflection.Assembly]::LoadFrom($p);$refs+=,$p}
$provider=New-Object Microsoft.VisualBasic.VBCodeProvider;$opts=New-Object CodeDom.Compiler.CompilerParameters;$opts.GenerateInMemory=$true;foreach($p in $refs){[void]$opts.ReferencedAssemblies.Add($p)}
$c=$provider.CompileAssemblyFromFile($opts,[string[]]@((Join-Path $PSScriptRoot 'VistasSinSql.vb'),(Join-Path $PSScriptRoot 'BuscadoresSinSql.vb')));if($c.Errors.HasErrors){throw ($c.Errors|Out-String)}
$old=$env:FORZA_ENTORNO;$env:FORZA_ENTORNO='CARACTERIZACION_SIN_SQL'
try{
 $l=$c.CompiledAssembly.CreateInstance('ForzaPruebasUI.LoginVista');try{ $method=[ForzaSuplementos.Presentacion.FrmLogin].GetMethod('btnIngresar_Click',[Reflection.BindingFlags]'Instance,NonPublic');[void]$method.Invoke($l,[object[]]@($null,[EventArgs]::Empty));[void]$method.Invoke($l,[object[]]@($null,[EventArgs]::Empty));Write-Output "Login: $($l.Aperturas) aperturas para dos Enter posteriores al exito (esperado 1)."}finally{$l.Dispose()}
 $v=$c.CompiledAssembly.CreateInstance('ForzaPruebasUI.VentasBuscadorVista');try{
 $p=New-Object ForzaSuplementos.Entidades.Producto;$p.IdProducto=1;$p.Activo=$true;$p.Stock=10;$p.Precio=-1
 try{$v.ElegirProducto($p);$v.Agregar(1);Write-Output 'Ventas: precio negativo llego al carrito (esperado rechazo).'}catch{Write-Output 'Ventas: precio invalido rechazado.'}
 }finally{$v.Dispose()}
 $r=$c.CompiledAssembly.CreateInstance('ForzaPruebasUI.ReportesVista');try{
 $flags=[Reflection.BindingFlags]'Instance,NonPublic';$type=[ForzaSuplementos.Presentacion.FrmReportes]
 $type.GetField('_ventas',$flags).SetValue($r,(New-Object ForzaSuplementos.Entidades.DashboardVentas))
 $action=[Func[Data.DataTable]]{return ,(New-Object Data.DataTable)}
 [void]$type.GetMethod('ConsultaHeredada',$flags).Invoke($r,[object[]]@($action))
 Write-Output "Reportes: modelo anterior conservado tras consulta heredada: $($null -ne $type.GetField('_ventas',$flags).GetValue($r)) (esperado False)."
 }finally{$r.Dispose()}
}finally{$env:FORZA_ENTORNO=$old}
