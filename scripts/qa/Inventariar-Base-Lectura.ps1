# Solo lectura; ejecutar con Windows PowerShell. No exporta filas de negocio ni definiciones de SP.
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Import-Module (Join-Path $PSScriptRoot 'QA.Common.psm1') -Force
$cn=Open-QaConnection
function Rows($table){@($table.Rows | ForEach-Object {$h=[ordered]@{};foreach($c in $table.Columns){$v=$_[$c.ColumnName];$h[$c.ColumnName]=if($v -is [DBNull]){$null}else{$v}};[pscustomobject]$h})}
try{
    $snapshot=[ordered]@{}
    $snapshot['tablas']=@(Rows (Invoke-QaQuery $cn "SELECT s.name esquema,t.name tabla,c.column_id orden,c.name columna,ty.name tipo,c.max_length longitud,c.precision,c.scale escala,c.is_nullable nullable,c.is_identity identidad,dc.name nombreDefecto,dc.definition defecto FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id JOIN sys.columns c ON c.object_id=t.object_id JOIN sys.types ty ON ty.user_type_id=c.user_type_id LEFT JOIN sys.default_constraints dc ON dc.object_id=c.default_object_id WHERE t.is_ms_shipped=0 ORDER BY s.name,t.name,c.column_id"))
    $snapshot['indices']=@(Rows (Invoke-QaQuery $cn "SELECT t.name tabla,i.name indice,i.is_primary_key pk,i.is_unique unico,i.type_desc tipo,i.is_disabled deshabilitado,i.filter_definition filtro,ic.key_ordinal orden,ic.is_descending_key descendente,c.name columna,ic.is_included_column incluida FROM sys.tables t JOIN sys.indexes i ON i.object_id=t.object_id JOIN sys.index_columns ic ON ic.object_id=i.object_id AND ic.index_id=i.index_id JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ic.column_id WHERE t.is_ms_shipped=0 AND i.index_id>0 ORDER BY t.name,i.name,ic.index_column_id"))
    $snapshot['fks']=@(Rows (Invoke-QaQuery $cn "SELECT fk.name nombre,pt.name hija,pc.name columna,rt.name padre,rc.name referenciada,fkc.constraint_column_id orden,pc.is_nullable nullable,fk.delete_referential_action_desc alBorrar,fk.update_referential_action_desc alActualizar,fk.is_disabled deshabilitada,fk.is_not_trusted noConfiable FROM sys.foreign_keys fk JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id=fk.object_id JOIN sys.tables pt ON pt.object_id=fk.parent_object_id JOIN sys.columns pc ON pc.object_id=pt.object_id AND pc.column_id=fkc.parent_column_id JOIN sys.tables rt ON rt.object_id=fk.referenced_object_id JOIN sys.columns rc ON rc.object_id=rt.object_id AND rc.column_id=fkc.referenced_column_id ORDER BY fk.name,fkc.constraint_column_id"))
    $snapshot['checks']=@(Rows (Invoke-QaQuery $cn "SELECT OBJECT_NAME(parent_object_id) tabla,name nombre,definition definicion,is_disabled deshabilitada,is_not_trusted noConfiable FROM sys.check_constraints ORDER BY tabla,nombre"))
    $snapshot['procedimientos']=@(Rows (Invoke-QaQuery $cn "SELECT pr.name procedimiento,pa.parameter_id orden,pa.name parametro,ty.name tipo,pa.max_length longitud,pa.precision,pa.scale escala,pa.is_output salida FROM sys.procedures pr LEFT JOIN sys.parameters pa ON pa.object_id=pr.object_id LEFT JOIN sys.types ty ON ty.user_type_id=pa.user_type_id WHERE pr.is_ms_shipped=0 ORDER BY pr.name,pa.parameter_id"))
    $snapshot['vistas']=@(Rows (Invoke-QaQuery $cn "SELECT s.name esquema,v.name vista FROM sys.views v JOIN sys.schemas s ON s.schema_id=v.schema_id WHERE v.is_ms_shipped=0 ORDER BY s.name,v.name"))
    $snapshot['triggers']=@(Rows (Invoke-QaQuery $cn "SELECT OBJECT_SCHEMA_NAME(parent_id) esquema,OBJECT_NAME(parent_id) tabla,name triggerNombre,is_disabled deshabilitado,is_instead_of_trigger enLugarDe FROM sys.triggers WHERE parent_class=1 AND is_ms_shipped=0 ORDER BY name"))
    $private=Join-Path $root 'private';$null=[IO.Directory]::CreateDirectory($private)
    $snapshot | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $private 'inventario-esquema-qa.json') -Encoding UTF8
    $snapshot.tablas | Group-Object tabla | ForEach-Object {Write-Output ($_.Name+': '+(($_.Group | ForEach-Object {$_.columna+' '+$_.tipo}) -join ', '))}
    'Tablas: '+@($snapshot.tablas | Group-Object tabla).Count
    'FK: '+@($snapshot.fks | Group-Object nombre).Count
    'SP: '+@($snapshot.procedimientos | Group-Object procedimiento).Count
    $snapshot.procedimientos | Group-Object procedimiento | ForEach-Object {Write-Output $_.Name}
}finally{$cn.Dispose()}
