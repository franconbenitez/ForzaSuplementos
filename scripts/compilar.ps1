param([ValidateSet('Debug', 'Release')][string]$Configuration = 'Debug')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$solution = Join-Path $projectRoot 'ForzaSuplementos\ForzaSuplementos\ForzaSuplementos.slnx'
$locator = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
if (!(Test-Path $locator)) { $locator = Join-Path $env:ProgramFiles 'Microsoft Visual Studio\Installer\vswhere.exe' }
if (!(Test-Path $locator)) { throw 'No se encuentra vswhere. Verificar la instalación de Visual Studio.' }
$msbuild = & $locator -latest -products Microsoft.VisualStudio.Product.Community Microsoft.VisualStudio.Product.Professional Microsoft.VisualStudio.Product.Enterprise Microsoft.VisualStudio.Product.BuildTools -requires Microsoft.Component.MSBuild -find 'MSBuild\**\Bin\MSBuild.exe' | Select-Object -First 1
if (!$msbuild) { throw 'No se encuentra MSBuild de Visual Studio.' }
& $msbuild $solution /t:Rebuild "/p:Configuration=$Configuration" /nologo /v:minimal /nr:false /p:UseSharedCompilation=false
exit $LASTEXITCODE
