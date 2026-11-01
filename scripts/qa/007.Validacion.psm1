# Validaciones compartidas y puras de 007; importar este modulo nunca conecta ni escribe SQL.
$ErrorActionPreference='Stop'
function Get-007PlanHash([string]$Source){
 $sha=[Security.Cryptography.SHA256]::Create()
 try{return ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($Source.Replace("`r`n","`n"))))).Replace('-','')}
 finally{$sha.Dispose()}
}
function Assert-007Plan([string]$Source){
 # Hash del texto SQL revisado, normalizado para LF/CRLF y sin BOM.
 if((Get-007PlanHash $Source) -cne 'D506BFCDAEF58541FA357FA6B16BE838FB783E55788E86E740BAE137E6978EC0'){throw '007 cambio respecto del alcance revisado. Detener y revisar; no ejecutar.'}
 $names=@([regex]::Matches($Source,'CREATE OR ALTER PROCEDURE dbo\.(\w+)') | ForEach-Object {$_.Groups[1].Value})
 if(($names -join ',') -cne 'sp_Compras_Registrar,sp_Compras_Historial,sp_Compras_Detalle'){throw 'Contratos 007 inesperados.'}
 foreach($batch in ([regex]::Split(($Source -replace '(?m)^:on error exit\s*',''),'(?im)^\s*GO\s*\r?$') | Where-Object {![string]::IsNullOrWhiteSpace($_)})){
  if(!$batch.Contains("IF DB_NAME()<>N'ForzaSuplementosDB_QA'") -or !$batch.Contains('Forza-QA-Aislada-v1') -or !$batch.Contains('$(QaExpectedServer)')){throw 'Lote 007 sin protecciones.'}
 }
 # Los INSERT/UPDATE estan permitidos solo en las definiciones, no en el despliegue.
 $ddl=[regex]::Replace($Source,"(?s)EXEC sys.sp_executesql N'((?:[^']|'')*)';",'') -replace '(?m)--.*$',''
 if($ddl -match '\b(INSERT|UPDATE|DELETE|MERGE|DROP|TRUNCATE|RESTORE|BACKUP|EXEC|EXECUTE|USE)\b' -or $ddl -match '\bSELECT\b[\s\S]*?\bINTO\b'){throw 'Operacion fuera del alcance estructural.'}
}
function Assert-007Destination([string]$Database,[string]$Server,[string]$ExpectedServer,[string]$Marker){
 if($Database -cne 'ForzaSuplementosDB_QA' -or [string]::IsNullOrWhiteSpace($ExpectedServer) -or $Server -ine $ExpectedServer -or $Marker -cne 'Forza-QA-Aislada-v1'){throw 'Destino 007 rechazado.'}
}
function Assert-007Baseline($State){
 if($State.Transacciones -ne 0 -or $State.OtrasTransacciones -ne 0 -or $State.Tablas -ne 15 -or $State.Procedimientos -ne 43 -or $State.FK -ne 13 -or $State.Indices -ne 23 -or $State.Checks -ne 9 -or $State.Objetos007 -ne 0 -or $State.Residuos007 -ne 0 -or $State.Seguridad -ne 0 -or $State.Credenciales -ne 0){throw 'Baseline incompatible o instalacion parcial 007. No se escribe.'}
}
function Get-007IntegrityQuery([string]$Table,[string]$Columns){
 # Table/Columns se obtienen exclusivamente de sys.* con QUOTENAME, no de entrada UI.
 return "SELECT HASHBYTES('SHA2_256',COALESCE(CONVERT(varbinary(max),(SELECT $Columns FROM $Table ORDER BY $Columns FOR XML RAW,BINARY BASE64)),CONVERT(varbinary(max),0x))) Huella;"
}
Export-ModuleMember -Function Get-007PlanHash,Assert-007Plan,Assert-007Destination,Assert-007Baseline,Get-007IntegrityQuery
