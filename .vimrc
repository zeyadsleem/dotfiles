call plug#begin('~/.vim/plugged')

Plug 'tpope/vim-sensible'
Plug 'preservim/nerdtree'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-commentary'
Plug 'airblade/vim-gitgutter'
Plug 'sheerun/vim-polyglot'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'honza/vim-snippets'

call plug#end()

syntax on
set number relativenumber
set numberwidth=6
set mouse=a
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent
set smartindent
set ignorecase
set smartcase
set incsearch
set hlsearch
set cursorline
set ruler
set showcmd
set wildmenu
set laststatus=2
set clipboard=unnamedplus

hi Normal guibg=NONE ctermbg=NONE
hi EndOfBuffer guibg=NONE ctermbg=NONE

let g:airline_powerline_fonts=1
let mapleader=" "

function! ToggleNERDTree(show_hidden)
  if a:show_hidden
    let g:NERDTreeShowHidden=1
  else
    let g:NERDTreeShowHidden=0
  endif
  NERDTreeToggle
endfunction

nnoremap <leader>e :call ToggleNERDTree(1)<CR>
nnoremap <leader>E :call ToggleNERDTree(0)<CR>
nnoremap <leader>f :Files<CR>
nnoremap <leader>b :Buffers<CR>
nnoremap <leader>g :Rg<CR>
nnoremap <leader>h :nohlsearch<CR>
vnoremap <C-c> "+y
nnoremap <C-v> "+p
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>x :x<CR>
nnoremap <leader>= gg=G
inoremap jj <Esc>

nnoremap <leader><leader> <C-^>

set undofile
set undodir=~/.vim/undo
