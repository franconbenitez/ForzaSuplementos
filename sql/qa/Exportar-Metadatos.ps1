# SOLO LECTURA: consulta catalogos; no consulta filas de tablas de la aplicacion.
$ErrorActionPreference = 'Stop'
$cn = New-Object System.Data.SqlClient.SqlConnection('Server=localhost;Initial Catalog=ForzaSuplementosDB;Integrated Security=True;TrustServerCertificate=True;ApplicationIntent=ReadOnly;Connect Timeout=5')
$query = @'
SELECT (SELECT
 CONVERT(nvarchar(128),SERVERPROPERTY('ServerName')) AS serverName,
 COALESCE(CONVERT(nvarchar(128),SERVERPROPERTY('InstanceName')),'MSSQLSERVER') AS instanceName,
 CONVERT(nvarchar(128),SERVERPROPERTY('ProductVersion')) AS productVersion,
 DB_NAME() AS sourceDatabase,CONVERT(nvarchar(128),DATABASEPROPERTYEX(DB_NAME(),'Collation')) AS collation,
 JSON_QUERY((SELECT s.name AS schemaName,t.name AS tableName,
   JSON_QUERY((SELECT c.name,ty.name AS typeName,c.max_length AS maxLength,c.precision,c.scale,c.is_nullable AS nullable,
     c.is_identity AS identityColumn,CONVERT(bigint,ic.seed_value) AS identitySeed,CONVERT(bigint,ic.increment_value) AS identityIncrement,
     dc.definition AS defaultDefinition,c.collation_name AS collation
     FROM sys.columns c JOIN sys.types ty ON ty.user_type_id=c.user_type_id
     LEFT JOIN sys.identity_columns ic ON ic.object_id=c.object_id AND ic.column_id=c.column_id
     LEFT JOIN sys.default_constraints dc ON dc.object_id=c.default_object_id
     WHERE c.object_id=t.object_id ORDER BY c.column_id FOR JSON PATH)) AS columns,
   JSON_QUERY((SELECT kc.name,kc.type AS keyType,i.type_desc AS indexType,
     JSON_QUERY((SELECT c.name,ic.is_descending_key AS descendingKey FROM sys.index_columns ic
       JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
       WHERE ic.object_id=kc.parent_object_id AND ic.index_id=kc.unique_index_id ORDER BY ic.key_ordinal FOR JSON PATH)) AS columns
     FROM sys.key_constraints kc JOIN sys.indexes i ON i.object_id=kc.parent_object_id AND i.index_id=kc.unique_index_id
     WHERE kc.parent_object_id=t.object_id ORDER BY kc.name FOR JSON PATH)) AS keys,
   JSON_QUERY((SELECT name,definition FROM sys.check_constraints WHERE parent_object_id=t.object_id FOR JSON PATH)) AS checks
   FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id WHERE t.is_ms_shipped=0 AND t.name<>'sysdiagrams' ORDER BY t.name FOR JSON PATH)) AS tables,
 JSON_QUERY((SELECT f.name,OBJECT_SCHEMA_NAME(f.parent_object_id) AS schemaName,OBJECT_NAME(f.parent_object_id) AS tableName,
   OBJECT_SCHEMA_NAME(f.referenced_object_id) AS referenceSchema,OBJECT_NAME(f.referenced_object_id) AS referenceTable,
   f.delete_referential_action_desc AS deleteAction,f.update_referential_action_desc AS updateAction,
   JSON_QUERY((SELECT pc.name,rc.name AS referenceColumn FROM sys.foreign_key_columns fc
     JOIN sys.columns pc ON pc.object_id=fc.parent_object_id AND pc.column_id=fc.parent_column_id
     JOIN sys.columns rc ON rc.object_id=fc.referenced_object_id AND rc.column_id=fc.referenced_column_id
     WHERE fc.constraint_object_id=f.object_id ORDER BY fc.constraint_column_id FOR JSON PATH)) AS columns
   FROM sys.foreign_keys f ORDER BY f.name FOR JSON PATH)) AS foreignKeys,
 JSON_QUERY((SELECT OBJECT_SCHEMA_NAME(p.object_id) AS schemaName,p.name,m.definition,m.uses_ansi_nulls,m.uses_quoted_identifier
   FROM sys.procedures p JOIN sys.sql_modules m ON m.object_id=p.object_id WHERE p.is_ms_shipped=0
   AND p.name NOT IN ('sp_alterdiagram','sp_creatediagram','sp_dropdiagram','sp_helpdiagramdefinition','sp_helpdiagrams','sp_renamediagram','sp_upgraddiagrams')
   ORDER BY p.name FOR JSON PATH)) AS procedures
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
'@
try {
    $cn.Open()
    $cmd = $cn.CreateCommand()
    $cmd.CommandText = $query
    $json = [string]$cmd.ExecuteScalar()
    $metadata = $json | ConvertFrom-Json
    if ($metadata.sourceDatabase -ne 'ForzaSuplementosDB') { throw 'Origen inesperado.' }
    [IO.File]::WriteAllText((Join-Path $PSScriptRoot 'source-schema.json'),($metadata | ConvertTo-Json -Depth 30),(New-Object Text.UTF8Encoding($false)))
    Write-Output "Metadatos exportados: $($metadata.tables.Count) tablas, $($metadata.foreignKeys.Count) FK y $($metadata.procedures.Count) SP. Sin filas de negocio."
} finally { $cn.Dispose() }
