param([switch]$AutorizarEscrituras,[switch]$Reanudar)
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'QA.Common.psm1') -Force
$cfg=Get-QaConfig
$master=Open-QaConnection -Master
try {
    $cmd=$master.CreateCommand();$cmd.CommandText="SELECT DB_ID(N'ForzaSuplementosDB_QA');";$exists=$cmd.ExecuteScalar() -isnot [DBNull];$cmd.Dispose()
    Write-Output "Destino verificado en lectura: $($cfg.ExpectedServer) / master. QA existente: $exists"
} finally {$master.Dispose()}
if(!$AutorizarEscrituras){ Write-Output 'Solo verificacion. No se ejecuto CREATE, migraciones ni datos ficticios. Requiere autorizacion expresa y -AutorizarEscrituras.';return }
if($exists -and !$Reanudar){throw 'QA ya existe. No se borra ni reemplaza. Revisar y usar -Reanudar solo si corresponde.'}
if($Reanudar -and !$exists){throw 'No existe QA para reanudar.'}
function Run-SqlFile([string]$File,[string]$Database,[switch]$WithoutMarker) {
    $probe=Open-QaConnection -Master:($Database -eq 'master') -WithoutMarker:$WithoutMarker
    try { Assert-QaDestination $probe -Master:($Database -eq 'master') -WithoutMarker:$WithoutMarker } finally {$probe.Dispose()}
    & sqlcmd -S $cfg.Server -d $Database -E -C -b -r 1 -v "QaExpectedServer=$($cfg.ExpectedServer)" -i (Join-Path $cfg.Root "sql\qa\$File")
    if($LASTEXITCODE -ne 0){throw "Fallo $File. No se ejecutaran mas archivos."}
}
if(!$Reanudar){
    Run-SqlFile '000_CrearBase_QA.sql' 'master'
    Run-SqlFile '010_EstructuraOriginal_QA.sql' $cfg.Database -WithoutMarker
}
Run-SqlFile '020_DatosFicticios_QA.sql' $cfg.Database
foreach($file in @('001_Caja_Pagos_QA.sql','002_Caja_Procedimientos_QA.sql','003_Ventas_Caja_Stock_QA.sql')){Run-SqlFile $file $cfg.Database}
Write-Output 'QA preparada. La aplicacion original y su base no fueron destinos de estos scripts.'
