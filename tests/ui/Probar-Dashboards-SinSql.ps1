param([string]$Configuration='Debug')
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$out=Join-Path $root "ForzaSuplementos\ForzaSuplementos\ForzaSuplementos.Presentacion\bin\$Configuration"
Add-Type -AssemblyName System.Windows.Forms,System.Drawing,System.Data,System.Windows.Forms.DataVisualization
$refs=@('System.dll','System.Core.dll','System.Data.dll','System.Xml.dll','System.Drawing.dll','System.Windows.Forms.dll','System.Windows.Forms.DataVisualization.dll')
foreach($layer in @('Entidades','Datos','Negocio','Presentacion')){$suffix=if($layer -eq 'Presentacion'){'exe'}else{'dll'};$p=Join-Path $out "ForzaSuplementos.$layer.$suffix";$null=[Reflection.Assembly]::LoadFrom($p);$refs+=,$p}
$provider=New-Object Microsoft.VisualBasic.VBCodeProvider;$opts=New-Object CodeDom.Compiler.CompilerParameters;$opts.GenerateInMemory=$true;$opts.CompilerOptions='/optionstrict+ /optionexplicit+'
foreach($ref in $refs){$null=$opts.ReferencedAssemblies.Add($ref)}
$c=$provider.CompileAssemblyFromFile($opts,(Join-Path $PSScriptRoot 'DashboardsSinSql.vb'));if($c.Errors.HasErrors){throw ($c.Errors|Out-String)}
$script:checks=0
function Assert-D([bool]$ok,[string]$text){if(!$ok){throw $text};$script:checks++;Write-Output "OK: $text"}
function Reject([string]$text,[scriptblock]$code){try{& $code|Out-Null}catch{$e=$_.Exception;while($e.InnerException){$e=$e.InnerException};if($e -isnot [ApplicationException]){throw};Assert-D $true $text;return};throw "No rechazo: $text"}
function Actor($role,$id=7){$a=New-Object ForzaSuplementos.Entidades.Usuario;$a.IdUsuario=$id;$a.NombrePerfil=$role;return $a}
function Points(){ $t=New-Object Data.DataTable;$null=$t.Columns.Add('Clave',[int]);$null=$t.Columns.Add('Etiqueta',[string]);$null=$t.Columns.Add('Importe',[decimal]);$null=$t.Columns.Add('Cantidad',[long]);return ,$t}
$old=$env:FORZA_ENTORNO;$env:FORZA_ENTORNO='PRUEBA_DASHBOARD_SIN_SQL'
try{
    $manager=Actor 'GERENTE';$seller=Actor 'VENDEDOR';$admin=Actor 'ADMINISTRADOR'
    $table=New-Object Data.DataTable;$null=$table.Columns.Add('Fecha',[datetime]);$null=$table.Columns.Add('Total ($)',[decimal])
    foreach($r in @(@('2025-12-31',999),@('2026-01-01',100.5),@('2026-01-31 23:59:59',125),@('2026-02-01',888))){$null=$table.Rows.Add([datetime]$r[0],[decimal]$r[1])}
    $from=[datetime]'2026-01-01';$to=[datetime]'2026-01-31'
    $model=[ForzaSuplementos.Negocio.DashboardBLL]::CalcularBasico($table,$from,$to)
    Assert-D ($model.TotalFacturado -eq 225.5 -and $model.Operaciones -eq 2) 'Resumen excluye fuera del rango e incluye ultimo segundo de hasta'
    Assert-D ($model.Diaria.Count -eq 2 -and $model.Mensual.Count -eq 1 -and $model.Mensual[0].Importe -eq 225.5) 'Agrupacion diaria/mensual exacta con Decimal'
    Assert-D (!$model.Completo -and $null -eq $model.Unidades) 'Fallback no inventa unidades ni detalle'
    $empty=[ForzaSuplementos.Negocio.DashboardBLL]::CalcularBasico($table,[datetime]'2020-01-01',[datetime]'2020-01-02')
    Assert-D ($empty.TotalFacturado -eq 0 -and $empty.Operaciones -eq 0 -and $empty.Diaria.Count -eq 0) 'Periodo sin filas representa cero real y serie vacia'
    $fake=New-Object ForzaPruebasUI.DashboardSimulado;$fake.Basico=$table;$fake.Pendiente=$true;$service=New-Object ForzaSuplementos.Negocio.DashboardBLL($fake)
    $result=$service.Ventas($seller,$from,$to)
    Assert-D ($fake.VendedorSolicitado -eq 7 -and $result.TotalFacturado -eq 225.5) 'Vendedor deriva alcance del actor y fallback usa datos reales recibidos'
    $before=$fake.Llamadas;Reject 'Vendedor no puede pedir otro ID' {$service.Ventas($seller,$from,$to,8,$null)}
    Assert-D ($fake.Llamadas -eq $before) 'Rechazo de ID ajeno antes de DAL'
    Reject 'Administrador no usa dashboard comercial' {$service.Ventas($admin,$from,$to)}
    Reject 'Gerente no consulta backups' {$service.Backups($manager,$from,$to)}
    Reject 'Vendedor no consulta backups' {$service.Backups($seller,$from,$to)}
    Reject 'Sesion ausente rechazada' {$service.Ventas($null,$from,$to)}
    Reject 'Rango invertido rechazado' {$service.Ventas($manager,$to,$from)}
    Reject 'Fecha incompatible con datetime SQL rechazada' {$service.Ventas($manager,[datetime]'1700-01-01',$to)}
    Reject 'Hasta no admite overflow del extremo exclusivo' {$service.Ventas($manager,$from,[datetime]'9999-12-31')}
    Reject 'ID no positivo rechazado' {$service.Ventas($manager,$from,$to,0,$null)}
    Reject 'Filtro de producto no se ignora si falta SP' {$service.Ventas($manager,$from,$to,$null,1)}
    Reject 'Filtro de vendedor no se ignora si falta SP' {$service.Ventas($manager,$from,$to,8,$null)}
    Reject 'Backups ausente queda pendiente, no inventa ceros' {$service.Backups($admin,$from,$to)}
    $fake.Fallar=$true;$before=$fake.LlamadasBasicas;$failed=$false
    try{$service.Ventas($manager,$from,$to)|Out-Null}catch{$e=$_.Exception;while($e.InnerException){$e=$e.InnerException};$failed=$e -is [InvalidOperationException]}
    Assert-D ($failed -and $fake.LlamadasBasicas -eq $before) 'Errores distintos de SP inexistente no degradan permisos ni hacen fallback'
    $fake.Fallar=$false;$fake.Pendiente=$false;$ds=New-Object Data.DataSet
    $summary=New-Object Data.DataTable;foreach($col in @('TotalFacturado','Operaciones','Unidades','VentasSinDetalle')){$null=$summary.Columns.Add($col,[decimal])};$null=$summary.Rows.Add(225.5,2,3,0);$ds.Tables.Add($summary)
    foreach($n in 1..5){$point=Points;$null=$point.Rows.Add($n,"Punto ficticio $n",225.5,3);$ds.Tables.Add($point)}
    $fake.Datos=$ds;$full=$service.Ventas($manager,$from,$to,8,3)
    Assert-D ($full.Completo -and $full.Unidades -eq 3 -and $full.Categorias.Count -eq 1 -and $full.Vendedores.Count -eq 1) 'Contrato completo mapea unidades y rankings sin duplicar facturacion'
    Assert-D ($fake.VendedorSolicitado -eq 8 -and $fake.ProductoSolicitado -eq 3) 'Gerente conserva filtros autorizados'
    $backupSet=New-Object Data.DataSet
    $countTable=New-Object Data.DataTable;$null=$countTable.Columns.Add('Cantidad',[int]);$null=$countTable.Rows.Add(2);$backupSet.Tables.Add($countTable)
    $history=New-Object Data.DataTable;$null=$history.Columns.Add('IdBackup',[int]);$null=$history.Columns.Add('IdUsuario',[int]);$null=$history.Columns.Add('Fecha',[datetime]);$null=$history.Columns.Add('Archivo',[string]);$null=$history.Rows.Add(1,7,$from,'fixture.bak');$backupSet.Tables.Add($history)
    foreach($n in 1..2){$p=Points;$null=$p.Rows.Add([DBNull]::Value,'Periodo ficticio',0,2);$backupSet.Tables.Add($p)}
    $fake.Datos=$backupSet;$audit=$service.Backups($admin,$from,$to)
    Assert-D ($audit.Cantidad -eq 2 -and $audit.Historial.Count -eq 1 -and $audit.Diaria[0].Cantidad -eq 2) 'Administrador mapea historial y cantidades registradas'
    Assert-D ($null -eq $audit.Exitosos -and $null -eq $audit.Fallidos) 'Estados de backup desconocidos permanecen Nothing'
    $bad=New-Object Data.DataSet;$fake.Datos=$bad;Reject 'Contrato incompleto falla sin mostrar cifras inventadas' {$service.Ventas($manager,$from,$to)}
    $cap=New-Object ForzaPruebasUI.DashboardCaptura;$null=$cap.Ventas($seller,$from,$to,7,$null)
    Assert-D ($cap.ActorId -eq 7 -and $cap.VendedorId -eq 7 -and $cap.EsSP -and $cap.FechaTipo -eq [Data.SqlDbType]::Date) 'DAL utiliza SP, actor y fechas tipadas'
    Reject 'DAL tambien rechaza ventas ajenas' {$cap.Ventas($seller,$from,$to,8,$null)}
    Reject 'DAL tambien rechaza backup de vendedor' {$cap.Backups($seller,$from,$to)}
    $flags=[Reflection.BindingFlags]'Instance,NonPublic,Public'
    foreach($role in @('ADMINISTRADOR','GERENTE','VENDEDOR')){
        $view=New-Object ForzaPruebasUI.DashboardVista
        try{
            $view.StartPosition='Manual';$view.Location=New-Object Drawing.Point(-30000,-30000);$view.ShowInTaskbar=$false;$view.Show();$view.Perfil((Actor $role))
            $type=[ForzaSuplementos.Presentacion.FrmReportes];$get={param($name) $type.GetProperty($name,$flags).GetValue($view,$null)}
            Assert-D ((& $get 'nudVendedor').Visible -eq ($role -eq 'GERENTE')) "$role filtro de vendedor solo para gerente"
            $view.Size=New-Object Drawing.Size(1000,720)
            Assert-D ((& $get 'dgvReportes').Bottom -le (& $get 'btnHistorial').Top -and (& $get 'grafico').Bottom -le (& $get 'dgvReportes').Top) "$role layout minimo no superpone grafico, grilla y botones"
            if($role -eq 'VENDEDOR'){
                Assert-D ((& $get 'cboGrafico').Items.Count -eq 3) 'Vendedor no tiene graficos de otros vendedores/categorias globales'
                $view.Modelo($model);$chart=& $get 'grafico'
                Assert-D ($chart.Visible -and $chart.Series[0].Points.Count -eq 2) 'Grafico usa puntos calculados, no serie ficticia'
                $view.Modelo($empty);Assert-D (!$chart.Visible -and (& $get 'lblEstado').Text -ceq 'Sin datos para el período seleccionado') 'Sin datos muestra mensaje exacto sin grafico inventado'
                $view.Modelo($model);(& $get 'dtpDesde').Value=[datetime]'2026-01-02'
                Assert-D (!$chart.Visible -and (& $get 'lblResumen').Text -ceq 'Filtros modificados') 'Cambiar fecha elimina cifras anteriores hasta consultar'
            }
        }finally{$view.Dispose()}
    }
    Write-Output "TOTAL DASHBOARDS OFFLINE: $script:checks comprobaciones aprobadas. No se ejecuto SQL."
}finally{$env:FORZA_ENTORNO=$old;$provider.Dispose()}
