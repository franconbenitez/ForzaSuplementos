:on error exit
-- SOLO si estos SP NO existian antes de 004. Si ya existian, restaurar sus definiciones previas revisadas.
IF DB_NAME()<>N'ForzaSuplementosDB_QA' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'Destino rechazado: se requiere QA en la instancia verificada.', 1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1')
    THROW 51201, 'Falta la marca de QA aislada.', 1;
IF N'$(AutorizarRetiro)'<>N'RETIRAR_SOLO_SP_NUEVOS' THROW 51499, 'Falta autorizacion de retiro.', 1;
DROP PROCEDURE IF EXISTS dbo.sp_Reportes_VentasDashboard;
DROP PROCEDURE IF EXISTS dbo.sp_Reportes_BackupsDashboard;
