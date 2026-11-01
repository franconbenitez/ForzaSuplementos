# Validaciones compartidas y puras de 008; importar este modulo nunca conecta ni escribe SQL.
$ErrorActionPreference='Stop'
function Get-008PlanHash([string]$Source){
 $sha=[Security.Cryptography.SHA256]::Create()
 try{return ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($Source.Replace("`r`n","`n"))))).Replace('-','')}
 finally{$sha.Dispose()}
}
function Assert-008Plan([string]$Source){
 if((Get-008PlanHash $Source) -cne 'AFEBAF6E4B68809B6897313BE876129328CE96186514F342F27E7A2ED09F7486'){throw '008 cambio respecto del alcance revisado; no ejecutar.'}
 $names=@([regex]::Matches($Source,'CREATE OR ALTER PROCEDURE dbo\.(\w+)') | ForEach-Object {$_.Groups[1].Value})
 if(($names -join ',') -cne 'sp_Inventario_Stock,sp_Inventario_Historial,sp_Inventario_Minimo,sp_Inventario_Ajustar,sp_Compras_Registrar,sp_Ventas_RegistrarConCaja,sp_Productos_Modificar,sp_Productos_Insertar'){throw 'Contratos 008 inesperados.'}
 foreach($batch in ([regex]::Split(($Source -replace '(?m)^:on error exit\s*',''),'(?im)^\s*GO\s*\r?$') | Where-Object {![string]::IsNullOrWhiteSpace($_)})){
  if(!$batch.Contains("IF DB_NAME()<>N'ForzaSuplementosDB_QA'") -or !$batch.Contains('Forza-QA-Aislada-v1') -or !$batch.Contains('$(QaExpectedServer)')){throw 'Lote 008 sin protecciones.'}
 }
 $ddl=[regex]::Replace($Source,"(?s)EXEC sys.sp_executesql N'((?:[^']|'')*)';",'') -replace '(?m)--.*$',''
 if($ddl -match '\b(INSERT|UPDATE|DELETE|MERGE|DROP|TRUNCATE|RESTORE|BACKUP|EXEC|EXECUTE|USE)\b'){throw 'Operacion ajena al alcance estructural 008.'}
}
function Assert-008Destination([string]$Database,[string]$Server,[string]$ExpectedServer,[string]$Marker){
 if($Database -cne 'ForzaSuplementosDB_QA' -or [string]::IsNullOrWhiteSpace($ExpectedServer) -or $Server -ine $ExpectedServer -or $Marker -cne 'Forza-QA-Aislada-v1'){throw 'Destino 008 rechazado.'}
}
function Assert-008Baseline($State){
 if($State.Transacciones -ne 0 -or $State.OtrasTransacciones -ne 0 -or $State.Tablas -ne 17 -or $State.Procedimientos -ne 46 -or $State.FK -ne 17 -or $State.Indices -ne 28 -or $State.Checks -ne 13 -or $State.Objetos008 -ne 0 -or $State.Residuos008 -ne 0 -or $State.Columna008 -isnot [DBNull] -or $State.Seguridad -ne 0 -or $State.Credenciales -ne 0){throw 'Baseline incompatible o instalacion parcial 008; no se escribe.'}
}
function Get-008IntegrityQuery([string]$Table,[string]$Columns){
 # Table/Columns se obtienen exclusivamente de sys.* con QUOTENAME, no de entrada UI.
 return "SELECT HASHBYTES('SHA2_256',COALESCE(CONVERT(varbinary(max),(SELECT $Columns FROM $Table ORDER BY $Columns FOR XML RAW,BINARY BASE64)),CONVERT(varbinary(max),0x))) Huella;"
}
function Get-008ProcedureContract([string]$Definition){
 $text=$Definition -replace '(?m)--.*$',''
 $m=[regex]::Match($text,'(?is)\b(?:CREATE(?:\s+OR\s+ALTER)?|ALTER)\s+PROCEDURE\s+(?:\[?dbo\]?\.)?\[?(?<name>\w+)\]?\s*(?<parameters>.*?)\s+AS\s+BEGIN\b')
 if(!$m.Success){throw 'Cabecera de procedimiento no reconocida; revisar.'}
 $pattern='(?is)@(?<name>\w+)\s+(?<type>int|varchar|nvarchar|decimal|date|uniqueidentifier|xml)\b(?<args>\s*\(\s*\d+\s*(?:,\s*\d+\s*)?\))?\s*(?:=\s*(?<default>NULL))?\s*(?<output>OUTPUT|OUT)?'
 $parameters=$m.Groups['parameters'].Value
 $parts=@([regex]::Matches($parameters,$pattern))
 if(!$parts.Count -or ([regex]::Replace($parameters,$pattern,'') -replace '[,\s]','') -ne ''){throw 'Parametros no reconocidos; revisar contrato sin asumir compatibilidad.'}
 $signature=@($parts | ForEach-Object {'@'+$_.Groups['name'].Value.ToLowerInvariant()+':'+$_.Groups['type'].Value.ToLowerInvariant()+($_.Groups['args'].Value -replace '\s','')+$(if($_.Groups['default'].Success){'=null'}else{''})+$(if($_.Groups['output'].Success){':output'}else{''})}) -join ','
 return [pscustomobject]@{Nombre=$m.Groups['name'].Value;Firma=$signature;Cantidad=$parts.Count}
}
Export-ModuleMember -Function Get-008PlanHash,Assert-008Plan,Assert-008Destination,Assert-008Baseline,Get-008IntegrityQuery,Get-008ProcedureContract
