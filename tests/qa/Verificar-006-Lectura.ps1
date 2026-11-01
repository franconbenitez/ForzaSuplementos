# Verificaciones exclusivamente de lectura despues de 006; no ejecuta Guardar/Asociar.
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Import-Module (Join-Path $root 'scripts/qa/QA.Common.psm1') -Force
$cn=Open-QaConnection
try{
 $t=Invoke-QaQuery $cn "SELECT @@TRANCOUNT Transacciones,(SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped=0) Tablas,(SELECT COUNT(*) FROM sys.procedures WHERE is_ms_shipped=0) Procedimientos,(SELECT activa FROM dbo.SeguridadEstado WHERE id=1) PBKDF2,(SELECT COUNT(*) FROM dbo.CredencialesUsuario) Credenciales;"
 $r=$t.Rows[0]
 if($r.Transacciones -ne 0 -or $r.Tablas -ne 15 -or $r.Procedimientos -ne 43 -or $r.PBKDF2 -or $r.Credenciales -ne 0){throw 'Estado 006 inesperado.'}
 $c=Invoke-QaQuery $cn "SELECT (SELECT COUNT(*) FROM sys.columns WHERE object_id=OBJECT_ID('dbo.Productos') AND name='idMarca' AND TYPE_NAME(user_type_id)='int' AND is_nullable=1) Columna,(SELECT COUNT(*) FROM sys.foreign_keys f JOIN sys.foreign_key_columns k ON k.constraint_object_id=f.object_id WHERE f.name='FK_Productos_Marca' AND f.parent_object_id=OBJECT_ID('dbo.Productos') AND f.referenced_object_id=OBJECT_ID('dbo.Marcas') AND COL_NAME(k.parent_object_id,k.parent_column_id)='idMarca' AND COL_NAME(k.referenced_object_id,k.referenced_column_id)='idMarca' AND f.is_disabled=0 AND f.is_not_trusted=0) Relacion,(SELECT COUNT(*) FROM sys.default_constraints WHERE name IN('DF_Proveedores_Activo','DF_Marcas_Activo') AND definition='((1))') Defaults;"
 if($c.Rows[0].Columna -ne 1 -or $c.Rows[0].Relacion -ne 1 -or $c.Rows[0].Defaults -ne 2){throw 'Columna relacion o defaults distintos.'}
 foreach($module in @('Catalogos','Compras','Inventario')){
  $q=$cn.CreateCommand();$q.CommandType='StoredProcedure';$q.CommandText='dbo.sp_Comercial_Estado'
  [void]$q.Parameters.Add('@modulo',[Data.SqlDbType]::VarChar,30);$q.Parameters['@modulo'].Value=$module
  try{$available=[bool]$q.ExecuteScalar();if($available -ne ($module -eq 'Catalogos')){throw 'Disponibilidad incorrecta.'}}finally{$q.Dispose()}
 }
 $actor=(Invoke-QaQuery $cn 'SELECT gerente FROM qa.Fixtures;').Rows[0].gerente
 foreach($type in @('Proveedores','Marcas')){
  $q=$cn.CreateCommand();$q.CommandType='StoredProcedure';$q.CommandText='dbo.sp_'+$type+'_Buscar'
  [void]$q.Parameters.Add('@idActor',[Data.SqlDbType]::Int);$q.Parameters['@idActor'].Value=$actor
  [void]$q.Parameters.Add('@filtro',[Data.SqlDbType]::NVarChar,100);$q.Parameters['@filtro'].Value=''
  try{$reader=$q.ExecuteReader();try{if($reader.Read()){throw 'Tabla de catalogo no vacia tras despliegue estructural.'}}finally{$reader.Dispose()}}finally{$q.Dispose()}
 }
 Write-Output '006 lectura: 15 tablas/43 SP, transacciones previas 0, FK y columna nullable correctas, defaults 1, catalogos disponibles y busquedas vacias; 007-008 pendientes; PBKDF2 inactivo.'
}finally{$cn.Dispose()}
