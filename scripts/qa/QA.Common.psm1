$ErrorActionPreference = 'Stop'
function Get-QaConfig {
    $root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $path = Join-Path $root 'config\qa.config'
    [xml]$xml = [IO.File]::ReadAllText($path)
    $cfg = $xml.qa
    if ($cfg.base -ne 'ForzaSuplementosDB_QA' -or $cfg.marca -ne 'Forza-QA-Aislada-v1') { throw 'Destino QA rechazado.' }
    return [pscustomobject]@{Root=$root;Path=$path;Server=[string]$cfg.servidor;ExpectedServer=[string]$cfg.servidorEsperado;Database=[string]$cfg.base;Marker=[string]$cfg.marca}
}
function Assert-QaDestination($Connection,[switch]$Master,[switch]$WithoutMarker) {
    $cfg=Get-QaConfig
    $expectedDb=if($Master){'master'}else{'ForzaSuplementosDB_QA'}
    $cmd=$Connection.CreateCommand()
    $cmd.CommandText="SELECT CONVERT(nvarchar(128),SERVERPROPERTY('ServerName')) AS serverName, DB_NAME() AS databaseName, (SELECT CONVERT(nvarchar(128),value) FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment') AS marker;"
    $reader=$cmd.ExecuteReader()
    try {
        if(!$reader.Read() -or $reader.GetString(0) -ne $cfg.ExpectedServer -or $reader.GetString(1) -cne $expectedDb) { throw 'Servidor/base inesperados. Operacion cancelada antes de escribir.' }
        if(!$Master -and !$WithoutMarker -and ($reader.IsDBNull(2) -or $reader.GetString(2) -cne $cfg.Marker)) { throw 'Falta la marca de QA aislada. Operacion cancelada.' }
    } finally { $reader.Dispose();$cmd.Dispose() }
}
function Open-QaConnection([switch]$Master,[switch]$WithoutMarker) {
    $cfg=Get-QaConfig
    $b=New-Object System.Data.SqlClient.SqlConnectionStringBuilder
    $b.set_DataSource($cfg.Server)
    $b.set_InitialCatalog($(if($Master){'master'}else{$cfg.Database}))
    $b.set_IntegratedSecurity($true);$b.set_TrustServerCertificate($true);$b.set_ConnectTimeout(5)
    $b.set_ApplicationName('Forza QA infrastructure')
    $b.set_AsynchronousProcessing($true)
    $cn=New-Object System.Data.SqlClient.SqlConnection($b.ConnectionString)
    try { $cn.Open(); Assert-QaDestination $cn -Master:$Master -WithoutMarker:$WithoutMarker; return $cn } catch { $cn.Dispose();throw }
}
function Invoke-QaQuery($Connection,[string]$Sql,[hashtable]$Parameters=@{}) {
    Assert-QaDestination $Connection
    $cmd=$Connection.CreateCommand();$cmd.CommandText=$Sql;$cmd.CommandTimeout=30
    foreach($key in $Parameters.Keys) { $null=$cmd.Parameters.AddWithValue($key,$Parameters[$key]) }
    $table=New-Object System.Data.DataTable
    try { $reader=$cmd.ExecuteReader();try{$table.Load($reader)}finally{$reader.Dispose()}; return ,$table } finally {$cmd.Dispose()}
}
Export-ModuleMember -Function Get-QaConfig,Assert-QaDestination,Open-QaConnection,Invoke-QaQuery
