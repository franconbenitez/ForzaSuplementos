# SOLO LECTURA: compara BLL/SP existentes con SELECT de control. No aplica migraciones ni fixtures.
param([string]$Configuration='Debug')
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Import-Module (Join-Path $root 'scripts/qa/QA.Common.psm1') -Force
$cfg=Get-QaConfig;$cn=Open-QaConnection
$out=Join-Path $root "ForzaSuplementos\ForzaSuplementos\ForzaSuplementos.Presentacion\bin\$Configuration"
Add-Type -AssemblyName System.Windows.Forms,System.Drawing,System.Windows.Forms.DataVisualization
foreach($layer in @('Entidades','Datos','Negocio','Presentacion')){$suffix=if($layer -eq 'Presentacion'){'exe'}else{'dll'};$null=[Reflection.Assembly]::LoadFrom((Join-Path $out "ForzaSuplementos.$layer.$suffix"))}
$old=$env:FORZA_ENTORNO;$oldConfig=$env:FORZA_QA_CONFIG;$env:FORZA_ENTORNO='QA';$env:FORZA_QA_CONFIG=$cfg.Path
$script:checks=0;$script:blocked=0
function Assert-Q([bool]$ok,[string]$name){if(!$ok){throw $name};$script:checks++;Write-Output "OK: $name"}
function Actor($role,$id){$u=New-Object ForzaSuplementos.Entidades.Usuario;$u.IdUsuario=$id;$u.NombrePerfil=$role;return $u}
$flags=[Reflection.BindingFlags]'Instance,Public,NonPublic'
function Member($f,$name){return ,($f.GetType().GetProperty($name,$flags).GetValue($f,$null))}
function Wait-Report($form){$clock=[Diagnostics.Stopwatch]::StartNew();do{[Windows.Forms.Application]::DoEvents();Start-Sleep -Milliseconds 10;if($clock.Elapsed.TotalSeconds -gt 20){throw 'Dashboard no termino'}}while(!(Member $form 'btnActualizar').Enabled)}
try{
    $ids=(Invoke-QaQuery $cn 'SELECT TOP(1) vendedor,otroVendedor,administrador,gerente FROM qa.Fixtures;').Rows[0]
    $ready=(Invoke-QaQuery $cn "SELECT CASE WHEN OBJECT_ID('dbo.sp_Reportes_VentasDashboard','P') IS NULL THEN 0 ELSE 1 END ventas, CASE WHEN OBJECT_ID('dbo.sp_Reportes_BackupsDashboard','P') IS NULL THEN 0 ELSE 1 END backups;").Rows[0]
    $service=New-Object ForzaSuplementos.Negocio.DashboardBLL
    $from=[datetime]'2000-01-01';$to=[datetime]'2030-12-31';$end=$to.AddDays(1)
    $cases=@(@('GERENTE',[int]$ids.gerente),@('VENDEDOR',[int]$ids.vendedor),@('VENDEDOR',[int]$ids.otroVendedor))
    foreach($case in $cases){
        $actor=Actor $case[0] $case[1]
        $model=$service.Ventas($actor,$from,$to)
        $seller=if($case[0] -eq 'VENDEDOR'){$case[1]}else{[DBNull]::Value}
        $params=@{'@desde'=$from;'@fin'=$end;'@vendedor'=$seller}
        $summary=(Invoke-QaQuery $cn 'SELECT COALESCE(SUM(total),0) total,COUNT(*) operaciones FROM dbo.Ventas WHERE fecha>=@desde AND fecha<@fin AND (@vendedor IS NULL OR idUsuario=@vendedor);' $params).Rows[0]
        Assert-Q ($model.TotalFacturado -eq [decimal]$summary.total -and $model.Operaciones -eq [int]$summary.operaciones) "$($case[0]) totales y operaciones coinciden con SQL independiente"
        foreach($kind in @('diaria','mensual')){
            $width=if($kind -eq 'diaria'){10}else{7}
            $control=Invoke-QaQuery $cn "SELECT CONVERT(char($width),fecha,23) etiqueta,SUM(total) total,COUNT(*) operaciones FROM dbo.Ventas WHERE fecha>=@desde AND fecha<@fin AND (@vendedor IS NULL OR idUsuario=@vendedor) GROUP BY CONVERT(char($width),fecha,23) ORDER BY etiqueta;" $params
            $series=if($kind -eq 'diaria'){$model.Diaria}else{$model.Mensual}
            $ok=$series.Count -eq $control.Rows.Count
            foreach($row in $control.Rows){$point=@($series | Where-Object {$_.Etiqueta -ceq [string]$row.etiqueta});if($point.Count -ne 1 -or $point[0].Importe -ne [decimal]$row.total -or $point[0].Cantidad -ne [long]$row.operaciones){$ok=$false}}
            Assert-Q $ok "$($case[0]) evolucion $kind coincide con GROUP BY de control"
        }
        if($ready.ventas){
            $details=(Invoke-QaQuery $cn 'SELECT COALESCE(SUM(CONVERT(bigint,d.cantidad)),0) unidades FROM dbo.Ventas v JOIN dbo.DetalleVentas d ON d.idVenta=v.idVenta WHERE v.fecha>=@desde AND v.fecha<@fin AND (@vendedor IS NULL OR v.idUsuario=@vendedor);' $params).Rows[0]
            Assert-Q ($model.Completo -and $model.Unidades -eq [long]$details.unidades) "$($case[0]) contrato completo y unidades coinciden con SQL"
        }
        if($ready.ventas){
            foreach($dimension in @('Productos','Categorias')){
                $key=if($dimension -eq 'Productos'){'d.idProducto'}else{'p.idCategoria'}
                $control=Invoke-QaQuery $cn "SELECT TOP(10) $key clave,SUM(d.subtotal) importe,SUM(CONVERT(bigint,d.cantidad)) cantidad FROM dbo.Ventas v JOIN dbo.DetalleVentas d ON d.idVenta=v.idVenta JOIN dbo.Productos p ON p.idProducto=d.idProducto WHERE v.fecha>=@desde AND v.fecha<@fin AND (@vendedor IS NULL OR v.idUsuario=@vendedor) GROUP BY $key ORDER BY cantidad DESC,clave;" $params
                $series=$model.$dimension;$ok=$series.Count -eq $control.Rows.Count
                foreach($r in $control.Rows){$point=@($series|Where-Object {$_.Clave -eq [int]$r.clave});if($point.Count -ne 1 -or $point[0].Importe -ne [decimal]$r.importe -or $point[0].Cantidad -ne [long]$r.cantidad){$ok=$false}}
                Assert-Q $ok "$($case[0]) ranking $dimension coincide con SQL independiente"
            }
        }
        if(!$ready.ventas){Assert-Q (!$model.Completo -and $null -eq $model.Unidades) 'SP completo ausente no inventa unidades ni rankings'}
    }
    $sellerActor=Actor 'VENDEDOR' ([int]$ids.vendedor)
    $rejected=$false;try{$service.Ventas($sellerActor,$from,$to,[int]$ids.otroVendedor,$null)|Out-Null}catch{$e=$_.Exception;while($e.InnerException){$e=$e.InnerException};if($e -isnot [ApplicationException]){throw};$rejected=$true}
    Assert-Q $rejected 'Vendedor rechaza ID ajeno antes de obtener estadisticas'
    $empty=$service.Ventas($sellerActor,[datetime]'1753-01-01',[datetime]'1753-01-02')
    Assert-Q ($empty.Operaciones -eq 0 -and $empty.TotalFacturado -eq 0 -and $empty.Diaria.Count -eq 0) 'Periodo realmente vacio sin serie ni cifras inventadas'
    $dir=Join-Path $root 'tests/artifacts/dashboards';$null=[IO.Directory]::CreateDirectory($dir)
    foreach($case in @(@('GERENTE',[int]$ids.gerente),@('VENDEDOR',[int]$ids.vendedor),@('ADMINISTRADOR',[int]$ids.administrador))){
        $form=New-Object ForzaSuplementos.Presentacion.FrmReportes
        try{
            $form.UsuarioActual=Actor $case[0] $case[1];$form.StartPosition='Manual';$form.ShowInTaskbar=$false;$form.Location=New-Object Drawing.Point(-30000,-30000);$form.Show();Wait-Report $form
            if($case[0] -ne 'ADMINISTRADOR'){
                (Member $form 'dtpDesde').Value=$from;(Member $form 'dtpHasta').Value=$to;(Member $form 'btnActualizar').PerformClick();Wait-Report $form
                $actual=$service.Ventas($form.UsuarioActual,$from,$to)
                $chart=Member $form 'grafico'
                Assert-Q ($actual.Operaciones -eq 0 -or ($chart.Visible -and $chart.Series[0].Points.Count -eq $actual.Diaria.Count)) "$($case[0]) grafico real refleja puntos calculados de QA"
                Assert-Q ((Member $form 'nudVendedor').Visible -eq ($case[0] -eq 'GERENTE')) "$($case[0]) interfaz conserva alcance y filtros permitidos"
            }elseif($ready.backups){
                (Member $form 'dtpDesde').Value=$from;(Member $form 'dtpHasta').Value=$to;(Member $form 'btnActualizar').PerformClick();Wait-Report $form
                $audit=$service.Backups($form.UsuarioActual,$from,$to)
                $count=(Invoke-QaQuery $cn 'SELECT COUNT(*) cantidad FROM dbo.AuditoriaBackups WHERE fecha>=@desde AND fecha<@fin;' @{'@desde'=$from;'@fin'=$end}).Rows[0].cantidad
                Assert-Q ($audit.Cantidad -eq [int]$count -and $audit.Historial.Count -eq [int]$count) 'Administrador historial y conteo coinciden con SQL independiente'
                Assert-Q ($null -eq $audit.Exitosos -and $null -eq $audit.Fallidos -and !(Member $form 'nudVendedor').Visible) 'Administrador no inventa estados ni ofrece filtro comercial'
            }elseif(!$ready.backups){Assert-Q (!(Member $form 'grafico').Visible -and (Member $form 'lblEstado').Text -match 'pendiente') 'Administrador muestra pendiente de migracion, no backups ficticios'}
            $bitmap=New-Object Drawing.Bitmap($form.Width,$form.Height);try{$form.DrawToBitmap($bitmap,(New-Object Drawing.Rectangle(0,0,$form.Width,$form.Height)));$bitmap.Save((Join-Path $dir ($case[0]+'.png')))}finally{$bitmap.Dispose()}
        }finally{$form.Dispose()}
    }
    if(!$ready.ventas){$script:blocked++;Write-Output 'BLOQUEADO: contrato SQL completo de ventas/rankings pendiente de aplicar 004.'}
    if(!$ready.backups){$script:blocked++;Write-Output 'BLOQUEADO: contrato SQL de auditoria de backups pendiente de aplicar 004.'}
    [pscustomobject]@{Aprobadas=$script:checks;Bloqueadas=$script:blocked;SQL='Solo lectura';ProcedimientosVentasAplicados=[bool]$ready.ventas;ProcedimientosBackupsAplicados=[bool]$ready.backups} | ConvertTo-Json | Set-Content (Join-Path $dir 'resultado.json') -Encoding UTF8
    Write-Output "TOTAL DASHBOARDS QA LECTURA: $script:checks aprobadas; $script:blocked verificaciones de SP bloqueadas por migracion pendiente."
}finally{$cn.Dispose();$env:FORZA_ENTORNO=$old;$env:FORZA_QA_CONFIG=$oldConfig}
