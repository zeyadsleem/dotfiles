#!/usr/bin/env bash
set -euo pipefail

# Noctalia's colors_changed hook runs after the kitty template has rewritten
# themes/noctalia.conf. Translate that palette into a Ptyxis user palette so
# the terminal uses the same colors as kitty, p10k and fzf.
#
# Ptyxis watches ~/.local/share/org.gnome.Ptyxis/palettes and reloads user
# palettes automatically. Existing tabs keep their colors until reopened;
# new tabs pick up the regenerated palette.

theme_file="${XDG_CONFIG_HOME:-$HOME/.config}/kitty/themes/noctalia.conf"
palette_dir="${XDG_DATA_HOME:-$HOME/.local/share}/org.gnome.Ptyxis/palettes"
palette_file="$palette_dir/noctalia.palette"

[[ -r "$theme_file" ]] || exit 0

declare -A colors=()
while read -r key value; do
  [[ -z "$key" || "$key" == \#* || -z "${value:-}" ]] && continue
  colors[$key]="$value"
done < "$theme_file"

[[ -n "${colors[background]:-}" && -n "${colors[foreground]:-}" ]] || exit 0
for index in {0..15}; do
  [[ -n "${colors[color$index]:-}" ]] || exit 0
done

# Kitty has no selection/cursor foreground fallback issue: both keys are
# always present in the Noctalia template, but keep sensible defaults.
cursor="${colors[cursor]:-${colors[foreground]}}"
cursor_text="${colors[cursor_text_color]:-${colors[background]}}"

mkdir -p "$palette_dir"
tmp="$(mktemp "$palette_dir/.noctalia.XXXXXX")"
trap 'rm -f "$tmp"' EXIT

{
  printf '[Palette]\nName=Noctalia\n\n'
  # Ptyxis expects both faces; Noctalia exposes a single (dark) palette.
  for scheme in Light Dark; do
    printf '[%s]\n' "$scheme"
    printf 'Foreground=%s\n' "${colors[foreground]}"
    printf 'Background=%s\n' "${colors[background]}"
    for index in {0..15}; do
      printf 'Color%s=%s\n' "$index" "${colors[color$index]}"
    done
    printf 'Cursor=%s\n' "$cursor"
    printf 'CursorForeground=%s\n' "$cursor_text"
    printf '\n'
  done
} > "$tmp"

if cmp -s "$tmp" "$palette_file"; then
  exit 0
fi

chmod 0644 "$tmp"
mv -f "$tmp" "$palette_file"
trap - EXIT
