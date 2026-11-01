# Lectura exclusiva: verifica la huella de tablas vacias y columnas existentes. No despliega.
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Import-Module (Join-Path $root 'scripts/qa/QA.Common.psm1') -Force
$cn=Open-QaConnection
try{
 $n=0
 $tables=Invoke-QaQuery $cn "SELECT t.object_id Id,QUOTENAME(s.name)+'.'+QUOTENAME(t.name) Nombre FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id WHERE t.is_ms_shipped=0 ORDER BY s.name,t.name;"
 foreach($table in $tables.Rows){
  $columns=Invoke-QaQuery $cn 'SELECT QUOTENAME(name) Nombre FROM sys.columns WHERE object_id=@id ORDER BY column_id;' @{'@id'=[int]$table.Id}
  $cols=(@($columns.Rows | ForEach-Object {[string]$_.Nombre}) -join ',')
  $query="SELECT HASHBYTES('SHA2_256',COALESCE(CONVERT(varbinary(max),(SELECT $cols FROM $($table.Nombre) ORDER BY $cols FOR XML RAW,BINARY BASE64)),CONVERT(varbinary(max),0x))) Huella;"
  $a=(Invoke-QaQuery $cn $query).Rows[0].Huella
  $b=(Invoke-QaQuery $cn $query).Rows[0].Huella
  if($a -isnot [byte[]] -or $a.Length -ne 32 -or [Convert]::ToBase64String($a) -cne [Convert]::ToBase64String($b)){throw 'Huella invalida o datos cambiantes; no desplegar.'}
  $n++
 }
 $empty=(Invoke-QaQuery $cn "SELECT HASHBYTES('SHA2_256',COALESCE(CONVERT(varbinary(max),(SELECT id FROM dbo.SeguridadEstado WHERE 1=0 FOR XML RAW,BINARY BASE64)),CONVERT(varbinary(max),0x))) Huella;").Rows[0].Huella
 if($empty -isnot [byte[]] -or $empty.Length -ne 32){throw 'Regresion de huella vacia.'}
 Write-Output "Integridad 006: $n tablas con huellas comparables y tabla vacia comprobada. Solo lectura; valores no exportados."
}finally{$cn.Dispose()}
