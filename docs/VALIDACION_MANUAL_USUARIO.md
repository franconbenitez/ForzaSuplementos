# Validación manual comunicada por el usuario

Fecha de comunicación: 26/10/2026.

El usuario informó haber ejecutado la aplicación desde el acceso directo QA y aprobó las comprobaciones de navegación indicadas: Login, cambios entre módulos, carrito, advertencias de cambios sin guardar y accesos de los perfiles. También aprobó la estética actual y pidió conservarla.

Esta es una validación manual realizada y comunicada por el usuario, no una sesión interactiva ejecutada por el agente. No se infieren resultados de operaciones SQL, restauraciones, backups, pruebas de concurrencia, escalado DPI o revocación de permisos en servidor que no hayan sido informados explícitamente.

La corrección de permisos está en el código funcional desde la etapa anterior: el gerente no puede acceder a Usuarios por menú, navegación directa, fábrica o Negocio. El vendedor solo consulta su propio identificador en reportes de aplicación; administrador no vende ni opera Caja. La comprobación automática se repite antes de preparar la publicación. Ver PERMISOS_Y_VALIDACION.md para los límites SQL pendientes.

No hay cambios de estética ni reglas de datos en esta preparación. Se preservan Caja, Ventas, navegación única y protección de cambios pendientes. La prioridad posterior a la primera publicación privada serán buscadores y reportes, con las pruebas correspondientes a cada cambio.
