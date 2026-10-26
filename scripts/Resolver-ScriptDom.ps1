function Resolve-ForzaScriptDom([string]$ExplicitPath) {
    if($ExplicitPath){
        if(!(Test-Path -LiteralPath $ExplicitPath -PathType Leaf)){throw 'No se encuentra ScriptDom en la ruta indicada.'}
        return (Resolve-Path -LiteralPath $ExplicitPath).Path
    }
    $locators=@(
        (Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'),
        (Join-Path $env:ProgramFiles 'Microsoft Visual Studio\Installer\vswhere.exe')
    )
    foreach($locator in $locators){
        if(Test-Path -LiteralPath $locator){
            $found=@(& $locator -products '*' -find '**\Microsoft.SqlServer.TransactSql.ScriptDom.dll')
            foreach($path in $found){if(Test-Path -LiteralPath $path -PathType Leaf){return $path}}
        }
    }
    throw 'No se encontro ScriptDom. Instalar herramientas SQL de Visual Studio o indicar -ScriptDomPath.'
}
