#!/usr/bin/env bash
set -euo pipefail

# Noctalia's colors_changed hook runs after the kitty template has rewritten
# themes/noctalia.conf. Translate that palette into a Konsole colour scheme so
# the terminal matches kitty, p10k and fzf.
#
# Konsole only reads schemes from $XDG_DATA_HOME/konsole/*.colorscheme — the
# KDE-global *.colors file the "kde" template writes is ignored. Existing
# Konsole windows keep their colours until reopened.

theme_file="${XDG_CONFIG_HOME:-$HOME/.config}/kitty/themes/noctalia.conf"
scheme_dir="${XDG_DATA_HOME:-$HOME/.local/share}/konsole"
scheme_file="$scheme_dir/noctalia.colorscheme"

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

# Konsole stores colours as "R,G,B"; the Noctalia palette is hex.
rgb() {
  local hex="${1#\#}"
  printf '%d,%d,%d' "$((16#${hex:0:2}))" "$((16#${hex:2:2}))" "$((16#${hex:4:2}))"
}

mkdir -p "$scheme_dir"
tmp="$(mktemp "$scheme_dir/.noctalia.XXXXXX")"
trap 'rm -f "$tmp"' EXIT

{
  printf '[Background]\nColor=%s\n' "$(rgb "${colors[background]}")"
  printf '[BackgroundFaint]\nColor=%s\n' "$(rgb "${colors[background]}")"
  printf '[BackgroundIntense]\nColor=%s\n' "$(rgb "${colors[background]}")"
  printf '[Foreground]\nColor=%s\n' "$(rgb "${colors[foreground]}")"
  # Noctalia exposes a single (dark) palette; colour8 doubles as the faint text.
  printf '[ForegroundFaint]\nColor=%s\n' "$(rgb "${colors[color8]}")"
  printf '[ForegroundIntense]\nColor=%s\n' "$(rgb "${colors[foreground]}")"
  # 0.9 mirrors kitty background_opacity.
  printf '[General]\nBlur=false\nColorRandomization=false\nDescription=Noctalia\nOpacity=0.9\nWallpaper=\n'
  # Color0..7 are the normal colours, Color0Intense..7Intense the bright ones.
  for index in {0..7}; do
    printf '[Color%s]\nColor=%s\n' "$index" "$(rgb "${colors[color$index]}")"
    printf '[Color%sIntense]\nColor=%s\n' "$index" "$(rgb "${colors[color$((index + 8))]}")"
  done
} > "$tmp"

if cmp -s "$tmp" "$scheme_file"; then
  exit 0
fi

chmod 0644 "$tmp"
mv -f "$tmp" "$scheme_file"
trap - EXIT
