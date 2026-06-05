# zsh_tree_autosuggestions

Plugin para Oh My Zsh que muestra un panel flotante de sugerencias mientras escribes en la terminal. Esta hecho en Zsh puro y combina historial, archivos del directorio actual, completado con Tab y una vista tipo arbol para navegar carpetas con `cd`.

## Que hace

- Sugiere comandos recientes del historial que coinciden con lo que estas escribiendo.
- Sugiere archivos y carpetas del directorio actual.
- Permite usar `Tab` para abrir sugerencias de completado.
- Muestra una vista tipo arbol cuando el contexto es `cd`, para elegir carpetas de forma visual.
- Usa las teclas de flecha para moverte por el panel.
- Acepta una sugerencia con `Right` o `Enter`.
- Cierra el panel con `Esc`.
- Reduce el delay de teclas como `Esc` y flechas ajustando `KEYTIMEOUT`.

## Requisitos

- Zsh.
- Oh My Zsh instalado.
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
| `Enter` | Aceptar la sugerencia o ejecutar el comando |
| `Tab` | Mostrar completados adicionales |
| `Esc` | Cerrar el panel |
| `Backspace` / `Delete` | Editar y actualizar sugerencias |

Para navegar carpetas, escribe:

```zsh
cd 
```

El plugin puede mostrar una vista tipo arbol con carpetas disponibles. Selecciona una carpeta y acepta la sugerencia para completar el comando `cd`.

## Configuracion

Puedes ajustar estas variables antes de cargar Oh My Zsh en tu `~/.zshrc`:

```zsh
ZSH_TREE_AUTOSUGGEST_MAX_ROWS=8
ZSH_TREE_AUTOSUGGEST_HISTORY_LIMIT=50
ZSH_TREE_AUTOSUGGEST_FILE_LIMIT=50
ZSH_TREE_AUTOSUGGEST_ENABLE_TAB_COMPLETIONS=1
ZSH_TREE_AUTOSUGGEST_ENABLE_CD_TREE=1
ZSH_TREE_AUTOSUGGEST_LS_TREE_DEPTH=1
ZSH_TREE_AUTOSUGGEST_LS_TREE_LIMIT=50
ZSH_TREE_AUTOSUGGEST_BORDER_STYLE=single
ZSH_TREE_AUTOSUGGEST_ENABLE_UPDATE_CHECK=1
ZSH_TREE_AUTOSUGGEST_UPDATE_CHECK_INTERVAL=86400
ZSH_TREE_AUTOSUGGEST_KEYTIMEOUT=1
```

Ejemplo:

```zsh
ZSH_TREE_AUTOSUGGEST_MAX_ROWS=10
ZSH_TREE_AUTOSUGGEST_LS_TREE_DEPTH=2

plugins=(
  git
  zsh_tree_autosuggestions
)
```

Opciones disponibles:

| Variable | Valor default | Descripcion |
| --- | ---: | --- |
| `ZSH_TREE_AUTOSUGGEST_MAX_ROWS` | `8` | Numero maximo de filas visibles en el panel. |
| `ZSH_TREE_AUTOSUGGEST_HISTORY_LIMIT` | `50` | Cantidad de comandos recientes que revisa del historial. |
| `ZSH_TREE_AUTOSUGGEST_FILE_LIMIT` | `50` | Limite de archivos/carpetas sugeridos. |
| `ZSH_TREE_AUTOSUGGEST_ENABLE_TAB_COMPLETIONS` | `1` | Activa o desactiva sugerencias al presionar `Tab`. |
| `ZSH_TREE_AUTOSUGGEST_ENABLE_CD_TREE` | `1` | Activa o desactiva la vista tipo arbol para `cd`. |
| `ZSH_TREE_AUTOSUGGEST_LS_TREE_DEPTH` | `1` | Profundidad de la vista tipo arbol. |
| `ZSH_TREE_AUTOSUGGEST_LS_TREE_LIMIT` | `50` | Limite de entradas en la vista tipo arbol. |
| `ZSH_TREE_AUTOSUGGEST_BORDER_STYLE` | `single` | Estilo del borde del panel. |
| `ZSH_TREE_AUTOSUGGEST_ENABLE_UPDATE_CHECK` | `1` | Activa o desactiva la revision de actualizaciones del plugin. |
| `ZSH_TREE_AUTOSUGGEST_UPDATE_CHECK_INTERVAL` | `86400` | Tiempo minimo entre revisiones, en segundos. |
| `ZSH_TREE_AUTOSUGGEST_KEYTIMEOUT` | `1` | Valor maximo de `KEYTIMEOUT` para que `Esc` y secuencias de flechas respondan sin pausa perceptible. |

Usa `0` para desactivar opciones booleanas:

```zsh
ZSH_TREE_AUTOSUGGEST_ENABLE_CD_TREE=0
ZSH_TREE_AUTOSUGGEST_ENABLE_TAB_COMPLETIONS=0
ZSH_TREE_AUTOSUGGEST_ENABLE_UPDATE_CHECK=0
```

## Revision de actualizaciones

Al abrir una nueva terminal, el plugin puede revisar si hay commits nuevos en el repositorio remoto. La revision corre en segundo plano y, por defecto, se hace maximo una vez cada 24 horas para no volver lenta la carga de la terminal.

Si hay una version nueva, veras un aviso como este:

```text
[zsh_tree_autosuggestions] Hay actualizaciones disponibles.
Ejecuta: git -C "$HOME/.oh-my-zsh/custom/plugins/zsh_tree_autosuggestions" pull --ff-only
```

Para revisar en cada terminal nueva:

```zsh
ZSH_TREE_AUTOSUGGEST_UPDATE_CHECK_INTERVAL=0
```

Para desactivar la revision:

```zsh
ZSH_TREE_AUTOSUGGEST_ENABLE_UPDATE_CHECK=0
```

Esta funcion solo se activa cuando `zsh_tree_autosuggestions` es un repositorio Git independiente con upstream configurado. Si la carpeta esta dentro del repo completo de Oh My Zsh, no revisa actualizaciones para evitar falsos avisos.

## Estructura del plugin

```text
zsh_tree_autosuggestions/
├── README.md
└── zsh_tree_autosuggestions.plugin.zsh
```

Oh My Zsh carga automaticamente el archivo `zsh_tree_autosuggestions.plugin.zsh` cuando el nombre del plugin aparece en `plugins=(...)`.

## Desinstalacion

Quita `zsh_tree_autosuggestions` de la lista `plugins=(...)` en `~/.zshrc` y elimina la carpeta:

```zsh
rm -rf ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh_tree_autosuggestions
source ~/.zshrc
```
