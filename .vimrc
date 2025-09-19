call plug#begin('~/.vim/plugged')
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'vim-airline/vim-airline'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-surround'
Plug 'airblade/vim-gitgutter'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'joshdick/onedark.vim'
Plug 'ryanoasis/vim-devicons'
Plug 'mattn/emmet-vim'
Plug 'jiangmiao/auto-pairs'
Plug 'christoomey/vim-tmux-navigator'
call plug#end()

" === Performance ===
set lazyredraw
set updatetime=300
set timeoutlen=500

" === Theme ===
syntax on
set termguicolors
colorscheme onedark
hi Normal guibg=NONE ctermbg=NONE
hi EndOfBuffer guibg=NONE ctermbg=NONE

" === General ===
set number relativenumber
set mouse=a
set tabstop=4 shiftwidth=4 expandtab
set smartindent
set ignorecase smartcase
set incsearch nohlsearch
set cursorline signcolumn=yes
set clipboard=unnamedplus
set undofile undodir=~/.vim/undo
set noswapfile nobackup
set hidden
set splitbelow splitright
set scrolloff=8
set wrap linebreak

let mapleader=" "
let g:user_emmet_leader_key='<C-y>'

" === Airline Settings ===
let g:airline_powerline_fonts=0
let g:airline_symbols_ascii=1
let g:airline#extensions#tabline#enabled=0
let g:airline_section_x=''
let g:airline_section_y='%{&filetype}'
let g:airline_section_z='%p%% : %l/%L'
let g:airline_mode_map={
    \ '__': '-',
    \ 'n': 'N',
    \ 'i': 'I',
    \ 'R': 'R',
    \ 'c': 'C',
    \ 'v': 'V',
    \ 'V': 'VL',
    \ 's': 'S',
    \ 'S': 'SL',
    \ }

" === Auto Pairs Settings ===
let g:AutoPairsMapCR=0

" === Tmux Navigator Settings ===
let g:tmux_navigator_save_on_switch=2
let g:tmux_navigator_disable_when_zoomed=1

" === CoC Extensions ===
let g:coc_global_extensions = [
      \ 'coc-tsserver',
      \ 'coc-prettier',
      \ 'coc-eslint',
      \ 'coc-json',
      \ 'coc-html',
      \ 'coc-css',
      \ 'coc-emmet'
      \ ]

" === Auto Format ===
augroup AutoFormat
  autocmd!
  autocmd BufWritePre *.js,*.jsx,*.ts,*.tsx silent! call CocAction('runCommand', 'eslint.executeAutofix')
  autocmd BufWritePre *.js,*.jsx,*.ts,*.tsx,*.json,*.css,*.scss,*.html silent! call CocAction('runCommand', 'prettier.forceFormatDocument')
  autocmd BufWritePre *.ts,*.tsx silent! call CocAction('runCommand', 'tsserver.organizeImports')
augroup END

" === File & Buffer ===
nnoremap <leader>f :Files<CR>
nnoremap <leader>b :Buffers<CR>
nnoremap <leader>g :Rg<CR>
nnoremap <Tab> :bnext<CR>
nnoremap <S-Tab> :bprev<CR>
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>

" === Code Navigation ===
nmap gd <Plug>(coc-definition)
nmap gr <Plug>(coc-references)
nmap [g <Plug>(coc-diagnostic-prev)
nmap ]g <Plug>(coc-diagnostic-next)
nnoremap K :call CocActionAsync('doHover')<CR>

" === Code Actions ===
nmap <leader>rn <Plug>(coc-rename)
nmap <leader>ca <Plug>(coc-codeaction)
nmap <leader>p <Plug>(coc-format)

" === Tmux + Vim Navigation ===
nnoremap <silent> <C-h> :<C-U>TmuxNavigateLeft<CR>
nnoremap <silent> <C-j> :<C-U>TmuxNavigateDown<CR>
nnoremap <silent> <C-k> :<C-U>TmuxNavigateUp<CR>
nnoremap <silent> <C-l> :<C-U>TmuxNavigateRight<CR>

" === Vim Window Resize ===
nnoremap <M-h> :vertical resize -2<CR>
nnoremap <M-j> :resize +2<CR>
nnoremap <M-k> :resize -2<CR>
nnoremap <M-l> :vertical resize +2<CR>

" === Editing ===
inoremap jj <Esc>
vnoremap <C-c> "+y
nnoremap <C-v> "+p
vnoremap < <gv
vnoremap > >gv
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv

" === CoC Completion ===
function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

inoremap <silent><expr> <Tab> coc#pum#visible() ? coc#pum#next(1) : CheckBackspace() ? "\<Tab>" : coc#refresh()
inoremap <silent><expr> <S-Tab> coc#pum#visible() ? coc#pum#prev(1) : "\<S-Tab>"
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm() : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
inoremap <silent><expr> <C-Space> coc#refresh()

" === Colors ===
highlight Pmenu guibg=#21252b guifg=#abb2bf
highlight PmenuSel guibg=#61afef guifg=#282c34
highlight PmenuSbar guibg=#2c323c
highlight PmenuThumb guibg=#61afef
