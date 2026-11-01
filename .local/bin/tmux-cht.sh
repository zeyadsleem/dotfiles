#!/usr/bin/env bash
# cht.sh reference for tmux (prefix + i).
#
#   tmux-cht.sh                   pick a topic, then ask a query
#   tmux-cht.sh <topic> <query>   skip the picker and go straight to the answer
#   tmux-cht.sh --window ...      show the answer in a throwaway window: q closes it
#
# Answers are cached for a week, cht.sh is queried with both URL shapes
# (/topic/query and topic~query) and anything still missing falls back to
# OpenCode's free model instead of showing an empty window.
set -uo pipefail

LANG_FILE="$HOME/.config/tmux/.tmux-cht-languages"
CMD_FILE="$HOME/.config/tmux/.tmux-cht-command"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/tmux-cht"
CACHE_TTL=$(( 7 * 24 * 60 * 60 ))
AI_MODEL="opencode/big-pickle"
ENV_FILE="$HOME/.config/themes/current/zsh/env.zsh"
WINDOW_MODE=0

die() {
    printf '%s\n' "$*" >&2
    pause_close
    exit 1
}

# In window mode the window dies with the script, so hold it open long enough to
# read the answer (or the error) and let one key dismiss it.
pause_close() {
    (( WINDOW_MODE )) || return 0
    printf '\n[ press any key to close ]' >&2
    read -rsn1 -t 120 </dev/tty 2>/dev/null || true
}

need() {
    local cmd
    for cmd in "$@"; do
        command -v "$cmd" >/dev/null 2>&1 || die "tmux-cht: missing dependency '$cmd'"
    done
}

topic_kind() {
    local topic="$1"
    if [[ -f $LANG_FILE ]] && grep -qxF -- "$topic" "$LANG_FILE"; then
        printf 'lang'
    else
        printf 'cmd'
    fi
}

load_theme() {
    [[ -f $ENV_FILE ]] || return 0
    eval "$(zsh -c "source \"$ENV_FILE\"; echo \"export FZF_DEFAULT_OPTS='\$FZF_DEFAULT_OPTS --height=100% --border=none'\"")"
}

pick_topic() {
    {
        grep -vE '^[[:space:]]*(#|$)' "$LANG_FILE" | sed 's/[[:space:]]*$//' | awk '{ print "lang\t" $0 }'
        grep -vE '^[[:space:]]*(#|$)' "$CMD_FILE"  | sed 's/[[:space:]]*$//' | awk '{ print "cmd\t" $0 }'
    } | awk -F'\t' 'length($2) && !seen[$2]++' \
      | fzf --delimiter='\t' --with-nth=2 --prompt='cht.sh > ' --height=100% --border=none
}

urlencode_word() {
    local word="$1"
    if command -v jq >/dev/null 2>&1; then
        printf '%s' "$word" | jq -sRr '@uri'
    elif command -v python3 >/dev/null 2>&1; then
        python3 -c 'import sys, urllib.parse; sys.stdout.write(urllib.parse.quote(sys.argv[1], safe=""))' "$word"
    else
        printf '%s' "$word" | sed 's/[^A-Za-z0-9._~-]/_/g'
    fi
}

# cht.sh takes the query as path segments with '+' between words.
urlencode_query() {
    local -a words encoded=()
    local word out=""
    read -ra words <<< "$*"
    for word in "${words[@]}"; do
        encoded+=("$(urlencode_word "$word")")
    done
    local IFS='+'
    out="${encoded[*]}"
    printf '%s' "$out"
}

strip_ansi() { sed 's/\x1b\[[0-9;]*[a-zA-Z]//g'; }

# cht.sh opens with a "--- / tags: [...] / ---" banner that is noise in a popup.
strip_banner() {
    awk '
        NR == 1 && /^-{2,}[[:space:]]*$/ { banner = 1; next }
        banner && /^tags:/             { next }
        banner && /^-{2,}[[:space:]]*$/ { banner = 0; next }
        banner                          { next }
        { print }
    '
}

# Give bat a language it knows so the answer gets real syntax colour instead of
# cht.sh's own ANSI, which bat would otherwise wrap in a second set of escapes.
bat_language() {
    local kind="$1" topic="$2"
    if [[ $kind == cmd ]]; then
        printf 'bash'
        return
    fi
    case $topic in
        bash|sh|zsh|tmux|shell)               printf 'bash' ;;
        golang)                               printf 'go' ;;
        nodejs|bun|deno|javascript|react|vue|svelte|angular|nextjs|electron)
                                              printf 'javascript' ;;
        typescript)                           printf 'typescript' ;;
        python|django|flask|fastapi)          printf 'python' ;;
        ruby|rails)                           printf 'ruby' ;;
        c)                                    printf 'c' ;;
        cpp|qt|gtk|godot|unity|game-development) printf 'cpp' ;;
        csharp)                               printf 'cs' ;;
        java)                                 printf 'java' ;;
        kotlin|flutter|dart)                  printf 'kotlin' ;;
        swift)                                printf 'swift' ;;
        scala|gradle|maven)                   printf 'scala' ;;
        php|laravel)                          printf 'php' ;;
        rust)                                 printf 'rust' ;;
        zig)                                  printf 'zig' ;;
        go)                                   printf 'go' ;;
        lua|neovim|vim|vimscript|emacs|lisp)   printf 'lua' ;;
        perl)                                 printf 'perl' ;;
        elixir)                               printf 'elixir' ;;
        haskell)                              printf 'haskell' ;;
        clojure)                              printf 'clojure' ;;
        ocaml)                                printf 'ocaml' ;;
        erlang)                               printf 'erlang' ;;
        julia)                                printf 'julia' ;;
        r)                                    printf 'r' ;;
        sql|postgres|mongodb|redis)           printf 'sql' ;;
        yaml|ansible|kubernetes|kubernetes-helm|helm) printf 'yaml' ;;
        json)                                 printf 'json' ;;
        toml)                                 printf 'toml' ;;
        xml|html)                             printf 'html' ;;
        css|tailwind)                         printf 'css' ;;
        graphql)                              printf 'graphql' ;;
        nix)                                  printf 'nix' ;;
        terraform)                            printf 'hcl' ;;
        makefile)                             printf 'makefile' ;;
        cmake)                                printf 'cmake' ;;
        nginx)                                printf 'nginx' ;;
        docker|docker-compose)                printf 'dockerfile' ;;
        *)                                    printf 'bash' ;;
    esac
}

# Follow the shell's theme when it has one, else the Catppuccin palette the rest
# of the dotfiles use, else bat's own default.
bat_theme() {
    if [[ -n ${BAT_THEME:-} ]]; then
        printf '%s' "$BAT_THEME"
    elif command -v bat >/dev/null 2>&1 && bat --list-themes 2>/dev/null | grep -qx 'Catppuccin Macchiato'; then
        printf 'Catppuccin Macchiato'
    fi
}

# Drop markdown fences, ANSI noise and leading blank lines from model output.
tidy() {
    strip_ansi | grep -vE '^[[:space:]]*```' | cat -s | sed '/./,$!d'
}

is_miss() {
    local body="$1"
    [[ -z ${body//[[:space:]]/} ]] && return 0
    # cht.sh answers an unknown *topic* on the topic~query form with a help page
    # instead of a 404, so that page has to count as a miss too.
    printf '%s' "$body" | strip_ansi | grep -qiE '404 NOT FOUND|Unknown cheat sheet|show cheat sheet: cht\.sh|help: cht\.sh --help'
}

# cht.sh serves two URL shapes and they do not cover the same pages:
# a language query answers best on /topic/query, a command on topic~query.
fetch_cht() {
    local kind="$1" topic="$2" query="$3"
    local encoded url body
    local -a candidates=()

    encoded="$(urlencode_query "$query")"
    [[ -z $encoded ]] && return 1

    if [[ $kind == lang ]]; then
        candidates=("https://cht.sh/$topic/$encoded" "https://cht.sh/$topic~$encoded")
    else
        candidates=("https://cht.sh/$topic~$encoded" "https://cht.sh/$topic/$encoded")
    fi

    for url in "${candidates[@]}"; do
        body="$(curl -s --max-time 12 "$url")" || continue
        if ! is_miss "$body"; then
            printf '%s' "$body" | strip_ansi
            return 0
        fi
    done
    return 1
}

cache_path() {
    local key
    key="$(printf '%s' "$1" | sha1sum | cut -d' ' -f1)"
    printf '%s/%s' "$CACHE_DIR" "$key"
}

cache_fresh() {
    local file="$1" mtime age
    [[ -f $file ]] || return 1
    mtime="$(stat -c %Y "$file" 2>/dev/null)" || return 1
    age=$(( $(date +%s) - mtime ))
    (( age < CACHE_TTL ))
}

ask_ai() {
    local topic="$1" query="$2" raw prompt
    command -v opencode >/dev/null 2>&1 || return 1

    prompt="You generate cht.sh-style reference snippets.
Reply with ONLY the answer: comment lines starting with '# ' followed by short copy-pasteable examples.
Never mention instructions, deliberation, process or yourself. No markdown code fences, no greeting, no closing remarks.

Topic: $topic
Question: $query"

    printf '\n cht.sh had nothing for "%s %s" — asking %s\n\n' "$topic" "$query" "$AI_MODEL" >&2

    if command -v jq >/dev/null 2>&1; then
        raw="$(opencode run -m "$AI_MODEL" --format json "$prompt" 2>/dev/null)" || return 1
        printf '%s\n' "$raw" | jq -r 'select(.type == "text") | .part.text' | tidy
    else
        raw="$(opencode run -m "$AI_MODEL" "$prompt" 2>/dev/null)" || return 1
        printf '%s\n' "$raw" | tidy
    fi
}

# Paint the answer through bat: plain style, no line numbers, the theme the
# rest of the shell uses, and the pager left on so long answers stay readable.
render() {
    local kind="$1" topic="$2" file="$3" text lang theme
    local -a args=(--style=plain --color=always --tabs=4 --paging=always)

    text="$(strip_ansi < "$file" | strip_banner)"

    if [[ -t 1 ]] && command -v bat >/dev/null 2>&1; then
        lang="$(bat_language "$kind" "$topic")"
        theme="$(bat_theme)"
        args+=(--language="$lang")
        [[ -n $theme ]] && args+=(--theme="$theme")
        printf '%s\n' "$text" | bat "${args[@]}"
    elif [[ -t 1 ]] && command -v less >/dev/null 2>&1; then
        printf '%s\n' "$text" | less -R
    else
        printf '%s\n' "$text"
    fi
}

main() {
    while (( $# )); do
        case $1 in
            -w|--window) WINDOW_MODE=1; shift ;;
            --) shift; break ;;
            -*) die "tmux-cht: unknown option '$1'" ;;
            *) break ;;
        esac
    done

    need curl fzf
    mkdir -p "$CACHE_DIR" || die "tmux-cht: cannot create $CACHE_DIR"
    load_theme

    local selection="" kind="" name="" query=""

    if (( $# >= 1 )); then
        name="$1"
        shift
        kind="$(topic_kind "$name")"
        query="$*"
    else
        selection="$(pick_topic)"
        [[ -z $selection ]] && exit 0
        kind="${selection%%$'\t'*}"
        name="${selection#*$'\t'}"
    fi

    if [[ -z $query ]]; then
        printf -v prompt '%s > ' "$name"
        read -rp "$prompt" query || exit 130
    fi

    [[ -z ${query//[[:space:]]/} ]] && exit 0

    local cache body
    cache="$(cache_path "$kind:$name:$query")"

    if cache_fresh "$cache"; then
        render "$kind" "$name" "$cache"
        return 0
    fi

    if body="$(fetch_cht "$kind" "$name" "$query")" && [[ -n ${body//[[:space:]]/} ]]; then
        printf '%s\n' "$body" > "$cache"
        render "$kind" "$name" "$cache"
        return 0
    fi

    if body="$(ask_ai "$name" "$query")" && [[ -n ${body//[[:space:]]/} ]]; then
        printf '%s\n' "$body" > "$cache"
        render "$kind" "$name" "$cache"
        return 0
    fi

    die "tmux-cht: no answer for '$name $query' (cht.sh missed, AI fallback unavailable)"
}

main "$@"
