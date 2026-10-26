param([string]$ScriptDomPath)
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
. (Join-Path $root 'scripts\Resolver-ScriptDom.ps1')
Add-Type -Path (Resolve-ForzaScriptDom $ScriptDomPath)
$parser=New-Object Microsoft.SqlServer.TransactSql.ScriptDom.TSql160Parser($true)
$failures=0
foreach($file in Get-ChildItem (Join-Path $root 'sql\qa\*.sql'),(Join-Path $root 'sql\migrations\*.sql')){
    $source=[IO.File]::ReadAllText($file.FullName)
    $parts=@($source -replace '(?m)^:on error exit\s*','')
    foreach($match in [regex]::Matches($source,"(?s)EXEC sys\.sp_executesql N'((?:''|[^'])*)';")){$parts+=,$match.Groups[1].Value.Replace("''", "'")}
    foreach($part in $parts){
        $reader=New-Object IO.StringReader($part);$errors=$null;$null=$parser.Parse($reader,[ref]$errors);$reader.Dispose()
        if($errors.Count){$failures+=$errors.Count;Write-Output $file.Name;$errors | Select-Object Line,Column,Message | Format-List}
    }
    if($file.Directory.Name -eq 'qa'){
        if($source -match '(?i)\bForzaSuplementosDB\b|\bDROP\s+(DATABASE|TABLE)|\bTRUNCATE\b|\bRESTORE\s+DATABASE|\bBACKUP\s+DATABASE|\.mdf\b|\.ldf\b|\.bak\b'){throw "Referencia peligrosa en $($file.Name)"}
        foreach($batch in [regex]::Split($source,'(?im)^\s*GO\s*\r?$')){
            if(![string]::IsNullOrWhiteSpace($batch) -and $batch -notmatch "IF DB_NAME\(\)<>"){throw "Lote sin guarda en $($file.Name)"}
        }
    }
    Write-Output "OK sintaxis/guardas: $($file.Name)"
}
if($failures){throw "Errores SQL: $failures"}
foreach($file in Get-ChildItem (Join-Path $root 'scripts\qa'),(Join-Path $root 'tests\qa'),(Join-Path $root 'sql\qa') -File -Recurse | Where-Object {$_.Extension -in '.ps1','.psm1'}){
    $tokens=$null;$errors=$null;$null=[Management.Automation.Language.Parser]::ParseFile($file.FullName,[ref]$tokens,[ref]$errors)
    if($errors.Count){throw ($file.Name+': '+($errors.Message -join '; '))}
}
foreach($name in @('001_Caja_Pagos','002_Caja_Procedimientos','003_Ventas_Caja_Stock')){
    $hash=(Get-FileHash (Join-Path $root "sql\migrations\$name.sql") -Algorithm SHA256).Hash
    $copy=[IO.File]::ReadAllText((Join-Path $root "sql\qa\${name}_QA.sql"))
    if($copy -notmatch "SOURCE_SHA256: $hash"){throw 'Copias QA desactualizadas. Regenerar offline.'}
}
$contracts=Get-Content (Join-Path $PSScriptRoot 'contratos.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$allSql=(Get-Content (Join-Path $root 'sql\migrations\002_Caja_Procedimientos.sql'),(Join-Path $root 'sql\migrations\003_Ventas_Caja_Stock.sql') -Raw) -join "`n"
$dal=(Get-Content (Join-Path $root 'ForzaSuplementos\ForzaSuplementos\ForzaSuplementos.Datos\CajaDAL.vb'),(Join-Path $root 'ForzaSuplementos\ForzaSuplementos\ForzaSuplementos.Datos\VentaDAL.vb') -Raw) -join "`n"
foreach($contract in $contracts){
    $pattern='(?is)CREATE\s+OR\s+ALTER\s+PROCEDURE\s+dbo\.'+[regex]::Escape($contract.procedure)+'\s+(.*?)\s+AS\s+BEGIN'
    $match=[regex]::Match($allSql,$pattern)
    if(!$match.Success -or !$dal.Contains('dbo.'+$contract.procedure)){throw 'Procedimiento ausente del contrato o DAL.'}
    $actual=@([regex]::Matches($match.Groups[1].Value,'(?i)(@\w+)\s+(int|date|xml|varchar|decimal)(?:\((\d+)(?:,(\d+))?\))?\s*(OUTPUT)?'))
    if($actual.Count -ne $contract.parameters.Count){throw 'Parametros incompatibles.'}
    for($i=0;$i -lt $actual.Count;$i++){
        $p=$contract.parameters[$i];$a=$actual[$i]
        if($a.Groups[1].Value -ne $p.name -or $a.Groups[2].Value -ne $p.type -or [int]('0'+$a.Groups[3].Value) -ne $p.size -or [int]('0'+$a.Groups[4].Value) -ne $p.scale -or $a.Groups[5].Success -ne $p.output -or !$dal.Contains('"'+$p.name+'"')){throw ('Contrato incompatible: '+$contract.procedure+$p.name)}
    }
    Write-Output "OK contrato declarado/DAL: $($contract.procedure)"
}
$out=Join-Path $root 'ForzaSuplementos\ForzaSuplementos\ForzaSuplementos.Presentacion\bin\Debug'
$null=[Reflection.Assembly]::LoadFrom((Join-Path $out 'ForzaSuplementos.Datos.dll'))
$oldEnv=$env:FORZA_ENTORNO;$oldConfig=$env:FORZA_QA_CONFIG
function Reject-BeforeSql([scriptblock]$action){
    $rejected=$false
    try{& $action | Out-Null}catch{$e=$_.Exception;while($e.InnerException){$e=$e.InnerException};if($e -isnot [ApplicationException]){throw};$rejected=$true}
    if(!$rejected){throw 'No fallo de forma cerrada.'}
}
try{
    Remove-Item Env:\FORZA_ENTORNO -ErrorAction SilentlyContinue
    $cn=[ForzaSuplementos.Datos.Conexion]::ObtenerConexion()
    try{if($cn.Database -ne 'ForzaSuplementosDB' -or $cn.State -ne 'Closed'){throw 'Se cambio la conexion habitual.'}}finally{$cn.Dispose()}
    $env:FORZA_ENTORNO='INVALIDO';Reject-BeforeSql {[ForzaSuplementos.Datos.Conexion]::ObtenerConexion()}
    $env:FORZA_ENTORNO='QA';$env:FORZA_QA_CONFIG='';Reject-BeforeSql {[ForzaSuplementos.Datos.Conexion]::ObtenerConexion()}
    $dir=Join-Path $root 'tests\artifacts';$null=[IO.Directory]::CreateDirectory($dir)
    $bad=Join-Path $dir 'qa-rechazada.config';[IO.File]::WriteAllText($bad,'<qa base="ForzaSuplementosDB" marca="Forza-QA-Aislada-v1" />')
    $env:FORZA_QA_CONFIG=$bad;Reject-BeforeSql {[ForzaSuplementos.Datos.Conexion]::ObtenerConexion()}
}finally{$env:FORZA_ENTORNO=$oldEnv;$env:FORZA_QA_CONFIG=$oldConfig}
Write-Output 'OK: conexion habitual conservada y tres rechazos QA previos a SQL. Ninguna escritura SQL ejecutada.'
