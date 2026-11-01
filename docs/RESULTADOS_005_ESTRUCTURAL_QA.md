# Resultado de 005 estructural en QA

Fecha local: 2026-10-31. Repositorio principal: ForzaSuplementos_GitHub.

## Alcance y resultado real

Se aplicó exclusivamente sql/qa/005_Seguridad_QA.sql mediante scripts/qa/Aplicar-005-Estructura-QA.ps1 -AutorizarEstructura005, después de autorización expresa. Finalizó correctamente. No se aplicaron 006, 007 ni 008; no se ejecutaron fixtures SQL de escritura, activación, provisionamiento, backups físicos ni push.

La conexión integrada verificó servidor local esperado, base exacta ForzaSuplementosDB_QA y marca Forza-QA-Aislada-v1 antes del despliegue. Se comprobó ausencia de transacción previa. Las definiciones anteriores de los dos procedimientos modificados y sus opciones ANSI quedaron conservadas en almacenamiento privado ignorado por Git, junto al registro del despliegue. No se ejecutó ninguna reversión adicional.

## Objetos comprobados

QA contiene 13 tablas (12 dbo y una auxiliar qa), 37 procedimientos, 12 claves foráneas, 18 índices y 6 restricciones CHECK. El inventario y el diagrama ER se regeneraron mediante metadatos, sin exportar filas.

Se agregó Perfiles.activo, SeguridadEstado con modo inactivo y CredencialesUsuario vacía. Los siete procedimientos nuevos son:

- sp_Seguridad_Estado
- sp_Seguridad_Credencial
- sp_Seguridad_Cambiar
- sp_Seguridad_UsuarioGuardar
- sp_Seguridad_Provisionar
- sp_Seguridad_Activar
- sp_Seguridad_RecuperarAdministrador

Se actualizaron sp_Usuarios_Login y sp_Usuarios_CambiarEstado. Se compararon los cuerpos instalados de los nueve procedimientos con el script autorizado: coincidieron.

## Conservación y autenticación

PBKDF2 permanece desactivado. CredencialesUsuario contiene cero filas. Los conteos de las tablas preexistentes permanecieron iguales. La comparación de una huella agregada de Usuarios antes y después confirmó que sus filas, incluidas contraseñas, no cambiaron. Esa huella solo se mantuvo en memoria; no se publicaron filas ni valores derivados.

El Login heredado se invocó exclusivamente para un identificador sentinela cuya inexistencia se verificó previamente: devolvió cero filas sin error. No se probó un ingreso exitoso con contraseña real. La conexión adicional de lectura confirmó @@TRANCOUNT = 0 y se cerró al terminar.

## Pruebas realmente ejecutadas

La regresión scripts/Validar-Avance.ps1 -IncluirLecturaQa terminó correctamente: compilación Debug/AnyCPU, 655 comprobaciones de comportamiento offline y lectura QA, más 65 lotes/procedimientos analizados estáticamente. El registro completo permanece privado. Ninguna suite ejecutó migraciones ni fixtures de escritura.

Se adaptó la comprobación de módulos pendientes para reconocer tanto el baseline 004 como el estado 005 estructural, exigiendo modo seguro inactivo y manteniendo 006–008 ausentes. El generador de inventario calcula las cantidades por esquema en lugar de asumir diez tablas dbo.

Una comprobación adicional intentada desde PowerShell 7 falló antes de conectarse por incompatibilidad de System.Data.SqlClient.AsynchronousProcessing. Se repitió correctamente con Windows PowerShell y ExecutionPolicy RemoteSigned para ese proceso. No fue un error del despliegue ni exigió corrección SQL.

## Verificación manual y siguiente autorización

Abrir FORZA SUPLEMENTOS - QA (GITHUB) y comprobar el Login habitual con una cuenta QA conocida. No activar PBKDF2 ni cambiar credenciales para esta verificación. En SSMS, sobre QA y tras verificar servidor/base/marca, consultar los metadatos y SELECT activa FROM dbo.SeguridadEstado WHERE id=1; SELECT COUNT(*) FROM dbo.CredencialesUsuario;: los resultados esperados son 0 y 0.

Quedan sin ejecutar los ensayos de escritura de seguridad y la activación PBKDF2. Requieren autorización específica independiente. El siguiente despliegue previsto, 006, también requiere revisión y autorización separadas; no está autorizado por 005. La validación visual final sigue pendiente del usuario.
