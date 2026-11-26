#!/usr/bin/env bash
set -euo pipefail

# Noctalia's colors_changed hook runs after the kitty template has rewritten
# themes/noctalia.conf. Translate that palette into Yazi's theme.toml so the
# status bar badges stay readable: Yazi's built-in theme paints `blue` and
# `gray` backgrounds with the terminal's default foreground, and in this
# palette both are light, which produces light-on-light text.
#
# Yazi merges theme.toml over its built-in dark theme, so only the sections
# that paint their own background need explicit foregrounds here.

theme_file="${XDG_CONFIG_HOME:-$HOME/.config}/kitty/themes/noctalia.conf"
yazi_dir="${XDG_CONFIG_HOME:-$HOME/.config}/yazi"
theme_out="$yazi_dir/theme.toml"

[[ -r "$theme_file" && -d "$yazi_dir" ]] || exit 0

declare -A colors=()
while read -r key value; do
  [[ -z "$key" || "$key" == \#* || -z "${value:-}" ]] && continue
  colors[$key]="$value"
done < "$theme_file"

for key in background foreground color0 color1 color2 color4 color6 color7 color8 color9; do
  [[ -n "${colors[$key]:-}" ]] || exit 0
done

bg="${colors[background]}"
fg="${colors[foreground]}"
surface="${colors[color0]}"
danger="${colors[color1]}"
accent="${colors[color2]}"
lavender="${colors[color4]}"
teal="${colors[color6]}"
muted="${colors[color7]}"
faint="${colors[color8]}"
danger_soft="${colors[color9]}"

tmp="$(mktemp "$yazi_dir/.theme.XXXXXX")"
trap 'rm -f "$tmp"' EXIT

cat > "$tmp" <<EOF
# Generated from ~/.config/kitty/themes/noctalia.conf by
# ~/.config/noctalia/hooks/yazi-theme.sh — do not edit by hand.

[tabs]
active   = { fg = "$bg", bg = "$accent", bold = true }
inactive = { fg = "$muted", bg = "$surface" }

[mode]
# Badges paint their own background, so the foreground must be explicit and
# dark: every accent in the Noctalia palette is a light colour.
normal_main = { fg = "$bg", bg = "$accent", bold = true }
normal_alt  = { fg = "$bg", bg = "$muted" }

select_main = { fg = "$bg", bg = "$danger", bold = true }
select_alt  = { fg = "$bg", bg = "$danger_soft" }

unset_main = { fg = "$bg", bg = "$danger", bold = true }
unset_alt  = { fg = "$bg", bg = "$danger_soft" }

[status]
perm_sep   = { fg = "$faint" }
perm_type  = { fg = "$accent" }
perm_read  = { fg = "$teal" }
perm_write = { fg = "$danger" }
perm_exec  = { fg = "$lavender" }

progress_label  = { fg = "$fg", bold = true }
progress_normal = { fg = "$fg", bg = "$surface" }
progress_error  = { fg = "$bg", bg = "$danger" }
EOF

if cmp -s "$tmp" "$theme_out"; then
  exit 0
fi

chmod 0644 "$tmp"
mv -f "$tmp" "$theme_out"
trap - EXIT
