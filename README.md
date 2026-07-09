# zsh_tree_autosuggestions

Plugin para Oh My Zsh que muestra un panel flotante de sugerencias mientras escribes en la terminal. Esta hecho principalmente en Zsh y combina historial, archivos del directorio actual, completado con Tab y una vista tipo arbol para navegar carpetas con `cd`.

## Que hace

- Sugiere comandos recientes del historial que coinciden con lo que estas escribiendo.
- Sugiere archivos y carpetas del directorio actual.
- Permite usar `Tab` para abrir sugerencias de completado.
- Completa ramas locales y remotas con `Tab` en `git pull origin`, `git push origin` y `git checkout`.
- Muestra una vista tipo arbol cuando el contexto es `cd`, para elegir carpetas de forma visual.
- Usa las teclas de flecha para moverte por el panel.
- Mantiene lo que estas escribiendo como primera opcion del panel.
- Acepta una sugerencia con `Right` o `Enter`.
- Completa la siguiente palabra de la sugerencia seleccionada con `Ctrl` + `Right` o `Option` + `Right` en macOS.
- Cierra el panel con `Esc`.
- Reduce el delay de teclas como `Esc` y flechas ajustando `KEYTIMEOUT`.

## Requisitos

- Zsh.
- Oh My Zsh instalado.
- Python 3 para leer `settings.json`.
- Git, si quieres instalarlo desde GitHub.

## Instalacion en un ambiente nuevo

Clona el plugin dentro de la carpeta de plugins personalizados de Oh My Zsh:

```zsh
git clone https://github.com/TU_USUARIO/zsh_tree_autosuggestions.git \
  ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh_tree_autosuggestions
```

Edita tu archivo `~/.zshrc` y agrega `zsh_tree_autosuggestions` a la lista de plugins:

```zsh
plugins=(
  git
  zsh_tree_autosuggestions
)
```

Recarga la configuracion de Zsh:

```zsh
source ~/.zshrc
```

Tambien puedes cerrar y abrir una nueva terminal.

## Uso

Empieza a escribir un comando. Si hay coincidencias en tu historial o en archivos del directorio actual, aparecera un panel con sugerencias.

Controles principales:

| Tecla | Accion |
| --- | --- |
| `Up` / `Down` | Mover la seleccion |
| `Right` | Aceptar la sugerencia seleccionada |
| `Ctrl` + `Right` / `Option` + `Right` | Completar la siguiente palabra de la sugerencia seleccionada |
| `Enter` | Aceptar la sugerencia o ejecutar el comando |
| `Tab` | Mostrar completados adicionales |
| `Esc` | Cerrar el panel |
| `Backspace` / `Delete` | Editar y actualizar sugerencias |

En repositorios Git, `Tab` despues de `git pull origin`, `git push origin` o `git checkout` muestra ramas locales primero y ramas remotas de `origin` despues. Las remotas se insertan sin el prefijo `origin/`.

Para navegar carpetas, escribe:

```zsh
cd 
```

El plugin puede mostrar una vista tipo arbol con carpetas disponibles. Selecciona una carpeta y acepta la sugerencia para completar el comando `cd`.

## Configuracion

La configuracion vive en `settings.json`. JSON permite listas claras y deja listo el camino para snippets personalizados sin inventar separadores como `|`.

El orden de prioridad es:

1. `settings.json` del usuario.
2. `example.settings.json` incluido en el plugin.

Para crear tu configuracion:

```zsh
mkdir -p "$HOME/.config/zsh_tree_autosuggestions"
cp "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh_tree_autosuggestions/example.settings.json" \
  "$HOME/.config/zsh_tree_autosuggestions/settings.json"
$EDITOR "$HOME/.config/zsh_tree_autosuggestions/settings.json"
```

Ejemplo de `settings.json`:

```json
{
  "maxRows": 10,
  "historySuggestionLimit": 5,
  "lsTreeDepth": 2,
  "historyStopPrefixes": [
    "git commit -m \"",
    "gh issue create --title "
  ],
  "rejectedCommandResponsePatterns": [
    "command not found",
    "OCI runtime exec failed: exec failed: unable to start container process: exec:"
  ],
  "customSnippets": [
    {
      "trigger": "gst",
      "command": "git status"
    }
  ]
}
```

`customSnippets` define atajos personalizados. Cuando el texto escrito coincide con `trigger`, el `command` aparece bajo la seccion `Snippets` como primera recomendacion seleccionable. Por ejemplo, `gst` sugiere `git status`.

Los comandos que terminan en `command not found` se guardan en una lista de bloqueo local y dejan de aparecer en sugerencias de historial. Tambien puedes definir `rejectedCommandResponsePatterns` para reconocer respuestas de herramientas que envuelven otros comandos, por ejemplo Docker con `OCI runtime exec failed: exec failed: unable to start container process: exec:`.

Si una integracion captura la respuesta de un comando, puede registrar el comando fallido asi:

```zsh
zsh_tree_autosuggest_reject_command_from_response "$cmd" "$stderr"
```

Cuando la respuesta contiene `exec: "nombre"`, se registra `nombre`; si no, se registra el primer comando de `$cmd`.

Para reiniciar esa lista:

```zsh
rm -f "${XDG_CACHE_HOME:-$HOME/.cache}/zsh_tree_autosuggestions/rejected-commands"
```

Si necesitas mover el archivo, define solo esta variable antes de cargar Oh My Zsh:

```zsh
ZSH_TREE_AUTOSUGGEST_SETTINGS_FILE="$HOME/.config/zsh_tree_autosuggestions/settings.json"
```

Opciones disponibles:

| Llave JSON | Valor default | Descripcion |
| --- | ---: | --- |
| `maxRows` | `8` | Numero maximo de filas visibles en el panel. |
| `historyLimit` | `50` | Cantidad de comandos recientes que revisa del historial. |
| `historySuggestionLimit` | `5` | Numero maximo de sugerencias unicas del historial que muestra para el comando escrito. |
| `fileLimit` | `50` | Limite de archivos/carpetas sugeridos. |
| `enableTabCompletions` | `true` | Activa o desactiva sugerencias al presionar `Tab`. |
| `enableCdTree` | `true` | Activa o desactiva la vista tipo arbol para `cd`. |
| `lsTreeDepth` | `1` | Profundidad de la vista tipo arbol. |
| `lsTreeLimit` | `50` | Limite de entradas en la vista tipo arbol. |
| `borderStyle` | `single` | Estilo del borde del panel. |
| `enableUpdateCheck` | `true` | Activa o desactiva la revision de actualizaciones del plugin. |
| `updateCheckInterval` | `86400` | Tiempo minimo entre revisiones, en segundos. |
| `keyTimeout` | `1` | Valor maximo de `KEYTIMEOUT` para que `Esc` y secuencias de flechas respondan sin pausa perceptible. |
| `showTypedOption` | `true` | Muestra lo escrito como primera opcion para evitar aceptar sugerencias por error con `Enter`. |
| `historyStopPrefixes` | `["git commit -m \"", "gh issue create --title "]` | Prefijos de historial que se pueden sugerir parcialmente; tambien bloquean otras sugerencias del mismo comando base mientras escribes hacia ese prefijo. |
| `rejectedCommandResponsePatterns` | `["command not found", "OCI runtime exec failed: exec failed: unable to start container process: exec:"]` | Fragmentos de respuesta que una integracion puede usar para mandar comandos fallidos a `rejected-commands`. |
| `customSnippets` | `[]` | Snippets personalizados reservados para una siguiente version. |

Con esa configuracion, si existe `git commit -m "mensaje privado"` en tu historial:

- Al escribir `git comm`, la sugerencia sera `git commit -m "`.
- Al escribir `git commit`, no apareceran variantes del historial como `git commit --amend` o mensajes previos.
- Al escribir `git commit -m "`, ya no apareceran sugerencias mas largas de historial para ese comando.

Usa `false` para desactivar opciones booleanas.

## Revision de actualizaciones

Al abrir una nueva terminal, el plugin puede revisar si hay commits nuevos en el repositorio remoto. La revision corre en segundo plano y, por defecto, se hace maximo una vez cada 24 horas para no volver lenta la carga de la terminal.

Si hay una version nueva, veras un aviso como este:

```text
[zsh_tree_autosuggestions] Hay actualizaciones disponibles.
Ejecuta: git -C "$HOME/.oh-my-zsh/custom/plugins/zsh_tree_autosuggestions" pull --ff-only
```

Para revisar en cada terminal nueva:

```json
{
  "updateCheckInterval": 0
}
```

Para desactivar la revision:

```json
{
  "enableUpdateCheck": false
}
```

Esta funcion solo se activa cuando `zsh_tree_autosuggestions` es un repositorio Git independiente con upstream configurado. Si la carpeta esta dentro del repo completo de Oh My Zsh, no revisa actualizaciones para evitar falsos avisos.

## Estructura del plugin

```text
zsh_tree_autosuggestions/
├── README.md
├── example.settings.json
└── zsh_tree_autosuggestions.plugin.zsh
```

Oh My Zsh carga automaticamente el archivo `zsh_tree_autosuggestions.plugin.zsh` cuando el nombre del plugin aparece en `plugins=(...)`.

## Desinstalacion

Quita `zsh_tree_autosuggestions` de la lista `plugins=(...)` en `~/.zshrc` y elimina la carpeta:

```zsh
rm -rf ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh_tree_autosuggestions
source ~/.zshrc
```
