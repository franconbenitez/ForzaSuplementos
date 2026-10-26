:on error exit
-- PREPARADO, NO EJECUTADO. Solo creacion nueva, nunca reemplaza una base existente.
IF DB_NAME()<>N'master' OR CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))<>N'$(QaExpectedServer)'
    THROW 51200, 'La creacion requiere master en la instancia auditada.', 1;
IF DB_ID(N'ForzaSuplementosDB_QA') IS NOT NULL
    THROW 51201, 'QA ya existe. No se elimina ni se recrea. Inspeccionarla antes de continuar.', 1;
-- SQL Server asigna archivos nuevos usando sus directorios por defecto.
-- Si hay un conflicto de archivos, CREATE falla: no hay ATTACH, REPLACE ni rutas fisicas.
CREATE DATABASE [ForzaSuplementosDB_QA] COLLATE Modern_Spanish_CI_AS;
