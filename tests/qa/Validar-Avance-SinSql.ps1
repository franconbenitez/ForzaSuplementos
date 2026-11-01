param([string]$ScriptDomPath)
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
. (Join-Path $root 'scripts/Resolver-ScriptDom.ps1')
Add-Type -Path (Resolve-ForzaScriptDom $ScriptDomPath)
$parser=New-Object Microsoft.SqlServer.TransactSql.ScriptDom.TSql160Parser($true)
$n=0
function Parse([string]$sql,[string]$name){
 $reader=New-Object IO.StringReader($sql);$errors=$null
 try{$null=$parser.Parse($reader,[ref]$errors)}finally{$reader.Dispose()}
 if($errors.Count){throw "$name : $($errors | Out-String)"}
 $script:n++
}
foreach($p in Get-ChildItem (Join-Path $root 'sql/qa/00[5-8]*.sql')){
 $s=[IO.File]::ReadAllText($p.FullName) -replace '(?m)^:on error exit\s*',''
 foreach($batch in [regex]::Split($s,'(?im)^\s*GO\s*\r?$')){
  if([string]::IsNullOrWhiteSpace($batch)){continue}
  if(!$batch.Contains("IF DB_NAME()<>N'ForzaSuplementosDB_QA'") -or !$batch.Contains('Forza-QA-Aislada-v1') -or !$batch.Contains('$(QaExpectedServer)')){throw "Lote sin guardas: $($p.Name)"}
  Parse $batch $p.Name
  foreach($m in [regex]::Matches($batch,"EXEC sys.sp_executesql N'((?:[^']|'')*)';",'Singleline')){Parse $m.Groups[1].Value.Replace("''", "'") ($p.Name+' SP interno')}
 }
 Write-Output "OK: sintaxis externa/interna y guardas $($p.Name)"
}
$fixture=[IO.File]::ReadAllText((Join-Path $root 'tests/qa/Avance_Transaccional_QA.sql')) -replace '(?m)^:on error exit\s*',''
Parse $fixture 'Fixture transaccional propuesto'
$negativos=[IO.File]::ReadAllText((Join-Path $root 'tests/qa/Negativos_Compras_Inventario_Preparados.sql')) -replace '(?m)^:on error exit\s*',''
Parse $negativos 'Negativos preparados'
foreach($name in @('Catalogos_006_Rollback_Preparado.sql','Compras_007_Rollback_Preparado.sql','Ventas_Caja_008_Rollback_Preparado.sql','Negativos_Ventas_Caja_008_Preparados.sql')){
 $script=[IO.File]::ReadAllText((Join-Path $root ('tests/qa/'+$name))) -replace '(?m)^:on error exit\s*',''
 if(!$script.Contains('Forza-QA-Aislada-v1') -or !$script.Contains('@@TRANCOUNT<>0') -or !$script.Contains('AutorizarEnsayo')){throw 'Fixture sin guardas.'}
 Parse $script $name
}
Write-Output "TOTAL LOTES/PROCEDIMIENTOS ANALIZADOS: $n. Sin ejecucion SQL; enlace contra tablas pendiente."
