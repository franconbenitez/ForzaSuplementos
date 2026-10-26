param([switch]$AutorizarEscrituras)
$ErrorActionPreference='Stop'
if(!$AutorizarEscrituras){throw 'Se requiere autorizacion expresa para cambiar solo claves ficticias de QA.'}
Import-Module (Join-Path $PSScriptRoot 'QA.Common.psm1') -Force
$cn=Open-QaConnection
try {
    $secure=Read-Host 'Clave nueva para usuarios ficticios QA (no se registra ni se imprime)' -AsSecureString
    if($secure.Length -lt 6 -or $secure.Length -gt 100){throw 'Longitud requerida: entre 6 y 100 caracteres.'}
    $ptr=[Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        Assert-QaDestination $cn
        $cmd=$cn.CreateCommand()
        $cmd.CommandText='UPDATE u SET contrasena=@clave FROM dbo.Usuarios u JOIN qa.Fixtures f ON u.idUsuario IN (f.vendedor,f.otroVendedor,f.administrador,f.gerente);'
        $null=$cmd.Parameters.Add('@clave',[Data.SqlDbType]::VarChar,100)
        $cmd.Parameters['@clave'].Value=[Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
        $null=$cmd.ExecuteNonQuery();$cmd.Parameters.Clear();$cmd.Dispose()
    } finally {[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr);$secure.Dispose()}
    Write-Output 'Actualizadas solo claves ficticias de QA. No se mostraron ni guardaron en archivos.'
} finally {$cn.Dispose()}
