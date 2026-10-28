# PREPARADO, NO EJECUTADO. Solo credenciales de cuentas qa_* referenciadas por qa.Fixtures; rollback obligatorio.
param([switch]$AutorizarFixtures)
$ErrorActionPreference='Stop'
if(!$AutorizarFixtures){throw 'Falta autorizacion especifica para ensayo de seguridad QA. No se conecta.'}
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Import-Module (Join-Path $root 'scripts/qa/QA.Common.psm1') -Force
$out=Join-Path $root 'ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.Presentacion/bin/Debug'
foreach($l in @('Entidades','Datos','Negocio')){[void][Reflection.Assembly]::LoadFrom((Join-Path $out "ForzaSuplementos.$l.dll"))}
$cn=Open-QaConnection;$tx=$null
try{
 $ready=Invoke-QaQuery $cn "SELECT CASE WHEN OBJECT_ID('dbo.sp_Seguridad_Credencial','P') IS NOT NULL THEN 1 ELSE 0 END listo;"
 if(!$ready.Rows[0].listo){throw 'BLOQUEADO: 005 no desplegada; no se escribe.'}
 $ids=(Invoke-QaQuery $cn 'SELECT TOP(1) administrador,vendedor FROM qa.Fixtures;').Rows[0]
 $safe=Invoke-QaQuery $cn "SELECT COUNT(*) cantidad FROM dbo.Usuarios WHERE (idUsuario=@a AND usuario='qa_admin') OR (idUsuario=@v AND usuario='qa_vendedor');" @{'@a'=[int]$ids.administrador;'@v'=[int]$ids.vendedor}
 if($safe.Rows[0].cantidad -ne 2){throw 'Fixtures no coinciden exactamente; no se escribe.'}
 $count=(Invoke-QaQuery $cn 'SELECT COUNT(*) cantidad FROM dbo.CredencialesUsuario;').Rows[0].cantidad
 $state=(Invoke-QaQuery $cn 'SELECT activa FROM dbo.SeguridadEstado WHERE id=1;').Rows[0].activa
 $clave=[guid]::NewGuid().ToString();$hash=[ForzaSuplementos.Negocio.ClaveSegura]::Crear($clave)
 $tx=$cn.BeginTransaction();$cmd=$cn.CreateCommand();$cmd.Transaction=$tx
 $cmd.CommandText=@"
UPDATE dbo.SeguridadEstado SET activa=1 WHERE id=1;
UPDATE dbo.CredencialesUsuario SET formato=@hash WHERE idUsuario=@v;
IF @@ROWCOUNT=0 INSERT dbo.CredencialesUsuario(idUsuario,formato) VALUES(@v,@hash);
DECLARE @resultado TABLE(idUsuario int,idPerfil int,nombrePerfil varchar(30),nombre varchar(50),apellido varchar(50),formato varchar(256));
INSERT @resultado EXEC dbo.sp_Seguridad_Credencial 'qa_vendedor';
IF NOT EXISTS(SELECT 1 FROM @resultado WHERE idUsuario=@v AND formato=@hash) THROW 51920,'Contrato de credencial invalido.',1;
EXEC dbo.sp_Seguridad_Cambiar @a,@v,@hash,NULL;
IF NOT EXISTS(SELECT 1 FROM dbo.CredencialesUsuario WHERE idUsuario=@v AND formato=@hash) THROW 51921,'Restablecimiento invalido.',1;
"@
 [void]$cmd.Parameters.AddWithValue('@a',[int]$ids.administrador);[void]$cmd.Parameters.AddWithValue('@v',[int]$ids.vendedor);[void]$cmd.Parameters.Add('@hash',[Data.SqlDbType]::VarChar,256);$cmd.Parameters['@hash'].Value=$hash
 try{[void]$cmd.ExecuteNonQuery()}finally{$cmd.Dispose()}
 $tx.Rollback();$tx.Dispose();$tx=$null
 if((Invoke-QaQuery $cn 'SELECT COUNT(*) cantidad FROM dbo.CredencialesUsuario;').Rows[0].cantidad -ne $count -or (Invoke-QaQuery $cn 'SELECT activa FROM dbo.SeguridadEstado WHERE id=1;').Rows[0].activa -ne $state){throw 'Rollback de seguridad no coincide; DETENER.'}
 Write-Output 'Contrato, restablecimiento y rollback de seguridad aprobados (solo tras ejecucion completa).'
}finally{if($tx){try{$tx.Rollback()}finally{$tx.Dispose()}};$cn.Dispose();$clave=$null;$hash=$null}
