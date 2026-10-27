# Inicio QA y trabajo en dos equipos

## Resultado local — 26/10/2026

Se verificó el proceso de Forza por nombre y ruta y se finalizó únicamente la instancia autorizada por el usuario. La solución completa recompiló en Debug / Any CPU en bin/Debug, sin errores. No se modificó código VB respecto de la mejora de interfaz anterior; bin/UIRevision sigue disponible como alternativa.

Se creó INICIAR_FORZA_QA.cmd en la raíz: usa la ubicación del propio CMD y el lanzador protegido, conserva el error visible si falla y no contiene conexiones ni contraseñas. Se creó el acceso directo FORZA SUPLEMENTOS - QA en el Escritorio del equipo de desarrollo, apuntando a ese CMD. El acceso directo es local, no se distribuye por Git.

El lanzador fue verificado con SoloVerificar: conexión exclusivamente QA, servidor esperado y marca de aislamiento correctos, procedimientos requeridos presentes. Solo se ejecutaron consultas de lectura. FORZA_ENTORNO=QA y FORZA_QA_CONFIG se asignan al proceso hijo; una configuración faltante/incorrecta aborta y no utiliza la conexión habitual como alternativa. No se ejecutaron migraciones ni pruebas SQL de escritura.

Pruebas repetidas contra bin/Debug: 59 comprobaciones UI y 20 de regresión offline aprobadas. La autenticación de las pruebas es simulada y el carrito usa datos ficticios en memoria. No se afirmó haber completado una sesión interactiva en WinForms. Pendientes: Login real por Enter/clic con QA, venta ficticia confirmada, revisión de los nueve formularios con datos cargados, diseñador y escalado 125/150 %. Las ventas existentes y stock no fueron modificados en esta tarea.

Archivos nuevos de esta etapa: INICIAR_FORZA_QA.cmd y este documento. La copia saneada recibe los 17 archivos de la mejora visual anterior y estos nuevos archivos mediante copia explícita de contenido, sin importar commits ni referencias del repositorio original. No se trasladan cambios privados o preparaciones anteriores que ya estaban en el árbol funcional.

## Uso diario de QA

En el equipo actual: cerrar la instancia anterior y hacer doble clic en FORZA SUPLEMENTOS - QA del Escritorio o en INICIAR_FORZA_QA.cmd. El iniciador usa Debug actualizado. Si hay un error, leerlo en la consola que queda abierta. No abrir el EXE directamente para QA.

Desde PowerShell, en la raíz del repositorio:

```powershell
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\scripts\compilar.ps1 -Configuration Debug
if ($LASTEXITCODE -ne 0) { throw 'No iniciar: fallo la compilacion.' }
.\INICIAR_FORZA_QA.cmd
```

Si una aplicación abierta impide compilar, cerrarla por su interfaz conservando primero el trabajo pendiente. No terminar otros procesos. Para usar la salida alternativa existente: `powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\scripts\qa\Iniciar-App-QA.ps1 -RevisionVisual`.

## Qué se sincroniza

La carpeta preparada para publicar es ForzaSuplementos_GitHub. Desarrollo_Codex conserva el historial original privado y no debe conectarse al remoto. Los ocho commits saneados se conservan como ancestros; las mejoras posteriores se añaden como commits nuevos. No copiar .git, bundles, bases, binarios, configuraciones privadas ni carpetas private entre repositorios.

En casa y trabajo se usarán clones normales del mismo remoto privado una vez publicada la copia saneada. Evitar desarrollar simultáneamente dos copias distintas del mismo cambio. No sincronizar una misma carpeta .git mediante almacenamiento en nube entre computadoras: mantener un clon local separado en cada PC y sincronizar con Git.

## Publicación futura — requiere autorización, no ejecutada

Instalar Git y GitHub CLI. En la raíz de ForzaSuplementos_GitHub:

```powershell
gh auth login --hostname github.com --git-protocol https --web
$cuenta = gh api user --jq .login
if ($LASTEXITCODE -ne 0 -or $cuenta -cne 'franconbenitez') { throw 'Cuenta incorrecta.' }
# Crear solo si el repositorio no existe, luego de autorizar la publicacion:
gh repo create franconbenitez/ForzaSuplementos --private
$repo = gh api repos/franconbenitez/ForzaSuplementos | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $repo.private -ne $true -or $repo.full_name -cne 'franconbenitez/ForzaSuplementos') { throw 'Destino incorrecto o no privado.' }
git remote -v
# Si origin ya existe, revisar su URL; no reemplazarlo automaticamente.
# Solo si no existe origin:
git remote add origin https://github.com/franconbenitez/ForzaSuplementos.git
git status
git push -u origin master
```

No usar force, mirror ni publicar desde Desarrollo_Codex. En esta etapa no se instaló CLI, no se autenticó una cuenta, no se configuró remoto ni se publicó.

## Configurar cada computadora después de publicar

Instalar Visual Studio Community con desarrollo de escritorio .NET, herramientas de VB y targeting pack de .NET Framework 4.7.2, Git, SQL Server y SSMS. Clonar en una carpeta local elegida en cada PC:

```powershell
git clone https://github.com/franconbenitez/ForzaSuplementos.git
cd ForzaSuplementos
Copy-Item .\config\qa.example.config .\config\qa.config
```

Editar únicamente la copia privada qa.config con el servidor de ESA computadora, su nombre esperado verificado y base ForzaSuplementosDB_QA. No copiar configuraciones del otro equipo. Cada equipo requiere su propia QA aislada con marca de entorno, esquema y fixtures: consultar sql/qa/README.md y preparar su creación por separado con autorización. No se incluye ni transfiere una base de datos mediante Git. Este documento no autoriza ejecutar SQL.

Compilar con scripts/compilar.ps1, validar el destino con `powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\scripts\qa\Iniciar-App-QA.ps1 -SoloVerificar` e iniciar con el CMD. Crear un acceso directo local al CMD si se desea. Abrir ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.slnx para editar; F5 sin entorno QA puede usar la conexión habitual: usar siempre el iniciador QA para ensayos.

Antes de trabajar: `git status` y `git pull --ff-only`. Si hay cambios locales, conservarlos en un commit o resolverlos antes de actualizar. Para un cambio nuevo: `git switch -c codex/descripcion`, editar, compilar y ejecutar pruebas offline. Revisar `git diff` y agregar solamente archivos previstos, nunca config/qa.config. Confirmar y, cuando los envíos estén autorizados, publicar la rama y revisar/integrar los cambios. En la otra PC, actualizar la rama antes de comenzar. Ante divergencias, resolverlas con revisión; no forzar el historial.

Siguiente paso: revisión interactiva contra QA y autorización separada para la primera publicación privada. La auditoría por patrones reduce riesgos pero no garantiza ausencia absoluta de secretos futuros; repetirla antes de cada publicación.
