#!/usr/bin/env bash
# cht.sh reference popup for tmux (prefix + i).
#
#   tmux-cht.sh                  pick a topic, then ask a query (inside the popup)
#   tmux-cht.sh <topic> <query>  skip the picker and go straight to the answer
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

die() { printf '%s\n' "$*" >&2; exit 1; }

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
            printf '%s' "$body"
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

render() {
    local file="$1"
    if [[ -t 1 ]] && command -v bat >/dev/null 2>&1; then
        bat --style=plain --paging=always "$file"
    else
        cat "$file"
    fi
}

main() {
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
        render "$cache"
        return 0
    fi

    if body="$(fetch_cht "$kind" "$name" "$query")" && [[ -n ${body//[[:space:]]/} ]]; then
        printf '%s\n' "$body" > "$cache"
        render "$cache"
        return 0
    fi

    if body="$(ask_ai "$name" "$query")" && [[ -n ${body//[[:space:]]/} ]]; then
        printf '%s\n' "$body" > "$cache"
        render "$cache"
        return 0
    fi

    die "tmux-cht: no answer for '$name $query' (cht.sh missed, AI fallback unavailable)"
}

main "$@"
