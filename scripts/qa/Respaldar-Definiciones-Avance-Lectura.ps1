# SOLO LECTURA SQL: copia local privada de definiciones para revisar restauracion antes de autorizar 005-008.
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'QA.Common.psm1') -Force
$cfg=Get-QaConfig;$cn=Open-QaConnection
try{
 $table=Invoke-QaQuery $cn "SELECT SCHEMA_NAME(schema_id) esquema,name,OBJECT_DEFINITION(object_id) definicion FROM sys.procedures WHERE name IN('sp_Usuarios_Login','sp_Compras_Registrar','sp_Ventas_RegistrarConCaja','sp_Productos_Insertar','sp_Productos_Modificar');"
 if(@($table.Rows|Where-Object {$_['definicion'] -is [DBNull]}).Count){throw 'Definicion no accesible; no continuar con despliegue.'}
 $items=@($table.Rows|ForEach-Object {[pscustomobject]@{Esquema=[string]$_.esquema;Nombre=[string]$_.name;Definicion=[string]$_.definicion}})
 $dir=Join-Path $cfg.Root 'private';[void][IO.Directory]::CreateDirectory($dir)
 ConvertTo-Json -InputObject $items -Depth 5 | Set-Content (Join-Path $dir ('antes-avance-'+[datetime]::UtcNow.ToString('yyyyMMdd-HHmmss-fffffff')+'.json')) -Encoding UTF8
 Write-Output "Definiciones existentes conservadas en archivo privado ignorado: $($items.Count). Sin backups fisicos ni escrituras SQL."
}finally{$cn.Dispose()}
