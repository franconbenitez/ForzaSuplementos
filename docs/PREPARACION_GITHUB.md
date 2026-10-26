# Preparación de publicación privada

Fecha: 26/10/2026. Objetivo remoto solicitado: `franconbenitez/ForzaSuplementos`, exclusivamente privado. No se creó un repositorio remoto, no se añadió origin, no se ejecutó push ni se reescribió el historial.

## Estado local comprobado

Al comenzar: árbol limpio, rama `master`, sin remotos. La raíz es la carpeta local del proyecto que devuelve `git rev-parse --show-toplevel`; no se almacena aquí la ruta del perfil de Windows.

Los ocho commits originales permanecen intactos, en este orden:

- a77eaf4 — Estado inicial del código antes de la auditoría.
- 7cfbb69 — Auditoría inicial y preparación de compilación local.
- c179987 — Restricción local de PowerShell y comando alternativo.
- 48aaa74 — Corrección de compilación preservando Caja pendiente.
- ddebb25 — Caja y ventas atómicas con pagos explícitos.
- e08b4df — Infraestructura QA y ensayos, antes de ejecutarlos.
- 81db955 — Normalización de los archivos QA generados.
- e1d5f17 — Validación real en QA, 18 ensayos aprobados.

No se cambió su autoría técnica ni se renombró la rama. La preparación actual queda como cambios revisables, sin modificar los hashes anteriores.

## Auditoría de archivos e historial

Se inspeccionaron los 114 archivos originalmente versionados, los árboles de los ocho commits, metadatos de autor/committer, reflogs, referencias locales auxiliares y los 133 blobs existentes (incluidos objetos no alcanzables por master). No había blobs binarios pendientes. El escáner local revisa tokens conocidos, claves privadas, credenciales literales, correos, perfiles Windows, identificadores de equipo y extensiones privadas; guarda solamente categorías/líneas, nunca valores detectados.

Resultados revisados en contexto:

- No se detectaron contraseñas literales, tokens, claves privadas ni cadenas SQL con contraseña. La conexión habitual usa autenticación integrada.
- No se encontraron .bak, .mdf, .ldf, ZIP u otras bases/respaldos en ningún árbol de commit.
- Los SQL versionados contienen definiciones y fixtures ficticias; el snapshot exportado contiene metadatos, no filas de usuarios ni ventas reales. Las contraseñas de fixtures se generan con NEWID, no están incorporadas a los archivos.
- La autoría registrada utiliza una identidad técnica con dominio .invalid; no se detectaron correos personales en los commits.
- **Bloqueo de privacidad:** los commits e08b4df y posteriores contienen un identificador real del equipo en configuración, SQL QA, snapshot y documentación/evidencia. e1d5f17 contiene además una ruta absoluta con el nombre del perfil Windows en docs/INICIAR_QA_WINDOWS.md. Sus valores se omiten en este informe.
- Hay referencias auxiliares de la aplicación dentro de Git. No deben publicarse con un push --mirror; la futura publicación debe seleccionar solo la rama autorizada.

El informe detallado permanece en `private/auditoria-git.json`, excluido de Git. La revisión por patrones y contexto no es una prueba matemática de ausencia de cualquier secreto posible; GitHub CLI y gitleaks no están disponibles en este entorno para ampliar esas verificaciones.

## Copia original preservada

Se creó y verificó `private/forza-historial-original-e1d5f17.bundle` mediante git bundle verify. Contiene el historial completo y las referencias existentes al comienzo. El bundle y las copias originales de metadatos/evidencia permanecen solo en directorios privados ignorados.

No subir ese bundle: conserva precisamente la información que se propone sanear. No se eliminó ningún commit, referencia original ni configuración local de QA.

## Cambios de preparación

- README.md: descripción profesional, cuatro capas, tecnologías, perfiles, funciones, instalación, QA y límites reales.
- .gitignore: ampliado para Visual Studio, temporales, artefactos, exportaciones, bases, certificados, configuraciones privadas y bundles.
- config/qa.example.config: plantilla sin identidad del equipo; config/qa.config se conserva localmente pero se retira del índice. Agregarlo a ignore sin retirarlo del índice no habría sido suficiente.
- Scripts QA publicables: servidor esperado obligatorio mediante variable SQLCMD QaExpectedServer, suministrada por el preparador desde la configuración privada validada. Se mantienen las guardas de base y servidor, sin valores personales fijos.
- Snapshot y documentación/evidencia: identificador de equipo y ruta de perfil anonimizados; originales preservados localmente.
- Exportador de metadatos: admite instancia mediante parámetro y guarda nuevas exportaciones únicamente en sql/qa/private.
- ScriptDom: resolución mediante vswhere o parámetro explícito, sin depender de la carpeta de instalación de una versión concreta de Visual Studio.
- scripts/auditar_git.py: auditoría reproducible local, sin publicación ni cambios de referencias.

Los scripts se basan en PSScriptRoot o la raíz de Git. No necesitan la ruta personal original. Los archivos QA exigen un destino local configurado: esa dependencia deliberada protege la base habitual y no debe sustituirse por una conexión insegura de reserva.

## Historial: decisión pendiente antes de publicar

**No está listo para publicar todo el historial original tal cual**, incluso siendo privado, bajo la condición de no compartir identificadores personales/locales. Corregir los archivos actuales o añadir .gitignore no elimina las versiones previas. GitHub documenta que retirar contenido previo requiere una [reescritura del historial](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository).

Estrategia recomendada, pendiente de autorización específica:

1. Conservar intactos este repositorio y el bundle verificado. Asegurar los cambios actuales con una copia local revisada antes de operar en otro checkout.
2. Crear una copia local independiente destinada a publicación, dentro del proyecto y excluida de Git. No operar sobre las referencias de este repositorio.
3. Sanear en esa copia todas las versiones de la configuración privada, las rutas del perfil y el identificador del equipo; aplicar la preparación actual al estado final.
4. Conservar todos los nodos de commit y sus relaciones, incluso los que queden vacíos por retirar datos privados. La reescritura cambia hashes por definición: guardar un mapa de hashes antiguos/nuevos. Los hashes y archivos originales se conservarán completos en la copia local original.
5. Repetir auditoría de todos los blobs/commits de la copia, verificar diferencias funcionales, compilar y comprobar el número de commits. No exportar referencias auxiliares ni objetos originales privados.
6. Solo después, confirmar cuenta, propiedad y visibilidad privada del remoto y pedir autorización para el primer push de la rama de la copia saneada.

Alternativa: publicar solo un snapshot limpio, preservando el historial original localmente. No pierde el historial local, pero no conserva la secuencia de commits en GitHub; por eso no es la opción recomendada para este objetivo.

No se ejecutó filter-repo, filter-branch, rebase, reset, limpieza de reflogs ni garbage collection.

## GitHub CLI y cuenta

gh no está en PATH ni en ubicaciones estándar, y GitHub CLI no aparece en los registros estándar de aplicaciones instaladas. **No se puede confirmar una sesión autenticada como franconbenitez**. No se inspeccionaron archivos de credenciales ni tokens ni se inició autenticación automáticamente.

Instalar GitHub CLI desde su [sitio oficial](https://cli.github.com/), reabrir PowerShell y ejecutar, sin compartir credenciales en el chat:

```powershell
gh --version
gh auth login --hostname github.com --git-protocol https --web
gh auth status --hostname github.com
gh api user --jq .login
```

El último comando debe devolver exactamente franconbenitez. La [autenticación web oficial](https://cli.github.com/manual/gh_auth_login) evita introducir tokens en archivos del proyecto. No usar --show-token ni imprimir variables de autenticación.

## Comandos futuros para vincular y publicar

**No ejecutados. No usarlos desde el historial original aún bloqueado.** Requieren completar el saneamiento y aprobar explícitamente la publicación; ejecutar desde la copia autorizada. Crear el repositorio vacío y privado desde GitHub, sin README/.gitignore/licencia remotos para evitar una historia inicial ajena.

Si se prefiere crearlo con CLI en la etapa autorizada, el comando es `gh repo create franconbenitez/ForzaSuplementos --private`; no agregar --push. La [documentación de gh repo create](https://cli.github.com/manual/gh_repo_create) distingue creación y envío de commits.

Comprobar cuenta y repositorio antes de agregar origin:

```powershell
$cuenta = gh api user --jq .login
if ($LASTEXITCODE -ne 0 -or $cuenta -cne 'franconbenitez') { throw 'Cuenta incorrecta o no autenticada.' }
$repo = gh api repos/franconbenitez/ForzaSuplementos | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $repo.full_name -cne 'franconbenitez/ForzaSuplementos' -or $repo.private -ne $true) {
    throw 'El repositorio debe pertenecer a la cuenta indicada y ser PRIVADO.'
}
git remote -v
# Ejecutar solo si no hay un origin existente; nunca sobrescribirlo sin revisar.
git remote add origin https://github.com/franconbenitez/ForzaSuplementos.git
git remote -v
```

Con autorización del primer envío y conservando el nombre master de la copia:

```powershell
git status
git branch --show-current
git push -u origin master
```

No se requiere --force ni --mirror para un repositorio remoto nuevo y vacío. Si origin ya existe, detenerse y revisar; no ejecutar set-url automáticamente. Si la rama de la copia tiene otro nombre, adaptar el último comando al nombre verificado sin renombrar ni borrar la rama original.

## Comprobaciones ejecutadas y límites

- git status, remote -v, branch --show-current, log -5 y log completo: realizados.
- Auditoría de objetos/archivos y bundle verify: realizados, sin reescritura.
- Validadores offline de QA, contratos y ScriptDom: aprobados tras los cambios de portabilidad.
- No cambió código VB, por lo que no se requirió recompilar las cuatro capas en esta preparación. No se ejecutaron migraciones ni operaciones SQL, tampoco se repitieron los 18 ensayos de escritura.
- El estado de 18/18 QA corresponde a la validación histórica documentada; la parametrización nueva se verificó estáticamente y no se declara ensayada contra SQL en esta tarea.
- Publicación y comprobación de la identidad GitHub: pendientes; no hay remote ni push realizados.
