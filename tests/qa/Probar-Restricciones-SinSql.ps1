# Regresion del error SQL Server 8141. Solo AST/semantica offline; sin DDL ni conexiones.
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Import-Module (Join-Path $root 'scripts/qa/Validar-Restricciones.psm1') -Force -DisableNameChecking
$n=0
function Accept($name,$sql){Assert-ForzaColumnChecks $sql;$script:n++;Write-Output "OK: $name"}
function Reject($name,$sql){$rejected=$false;try{Assert-ForzaColumnChecks $sql}catch{if($_.Exception.ToString() -notmatch 'CHECK de columna'){throw};$rejected=$true};if(!$rejected){throw $name};$script:n++;Write-Output "OK: $name"}
Reject 'Reproduce error original: subtotal referencia cantidad/costo' 'CREATE TABLE dbo.T(cantidad int,costo decimal(18,2),subtotal decimal(18,2) CONSTRAINT CK_Subtotal CHECK(subtotal=cantidad*costo));'
Reject 'CHECK anonimo de columna cruzada rechazado' 'CREATE TABLE dbo.T(a int,b int CHECK(b>a));'
Reject 'Identificadores delimitados y funciones no ocultan referencia' 'CREATE TABLE dbo.T([Cantidad] int,[Subtotal] decimal(18,2) CHECK(ABS([Subtotal])>CONVERT(decimal(18,2),[Cantidad])));'
Reject 'ALTER ADD columna tambien se inspecciona' 'ALTER TABLE dbo.T ADD nuevo int CONSTRAINT CK_Nuevo CHECK(nuevo>anterior);'
Reject 'Tabla variable con CHECK cruzado rechazada' 'DECLARE @t TABLE(a int,b int CHECK(b>a));'
Accept 'CHECK de columna propia valido' 'CREATE TABLE dbo.T(a int CONSTRAINT CK_A CHECK(a>0));'
Accept 'CHECK de tabla con varias columnas valido' 'CREATE TABLE dbo.T(a int,b int,CONSTRAINT CK_AB CHECK(b>a));'
Accept 'DEFAULT no se confunde con CHECK de columna' 'CREATE TABLE dbo.T(a int DEFAULT(0),b int,CONSTRAINT CK_AB CHECK(b>=a));'
Accept 'Funciones y conversiones de la misma columna validas' 'CREATE TABLE dbo.T(a int CHECK(ABS(CONVERT(bigint,a))<100));'
Accept 'Nombres entre corchetes y mayusculas equivalentes' 'CREATE TABLE dbo.T([Cantidad] int CHECK([cantidad]>0));'
Reject 'Se inspecciona DDL dentro de SQL dinamico preparado' "EXEC sys.sp_executesql N'CREATE TABLE dbo.T(a int,b int CHECK(b>a));';"
foreach($file in @('007_Compras_QA.sql','008_Inventario_QA.sql')){
 Accept ('Migracion real sin CHECK cruzado de columna: '+$file) ([IO.File]::ReadAllText((Join-Path $root ('sql/qa/'+$file))))
}
Write-Output "TOTAL RESTRICCIONES OFFLINE: $n comprobaciones aprobadas. No se ejecuta SQL."
