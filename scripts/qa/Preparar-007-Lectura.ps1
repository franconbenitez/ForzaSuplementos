# Revision previa de 007: solo metadatos/lecturas, NO aplica migraciones.
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'QA.Common.psm1') -Force
$cfg=Get-QaConfig
$path=Join-Path $cfg.Root 'sql/qa/007_Compras_QA.sql'
$source=[IO.File]::ReadAllText($path)
$names=@([regex]::Matches($source,'CREATE OR ALTER PROCEDURE dbo\.(\w+)') | ForEach-Object {$_.Groups[1].Value})
if($names.Count -ne 3 -or $source -match 'ForzaSuplementosDB(?!_QA)' -or $source -notmatch 'BEGIN TRANSACTION' -or $source -notmatch 'IF @@TRANCOUNT<>1'){throw 'Alcance o transaccion 007 inesperados.'}
foreach($batch in ([regex]::Split(($source -replace '(?m)^:on error exit\s*',''),'(?im)^\s*GO\s*\r?$') | Where-Object {![string]::IsNullOrWhiteSpace($_)})){
 if(!$batch.Contains("IF DB_NAME()<>N'ForzaSuplementosDB_QA'") -or !$batch.Contains('Forza-QA-Aislada-v1') -or !$batch.Contains('$(QaExpectedServer)')){throw '007 contiene lote sin guardas.'}
}
$cn=Open-QaConnection
try{
 $state=Invoke-QaQuery $cn "SELECT @@TRANCOUNT Transacciones,(SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped=0) Tablas,(SELECT COUNT(*) FROM sys.procedures WHERE is_ms_shipped=0) Procedimientos,OBJECT_ID('dbo.Compras','U') Compras,OBJECT_ID('dbo.DetalleCompras','U') DetalleCompras,OBJECT_ID('dbo.MovimientosStock','U') Movimientos, (SELECT activa FROM dbo.SeguridadEstado WHERE id=1) PBKDF2,(SELECT COUNT(*) FROM dbo.CredencialesUsuario) Credenciales;"
 $r=$state.Rows[0]
 if($r.Transacciones -ne 0 -or $r.Tablas -ne 15 -or $r.Procedimientos -ne 43 -or $r.PBKDF2 -or $r.Credenciales -ne 0){throw 'Baseline 006 distinto.'}
 if($r.Compras -isnot [DBNull] -or $r.DetalleCompras -isnot [DBNull] -or $r.Movimientos -isnot [DBNull]){throw '007/008 existente o parcial: detener revision automatica.'}
 $defs=Invoke-QaQuery $cn 'SELECT p.name Nombre,m.definition Codigo,m.uses_ansi_nulls AnsiNulls,m.uses_quoted_identifier QuotedIdentifier FROM sys.procedures p JOIN sys.sql_modules m ON m.object_id=p.object_id WHERE p.schema_id=SCHEMA_ID(''dbo'');'
 if(@($defs.Rows | Where-Object {$names -contains $_.Nombre}).Count){throw 'Existen contratos previos 007; revisar manualmente.'}
 $checked=0
 foreach($file in @('005_Seguridad_QA.sql','006_Catalogos_QA.sql')){
  $text=[IO.File]::ReadAllText((Join-Path $cfg.Root ('sql/qa/'+$file)))
  foreach($m in [regex]::Matches($text,"(?s)EXEC sys.sp_executesql N'((?:[^']|'')*)';")){
   $expected=$m.Groups[1].Value.Replace("''","'")
   $name=[regex]::Match($expected,'CREATE OR ALTER PROCEDURE dbo\.(\w+)').Groups[1].Value
   $actual=@($defs.Rows | Where-Object {$_.Nombre -eq $name})
   if($actual.Count -ne 1){throw 'Dependencia 005/006 ausente.'}
   $eb=[regex]::Match($expected,'(?is)\bAS\s+BEGIN\b(.*)').Groups[1].Value
   $ab=[regex]::Match([string]$actual[0].Codigo,'(?is)\bAS\s+BEGIN\b(.*)').Groups[1].Value
   if(($eb -replace '\s+',' ').Trim() -cne ($ab -replace '\s+',' ').Trim()){throw 'Dependencia 005/006 distinta.'};$checked++
  }
 }
 if($checked -ne 15){throw 'Verificacion de dependencias incompleta.'}
 $folder=Join-Path $cfg.Root ('private/007-revision-'+[datetime]::UtcNow.ToString('yyyyMMdd-HHmmss-fffffff'))
 [void][IO.Directory]::CreateDirectory($folder)
 $snapshot=@($defs.Rows | ForEach-Object {[pscustomobject]@{Nombre=[string]$_.Nombre;Definicion=[string]$_.Codigo;AnsiNulls=[bool]$_.AnsiNulls;QuotedIdentifier=[bool]$_.QuotedIdentifier}})
 ConvertTo-Json -InputObject $snapshot -Depth 5 | Set-Content (Join-Path $folder 'definiciones-baseline.json') -Encoding UTF8
 ConvertTo-Json -InputObject @() | Set-Content (Join-Path $folder 'definiciones-previas-007.json') -Encoding UTF8
 [pscustomobject]@{SoloLectura=$true;ServidorVerificado=$true;Base=$cfg.Database;MarcaVerificada=$true;Tablas=15;Procedimientos=43;DependenciasVerificadas=15;Objetos007Ausentes=$true;PBKDF2=$false;ScriptSHA256=(Get-FileHash $path -Algorithm SHA256).Hash;Head=(& git -C $cfg.Root rev-parse HEAD)} | ConvertTo-Json | Set-Content (Join-Path $folder 'resultado.json') -Encoding UTF8
 Write-Output 'Revision 007 en lectura: QA verificada; 15 tablas/43 SP; 15 contratos de 005/006 coinciden; 007/008 ausentes; definiciones preservadas. No se aplico 007.'
}finally{$cn.Dispose()}
