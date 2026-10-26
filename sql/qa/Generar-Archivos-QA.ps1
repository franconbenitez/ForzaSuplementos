# Generacion OFFLINE desde metadatos. No conecta ni ejecuta instrucciones SQL.
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$m = Get-Content (Join-Path $PSScriptRoot 'source-schema.json') -Raw -Encoding UTF8 | ConvertFrom-Json
if ($m.sourceDatabase -ne 'ForzaSuplementosDB' -or $m.tables.Count -ne 9) { throw 'Snapshot inesperado.' }
$expectedServer = '$'+'(QaExpectedServer)'
$options = @'
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
'@
$guard = @"
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$expectedServer'
    THROW 51200, 'Destino rechazado: se requiere la instancia auditada y ForzaSuplementosDB_QA.', 1;
$options
"@
function Quote-Name([string]$name) { return '['+$name.Replace(']',']]')+']' }
function Write-Utf8([string]$name,[string]$content) {
    [IO.File]::WriteAllText((Join-Path $PSScriptRoot $name),$content,(New-Object Text.UTF8Encoding($false)))
}
function Guarded-Batch([string]$sql,[switch]$Dynamic,[switch]$RequireMarker) {
    if ($Dynamic) { $sql="EXEC sys.sp_executesql N'"+$sql.Replace("'","''")+"';" }
    $marker=''
    if($RequireMarker){$marker="IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1') THROW 51200, 'Falta la marca QA aislada.', 1;`r`n"}
    return $guard+"`r`n"+$marker+$sql+"`r`nGO`r`n"
}
$create = @"
:on error exit
-- PREPARADO, NO EJECUTADO. Solo creacion nueva, nunca reemplaza una base existente.
IF DB_NAME()<>N'master' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$expectedServer'
    THROW 51200, 'La creacion requiere master en la instancia auditada.', 1;
IF DB_ID(N'ForzaSuplementosDB_QA') IS NOT NULL
    THROW 51201, 'QA ya existe. No se elimina ni se recrea. Inspeccionarla antes de continuar.', 1;
-- SQL Server asigna archivos nuevos usando sus directorios por defecto.
-- Si hay un conflicto de archivos, CREATE falla: no hay ATTACH, REPLACE ni rutas fisicas.
CREATE DATABASE [ForzaSuplementosDB_QA] COLLATE $($m.collation);
"@
Write-Utf8 '000_CrearBase_QA.sql' $create
$baseline = ":on error exit`r`n-- Esquema sin datos. No exporta diagramas ni filas del origen.`r`n"
$baseline += Guarded-Batch "SET XACT_ABORT ON;`r`nIF EXISTS(SELECT 1 FROM sys.tables WHERE is_ms_shipped=0) THROW 51202, 'El esquema inicial requiere QA vacia; no se sobreescribe.', 1;`r`nBEGIN TRANSACTION;"
foreach ($table in $m.tables) {
    if ($table.schemaName -ne 'dbo') { throw 'Esquema no soportado.' }
    $columns = @()
    foreach ($c in $table.columns) {
        $type = $c.typeName
        if ($type -in @('varchar','char','varbinary','binary','nvarchar','nchar')) {
            $len = $c.maxLength
            if ($len -eq -1) { $len='max' } elseif($type -in @('nvarchar','nchar')) { $len=$len/2 }
            $type += "($len)"
        } elseif($type -in @('decimal','numeric')) { $type += "($($c.precision),$($c.scale))" }
        $line = '    '+(Quote-Name $c.name)+' '+$type
        if ($c.identityColumn) { $line += " IDENTITY($($c.identitySeed),$($c.identityIncrement))" }
        $line += $(if($c.nullable){' NULL'}else{' NOT NULL'})
        if ($c.defaultDefinition) { $line += ' DEFAULT '+$c.defaultDefinition }
        $columns += $line
    }
    foreach ($key in $table.keys) {
        $kind = $(if($key.keyType -eq 'PK'){'PRIMARY KEY'}else{'UNIQUE'})
        $cols = @($key.columns | ForEach-Object { (Quote-Name $_.name)+$(if($_.descendingKey){' DESC'}else{' ASC'}) }) -join ','
        $columns += '    CONSTRAINT '+(Quote-Name $key.name)+" $kind $($key.indexType) ($cols)"
    }
    foreach ($check in $table.checks) {
        $columns += '    CONSTRAINT '+(Quote-Name $check.name)+' CHECK '+$check.definition
    }
    $statement = 'CREATE TABLE dbo.'+(Quote-Name $table.tableName)+" (`r`n"+($columns -join ",`r`n")+"`r`n);"
    $baseline += Guarded-Batch $statement
}
foreach ($fk in $m.foreignKeys) {
    if ($fk.schemaName -ne 'dbo' -or $fk.referenceSchema -ne 'dbo' -or $fk.deleteAction -ne 'NO_ACTION' -or $fk.updateAction -ne 'NO_ACTION') { throw 'FK inesperada: revisar manualmente.' }
    $cols = @($fk.columns | ForEach-Object {Quote-Name $_.name}) -join ','
    $refs = @($fk.columns | ForEach-Object {Quote-Name $_.referenceColumn}) -join ','
    $baseline += Guarded-Batch ('ALTER TABLE dbo.'+(Quote-Name $fk.tableName)+' WITH CHECK ADD CONSTRAINT '+(Quote-Name $fk.name)+" FOREIGN KEY ($cols) REFERENCES dbo."+(Quote-Name $fk.referenceTable)+" ($refs);")
}
foreach ($sp in $m.procedures) {
    $definition = $sp.definition
    if ($sp.name -eq 'sp_Backup_Generar') {
        $definition = "CREATE OR ALTER PROCEDURE dbo.sp_Backup_Generar @rutaDestino varchar(255) AS BEGIN THROW 51203, 'Backups fisicos deshabilitados en QA. No se crean ni se sobreescriben archivos.', 1; END;"
    } else {
        if ($definition -match '(?i)ForzaSuplementosDB|\bUSE\s|\bBACKUP\s|\bRESTORE\s|\bOPENROWSET\b|\bOPENDATASOURCE\b|\.mdf|\.ldf|\.bak') { throw "Referencia peligrosa en $($sp.name)." }
        $definition = [regex]::Replace($definition,'(?i)^\s*CREATE\s+(?:OR\s+ALTER\s+)?PROCEDURE','CREATE OR ALTER PROCEDURE')
    }
    $baseline += Guarded-Batch $definition -Dynamic
}
$baseline += Guarded-Batch "EXEC sys.sp_addextendedproperty @name=N'ForzaQaEnvironment',@value=N'Forza-QA-Aislada-v1';`r`nCOMMIT TRANSACTION;"
Write-Utf8 '010_EstructuraOriginal_QA.sql' $baseline
foreach ($filename in @('001_Caja_Pagos.sql','002_Caja_Procedimientos.sql','003_Ventas_Caja_Stock.sql')) {
    $source = [IO.File]::ReadAllText((Join-Path $projectRoot "sql\migrations\$filename"))
    $hash = (Get-FileHash (Join-Path $projectRoot "sql\migrations\$filename") -Algorithm SHA256).Hash
    if ($source -match '(?i)ForzaSuplementosDB|\bUSE\s+\[|\.mdf|\.ldf|\.bak') { throw "Referencia fija no admitida en $filename" }
    $source = $source -replace '(?m)^:on error exit\s*',''
    $copy = ":on error exit`r`n-- COPIA QA generada desde sql/migrations/$filename. No ejecutar sobre otra base.`r`n-- SOURCE_SHA256: $hash`r`n"
    foreach ($batch in [regex]::Split($source,'(?im)^\s*GO\s*\r?$')) {
        if ([string]::IsNullOrWhiteSpace($batch)) { continue }
        $dynamic = $batch -match '(?is)^\s*(?:--[^\r\n]*[\r\n]+\s*)*CREATE\s+OR\s+ALTER\b'
        $copy += Guarded-Batch $batch -Dynamic:$dynamic -RequireMarker
    }
    Write-Utf8 $filename.Replace('.sql','_QA.sql') $copy
}
Write-Output 'Generados offline: creacion, esquema original y tres copias QA con guardas por lote.'
