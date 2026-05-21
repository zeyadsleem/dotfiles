" Minimal fallback for systems without Neovim/LazyVim
set nocompatible
filetype plugin indent on
syntax on

set number relativenumber
set mouse=a
set tabstop=2 shiftwidth=2 expandtab
set smartindent
set ignorecase smartcase
set incsearch nohlsearch
set cursorline signcolumn=yes
set clipboard=unnamedplus
set hidden
set scrolloff=8
set wrap linebreak

let mapleader=" "
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
inoremap jj <Esc>
