call plug#begin('~/.vim/plugged')
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'vim-airline/vim-airline'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-surround'
Plug 'airblade/vim-gitgutter'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'joshdick/onedark.vim'
Plug 'mattn/emmet-vim'
Plug 'jiangmiao/auto-pairs'
Plug 'christoomey/vim-tmux-navigator'
Plug 'preservim/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'ryanoasis/vim-devicons'
Plug 'sheerun/vim-polyglot'
Plug 'mbbill/undotree'
call plug#end()

syntax on
set termguicolors
colorscheme onedark
hi Normal guibg=NONE ctermbg=NONE
hi EndOfBuffer guibg=NONE ctermbg=NONE

set number relativenumber
set mouse=a
set tabstop=4 shiftwidth=4 expandtab
set smartindent
set ignorecase smartcase
set incsearch nohlsearch
set cursorline signcolumn=yes
set clipboard=unnamedplus
set undofile undodir=~/.vim/undo//
set noswapfile nobackup
set hidden
set splitbelow splitright
set scrolloff=8
set wrap linebreak
set completeopt=menuone,noinsert,noselect
let mapleader=" "

let g:airline_powerline_fonts=0
let g:airline_symbols_ascii=1

let g:AutoPairsMapCR=0
let g:tmux_navigator_save_on_switch=2
let g:tmux_navigator_disable_when_zoomed=1

let g:coc_global_extensions = [
  \ 'coc-tsserver',
  \ 'coc-prettier',
  \ 'coc-eslint',
  \ 'coc-json',
  \ 'coc-html',
  \ 'coc-css',
  \ 'coc-emmet'
  \ ]

let g:NERDTreeMinimalUI = 1
let g:NERDTreeShowHidden = 1
let g:NERDTreeWinSize = 30
let g:NERDTreeQuitOnOpen = 1
nnoremap <leader>e :NERDTreeToggle<CR>

autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists('s:std_in') | NERDTree | endif

nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <Tab> :bnext<CR>
nnoremap <S-Tab> :bprev<CR>
inoremap jj <Esc>

nnoremap <leader>u :UndotreeToggle<CR>

function! s:close_nerdtree_before_fzf()
  if exists('t:NERDTreeBufName') && bufwinnr(t:NERDTreeBufName) != -1
    NERDTreeClose
  endif
endfunction
command! FilesSafe call s:close_nerdtree_before_fzf() | Files
nnoremap <leader>f :FilesSafe<CR>

nmap gd <Plug>(coc-definition)
nmap gr <Plug>(coc-references)
nmap [g <Plug>(coc-diagnostic-prev)
nmap ]g <Plug>(coc-diagnostic-next)
nnoremap K :call CocActionAsync('doHover')<CR>
nmap <leader>rn <Plug>(coc-rename)
nmap <leader>p <Plug>(coc-format)

nnoremap <silent> <C-h> :TmuxNavigateLeft<CR>
nnoremap <silent> <C-j> :TmuxNavigateDown<CR>
nnoremap <silent> <C-k> :TmuxNavigateUp<CR>
nnoremap <silent> <C-l> :TmuxNavigateRight<CR>

highlight Pmenu guibg=#21252b guifg=#abb2bf
highlight PmenuSel guibg=#61afef guifg=#282c34
highlight PmenuSbar guibg=#2c323c
highlight PmenuThumb guibg=#61afef
