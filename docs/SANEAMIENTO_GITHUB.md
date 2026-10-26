# Copia saneada para GitHub

Fecha: 26/10/2026. Destino previsto: franconbenitez/ForzaSuplementos, privado.

Se reconstruyeron ocho commits en una base de objetos nueva, sin clonar el .git original ni importar sus referencias auxiliares, remotos o reflogs. Se conservaron orden, mensajes, autores y fechas; los hashes cambiaron por las sustituciones y exclusiones. El mapa completo se entrega localmente en private/MAPA_COMMITS.json, ignorado para evitar una referencia circular al hash del propio ultimo commit.

La carpeta original Desarrollo_Codex, incluido su estado de trabajo previo y el bundle, no se modifica. La prueba de integridad compara hashes de sus archivos antes/despues. Los resultados detallados de auditoria, comparacion y validaciones se entregan localmente en private; no contienen credenciales.

El ultimo arbol incorpora la preparacion de publicacion previamente revisada: README, reglas ignore, plantilla QA y parametrizacion portable del servidor. No se copia config/qa.config ni datos privados. Los originales de los archivos de negocio VB, recursos, proyectos, solucion, App.config y migraciones principales se comparan con e1d5f17. Las guardas de QA se mantienen: requieren configurar una instancia propia y no se autoriza ejecutar SQL durante esta entrega.

La evidencia QA de 18/18 corresponde a la ejecucion historica documentada. En esta copia solo se ejecutan validaciones offline y compilacion; no se afirma haber repetido pruebas SQL.

Para preparar QA en otra computadora copiar config/qa.example.config a config/qa.config y configurar un servidor verificado; la copia privada queda ignorada. No copiar credenciales o configuraciones del equipo original. No usar F5 normal para ensayos QA; consultar README y docs/INICIAR_QA_WINDOWS.md.

## Publicacion posterior, no ejecutada

Instalar GitHub CLI desde https://cli.github.com/ y, desde la carpeta de esta copia, comprobar:

```powershell
gh auth login --hostname github.com --git-protocol https --web
$cuenta = gh api user --jq .login
if ($LASTEXITCODE -ne 0 -or $cuenta -cne 'franconbenitez') { throw 'Cuenta incorrecta.' }
```

Solo con nueva autorizacion para publicar, crear el repositorio vacio PRIVADO desde GitHub (sin README remoto) o con `gh repo create franconbenitez/ForzaSuplementos --private`, sin envio automatico. Luego comprobar propiedad y privacidad:

```powershell
$repo = gh api repos/franconbenitez/ForzaSuplementos | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $repo.full_name -cne 'franconbenitez/ForzaSuplementos' -or $repo.private -ne $true) { throw 'Destino no privado o incorrecto.' }
git remote -v
# Solo si no existe origin:
git remote add origin https://github.com/franconbenitez/ForzaSuplementos.git
git status
git branch --show-current
# Exclusivamente tras autorizar el primer envio:
git push -u origin master
```

No publicar desde Desarrollo_Codex, no importar refs originales y no usar envio forzado ni espejo. No hay remoto configurado en esta entrega. La autenticacion GitHub queda pendiente; nunca imprimir tokens.
