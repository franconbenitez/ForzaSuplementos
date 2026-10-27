# Publicación privada y uso diario desde casa y trabajo

Preparación del 26/10/2026. No se ejecutó push, no se creó un repositorio remoto ni se modificaron bases. La revisión manual de navegación y estética está aprobada por el usuario; ver VALIDACION_MANUAL_USUARIO.md. Este documento complementa TRABAJO_DOS_EQUIPOS.md y reemplaza sus pendientes de revisión manual dentro del alcance expresamente aprobado.

## Estado comprobado

Git está disponible: 2.56.0.windows.1. GitHub CLI no aparece en PATH ni en las ubicaciones habituales revisadas. No se puede confirmar una sesión CLI como franconbenitez hasta instalarla/iniciar sesión. No se inspeccionaron archivos de credenciales ni se copiaron tokens. WinGet está disponible.

Navegación y permisos ya estaban sincronizados en la copia saneada. No se repite su implementación ni se importa historial original. Los nuevos archivos de esta preparación se copian por contenido y se confirman en commits independientes. Los ocho commits saneados originales se conservan como ancestros. Desarrollo_Codex mantiene sus cambios privados previos fuera del commit de preparación y nunca debe ser el origen de publicación.

La corrección de gerente/Usuarios está en menús, fábrica, formularios y Negocio. Las pruebas de permisos, navegación, interfaz y reglas suman 370 comprobaciones offline por repositorio. Los controles SQL adicionales documentados en PERMISOS_Y_VALIDACION.md siguen pendientes: esta preparación de GitHub no requiere modificar SP ni ejecutar una migración. No equivale a certificar seguridad de SQL Server ni a terminar ABM de categorías o auditoría de backups.

## Instalar y autenticar GitHub CLI

Acciones manuales, todavía no ejecutadas. En Windows PowerShell:

```powershell
winget install --id GitHub.cli --source winget
```

Cerrar la ventana de terminal y abrir una nueva para cargar el PATH actualizado; comprobar e iniciar sesión:

```powershell
gh --version
gh auth login --hostname github.com --git-protocol https --web
gh auth setup-git --hostname github.com
gh auth status --hostname github.com
$login = gh api user --hostname github.com --jq .login
if ($LASTEXITCODE -ne 0 -or $login -cne 'franconbenitez') { throw 'Cuenta incorrecta: no publicar.' }
```

Completar el flujo del navegador con la cuenta franconbenitez. No guardar contraseñas/tokens en el proyecto ni compartir la salida de comandos que revelen credenciales. Instalación y reinicio de terminal según la [guía oficial de GitHub CLI para Windows](https://github.com/cli/cli/blob/trunk/docs/install_windows.md).

## Primera publicación — ejecutar solo después de autorización expresa

Abrir una terminal en la raíz de **ForzaSuplementos_GitHub**, no Desarrollo_Codex. Puede usarse Abrir en Terminal desde el Explorador. Comprobar ubicación, rama, archivos y remotos:

```powershell
git rev-parse --show-toplevel
git status
git branch --show-current
git remote -v
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\scripts\Verificar-PrimeraPublicacion.ps1
if ($LASTEXITCODE -ne 0) { throw 'Corregir la preparacion antes de continuar.' }
```

El verificador solo lee Git localmente. Rechaza usar el original, cambios sin confirmar, rutas privadas versionadas, referencias inesperadas y URLs remotas distintas del destino pedido. No reemplaza la auditoría completa de blobs/historial y no publica nada. Su modo de consulta GitHub es opcional y solo de lectura.

Si el repositorio aún no existe, crearlo PRIVADO y vacío, sin README/licencia/ignore remotos que introduzcan otro historial:

```powershell
gh repo create franconbenitez/ForzaSuplementos --private
if ($LASTEXITCODE -ne 0) { throw 'Detenerse y revisar: no repetir ni cambiar visibilidad automaticamente.' }
```

Si ya existe, omitir la creación y verificarlo. Si contiene archivos o commits ajenos, detenerse para revisar su historia; no sobreescribirla. Verificar cuenta/privacidad en lectura antes de configurar origin:

```powershell
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\scripts\Verificar-PrimeraPublicacion.ps1 -ConsultarGitHub
if ($LASTEXITCODE -ne 0) { throw 'No se verifico cuenta/destino PRIVATE.' }
# Solo si git remote -v confirmo que no existe origin:
git remote add origin https://github.com/franconbenitez/ForzaSuplementos.git
if ($LASTEXITCODE -ne 0) { throw 'No cambiar un remoto existente sin revisarlo.' }
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\scripts\Verificar-PrimeraPublicacion.ps1 -ConsultarGitHub
if ($LASTEXITCODE -ne 0) { throw 'No publicar.' }
# Solo con autorizacion de envio y destino vacio/revisado:
git push -u origin master
```

Si origin ya existe y es correcto, omitir remote add. No cambiarlo automáticamente. Nunca usar force, mirror ni enviar referencias del original. Mantener PRIVATE; no se necesita visibilidad pública para clonar en la segunda PC. Estos comandos son instrucciones futuras, no acciones realizadas por el agente.

## Descargar y abrir en la PC del trabajo

Instalar Git, GitHub CLI, Visual Studio Community con escritorio .NET/VB y targeting pack de .NET Framework 4.7.2. Para ejecutar, disponer además de SQL Server/SSMS y una QA local independiente. Autenticar GitHub CLI en esa PC con la misma cuenta y configurar Git mediante gh auth setup-git. No copiar el almacén de credenciales de la PC de casa.

Elegir una carpeta local de desarrollo en cada PC. Clonar solo después de la primera publicación:

```powershell
git clone https://github.com/franconbenitez/ForzaSuplementos.git
if ($LASTEXITCODE -ne 0) { throw 'Verificar autenticacion y acceso al repositorio privado.' }
cd ForzaSuplementos
git status
git log -5 --oneline
```

Usar un clon local distinto en cada computadora. Evitar una misma carpeta .git sincronizada por OneDrive u otra nube. El repositorio original y los bundles quedan locales; no son necesarios para trabajar desde la otra PC.

**Codex:** crear/abrir un proyecto local y asociar la carpeta raíz del clon ForzaSuplementos, la que contiene AGENTS.md. Si hace falta cambiar la carpeta, usar el menú del proyecto, Edit project / Editar proyecto, y asociar el clon como carpeta principal. Iniciar el chat desde ese proyecto. La sincronización del chat no descarga los archivos: Git clone/pull hace esa parte. Fuente: [documentación oficial de proyectos locales](https://learn.chatgpt.com/docs/projects).

**Visual Studio:** Archivo > Abrir > Proyecto o solución; seleccionar ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.slnx dentro del clon. Elegir Debug / Any CPU. Usar una versión de Visual Studio que soporte slnx. No convertir a C#, cambiar framework ni reorganizar capas. Para ensayar contra QA usar el CMD protegido; F5 o el EXE directo sin entorno QA pueden usar la conexión habitual.

Los chats no sustituyen la documentación versionada. Al iniciar un chat nuevo indicar que debe leer AGENTS.md, PERMISOS_Y_VALIDACION.md y los documentos de QA. No agregar las carpetas de la base ni configuraciones privadas como fuentes compartidas.

## Comenzar y terminar una jornada

Para el flujo sencillo de un único desarrollador, trabajar secuencialmente en master entre equipos. No editar en la otra computadora hasta publicar y descargar lo pendiente de la primera.

Al comenzar, desde la raíz del clon:

```powershell
git status
# Si hay cambios sin confirmar, conservarlos y revisarlos antes de seguir.
git switch master
git pull --ff-only origin master
if ($LASTEXITCODE -ne 0) { throw 'Detenerse: no forzar la actualizacion.' }
```

Realizar cambios pequeños. Al terminar, cerrar la aplicación antes de compilar y ejecutar:

```powershell
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\scripts\compilar.ps1 -Configuration Debug
if ($LASTEXITCODE -ne 0) { throw 'No enviar una version que no compila.' }
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\tests\ui\Probar-Permisos-SinSql.ps1
if ($LASTEXITCODE -ne 0) { throw 'Revisar permisos.' }
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\tests\ui\Probar-Navegacion-SinSql.ps1
if ($LASTEXITCODE -ne 0) { throw 'Revisar navegacion.' }
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\tests\ui\Probar-Interfaz-SinSql.ps1
if ($LASTEXITCODE -ne 0) { throw 'Revisar interfaz.' }
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\tests\Probar-Caja-SinSql.ps1
if ($LASTEXITCODE -ne 0) { throw 'Revisar Caja/Ventas.' }
git diff --check
git diff
git status
# Reemplazar la ruta de ejemplo por archivos revisados; no agregar todo a ciegas:
git add -- ruta/del/archivo-revisado
git diff --cached
git commit -m "Describir el cambio concreto"
# Cuando los envios esten autorizados y desde el clon saneado:
git push origin master
```

Configurar nombre/correo de autor local si Git lo solicita. Para privacidad, utilizar la dirección noreply mostrada por tu cuenta de GitHub; no inventar una dirección ni incorporar datos personales al código. Revisar los archivos agregados: nunca qa.config, backups, bases, bundles, credenciales o binarios.

Antes de ir a la otra PC confirmar que push terminó correctamente. Allí ejecutar pull antes de editar. Si push se rechaza por cambios remotos, no forzarlo: conservar el commit local, ejecutar git fetch origin y revisar git log --oneline --graph --all; resolver la divergencia con revisión. No usar reset --hard ni descartar archivos para solucionar conflictos. Para cambios grandes puede utilizarse una rama codex/descripcion y un PR; alternar equipos sobre la misma rama explícitamente.

El verificador de primera publicación es deliberadamente estricto con las referencias iniciales; después de publicar y tener refs/remotes u otras ramas no corresponde usarlo como prueba de flujo diario.

## QA independiente por computadora

Git transmite código y fixtures, no una base ni los datos de la otra computadora. Solo copiar la plantilla si todavía no existe la configuración privada:

```powershell
if (!(Test-Path .\config\qa.config)) {
    Copy-Item .\config\qa.example.config .\config\qa.config
}
git check-ignore config/qa.config
```

Editar localmente qa.config con la instancia de ESA computadora, el nombre de servidor verificado y ForzaSuplementosDB_QA. Mantener la marca de aislamiento y autenticación integrada; no copiar contraseñas ni apuntar a la base original. Ver sql/qa/README.md para preparar el esquema y fixtures con autorización separada; esta guía no ejecuta ni autoriza creación/migraciones.

Una vez preparada y verificada la QA propia:

```powershell
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\scripts\qa\Iniciar-App-QA.ps1 -SoloVerificar
if ($LASTEXITCODE -ne 0) { throw 'No iniciar: destino QA no verificado.' }
.\INICIAR_FORZA_QA.cmd
```

En cada PC crear, si se desea, su propio acceso directo al CMD. No copiar accesos directos con rutas del otro equipo. Las fallas de QA deben detener el inicio; nunca resolverlas quitando guardas o abriendo el EXE habitual.

## Entrega y límites

La copia saneada queda preparada localmente para una primera publicación privada después de instalar/autenticar CLI, verificar cuenta/destino y recibir autorización de envío. La privacidad remota no puede confirmarse sin consultar la cuenta y el repositorio. No se afirma que GitHub esté vinculado ni publicado.

Nuevos archivos de esta etapa: este documento, VALIDACION_MANUAL_USUARIO.md y scripts/Verificar-PrimeraPublicacion.ps1. No se cambia código VB, estética, SQL o configuración. La próxima tarea funcional, después de publicar, será buscadores y reportes según prioridad del usuario.
