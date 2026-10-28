# PENDIENTE DE AUTORIZACION. Solo permite aplicar 004 a QA verificada; no crea bases ni toca filas.
param([switch]$AutorizarMigracion)
$ErrorActionPreference='Stop'
if(!$AutorizarMigracion){throw 'No se ejecuta: falta autorizacion expresa para aplicar la migracion QA 004.'}
Import-Module (Join-Path $PSScriptRoot 'QA.Common.psm1') -Force
$cfg=Get-QaConfig;$cn=Open-QaConnection;$tx=$null
try{
    # Guardar solo definiciones anteriores de estos dos SP para reversion; archivo privado ignorado.
    $before=Invoke-QaQuery $cn "SELECT name,OBJECT_DEFINITION(object_id) definicion FROM sys.procedures WHERE schema_id=SCHEMA_ID('dbo') AND name IN ('sp_Reportes_VentasDashboard','sp_Reportes_BackupsDashboard');"
    if(@($before.Rows | Where-Object {$_['definicion'] -is [DBNull]}).Count){throw 'No se puede respaldar una definicion existente: no se aplica.'}
    $snapshot=@($before.Rows | ForEach-Object {[pscustomobject]@{Nombre=[string]$_.name;Definicion=[string]$_.definicion}})
    $dir=Join-Path $cfg.Root 'private';$null=[IO.Directory]::CreateDirectory($dir)
    ConvertTo-Json -InputObject $snapshot -Depth 4 | Set-Content (Join-Path $dir ('antes-reportes-004-'+[datetime]::UtcNow.ToString('yyyyMMdd-HHmmss-fffffff')+'.json')) -Encoding UTF8
    $source=[IO.File]::ReadAllText((Join-Path $cfg.Root 'sql/qa/004_Reportes_Dashboards_QA.sql'))
    $source=$source.Replace('$(QaExpectedServer)',$cfg.ExpectedServer) -replace '(?m)^:on error exit\s*',''
    $batches=[regex]::Split($source,'(?im)^\s*GO\s*\r?$') | Where-Object {![string]::IsNullOrWhiteSpace($_)}
    $tx=$cn.BeginTransaction()
    foreach($batch in $batches){
        if($batch -notmatch "IF DB_NAME\(\)<>"){throw 'Lote sin guarda: no se aplica.'}
        $cmd=$cn.CreateCommand();$cmd.Transaction=$tx;$cmd.CommandText=$batch;$cmd.CommandTimeout=30
        try{$null=$cmd.ExecuteNonQuery()}finally{$cmd.Dispose()}
    }
    $tx.Commit();$tx.Dispose();$tx=$null
    Write-Output 'Migracion 004 aplicada unicamente a QA: dos SP, sin modificar tablas ni filas.'
}finally{if($tx){$tx.Rollback();$tx.Dispose()};$cn.Dispose()}
