# Solo consultas. Conserva metadatos privados; NO aplica 006 ni ejecuta fixtures.
param()
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'QA.Common.psm1') -Force
$cfg=Get-QaConfig
$sourcePath=Join-Path $cfg.Root 'sql/qa/006_Catalogos_QA.sql'
$source=[IO.File]::ReadAllText($sourcePath)
$names=@([regex]::Matches($source,'CREATE OR ALTER PROCEDURE dbo\.(\w+)') | ForEach-Object {$_.Groups[1].Value})
if($names.Count -ne 6){throw 'Alcance 006 inesperado.'}
foreach($batch in ([regex]::Split(($source -replace '(?m)^:on error exit\s*',''),'(?im)^\s*GO\s*\r?$') | Where-Object {![string]::IsNullOrWhiteSpace($_)})){
 if(!$batch.Contains("IF DB_NAME()<>N'ForzaSuplementosDB_QA'") -or !$batch.Contains('Forza-QA-Aislada-v1') -or !$batch.Contains('$(QaExpectedServer)')){throw 'Lote sin protecciones.'}
}
$cn=Open-QaConnection
try{
 $state=Invoke-QaQuery $cn "SELECT @@TRANCOUNT Transacciones,(SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped=0) Tablas,(SELECT COUNT(*) FROM sys.procedures WHERE is_ms_shipped=0) Procedimientos,COL_LENGTH('dbo.Perfiles','activo') PerfilActivo,OBJECT_ID('dbo.Proveedores','U') Proveedores,OBJECT_ID('dbo.Marcas','U') Marcas,COL_LENGTH('dbo.Productos','idMarca') ProductoMarca;"
 $r=$state.Rows[0]
 if($r.Transacciones -ne 0 -or $r.Tablas -ne 13 -or $r.Procedimientos -ne 37 -or $r.PerfilActivo -is [DBNull]){throw 'Baseline 005 estructural distinto; detener.'}
 if($r.Proveedores -isnot [DBNull] -or $r.Marcas -isnot [DBNull] -or $r.ProductoMarca -isnot [DBNull]){throw '006 existente o parcial; no continuar automaticamente.'}
 $mode=Invoke-QaQuery $cn 'SELECT activa FROM dbo.SeguridadEstado WHERE id=1;'
 if($mode.Rows.Count -ne 1 -or [bool]$mode.Rows[0].activa -or (Invoke-QaQuery $cn 'SELECT COUNT(*) Cantidad FROM dbo.CredencialesUsuario;').Rows[0].Cantidad -ne 0){throw 'Estado de seguridad distinto del autorizado.'}
 $definitions=Invoke-QaQuery $cn 'SELECT p.name Nombre,m.definition Codigo,m.uses_ansi_nulls AnsiNulls,m.uses_quoted_identifier QuotedIdentifier FROM sys.procedures p JOIN sys.sql_modules m ON m.object_id=p.object_id WHERE p.schema_id=SCHEMA_ID(''dbo'');'
 $security=[IO.File]::ReadAllText((Join-Path $cfg.Root 'sql/qa/005_Seguridad_QA.sql'))
 $checked=0
 foreach($m in [regex]::Matches($security,"(?s)EXEC sys.sp_executesql N'((?:[^']|'')*)';")){
  $expected=$m.Groups[1].Value.Replace("''","'")
  $name=[regex]::Match($expected,'CREATE OR ALTER PROCEDURE dbo\.(\w+)').Groups[1].Value
  $actual=@($definitions.Rows | Where-Object {$_.Nombre -eq $name})
  if($actual.Count -ne 1 -or $actual[0].Codigo -is [DBNull]){throw 'Contrato 005 ausente o ilegible.'}
  $eb=[regex]::Match($expected,'(?is)\bAS\s+BEGIN\b(.*)').Groups[1].Value
  $ab=[regex]::Match([string]$actual[0].Codigo,'(?is)\bAS\s+BEGIN\b(.*)').Groups[1].Value
  if(($eb -replace '\s+',' ').Trim() -cne ($ab -replace '\s+',' ').Trim()){throw 'Definicion 005 distinta de fuente.'}
  $checked++
 }
 if($checked -ne 9){throw 'Verificacion 005 incompleta.'}
 $previous=@($definitions.Rows | Where-Object {$names -contains $_.Nombre} | ForEach-Object {[pscustomobject]@{Nombre=[string]$_.Nombre;Definicion=[string]$_.Codigo;AnsiNulls=[bool]$_.AnsiNulls;QuotedIdentifier=[bool]$_.QuotedIdentifier}})
 if($previous.Count){throw 'Existen contratos 006 previos: revisar antes de preparar despliegue.'}
 $folder=Join-Path $cfg.Root ('private/006-preparacion-'+[datetime]::UtcNow.ToString('yyyyMMdd-HHmmss-fffffff'))
 [void][IO.Directory]::CreateDirectory($folder)
 ConvertTo-Json -InputObject $previous -Depth 5 | Set-Content (Join-Path $folder 'definiciones-previas-006.json') -Encoding UTF8
 # Conservar 005 y definiciones preexistentes, sin filas ni claves.
 $snapshot=@($definitions.Rows | ForEach-Object {[pscustomobject]@{Nombre=[string]$_.Nombre;Definicion=[string]$_.Codigo;AnsiNulls=[bool]$_.AnsiNulls;QuotedIdentifier=[bool]$_.QuotedIdentifier}})
 ConvertTo-Json -InputObject $snapshot -Depth 5 | Set-Content (Join-Path $folder 'definiciones-baseline.json') -Encoding UTF8
 $metadata=Invoke-QaQuery $cn "SELECT s.name Esquema,t.name Tabla,c.name Columna,TYPE_NAME(c.user_type_id) Tipo,c.max_length Longitud,c.is_nullable Nulable FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id JOIN sys.columns c ON c.object_id=t.object_id ORDER BY s.name,t.name,c.column_id;"
 $metadata | Export-Clixml (Join-Path $folder 'columnas-baseline.xml')
 [pscustomobject]@{Base=$cfg.Database;ServidorVerificado=$true;MarcaVerificada=$true;TransaccionesPrevias=0;Tablas=13;Procedimientos=37;Contratos005Verificados=$checked;ModoPBKDF2=$false;Credenciales=0;Contratos006Previos=$previous.Count;ScriptSHA256=(Get-FileHash $sourcePath -Algorithm SHA256).Hash;Head=(& git -C $cfg.Root rev-parse HEAD);SoloLectura=$true} | ConvertTo-Json | Set-Content (Join-Path $folder 'resultado.json') -Encoding UTF8
 Write-Output 'Preparacion 006: QA verificada, 005 coincide (9 contratos), 13 tablas/37 SP, PBKDF2 inactivo, sin objetos 006. Snapshot privado conservado. Sin escrituras SQL.'
}finally{$cn.Dispose()}
