param([string]$ScriptDomPath = "$env:ProgramFiles\Microsoft Visual Studio\18\Community\Common7\IDE\Extensions\Microsoft\SQLCommon\Microsoft.SqlServer.TransactSql.ScriptDom.dll")
$ErrorActionPreference = 'Stop'
Add-Type -Path $ScriptDomPath
$parser = New-Object Microsoft.SqlServer.TransactSql.ScriptDom.TSql160Parser($true)
$failures = 0
$projectRoot = Split-Path $PSScriptRoot -Parent
Get-ChildItem (Join-Path $projectRoot 'sql\migrations\*.sql') | ForEach-Object {
    # ScriptDom analiza T-SQL; las directivas SQLCMD se verifican por separado.
    $sql = [IO.File]::ReadAllText($_.FullName) -replace '(?m)^:on error exit\s*',''
    $reader = New-Object IO.StringReader($sql)
    $errors = $null
    $null = $parser.Parse($reader,[ref]$errors)
    $reader.Dispose()
    if ($errors.Count) {
        $failures += $errors.Count
        Write-Output $_.Name
        $errors | Select-Object Line,Column,Message | Format-List
    } else { Write-Output "OK sintaxis: $($_.Name)" }
}
if ($failures) { throw "Errores de sintaxis SQL: $failures" }
Write-Output 'Solo analisis de sintaxis. No se ejecuto SQL ni se verifico enlace con tablas.'
