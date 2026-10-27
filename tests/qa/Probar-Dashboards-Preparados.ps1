# PENDIENTE: no ejecutar sin autorizacion expresa para escrituras QA ficticias.
param([switch]$AutorizarFixtures)
$ErrorActionPreference='Stop'
if(!$AutorizarFixtures){throw 'No se ejecuta: falta autorizacion expresa de fixtures QA. No se abre una transaccion.'}
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Import-Module (Join-Path $root 'scripts/qa/QA.Common.psm1') -Force
$cfg=Get-QaConfig;$cn=Open-QaConnection;$tx=$null
$script:checks=0
function Assert-R([bool]$ok,[string]$name){if(!$ok){throw $name};$script:checks++;Write-Output "OK: $name"}
function Read-SP($name,[int]$actor,$vendedor=$null,$producto=$null){
    $cmd=$cn.CreateCommand();$cmd.Transaction=$tx;$cmd.CommandType='StoredProcedure';$cmd.CommandText=$name
    $null=$cmd.Parameters.Add('@idActor',[Data.SqlDbType]::Int);$cmd.Parameters['@idActor'].Value=$actor
    $null=$cmd.Parameters.Add('@desde',[Data.SqlDbType]::Date);$cmd.Parameters['@desde'].Value=[datetime]'2099-01-01'
    $null=$cmd.Parameters.Add('@hasta',[Data.SqlDbType]::Date);$cmd.Parameters['@hasta'].Value=[datetime]'2099-01-31'
    if($name -eq 'dbo.sp_Reportes_VentasDashboard'){
        $null=$cmd.Parameters.Add('@idVendedor',[Data.SqlDbType]::Int);$cmd.Parameters['@idVendedor'].Value=if($null -eq $vendedor){[DBNull]::Value}else{$vendedor}
        $null=$cmd.Parameters.Add('@idProducto',[Data.SqlDbType]::Int);$cmd.Parameters['@idProducto'].Value=if($null -eq $producto){[DBNull]::Value}else{$producto}
    }
    $set=New-Object Data.DataSet;$adapter=New-Object Data.SqlClient.SqlDataAdapter($cmd)
    try{$null=$adapter.Fill($set);return ,$set}finally{$adapter.Dispose();$cmd.Dispose()}
}
try{
    $ready=(Invoke-QaQuery $cn "SELECT CASE WHEN OBJECT_ID('dbo.sp_Reportes_VentasDashboard','P') IS NOT NULL AND OBJECT_ID('dbo.sp_Reportes_BackupsDashboard','P') IS NOT NULL THEN 1 ELSE 0 END ready;").Rows[0].ready
    if(!$ready){throw 'BLOQUEADO: aplicar primero la migracion 004 autorizada. No se insertaron fixtures.'}
    $ids=(Invoke-QaQuery $cn 'SELECT TOP(1) vendedor,otroVendedor,administrador,gerente,inactivo FROM qa.Fixtures;').Rows[0]
    $tx=$cn.BeginTransaction()
    $cmd=$cn.CreateCommand();$cmd.Transaction=$tx;$cmd.CommandText=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'fixtures/Reportes_Fixtures_QA.sql'))
    $null=$cmd.Parameters.AddWithValue('@QaExpectedServer',$cfg.ExpectedServer);$null=$cmd.Parameters.AddWithValue('@AutorizarFixtures',1)
    $fixtureTable=New-Object Data.DataTable
    try{$reader=$cmd.ExecuteReader();try{$fixtureTable.Load($reader)}finally{$reader.Dispose()}}finally{$cmd.Dispose()}
    $product=[int]$fixtureTable.Rows[0].Producto
    $all=Read-SP 'dbo.sp_Reportes_VentasDashboard' ([int]$ids.gerente)
    Assert-R ($all.Tables.Count -eq 6) 'Contrato comercial de seis resultados'
    $summary=$all.Tables[0].Rows[0]
    Assert-R ($summary.TotalFacturado -eq 450 -and $summary.Operaciones -eq 2 -and $summary.Unidades -eq 5) 'Cabeceras no se duplican por dos detalles'
    Assert-R ($all.Tables[1].Rows.Count -eq 2 -and $all.Tables[2].Rows[0].Importe -eq 450) 'Evolucion diaria y mensual exacta'
    Assert-R ($all.Tables[3].Rows.Count -eq 2 -and ($all.Tables[3].Rows | Measure-Object Cantidad -Sum).Sum -eq 5) 'Ranking de productos suma unidades registradas'
    Assert-R (($all.Tables[4].Rows | Measure-Object Cantidad -Sum).Sum -eq 5) 'Categorias calculadas desde productos reales'
    Assert-R ($all.Tables[5].Rows.Count -eq 2 -and ($all.Tables[5].Rows | Measure-Object Importe -Sum).Sum -eq 450) 'Comparacion no mezcla vendedores por nombre'
    $own=Read-SP 'dbo.sp_Reportes_VentasDashboard' ([int]$ids.vendedor)
    Assert-R ($own.Tables[0].Rows[0].TotalFacturado -eq 350 -and $own.Tables[0].Rows[0].Operaciones -eq 1) 'Vendedor solo ve su venta'
    $filtered=Read-SP 'dbo.sp_Reportes_VentasDashboard' ([int]$ids.gerente) $null $product
    Assert-R ($filtered.Tables[0].Rows[0].TotalFacturado -eq 150 -and $filtered.Tables[0].Rows[0].Unidades -eq 2) 'Filtro producto usa importe de lineas, no total completo de factura'
    $audit=Read-SP 'dbo.sp_Reportes_BackupsDashboard' ([int]$ids.administrador)
    Assert-R ($audit.Tables.Count -eq 4 -and $audit.Tables[0].Rows[0].Cantidad -eq 2 -and $audit.Tables[1].Rows.Count -eq 2) 'Auditoria filtra dos registros ficticios'
    Assert-R (!$audit.Tables[1].Columns.Contains('Estado') -and [string]$audit.Tables[1].Rows[0].Archivo -notmatch '[/\\]') 'No inventa estado ni expone ruta completa'
    $tx.Rollback();$tx.Dispose();$tx=$null
    Assert-R ((Read-SP 'dbo.sp_Reportes_VentasDashboard' ([int]$ids.gerente)).Tables[0].Rows[0].Operaciones -eq 0) 'Rollback elimina exclusivamente los fixtures del periodo'
    foreach($case in @(@('dbo.sp_Reportes_VentasDashboard',[int]$ids.vendedor,[int]$ids.otroVendedor,51404),@('dbo.sp_Reportes_VentasDashboard',[int]$ids.administrador,$null,51403),@('dbo.sp_Reportes_BackupsDashboard',[int]$ids.gerente,$null,51405),@('dbo.sp_Reportes_VentasDashboard',[int]$ids.inactivo,$null,51403))){
        $rejected=$false;try{Read-SP $case[0] $case[1] $case[2]|Out-Null}catch{$e=$_.Exception;while($e.InnerException){$e=$e.InnerException};if($e -isnot [Data.SqlClient.SqlException] -or $e.Number -ne $case[3]){throw};$rejected=$true}
        Assert-R $rejected 'Servidor rechaza perfil/activo/alcance no autorizado'
    }
    Write-Output "TOTAL DASHBOARDS PREPARADOS: $script:checks aprobadas con fixtures revertidas."
}finally{if($tx){$tx.Rollback();$tx.Dispose()};$cn.Dispose()}
