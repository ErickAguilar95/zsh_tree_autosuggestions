# zsh_tree_autosuggestions
# A pure-zsh floating suggestion panel for Oh My Zsh.

(( ! ${+ZSH_TREE_AUTOSUGGEST_MAX_ROWS} )) &&
typeset -g ZSH_TREE_AUTOSUGGEST_MAX_ROWS=8

(( ! ${+ZSH_TREE_AUTOSUGGEST_HISTORY_LIMIT} )) &&
typeset -g ZSH_TREE_AUTOSUGGEST_HISTORY_LIMIT=50

(( ! ${+ZSH_TREE_AUTOSUGGEST_FILE_LIMIT} )) &&
typeset -g ZSH_TREE_AUTOSUGGEST_FILE_LIMIT=50

(( ! ${+ZSH_TREE_AUTOSUGGEST_ENABLE_TAB_COMPLETIONS} )) &&
typeset -g ZSH_TREE_AUTOSUGGEST_ENABLE_TAB_COMPLETIONS=1

(( ! ${+ZSH_TREE_AUTOSUGGEST_ENABLE_CD_TREE} )) &&
typeset -g ZSH_TREE_AUTOSUGGEST_ENABLE_CD_TREE=1

(( ! ${+ZSH_TREE_AUTOSUGGEST_LS_TREE_DEPTH} )) &&
typeset -g ZSH_TREE_AUTOSUGGEST_LS_TREE_DEPTH=1

(( ! ${+ZSH_TREE_AUTOSUGGEST_LS_TREE_LIMIT} )) &&
typeset -g ZSH_TREE_AUTOSUGGEST_LS_TREE_LIMIT=50

(( ! ${+ZSH_TREE_AUTOSUGGEST_BORDER_STYLE} )) &&
typeset -g ZSH_TREE_AUTOSUGGEST_BORDER_STYLE=single

(( ! ${+ZSH_TREE_AUTOSUGGEST_ENABLE_UPDATE_CHECK} )) &&
typeset -g ZSH_TREE_AUTOSUGGEST_ENABLE_UPDATE_CHECK=1

(( ! ${+ZSH_TREE_AUTOSUGGEST_UPDATE_CHECK_INTERVAL} )) &&
typeset -g ZSH_TREE_AUTOSUGGEST_UPDATE_CHECK_INTERVAL=86400

(( ! ${+ZSH_TREE_AUTOSUGGEST_KEYTIMEOUT} )) &&
typeset -g ZSH_TREE_AUTOSUGGEST_KEYTIMEOUT=1

typeset -ga _ZSH_TREE_AUTOSUGGEST_MAIN_ITEMS
typeset -ga _ZSH_TREE_AUTOSUGGEST_TAB_ITEMS
typeset -ga _ZSH_TREE_AUTOSUGGEST_LS_TREE_ITEMS
typeset -ga _ZSH_TREE_AUTOSUGGEST_LS_TREE_VALUES
typeset -ga _ZSH_TREE_AUTOSUGGEST_ENTRY_TEXT
typeset -ga _ZSH_TREE_AUTOSUGGEST_ENTRY_VALUE
typeset -ga _ZSH_TREE_AUTOSUGGEST_ENTRY_SELECTABLE
typeset -ga _ZSH_TREE_AUTOSUGGEST_ENTRY_KIND
typeset -gA _ZSH_TREE_AUTOSUGGEST_COMMAND_VALID_CACHE
typeset -gi _ZSH_TREE_AUTOSUGGEST_VISIBLE=0
typeset -gi _ZSH_TREE_AUTOSUGGEST_SELECTED=0
typeset -gi _ZSH_TREE_AUTOSUGGEST_SCROLL=0
typeset -g _ZSH_TREE_AUTOSUGGEST_LAST_BUFFER=''
typeset -g _ZSH_TREE_AUTOSUGGEST_PANEL_POSITION=below
typeset -g _ZSH_TREE_AUTOSUGGEST_ORIG_PREDISPLAY=''
typeset -g _ZSH_TREE_AUTOSUGGEST_ORIG_POSTDISPLAY=''
typeset -g _ZSH_TREE_AUTOSUGGEST_ORIG_KEYTIMEOUT=''
typeset -g _ZSH_TREE_AUTOSUGGEST_ORIG_UP_WIDGET=''
typeset -g _ZSH_TREE_AUTOSUGGEST_ORIG_DOWN_WIDGET=''
typeset -g _ZSH_TREE_AUTOSUGGEST_ORIG_RIGHT_WIDGET=''
typeset -g _ZSH_TREE_AUTOSUGGEST_ORIG_ENTER_WIDGET=''
typeset -g _ZSH_TREE_AUTOSUGGEST_ORIG_TAB_WIDGET=''
typeset -g _ZSH_TREE_AUTOSUGGEST_ORIG_DELETE_WIDGET=''
typeset -g _ZSH_TREE_AUTOSUGGEST_ORIG_BACKSPACE_WIDGET=''
typeset -g _ZSH_TREE_AUTOSUGGEST_ORIG_ESCAPE_WIDGET=''
typeset -g _ZSH_TREE_AUTOSUGGEST_ORIG_SELF_INSERT_WIDGET=''
typeset -g _ZSH_TREE_AUTOSUGGEST_ORIG_LINE_INIT=''
typeset -g _ZSH_TREE_AUTOSUGGEST_ORIG_LINE_FINISH=''
typeset -g _ZSH_TREE_AUTOSUGGEST_PLUGIN_DIR="${${(%):-%x}:A:h}"
typeset -gi _ZSH_TREE_AUTOSUGGEST_HAS_DISPLAY=0
typeset -gi _ZSH_TREE_AUTOSUGGEST_IN_LINE_INIT=0
typeset -gi _ZSH_TREE_AUTOSUGGEST_IN_LINE_FINISH=0

_zsh_tree_autosuggest_strip_ansi() {
	emulate -L zsh
	local text="$1"
	print -r -- "${text//$'\033'\[[0-9;]##[A-Za-z]/}"
}

_zsh_tree_autosuggest_truncate_reply() {
	emulate -L zsh
	local text="$1"
	local -i width="$2"
	local -i end

	REPLY=''
	(( width <= 0 )) && return

	if (( $#text <= width )); then
		REPLY="$text"
	elif (( width > 1 )); then
		end=$(( width - 1 ))
		REPLY="${text[1,$end]}>"
	else
		REPLY="${text[1,1]}"
	fi
}

_zsh_tree_autosuggest_unique_push() {
	emulate -L zsh
	setopt local_options extended_glob
	local array_name="$1"
	local value="${2%%[[:space:]]##}"
	local item

	[[ -z "$value" ]] && return

	case "$array_name" in
		_ZSH_TREE_AUTOSUGGEST_MAIN_ITEMS)
			for item in "${_ZSH_TREE_AUTOSUGGEST_MAIN_ITEMS[@]}"; do
				[[ "${item%%[[:space:]]##}" == "$value" ]] && return
			done
			_ZSH_TREE_AUTOSUGGEST_MAIN_ITEMS+=( "$value" )
			;;
		_ZSH_TREE_AUTOSUGGEST_TAB_ITEMS)
			for item in "${_ZSH_TREE_AUTOSUGGEST_TAB_ITEMS[@]}"; do
				[[ "${item%%[[:space:]]##}" == "$value" ]] && return
			done
			_ZSH_TREE_AUTOSUGGEST_TAB_ITEMS+=( "$value" )
			;;
	esac
}

_zsh_tree_autosuggest_current_token() {
	emulate -L zsh
	local token="${LBUFFER##*[[:space:]]}"
	print -r -- "$token"
}

_zsh_tree_autosuggest_command_is_valid() {
	emulate -L zsh
	local line="$1"
	local token command
	local -a tokens precommands

	tokens=( ${(z)line} )
	precommands=( builtin command exec noglob time coproc )

	for token in "${tokens[@]}"; do
		command="${(Q)token}"
		[[ -z "$command" ]] && continue
		[[ "$command" =~ '^[A-Za-z_][A-Za-z0-9_]*(\[[^]]+\])?=' ]] && continue
		(( ${precommands[(Ie)$command]} )) && continue

		if [[ "$command" == */* ]]; then
			[[ -x "${~command}" ]] && return 0
			return 1
		fi

		if [[ -n "${_ZSH_TREE_AUTOSUGGEST_COMMAND_VALID_CACHE[$command]}" ]]; then
			[[ "${_ZSH_TREE_AUTOSUGGEST_COMMAND_VALID_CACHE[$command]}" == 1 ]]
			return
		fi

		(( ${+commands[$command]} ||
		   ${+builtins[$command]} ||
		   ${+functions[$command]} ||
		   ${+aliases[$command]} ||
		   ${reswords[(Ie)$command]} )) && {
			_ZSH_TREE_AUTOSUGGEST_COMMAND_VALID_CACHE[$command]=1
			return 0
		}

		if whence -w "$command" >/dev/null 2>&1; then
			_ZSH_TREE_AUTOSUGGEST_COMMAND_VALID_CACHE[$command]=1
			return 0
		fi
		_ZSH_TREE_AUTOSUGGEST_COMMAND_VALID_CACHE[$command]=0
		return 1
	done

	return 1
}

_zsh_tree_autosuggest_buffer_command_is_valid() {
	emulate -L zsh
	local token="$(_zsh_tree_autosuggest_current_token)"
	local before="${LBUFFER[1,$(( $#LBUFFER - $#token ))]}"

	[[ -n "$before" ]] || return 1
	_zsh_tree_autosuggest_command_is_valid "$before"
}

_zsh_tree_autosuggest_collect_history() {
	emulate -L zsh
	local prefix="$BUFFER"
	local line
	local -a history_lines
	local -i count=0 index

	[[ -z "$prefix" ]] && return

	history_lines=( "${(@f)$(fc -ln -$ZSH_TREE_AUTOSUGGEST_HISTORY_LIMIT 2>/dev/null)}" )

	for (( index=${#history_lines}; index>=1; index-- )); do
		line="${history_lines[index]}"
		line="${line#"${line%%[![:space:]]*}"}"
		[[ "$line" == "$prefix"* && "$line" != "$prefix" ]] || continue
		_zsh_tree_autosuggest_command_is_valid "$line" || continue
		_zsh_tree_autosuggest_unique_push _ZSH_TREE_AUTOSUGGEST_MAIN_ITEMS "$line"
		(( ++count >= ZSH_TREE_AUTOSUGGEST_HISTORY_LIMIT )) && break
	done
}

_zsh_tree_autosuggest_collect_files() {
	emulate -L zsh
	setopt local_options null_glob

	local token="$(_zsh_tree_autosuggest_current_token)"
	local dir base before candidate_path name display replacement
	local -a candidates
	local -i count=0
	local -i command_position=0

	[[ -z "$LBUFFER" ]] && return

	if [[ "$token" == */* ]]; then
		dir="${token:h}"
		base="${token:t}"
		[[ -z "$dir" ]] && dir="/"
	else
		dir="."
		base="$token"
	fi

	[[ -d "$dir" ]] || return

	candidates=( "$dir"/*(N) "$dir"/.*(N) )
	before="${LBUFFER[1,$(( $#LBUFFER - $#token ))]}"
	[[ -z "$before" ]] && command_position=1
	(( command_position )) || _zsh_tree_autosuggest_buffer_command_is_valid || return

	for candidate_path in "${candidates[@]}"; do
		name="${candidate_path:t}"
		[[ "$name" == "." || "$name" == ".." ]] && continue
		[[ -z "$base" || "$name" == "$base"* ]] || continue
		(( command_position )) && [[ ! -x "$candidate_path" ]] && continue

		if [[ "$dir" == "." ]]; then
			display="$name"
		else
			display="${dir%/}/$name"
		fi

		[[ -d "$candidate_path" ]] && display="$display/"
		replacement="$before$display$RBUFFER"
		_zsh_tree_autosuggest_unique_push _ZSH_TREE_AUTOSUGGEST_MAIN_ITEMS "$replacement"

		(( ++count >= ZSH_TREE_AUTOSUGGEST_FILE_LIMIT )) && break
	done
}

_zsh_tree_autosuggest_collect_cd_tree_dir() {
	emulate -L zsh
	setopt local_options null_glob

	local dir="$1"
	local prefix="$2"
	local -i depth="$3"
	local -i max_depth="$4"
	local value_prefix="$5"
	local candidate_path name connector child_prefix display
	local -a candidates
	local -i index total

	(( ${#_ZSH_TREE_AUTOSUGGEST_LS_TREE_ITEMS} >= ZSH_TREE_AUTOSUGGEST_LS_TREE_LIMIT )) && return
	(( depth > max_depth )) && return

	candidates=( "$dir"/*(N/) )
	total="${#candidates}"

	for (( index=1; index<=total; index++ )); do
		(( ${#_ZSH_TREE_AUTOSUGGEST_LS_TREE_ITEMS} >= ZSH_TREE_AUTOSUGGEST_LS_TREE_LIMIT )) && return

		candidate_path="${candidates[index]}"
		name="${candidate_path:t}"
		[[ "$name" == "." || "$name" == ".." ]] && continue

		if (( index == total )); then
			connector="└── "
			child_prefix="${prefix}    "
		else
			connector="├── "
			child_prefix="${prefix}│   "
		fi

		display="$name"
		[[ -d "$candidate_path" ]] && display="$display/"
		_ZSH_TREE_AUTOSUGGEST_LS_TREE_ITEMS+=( "$prefix$connector$display" )
		_ZSH_TREE_AUTOSUGGEST_LS_TREE_VALUES+=( "cd $value_prefix$name/" )

		if [[ -d "$candidate_path" ]]; then
			_zsh_tree_autosuggest_collect_cd_tree_dir "$candidate_path" "$child_prefix" $(( depth + 1 )) "$max_depth" "$value_prefix$name/"
		fi
	done
}

_zsh_tree_autosuggest_collect_cd_tree_context() {
	emulate -L zsh
	local -a tokens
	local arg root_dir root_label value_prefix

	[[ "$BUFFER" == *[[:space:]] ]] && return 1
	tokens=( ${(z)BUFFER} )
	[[ "${tokens[1]}" == cd ]] || return 1
	(( ${#tokens} <= 2 )) || return 1

	arg="${tokens[2]}"
	[[ "$arg" == -* ]] && return 1

	if [[ -z "$arg" ]]; then
		root_dir="."
		root_label="."
		value_prefix=""
	else
		root_dir="$arg"
		root_label="$arg"
		value_prefix="${arg%/}/"
	fi

	[[ -d "${~root_dir}" ]] || return 1
	print -r -- "$root_dir"$'\n'"$root_label"$'\n'"$value_prefix"
}

_zsh_tree_autosuggest_collect_cd_tree() {
	emulate -L zsh
	local -i depth="$ZSH_TREE_AUTOSUGGEST_LS_TREE_DEPTH"
	local -i limit="$ZSH_TREE_AUTOSUGGEST_LS_TREE_LIMIT"
	local root_dir root_label value_prefix
	local -a context

	_ZSH_TREE_AUTOSUGGEST_LS_TREE_ITEMS=()
	_ZSH_TREE_AUTOSUGGEST_LS_TREE_VALUES=()

	(( ZSH_TREE_AUTOSUGGEST_ENABLE_CD_TREE )) || return
	(( depth < 1 )) && return
	(( limit < 1 )) && return

	context=( "${(@f)$(_zsh_tree_autosuggest_collect_cd_tree_context)}" ) || return
	(( ${#context} >= 2 )) || return
	root_dir="${context[1]}"
	root_label="${context[2]}"
	value_prefix="${context[3]}"

	_ZSH_TREE_AUTOSUGGEST_LS_TREE_ITEMS+=( "$root_label" )
	_ZSH_TREE_AUTOSUGGEST_LS_TREE_VALUES+=( "${value_prefix:+cd $value_prefix}" )
	_zsh_tree_autosuggest_collect_cd_tree_dir "$root_dir" "" 1 "$depth" "$value_prefix"
}

_zsh_tree_autosuggest_collect_main() {
	emulate -L zsh
	_ZSH_TREE_AUTOSUGGEST_MAIN_ITEMS=()
	_ZSH_TREE_AUTOSUGGEST_LS_TREE_ITEMS=()
	_ZSH_TREE_AUTOSUGGEST_LS_TREE_VALUES=()

	_zsh_tree_autosuggest_collect_cd_tree
	(( ${#_ZSH_TREE_AUTOSUGGEST_LS_TREE_ITEMS} )) && return
	_zsh_tree_autosuggest_collect_history
	_zsh_tree_autosuggest_collect_files
}

_zsh_tree_autosuggest_collect_tab_commands() {
	emulate -L zsh
	local token="$(_zsh_tree_autosuggest_current_token)"
	local before name
	local -i count=0
	local -a names

	[[ "$LBUFFER" != "$token" ]] && return
	[[ -z "$token" ]] && return

	before="${LBUFFER[1,$(( $#LBUFFER - $#token ))]}"
	names=( ${(k)commands} ${(k)builtins} ${(k)aliases} ${(k)functions} )

	for name in "${(@on)names}"; do
		[[ "$name" == "$token"* && "$name" != "$token" ]] || continue
		_zsh_tree_autosuggest_unique_push _ZSH_TREE_AUTOSUGGEST_TAB_ITEMS "$before$name$RBUFFER"
		(( ++count >= ZSH_TREE_AUTOSUGGEST_FILE_LIMIT )) && break
	done
}

_zsh_tree_autosuggest_collect_tab() {
	emulate -L zsh
	_ZSH_TREE_AUTOSUGGEST_TAB_ITEMS=()
	_ZSH_TREE_AUTOSUGGEST_LS_TREE_ITEMS=()
	_ZSH_TREE_AUTOSUGGEST_LS_TREE_VALUES=()

	(( ZSH_TREE_AUTOSUGGEST_ENABLE_TAB_COMPLETIONS )) || return

	_zsh_tree_autosuggest_collect_files
	_ZSH_TREE_AUTOSUGGEST_TAB_ITEMS=( "${_ZSH_TREE_AUTOSUGGEST_MAIN_ITEMS[@]}" )
	_ZSH_TREE_AUTOSUGGEST_MAIN_ITEMS=()
	_zsh_tree_autosuggest_collect_tab_commands
}

_zsh_tree_autosuggest_build_entries() {
	emulate -L zsh
	local item value
	local -i index first_selectable=0

	_ZSH_TREE_AUTOSUGGEST_ENTRY_TEXT=()
	_ZSH_TREE_AUTOSUGGEST_ENTRY_VALUE=()
	_ZSH_TREE_AUTOSUGGEST_ENTRY_SELECTABLE=()
	_ZSH_TREE_AUTOSUGGEST_ENTRY_KIND=()

	if (( ${#_ZSH_TREE_AUTOSUGGEST_LS_TREE_ITEMS} )); then
		_ZSH_TREE_AUTOSUGGEST_ENTRY_TEXT+=( "Listado" )
		_ZSH_TREE_AUTOSUGGEST_ENTRY_VALUE+=( "" )
		_ZSH_TREE_AUTOSUGGEST_ENTRY_SELECTABLE+=( 0 )
		_ZSH_TREE_AUTOSUGGEST_ENTRY_KIND+=( "header" )

		for (( index=1; index<=${#_ZSH_TREE_AUTOSUGGEST_LS_TREE_ITEMS}; index++ )); do
			item="${_ZSH_TREE_AUTOSUGGEST_LS_TREE_ITEMS[index]}"
			value="${_ZSH_TREE_AUTOSUGGEST_LS_TREE_VALUES[index]}"
			_ZSH_TREE_AUTOSUGGEST_ENTRY_TEXT+=( "$item" )
			_ZSH_TREE_AUTOSUGGEST_ENTRY_VALUE+=( "$value" )
			if [[ -n "$value" ]]; then
				_ZSH_TREE_AUTOSUGGEST_ENTRY_SELECTABLE+=( 1 )
				_ZSH_TREE_AUTOSUGGEST_ENTRY_KIND+=( "cd-tree" )
				(( first_selectable )) || first_selectable="${#_ZSH_TREE_AUTOSUGGEST_ENTRY_TEXT}"
			else
				_ZSH_TREE_AUTOSUGGEST_ENTRY_SELECTABLE+=( 0 )
				_ZSH_TREE_AUTOSUGGEST_ENTRY_KIND+=( "preview" )
			fi
		done
	fi

	if (( ${#_ZSH_TREE_AUTOSUGGEST_MAIN_ITEMS} )); then
		_ZSH_TREE_AUTOSUGGEST_ENTRY_TEXT+=( "Sugerencias" )
		_ZSH_TREE_AUTOSUGGEST_ENTRY_VALUE+=( "" )
		_ZSH_TREE_AUTOSUGGEST_ENTRY_SELECTABLE+=( 0 )
		_ZSH_TREE_AUTOSUGGEST_ENTRY_KIND+=( "header" )

		for item in "${_ZSH_TREE_AUTOSUGGEST_MAIN_ITEMS[@]}"; do
			_ZSH_TREE_AUTOSUGGEST_ENTRY_TEXT+=( "$item" )
			_ZSH_TREE_AUTOSUGGEST_ENTRY_VALUE+=( "$item" )
			_ZSH_TREE_AUTOSUGGEST_ENTRY_SELECTABLE+=( 1 )
			_ZSH_TREE_AUTOSUGGEST_ENTRY_KIND+=( "item" )
			(( first_selectable )) || first_selectable="${#_ZSH_TREE_AUTOSUGGEST_ENTRY_TEXT}"
		done
	fi

	if (( ${#_ZSH_TREE_AUTOSUGGEST_TAB_ITEMS} )); then
		_ZSH_TREE_AUTOSUGGEST_ENTRY_TEXT+=( "Tab" )
		_ZSH_TREE_AUTOSUGGEST_ENTRY_VALUE+=( "" )
		_ZSH_TREE_AUTOSUGGEST_ENTRY_SELECTABLE+=( 0 )
		_ZSH_TREE_AUTOSUGGEST_ENTRY_KIND+=( "header" )

		for item in "${_ZSH_TREE_AUTOSUGGEST_TAB_ITEMS[@]}"; do
			_ZSH_TREE_AUTOSUGGEST_ENTRY_TEXT+=( "$item" )
			_ZSH_TREE_AUTOSUGGEST_ENTRY_VALUE+=( "$item" )
			_ZSH_TREE_AUTOSUGGEST_ENTRY_SELECTABLE+=( 1 )
			_ZSH_TREE_AUTOSUGGEST_ENTRY_KIND+=( "item" )
			(( first_selectable )) || first_selectable="${#_ZSH_TREE_AUTOSUGGEST_ENTRY_TEXT}"
		done
	fi

	if (( ! ${#_ZSH_TREE_AUTOSUGGEST_ENTRY_TEXT} )); then
		_ZSH_TREE_AUTOSUGGEST_SELECTED=0
		_ZSH_TREE_AUTOSUGGEST_SCROLL=0
		return
	fi

	if (( _ZSH_TREE_AUTOSUGGEST_SELECTED < 1 ||
	      _ZSH_TREE_AUTOSUGGEST_SELECTED > ${#_ZSH_TREE_AUTOSUGGEST_ENTRY_TEXT} ||
	      ! _ZSH_TREE_AUTOSUGGEST_ENTRY_SELECTABLE[_ZSH_TREE_AUTOSUGGEST_SELECTED] )); then
		_ZSH_TREE_AUTOSUGGEST_SELECTED="$first_selectable"
	fi
}

_zsh_tree_autosuggest_adjust_scroll() {
	emulate -L zsh
	local -i max_rows="$ZSH_TREE_AUTOSUGGEST_MAX_ROWS"
	local -i selected="$_ZSH_TREE_AUTOSUGGEST_SELECTED"

	(( selected > 0 )) || return

	if (( selected <= _ZSH_TREE_AUTOSUGGEST_SCROLL )); then
		_ZSH_TREE_AUTOSUGGEST_SCROLL=$(( selected - 1 ))
	elif (( selected > _ZSH_TREE_AUTOSUGGEST_SCROLL + max_rows )); then
		_ZSH_TREE_AUTOSUGGEST_SCROLL=$(( selected - max_rows ))
	fi

	(( _ZSH_TREE_AUTOSUGGEST_SCROLL < 0 )) && _ZSH_TREE_AUTOSUGGEST_SCROLL=0
}

_zsh_tree_autosuggest_choose_position() {
	emulate -L zsh
	local -i columns="${COLUMNS:-80}"
	local -i lines="${LINES:-24}"
	local expanded_prompt="$(_zsh_tree_autosuggest_strip_ansi "${(%)PROMPT}")"
	local -i prompt_rows buffer_rows used_rows below_space
	local -i panel_height="$1"

	(( columns < 1 )) && columns=80
	(( lines < 1 )) && lines=24

	prompt_rows=$(( (${#expanded_prompt} / columns) + 1 ))
	buffer_rows=$(( (${#BUFFER} / columns) + 1 ))
	used_rows=$(( prompt_rows + buffer_rows + 1 ))
	below_space=$(( lines - used_rows ))

	if (( below_space >= panel_height )); then
		_ZSH_TREE_AUTOSUGGEST_PANEL_POSITION=below
	else
		_ZSH_TREE_AUTOSUGGEST_PANEL_POSITION=above
	fi
}

_zsh_tree_autosuggest_render_panel() {
	emulate -L zsh
	local -i columns="${COLUMNS:-80}"
	local -i width=$(( columns - 4 ))
	local -i max_width=80
	local -i min_width=24
	local -i total="${#_ZSH_TREE_AUTOSUGGEST_ENTRY_TEXT}"
	local -i max_rows="$ZSH_TREE_AUTOSUGGEST_MAX_ROWS"
	local -i visible_rows start end index panel_height
	local top bottom line marker text plain
	local border_tl='╔' border_tr='╗'
	local border_v='║' border_bl='╚' border_bj='╩' border_br='╝'
	local -a lines

	(( columns < 1 )) && columns=80

	(( total )) || return 1
	(( width > max_width )) && width=$max_width
	(( width < min_width )) && width=$min_width
	(( max_rows < 1 )) && max_rows=1

	(( max_rows < total )) && visible_rows="$max_rows" || visible_rows="$total"
	_zsh_tree_autosuggest_adjust_scroll

	start=$(( _ZSH_TREE_AUTOSUGGEST_SCROLL + 1 ))
	end=$(( start + visible_rows - 1 ))
	(( end > total )) && end=$total

	top="${border_tl}${(l:$width::═:)}${border_tr}"
	bottom="$top"
	lines=( "$top" )

	for index in {$start..$end}; do
		text="${_ZSH_TREE_AUTOSUGGEST_ENTRY_TEXT[index]}"

		if (( _ZSH_TREE_AUTOSUGGEST_ENTRY_SELECTABLE[index] )); then
			if (( index == _ZSH_TREE_AUTOSUGGEST_SELECTED )); then
				marker="> "
			else
				marker="  "
			fi
			_zsh_tree_autosuggest_truncate_reply "$text" $(( width - 2 ))
			plain="$marker$REPLY"
		elif [[ "${_ZSH_TREE_AUTOSUGGEST_ENTRY_KIND[index]}" == header ]]; then
			plain="-- $text "
			plain="${plain}${(l:$(( width - $#plain ))::-:)}"
		else
			plain="$text"
		fi

		_zsh_tree_autosuggest_truncate_reply "$plain" "$width"
		plain="$REPLY"
		line="${border_v}${(r:$width:: :)plain}${border_v}"
		lines+=( "$line" )
	done

	if (( total > visible_rows )); then
		plain=" ${start}-${end}/${total} "
		bottom="${border_bl}${plain}${border_bj}${(l:$(( width - $#plain - 1 ))::═:)}${border_br}"
	else
		bottom="${border_bl}${(l:$width::═:)}${border_br}"
	fi

	lines+=( "$bottom" )
	panel_height="${#lines}"
	_zsh_tree_autosuggest_choose_position "$panel_height"

	print -r -- "${(F)lines}"
}

_zsh_tree_autosuggest_restore_display() {
	emulate -L zsh

	if (( _ZSH_TREE_AUTOSUGGEST_HAS_DISPLAY )); then
		PREDISPLAY="$_ZSH_TREE_AUTOSUGGEST_ORIG_PREDISPLAY"
		POSTDISPLAY="$_ZSH_TREE_AUTOSUGGEST_ORIG_POSTDISPLAY"
		_ZSH_TREE_AUTOSUGGEST_HAS_DISPLAY=0
	fi
}

_zsh_tree_autosuggest_clear() {
	emulate -L zsh
	local skip_redraw="$1"

	_ZSH_TREE_AUTOSUGGEST_VISIBLE=0
	_ZSH_TREE_AUTOSUGGEST_SELECTED=0
	_ZSH_TREE_AUTOSUGGEST_SCROLL=0
	_ZSH_TREE_AUTOSUGGEST_MAIN_ITEMS=()
	_ZSH_TREE_AUTOSUGGEST_TAB_ITEMS=()
	_ZSH_TREE_AUTOSUGGEST_LS_TREE_ITEMS=()
	_ZSH_TREE_AUTOSUGGEST_LS_TREE_VALUES=()
	_ZSH_TREE_AUTOSUGGEST_ENTRY_TEXT=()
	_ZSH_TREE_AUTOSUGGEST_ENTRY_VALUE=()
	_ZSH_TREE_AUTOSUGGEST_ENTRY_SELECTABLE=()
	_ZSH_TREE_AUTOSUGGEST_ENTRY_KIND=()
	_ZSH_TREE_AUTOSUGGEST_LAST_BUFFER=''
	_zsh_tree_autosuggest_restore_display

	[[ "$skip_redraw" == --no-redraw ]] || zle -R
}

_zsh_tree_autosuggest_draw() {
	emulate -L zsh

	_zsh_tree_autosuggest_build_entries
	_zsh_tree_autosuggest_redraw
}

_zsh_tree_autosuggest_redraw() {
	emulate -L zsh
	local panel

	if (( ! ${#_ZSH_TREE_AUTOSUGGEST_ENTRY_TEXT} )); then
		_zsh_tree_autosuggest_clear
		return
	fi

	panel="$(_zsh_tree_autosuggest_render_panel)" || {
		_zsh_tree_autosuggest_clear
		return
	}

	if (( ! _ZSH_TREE_AUTOSUGGEST_HAS_DISPLAY )); then
		_ZSH_TREE_AUTOSUGGEST_ORIG_PREDISPLAY="$PREDISPLAY"
		_ZSH_TREE_AUTOSUGGEST_ORIG_POSTDISPLAY="$POSTDISPLAY"
		_ZSH_TREE_AUTOSUGGEST_HAS_DISPLAY=1
	fi

	PREDISPLAY="$_ZSH_TREE_AUTOSUGGEST_ORIG_PREDISPLAY"
	POSTDISPLAY="$_ZSH_TREE_AUTOSUGGEST_ORIG_POSTDISPLAY"

	if [[ "$_ZSH_TREE_AUTOSUGGEST_PANEL_POSITION" == above ]]; then
		PREDISPLAY="${PREDISPLAY}${panel}"$'\n'
	else
		POSTDISPLAY="${POSTDISPLAY}"$'\n'"${panel}"
	fi

	_ZSH_TREE_AUTOSUGGEST_VISIBLE=1
	_ZSH_TREE_AUTOSUGGEST_LAST_BUFFER="$BUFFER"
	zle -R
}

_zsh_tree_autosuggest_refresh() {
	emulate -L zsh

	if [[ "$BUFFER" == "$_ZSH_TREE_AUTOSUGGEST_LAST_BUFFER" && $_ZSH_TREE_AUTOSUGGEST_VISIBLE -eq 1 ]]; then
		_zsh_tree_autosuggest_draw
		return
	fi

	_ZSH_TREE_AUTOSUGGEST_TAB_ITEMS=()
	_ZSH_TREE_AUTOSUGGEST_SELECTED=0
	_ZSH_TREE_AUTOSUGGEST_SCROLL=0
	_zsh_tree_autosuggest_collect_main
	_zsh_tree_autosuggest_draw
}

_zsh_tree_autosuggest_select_relative() {
	emulate -L zsh
	local -i direction="$1"
	local -i index="$_ZSH_TREE_AUTOSUGGEST_SELECTED"
	local -i total="${#_ZSH_TREE_AUTOSUGGEST_ENTRY_TEXT}"
	local -i attempts=0

	(( _ZSH_TREE_AUTOSUGGEST_VISIBLE && total && _ZSH_TREE_AUTOSUGGEST_SELECTED > 0 )) || return 1

	while (( attempts < total )); do
		(( attempts++ ))
		index=$(( index + direction ))

		(( index < 1 )) && index=$total
		(( index > total )) && index=1

		if (( _ZSH_TREE_AUTOSUGGEST_ENTRY_SELECTABLE[index] )); then
			_ZSH_TREE_AUTOSUGGEST_SELECTED="$index"
			_zsh_tree_autosuggest_redraw
			return 0
		fi

		(( index == _ZSH_TREE_AUTOSUGGEST_SELECTED )) && return 1
	done

	return 1
}

_zsh_tree_autosuggest_accept() {
	emulate -L zsh

	if (( _ZSH_TREE_AUTOSUGGEST_VISIBLE &&
	      _ZSH_TREE_AUTOSUGGEST_SELECTED > 0 &&
	      _ZSH_TREE_AUTOSUGGEST_ENTRY_SELECTABLE[_ZSH_TREE_AUTOSUGGEST_SELECTED] )); then
		BUFFER="${_ZSH_TREE_AUTOSUGGEST_ENTRY_VALUE[_ZSH_TREE_AUTOSUGGEST_SELECTED]}"
		CURSOR=$#BUFFER
		_zsh_tree_autosuggest_clear
		return 0
	fi

	return 1
}

_zsh_tree_autosuggest_tab() {
	emulate -L zsh

	if (( _ZSH_TREE_AUTOSUGGEST_VISIBLE &&
	      _ZSH_TREE_AUTOSUGGEST_SELECTED > 0 &&
	      _ZSH_TREE_AUTOSUGGEST_ENTRY_SELECTABLE[_ZSH_TREE_AUTOSUGGEST_SELECTED] )) &&
	   [[ "${_ZSH_TREE_AUTOSUGGEST_ENTRY_KIND[_ZSH_TREE_AUTOSUGGEST_SELECTED]}" == cd-tree ]]; then
		BUFFER="${_ZSH_TREE_AUTOSUGGEST_ENTRY_VALUE[_ZSH_TREE_AUTOSUGGEST_SELECTED]}"
		CURSOR=$#BUFFER
		_ZSH_TREE_AUTOSUGGEST_TAB_ITEMS=()
		_ZSH_TREE_AUTOSUGGEST_SELECTED=0
		_ZSH_TREE_AUTOSUGGEST_SCROLL=0
		_zsh_tree_autosuggest_collect_main
		_zsh_tree_autosuggest_draw
		return 0
	fi

	if (( ZSH_TREE_AUTOSUGGEST_ENABLE_TAB_COMPLETIONS )); then
		_ZSH_TREE_AUTOSUGGEST_MAIN_ITEMS=()
		_ZSH_TREE_AUTOSUGGEST_SELECTED=0
		_ZSH_TREE_AUTOSUGGEST_SCROLL=0
		_zsh_tree_autosuggest_collect_tab
		_zsh_tree_autosuggest_draw
		return 0
	fi

	_zsh_tree_autosuggest_call_widget "$_ZSH_TREE_AUTOSUGGEST_ORIG_TAB_WIDGET" .expand-or-complete
}

_zsh_tree_autosuggest_self_insert() {
	_zsh_tree_autosuggest_call_widget "$_ZSH_TREE_AUTOSUGGEST_ORIG_SELF_INSERT_WIDGET" .self-insert
	_zsh_tree_autosuggest_refresh
}

_zsh_tree_autosuggest_backward_delete_char() {
	local old_lbuffer="$LBUFFER"
	local old_rbuffer="$RBUFFER"
	_zsh_tree_autosuggest_call_widget "$_ZSH_TREE_AUTOSUGGEST_ORIG_BACKSPACE_WIDGET" .backward-delete-char
	if [[ "$LBUFFER" == "$old_lbuffer" && "$RBUFFER" == "$old_rbuffer" && -n "$LBUFFER" ]]; then
		LBUFFER="${LBUFFER[1,-2]}"
	fi
	_zsh_tree_autosuggest_refresh
}

_zsh_tree_autosuggest_delete_char() {
	local old_lbuffer="$LBUFFER"
	local old_rbuffer="$RBUFFER"
	_zsh_tree_autosuggest_call_widget "$_ZSH_TREE_AUTOSUGGEST_ORIG_DELETE_WIDGET" .delete-char
	if [[ "$LBUFFER" == "$old_lbuffer" && "$RBUFFER" == "$old_rbuffer" && -n "$RBUFFER" ]]; then
		RBUFFER="${RBUFFER[2,-1]}"
	fi
	_zsh_tree_autosuggest_refresh
}

_zsh_tree_autosuggest_up() {
	if ! _zsh_tree_autosuggest_select_relative -1; then
		_zsh_tree_autosuggest_call_widget "$_ZSH_TREE_AUTOSUGGEST_ORIG_UP_WIDGET" .up-line-or-history
	fi
}

_zsh_tree_autosuggest_down() {
	if ! _zsh_tree_autosuggest_select_relative 1; then
		_zsh_tree_autosuggest_call_widget "$_ZSH_TREE_AUTOSUGGEST_ORIG_DOWN_WIDGET" .down-line-or-history
	fi
}

_zsh_tree_autosuggest_forward_char() {
	if ! _zsh_tree_autosuggest_accept; then
		_zsh_tree_autosuggest_call_widget "$_ZSH_TREE_AUTOSUGGEST_ORIG_RIGHT_WIDGET" .forward-char
	fi
}

_zsh_tree_autosuggest_accept_line() {
	if ! _zsh_tree_autosuggest_accept; then
		_zsh_tree_autosuggest_clear
		_zsh_tree_autosuggest_call_widget "$_ZSH_TREE_AUTOSUGGEST_ORIG_ENTER_WIDGET" .accept-line
	fi
}

_zsh_tree_autosuggest_escape() {
	if (( _ZSH_TREE_AUTOSUGGEST_VISIBLE )); then
		_zsh_tree_autosuggest_clear
	else
		_zsh_tree_autosuggest_call_widget "$_ZSH_TREE_AUTOSUGGEST_ORIG_ESCAPE_WIDGET" .send-break
	fi
}

_zsh_tree_autosuggest_line_init() {
	(( _ZSH_TREE_AUTOSUGGEST_IN_LINE_INIT )) && return
	_ZSH_TREE_AUTOSUGGEST_IN_LINE_INIT=1
	{
		[[ -n "$_ZSH_TREE_AUTOSUGGEST_ORIG_LINE_INIT" &&
		   "$_ZSH_TREE_AUTOSUGGEST_ORIG_LINE_INIT" != _zsh_tree_autosuggest_* &&
		   "$_ZSH_TREE_AUTOSUGGEST_ORIG_LINE_INIT" != tree-autosuggest-* &&
		   -n "${widgets[$_ZSH_TREE_AUTOSUGGEST_ORIG_LINE_INIT]}" ]] &&
			zle "$_ZSH_TREE_AUTOSUGGEST_ORIG_LINE_INIT"
		_zsh_tree_autosuggest_clear --no-redraw
	} always {
		_ZSH_TREE_AUTOSUGGEST_IN_LINE_INIT=0
	}
}

_zsh_tree_autosuggest_line_finish() {
	(( _ZSH_TREE_AUTOSUGGEST_IN_LINE_FINISH )) && return
	_ZSH_TREE_AUTOSUGGEST_IN_LINE_FINISH=1
	{
		_zsh_tree_autosuggest_clear --no-redraw
		[[ -n "$_ZSH_TREE_AUTOSUGGEST_ORIG_LINE_FINISH" &&
		   "$_ZSH_TREE_AUTOSUGGEST_ORIG_LINE_FINISH" != _zsh_tree_autosuggest_* &&
		   "$_ZSH_TREE_AUTOSUGGEST_ORIG_LINE_FINISH" != tree-autosuggest-* &&
		   -n "${widgets[$_ZSH_TREE_AUTOSUGGEST_ORIG_LINE_FINISH]}" ]] &&
			zle "$_ZSH_TREE_AUTOSUGGEST_ORIG_LINE_FINISH"
	} always {
		_ZSH_TREE_AUTOSUGGEST_IN_LINE_FINISH=0
	}
}

_zsh_tree_autosuggest_key_widget() {
	emulate -L zsh
	local key="$1"
	local binding widget

	binding="$(bindkey "$key" 2>/dev/null)" || return
	widget="${${(z)binding}[-1]}"

	[[ "$widget" == undefined-key ]] && return
	print -r -- "$widget"
}

_zsh_tree_autosuggest_call_widget() {
	emulate -L zsh
	local widget="$1"
	local fallback="$2"

	if [[ -n "$widget" &&
	      "$widget" != tree-autosuggest-* &&
	      "$widget" != _zsh_tree_autosuggest_* &&
	      "$widget" != "$WIDGET" &&
	      -n "${widgets[$widget]}" ]]; then
		zle "$widget"
	else
		zle "$fallback"
	fi
}

_zsh_tree_autosuggest_check_for_updates() {
	emulate -L zsh
	setopt local_options no_notify

	(( ZSH_TREE_AUTOSUGGEST_ENABLE_UPDATE_CHECK )) || return
	(( $+commands[git] )) || return

	local plugin_dir="$_ZSH_TREE_AUTOSUGGEST_PLUGIN_DIR"
	local git_root cache_dir stamp_file now last interval

	git_root="$(git -C "$plugin_dir" rev-parse --show-toplevel 2>/dev/null)" || return
	[[ "$git_root" == "$plugin_dir" ]] || return
	git -C "$plugin_dir" rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1 || return

	cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh_tree_autosuggestions"
	stamp_file="$cache_dir/update-check"
	interval="$ZSH_TREE_AUTOSUGGEST_UPDATE_CHECK_INTERVAL"
	now="${EPOCHSECONDS:-$(date +%s)}"
	last=0

	[[ -r "$stamp_file" ]] && read -r last < "$stamp_file"
	[[ "$interval" == <-> ]] || interval=86400
	[[ "$last" == <-> ]] || last=0
	(( interval > 0 && now - last < interval )) && return

	mkdir -p "$cache_dir" 2>/dev/null || return
	print -r -- "$now" >| "$stamp_file" 2>/dev/null

	(
		emulate -L zsh
		local local_ref upstream_ref base_ref current_branch

		git -C "$plugin_dir" fetch --quiet --prune >/dev/null 2>&1 || return
		local_ref="$(git -C "$plugin_dir" rev-parse '@' 2>/dev/null)" || return
		upstream_ref="$(git -C "$plugin_dir" rev-parse '@{u}' 2>/dev/null)" || return
		[[ "$local_ref" == "$upstream_ref" ]] && return
		base_ref="$(git -C "$plugin_dir" merge-base '@' '@{u}' 2>/dev/null)" || return
		[[ "$base_ref" == "$local_ref" ]] || return

		current_branch="$(git -C "$plugin_dir" rev-parse --abbrev-ref HEAD 2>/dev/null)"
		print -r -- ""
		print -r -- "[zsh_tree_autosuggestions] Hay actualizaciones disponibles."
		print -r -- "Ejecuta: git -C \"$plugin_dir\" pull --ff-only"
		[[ -n "$current_branch" ]] &&
			print -r -- "Rama actual: $current_branch"
	) &!
}

zle -N tree-autosuggest-self-insert _zsh_tree_autosuggest_self_insert
zle -N tree-autosuggest-backward-delete-char _zsh_tree_autosuggest_backward_delete_char
zle -N tree-autosuggest-delete-char _zsh_tree_autosuggest_delete_char
zle -N tree-autosuggest-up _zsh_tree_autosuggest_up
zle -N tree-autosuggest-down _zsh_tree_autosuggest_down
zle -N tree-autosuggest-forward-char _zsh_tree_autosuggest_forward_char
zle -N tree-autosuggest-accept-line _zsh_tree_autosuggest_accept_line
zle -N tree-autosuggest-tab _zsh_tree_autosuggest_tab
zle -N tree-autosuggest-escape _zsh_tree_autosuggest_escape
[[ "${widgets[zle-line-init]}" == user:* &&
   "${widgets[zle-line-init]#user:}" != _zsh_tree_autosuggest_* &&
   "${widgets[zle-line-init]#user:}" != tree-autosuggest-* ]] &&
	_ZSH_TREE_AUTOSUGGEST_ORIG_LINE_INIT="${widgets[zle-line-init]#user:}"
[[ "$_ZSH_TREE_AUTOSUGGEST_ORIG_LINE_INIT" == _zsh_tree_autosuggest_* ||
   "$_ZSH_TREE_AUTOSUGGEST_ORIG_LINE_INIT" == tree-autosuggest-* ]] &&
	_ZSH_TREE_AUTOSUGGEST_ORIG_LINE_INIT=''
[[ "${widgets[zle-line-finish]}" == user:* &&
   "${widgets[zle-line-finish]#user:}" != _zsh_tree_autosuggest_* &&
   "${widgets[zle-line-finish]#user:}" != tree-autosuggest-* ]] &&
	_ZSH_TREE_AUTOSUGGEST_ORIG_LINE_FINISH="${widgets[zle-line-finish]#user:}"
[[ "$_ZSH_TREE_AUTOSUGGEST_ORIG_LINE_FINISH" == _zsh_tree_autosuggest_* ||
   "$_ZSH_TREE_AUTOSUGGEST_ORIG_LINE_FINISH" == tree-autosuggest-* ]] &&
	_ZSH_TREE_AUTOSUGGEST_ORIG_LINE_FINISH=''

zle -N zle-line-init _zsh_tree_autosuggest_line_init
zle -N zle-line-finish _zsh_tree_autosuggest_line_finish

_ZSH_TREE_AUTOSUGGEST_ORIG_TAB_WIDGET="$(_zsh_tree_autosuggest_key_widget '^I')"
_ZSH_TREE_AUTOSUGGEST_ORIG_ENTER_WIDGET="$(_zsh_tree_autosuggest_key_widget '^M')"
_ZSH_TREE_AUTOSUGGEST_ORIG_BACKSPACE_WIDGET="$(_zsh_tree_autosuggest_key_widget '^?')"
_ZSH_TREE_AUTOSUGGEST_ORIG_DELETE_WIDGET="$(_zsh_tree_autosuggest_key_widget '^[[3~')"
_ZSH_TREE_AUTOSUGGEST_ORIG_UP_WIDGET="$(_zsh_tree_autosuggest_key_widget '^[[A')"
_ZSH_TREE_AUTOSUGGEST_ORIG_DOWN_WIDGET="$(_zsh_tree_autosuggest_key_widget '^[[B')"
_ZSH_TREE_AUTOSUGGEST_ORIG_RIGHT_WIDGET="$(_zsh_tree_autosuggest_key_widget '^[[C')"
_ZSH_TREE_AUTOSUGGEST_ORIG_ESCAPE_WIDGET="$(_zsh_tree_autosuggest_key_widget '^[')"
[[ "${widgets[self-insert]}" == user:* ]] &&
	_ZSH_TREE_AUTOSUGGEST_ORIG_SELF_INSERT_WIDGET="${widgets[self-insert]#user:}"
[[ "$_ZSH_TREE_AUTOSUGGEST_ORIG_SELF_INSERT_WIDGET" == _zsh_tree_autosuggest_* ||
   "$_ZSH_TREE_AUTOSUGGEST_ORIG_SELF_INSERT_WIDGET" == tree-autosuggest-* ]] &&
	_ZSH_TREE_AUTOSUGGEST_ORIG_SELF_INSERT_WIDGET=''

bindkey '^I' tree-autosuggest-tab
bindkey '^M' tree-autosuggest-accept-line
bindkey '^?' tree-autosuggest-backward-delete-char
bindkey '^[[3~' tree-autosuggest-delete-char
bindkey '^[[A' tree-autosuggest-up
bindkey '^[[B' tree-autosuggest-down
bindkey '^[[C' tree-autosuggest-forward-char
bindkey '^[' tree-autosuggest-escape

if [[ "$ZSH_TREE_AUTOSUGGEST_KEYTIMEOUT" == <-> ]]; then
	_ZSH_TREE_AUTOSUGGEST_ORIG_KEYTIMEOUT="$KEYTIMEOUT"
	(( KEYTIMEOUT > ZSH_TREE_AUTOSUGGEST_KEYTIMEOUT )) &&
		KEYTIMEOUT="$ZSH_TREE_AUTOSUGGEST_KEYTIMEOUT"
fi

zle -N self-insert _zsh_tree_autosuggest_self_insert

_zsh_tree_autosuggest_check_for_updates
