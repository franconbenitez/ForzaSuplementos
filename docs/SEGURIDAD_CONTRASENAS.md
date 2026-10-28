# Seguridad de contraseñas — pendiente de SQL

005 NO ejecutada. PBKDF2-HMAC-SHA256, versión 1, 600000 iteraciones, salt aleatorio de 16 bytes y salida de 32 bytes. Comparación de todos los bytes sin salida temprana; formato y límites validados antes de derivar. No hay hash en Usuario ni formularios de administración. El servicio es reutilizable y el contrato CredencialAcceso es solo del flujo de autenticación.

## Corte controlado

1. Revisar/autorizar 005 en QA, conservar antes las definiciones de sp_Usuarios_Login y los SP afectados. No desplegar todavía en otra base. Instancia, base y marca obligatorias en cada lote. No existe aplicador automático de esta migración.
2. Desplegar aplicación con servicio seguro. El SP Estado devuelve activa=0 y mantiene login QA heredado durante esta preparación. Si no está desplegado Estado, únicamente el error SQL 2812 permite esta compatibilidad; cualquier otro error detiene login.
3. Un operador autorizado establece NUEVAS claves individuales usando PBKDF2 y sp_Seguridad_Provisionar parametrizado. No leer ni convertir claves antiguas en lote. No incluir hashes/secretos en argumentos, capturas ni historial. Planificar recuperación y verificar una cuenta administradora provisionada antes del corte.
4. Después de autorizar explícitamente la activación, sp_Seguridad_Activar exige confirmación textual y todas las cuentas activas provisionadas. Marca activa=1 e inutiliza las claves recuperables dentro de una transacción. No borrar tablas ni desactivar modo seguro para recuperar acceso.
5. Tras el corte, Login usa exclusivamente la credencial PBKDF2; el SP Login heredado rechaza operaciones. Un fallo de hash no usa fallback. Cambiar contraseña requiere clave actual y compare-and-swap del hash; administrador puede restablecer una clave sin recuperar la anterior.
6. Recuperación: operador SQL autorizado debe provisionar una nueva credencial de administrador mediante sp_Seguridad_RecuperarAdministrador, que requiere confirmación y autorización específica; no volver a texto plano. El contrato de recuperación está preparado en 005 y no se ejecutó.

Alta/edición segura usa sp_Seguridad_UsuarioGuardar: hash nuevo únicamente en alta o cambio explícito, NULL conserva credencial. Antes del corte, edición con clave vacía conserva la clave dentro de DAL sin exponerla al formulario. La grilla no recibe secretos. Mi contraseña abre diálogo; si 005 no está activada explica el requisito y no escribe. En Usuarios, menú contextual sobre usuario activo ofrece restablecimiento bajo la misma protección.

Los SP validan cuenta y perfil activos. Perfiles.activo es una columna propuesta en 005. El esquema actual todavía no la tiene. SQL integrado con privilegios de propietario no proporciona identidad por usuario de aplicación; el ID del actor no es un token criptográfico. Quedan pendientes credenciales SQL de mínimos privilegios, rate limiting/bloqueo progresivo, pruebas SQL de corte, recuperación y endurecimiento de los SP heredados de administración. No se declara seguridad integral de producción.

Pruebas de integración pendientes: provisionar cuentas ficticias en transacción, corte con cuenta faltante rechazado, cuenta/perfil inactivo, login con hash, clave errónea, edición sin hash conserva credencial, cambio simultáneo rechazado, reset solo administrador y login heredado rechazado. Todo requiere autorización específica: no se ejecutó ninguna escritura de seguridad.
