#!/bin/bash

current_dir=$(pwd)

EditorConfigCliFile="$current_dir/.editorconfig"

if [ -f "$EditorConfigCliFile" ]; then
	echo ".editorconfig file is already exist❗."
else
	cat <<EOL >"$EditorConfigCliFile"
# EditorConfig is awesome: https://editorconfig.org
# top-most EditorConfig file
root = true

# Unix-style newlines with a newline ending every file
[*]
end_of_line = lf
insert_final_newline = true

# Matches multiple files with brace expansion notation
# Set default charset
[*.{js,py}]
charset = utf-8

# 4 space indentation
[*.py]
indent_style = space
indent_size = 4

# Tab indentation (no size specified)
[Makefile]
indent_style = tab

# Indentation override for all JS/TS
[*{.js,ts}]
indent_style = tab
indent_size = 4

# html, css files
[*.{html,css}]
indent_style = tab
indent_size = 4

# Matches the exact files either package.json or .travis.yml
[{package.json,.travis.yml}]
indent_style = space
indent_size = 2
EOL
	echo ".editorconfig file has been create👌."
fi
