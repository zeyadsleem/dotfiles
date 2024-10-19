#!/bin/bash

current_dir=$(pwd)

EditorConfigCliFile="$current_dir/.editorconfig"

if [ -f "$EditorConfigCliFile" ]; then
	echo ".editorconfig file is already exist❗."
else
	cat <<EOL >"$EditorConfigCliFile"
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
indent_style = space
indent_size = 4
trim_trailing_whitespace = true

[*.md]
trim_trailing_whitespace = false

[*.{yml,yaml}]
indent_size = 2

[docker-compose.yml]
indent_size = 4
EOL
	echo ".editorconfig file has been create👌."
fi
