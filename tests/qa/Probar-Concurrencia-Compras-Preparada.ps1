# PREPARADO, NO EJECUTADO. Dos compras sobre un producto ficticio; ambas transacciones externas se revierten.
param([switch]$AutorizarEnsayo,[int]$IdProveedor)
$ErrorActionPreference='Stop'
if(!$AutorizarEnsayo -or $IdProveedor -le 0){throw 'Requiere autorizacion especifica de concurrencia QA y proveedor ficticio existente. No se conecta.'}
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Import-Module (Join-Path $root 'scripts/qa/QA.Common.psm1') -Force
$a=Open-QaConnection;$b=$null;$ta=$null;$tb=$null;$ca=$null;$cb=$null
function Stock($cn,$tx,$id){$c=$cn.CreateCommand();$c.Transaction=$tx;$c.CommandText='SELECT stock FROM dbo.Productos WHERE idProducto=@id';[void]$c.Parameters.AddWithValue('@id',$id);try{return [int]$c.ExecuteScalar()}finally{$c.Dispose()}}
function Buy($cn,$tx,$actor,$product){$c=$cn.CreateCommand();$c.Transaction=$tx;$c.CommandType='StoredProcedure';$c.CommandText='dbo.sp_Compras_Registrar';$c.CommandTimeout=15;[void]$c.Parameters.AddWithValue('@idActor',$actor);[void]$c.Parameters.AddWithValue('@idProveedor',$IdProveedor);[void]$c.Parameters.AddWithValue('@operacion',[guid]::NewGuid());$p=$c.Parameters.Add('@detalles',[Data.SqlDbType]::Xml);$p.Value='<detalles><item producto="'+$product+'" cantidad="1" costo="1.00" /></detalles>';return $c}
try{
 $b=Open-QaConnection
 $ref=(Invoke-QaQuery $a 'SELECT TOP(1) gerente,productoHistorico FROM qa.Fixtures;').Rows[0]
 $p=Invoke-QaQuery $a "SELECT idProveedor FROM dbo.Proveedores WHERE idProveedor=@id AND activo=1 AND nombre LIKE N'QA %';" @{'@id'=$IdProveedor}
 if($p.Rows.Count -ne 1){throw 'Proveedor no es ficticio identificado QA; no se escribe.'}
 $stock=Stock $a $null $ref.productoHistorico
 if($stock -eq [int]::MaxValue){throw 'Stock excederia limite; no se escribe.'}
 $ta=$a.BeginTransaction();$tb=$b.BeginTransaction()
 $ca=Buy $a $ta $ref.gerente $ref.productoHistorico;[void]$ca.ExecuteNonQuery()
 $cb=Buy $b $tb $ref.gerente $ref.productoHistorico;$pending=$cb.BeginExecuteNonQuery()
 Start-Sleep -Milliseconds 300
 if($pending.IsCompleted){throw 'Se esperaba bloqueo por la primera transaccion.'}
 $ta.Rollback();$ta.Dispose();$ta=$null
 [void]$cb.EndExecuteNonQuery($pending)
 if((Stock $b $tb $ref.productoHistorico) -ne $stock+1){throw 'Segunda compra no observa stock consistente.'}
 $tb.Rollback();$tb.Dispose();$tb=$null
 if((Stock $a $null $ref.productoHistorico) -ne $stock){throw 'Rollback no conserva stock; DETENER.'}
 Write-Output 'Concurrencia y rollback aprobados (solo si esta ejecucion termina correctamente).'
}finally{if($ca){$ca.Dispose()};if($cb){$cb.Dispose()};if($ta){try{$ta.Rollback()}finally{$ta.Dispose()}};if($tb){try{$tb.Rollback()}finally{$tb.Dispose()}};$a.Dispose();if($b){$b.Dispose()}}
