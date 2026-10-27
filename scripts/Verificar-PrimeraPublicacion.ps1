param([switch]$ConsultarGitHub)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
if(!(Get-Command git -ErrorAction SilentlyContinue)){throw 'Instalar Git y abrir una terminal nueva.'}
git --version
$marker=@(& git -C $root ls-files -- docs/SANEAMIENTO_GITHUB.md)
if($LASTEXITCODE -ne 0 -or $marker.Count -ne 1){throw 'Usar exclusivamente la copia saneada ForzaSuplementos_GitHub o su clon; no Desarrollo_Codex.'}
$changes=@(& git -C $root status --porcelain)
if($LASTEXITCODE -ne 0 -or $changes.Count){throw 'El arbol debe estar limpio. Conservar y revisar cambios antes de publicar.'}
$paths=@(& git -C $root ls-files)
if($LASTEXITCODE -ne 0){throw 'No se pudo inspeccionar el indice.'}
foreach($path in $paths){
    if($path -match '(?i)(^|/)(bin|obj|\.vs|private)/|^config/qa\.config$|\.(bak|mdf|ldf|ndf|trn|bundle|pfx|p12|key|exe|dll)$'){
        throw 'Hay archivos locales/privados versionados. Revisar antes de publicar.'
    }
}
$refs=@(& git -C $root for-each-ref --format='%(refname)')
if($LASTEXITCODE -ne 0 -or $refs.Count -ne 1 -or $refs[0] -cne 'refs/heads/master'){
    throw 'Esta comprobacion inicial requiere exclusivamente la rama master revisada. No elimina ni cambia referencias.'
}
$remotes=@(& git -C $root remote)
if($LASTEXITCODE -ne 0){throw 'No se pudieron inspeccionar los remotos.'}
if($remotes.Count){
    if($remotes.Count -ne 1 -or $remotes[0] -cne 'origin'){throw 'Remotos inesperados: revisar sin cambiarlos automaticamente.'}
    $urls=@(& git -C $root remote get-url --all origin)
    $pushUrls=@(& git -C $root remote get-url --push --all origin)
    $allowed=@('https://github.com/franconbenitez/ForzaSuplementos.git')
    if($LASTEXITCODE -ne 0 -or $urls.Count -ne 1 -or $pushUrls.Count -ne 1 -or $urls[0] -cnotin $allowed -or $pushUrls[0] -cnotin $allowed){throw 'URL de lectura o envio no autorizada.'}
}
Write-Output 'Preparacion local aprobada. Complementar con auditoria completa de historial; este control no detecta todos los secretos.'
$gh=Get-Command gh -ErrorAction SilentlyContinue
if(!$ConsultarGitHub){
    if(!$gh){Write-Output 'GitHub CLI no esta disponible en PATH: instalacion/autenticacion pendientes.'}
    Write-Output 'No se consulto GitHub ni se comprobo la privacidad remota. No se creo remoto ni se envio contenido.'
    return
}
if(!$gh){throw 'Instalar GitHub CLI, abrir una terminal nueva y ejecutar gh auth login --hostname github.com --git-protocol https --web.'}
$login=& gh api user --hostname github.com --jq .login
if($LASTEXITCODE -ne 0 -or $login -cne 'franconbenitez'){throw 'Sesion no verificada como franconbenitez. No publicar.'}
$json=& gh api repos/franconbenitez/ForzaSuplementos --hostname github.com
if($LASTEXITCODE -ne 0){throw 'No se pudo verificar el repositorio privado. No publicar.'}
$repo=$json | ConvertFrom-Json
if($repo.full_name -cne 'franconbenitez/ForzaSuplementos' -or $repo.private -ne $true){throw 'Repositorio incorrecto o no privado. No publicar.'}
Write-Output 'Cuenta y destino PRIVATE verificados en lectura. La publicacion sigue requiriendo autorizacion; no se ejecuto push.'
