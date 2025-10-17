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
Plug 'mattn/emmet-vim'
Plug 'jiangmiao/auto-pairs'
Plug 'christoomey/vim-tmux-navigator'
Plug 'preservim/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'ryanoasis/vim-devicons'
Plug 'sheerun/vim-polyglot'
Plug 'mbbill/undotree'
Plug 'junegunn/vim-easy-align'
Plug 'easymotion/vim-easymotion'
Plug 'pangloss/vim-javascript'
Plug 'leafgarland/typescript-vim'
Plug 'maxmellon/vim-jsx-pretty'
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
Plug 'tpope/vim-rhubarb'
Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
Plug 'yegappan/mru'
Plug 'kyazdani42/nvim-web-devicons'
call plug#end()

" === Performance Settings ===
set lazyredraw
set updatetime=300
set timeoutlen=500
set synmaxcol=200
set regexpengine=1

" === Theme and Syntax ===
syntax on
set termguicolors
colorscheme onedark
hi Normal guibg=NONE ctermbg=NONE
hi EndOfBuffer guibg=NONE ctermbg=NONE

" === General Editing Settings ===
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
set directory=~/.vim/swp//
set hidden
set splitbelow splitright
set scrolloff=8
set wrap linebreak
set foldmethod=indent
set foldlevelstart=99
set completeopt=menuone,noinsert,noselect
set shortmess+=c
autocmd BufLeave * if &buftype == '' | update | endif

let mapleader=" "
let g:user_emmet_leader_key='<C-y>'

" === Airline Status Bar ===
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

" === Auto Pairs and Tmux ===
let g:AutoPairsMapCR=0
let g:tmux_navigator_save_on_switch=2
let g:tmux_navigator_disable_when_zoomed=1

" === CoC Extensions and Auto Format ===
let g:coc_global_extensions = [
    \ 'coc-tsserver',
    \ 'coc-prettier',
    \ 'coc-eslint',
    \ 'coc-json',
    \ 'coc-html',
    \ 'coc-css',
    \ 'coc-emmet',
    \ 'coc-snippets'
    \ ]

augroup AutoFormat
    autocmd!
    autocmd BufWritePre *.js,*.jsx,*.ts,*.tsx silent! call CocAction('runCommand', 'eslint.executeAutofix')
    autocmd BufWritePre *.js,*.jsx,*.ts,*.tsx,*.json,*.css,*.scss,*.html silent! call CocAction('runCommand', 'prettier.forceFormatDocument')
    autocmd BufWritePre *.ts,*.tsx silent! call CocAction('runCommand', 'tsserver.organizeImports')
augroup END

" === NERDTree File Explorer ===
nnoremap <leader>e :NERDTreeToggle<CR>
let g:NERDTreeMinimalUI = 1
let g:NERDTreeWinSize = 30
let g:NERDTreeDirArrowExpandable = '>'
let g:NERDTreeDirArrowCollapsible = 'v'
let g:NERDTreeAutoDeleteBuffer = 1
let g:NERDTreeQuitOnOpen = 1
let g:NERDTreeShowBookmarks = 1
let g:NERDTreeGitStatusUseNerdFonts = 0
let g:NERDTreeIgnore = ['^node_modules$', '^dist$', '^build$', '^\.git$', '\.DS_Store$', '\.pyc$', '__pycache__', '\.swp$']
let g:NERDTreeGitStatusShowIgnored = 1
let g:NERDTreeShowHidden = 1
let g:NERDTreeHighlightCursorline = 1
let g:NERDTreeRespectWildIgnore = 1

let g:NERDTreeGitStatusIndicatorMapCustom = {
    \ 'Modified' : '*',
    \ 'Staged' : '+',
    \ 'Untracked' : '?',
    \ 'Renamed' : '->',
    \ 'Unmerged' : '=',
    \ 'Deleted' : 'x',
    \ 'Dirty' : '!',
    \ 'Clean' : '',
    \ 'Ignored' : 'X',
    \ 'Unknown' : '?'
    \ }

let g:NERDTreeFileExtensionHighlightFullName = 1
let g:NERDTreeExactMatchHighlightFullName = 1
let g:NERDTreePatternMatchHighlightFullName = 1
let g:NERDTreeHighlightFolders = 1

let g:NERDTreeSyntaxDisableDefaultExtensions = 0
let g:NERDTreeSyntaxDisableDefaultExactMatches = 0
let g:NERDTreeSyntaxDisableDefaultPatternMatches = 0
let g:NERDTreeSyntaxEnabledExtensions = ['js', 'ts', 'jsx', 'tsx', 'html', 'css', 'json', 'md', 'py', 'vim', 'rb']
let g:NERDTreeSyntaxEnabledExactMatches = ['node_modules', 'dist', 'build', '.git']

autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists('s:std_in') | NERDTree | endif
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif

autocmd BufEnter * if bufname('#') =~ 'NERD_tree \d\+' && bufname('%') !~ 'NERD_tree_' && winnr('$') > 1 |
    \ let buf=bufnr() | buffer# | execute "normal! \<C-W>w" | execute 'buffer'.buf | endif

let g:NERDTreeChDirMode = 2
let g:NERDTreeSortOrder = ['^__\.py$', '\/$', '*', '\.swp$', '\.bak$', '\~$']

let g:NERDTreeMapActivateNode='o'
let g:NERDTreeMapPreview='p'
let g:NERDTreeMapDeleteBookmark='D'

function! NERDTreeAddNode()
  let l:node = g:NERDTreeFileNode.GetSelected()
  if l:node == {} || !l:node.isDir | let l:currentDir = getcwd() | else | let l:currentDir = l:node.path.str() | endif
  let l:path = input('New file/folder (relative to ' . l:currentDir . '): ', '', 'file')
  if empty(l:path) | return | endif
  let l:fullpath = l:currentDir . '/' . l:path
  if l:path =~ '/$'
    silent! exec '!mkdir -p ' . fnameescape(l:fullpath)
  else
    silent! exec '!touch ' . fnameescape(l:fullpath)
  endif
  call b:NERDTree.root.refresh()
  call b:NERDTree.render()
endfunction

function! NERDTreeDeleteNode()
  let l:node = g:NERDTreeFileNode.GetSelected()
  if l:node == {} | return | endif
  let l:confirm = confirm('Delete ' . l:node.path.str() . '? ', "&Yes\n&No")
  if l:confirm == 1
    silent! exec '!rm -rf ' . fnameescape(l:node.path.str())
    call l:node.parent.refresh()
    call b:NERDTree.render()
  endif
endfunction

function! NERDTreeMoveNode()
  let l:node = g:NERDTreeFileNode.GetSelected()
  if l:node == {} | return | endif
  let l:newpath = input('Move to: ', l:node.path.str())
  if empty(l:newpath) | return | endif
  silent! exec '!mv ' . fnameescape(l:node.path.str()) . ' ' . fnameescape(l:newpath)
  if v:shell_error == 0
    call l:node.parent.refresh()
    call b:NERDTree.render()
  else
    echo 'Error: File exists or permission issue.'
  endif
endfunction

function! NERDTreeCopyNode()
  let l:node = g:NERDTreeFileNode.GetSelected()
  if l:node == {} | return | endif
  let l:newpath = input('Copy to: ', l:node.path.str())
  if empty(l:newpath) | return | endif
  silent! exec '!cp -r ' . fnameescape(l:node.path.str()) . ' ' . fnameescape(l:newpath)
  if v:shell_error == 0
    call l:node.parent.refresh()
    call b:NERDTree.render()
  else
    echo 'Error: File exists or permission issue.'
  endif
endfunction

autocmd FileType nerdtree nnoremap <buffer> a :call NERDTreeAddNode()<CR>
autocmd FileType nerdtree nnoremap <buffer> d :call NERDTreeDeleteNode()<CR>
autocmd FileType nerdtree nnoremap <buffer> m :call NERDTreeMoveNode()<CR>
autocmd FileType nerdtree nnoremap <buffer> c :call NERDTreeCopyNode()<CR>
autocmd FileType nerdtree nnoremap <buffer> r :NERDTreeRefreshRoot<CR>
nnoremap <leader>n :NERDTreeFind<CR>
nnoremap <leader>r :NERDTreeRefreshRoot<CR>

" === MRU Configuration ===
let g:MRU_Max_Entries = 100
let g:MRU_File = '~/.vim_mru_files'
let g:MRU_Exclude_Files = '^/tmp/.*\|^/var/tmp/.*'
let g:MRU_Add_Menu = 1
let g:MRU_Open_Below = 1
nnoremap <leader>m :MRU<CR>

" === FZF Search Integration ===
function! s:fzf_files_with_nerdtree()
  if exists('t:NERDTreeBufName') && bufwinnr(t:NERDTreeBufName) != -1
    NERDTreeClose
  endif
  Files
endfunction
command! FilesWithNERDTree call <SID>fzf_files_with_nerdtree()
nnoremap <leader>f :FilesWithNERDTree<CR>

function! s:fzf_rg_with_nerdtree()
  if exists('t:NERDTreeBufName') && bufwinnr(t:NERDTreeBufName) != -1
    NERDTreeClose
  endif
  Rg
endfunction
command! RgWithNERDTree call <SID>fzf_rg_with_nerdtree()
nnoremap <leader>g :RgWithNERDTree<CR>

nnoremap <leader>b :Buffers<CR>
nnoremap <leader>/ :BLines<CR>

" === Undotree and EasyAlign ===
nnoremap <leader>u :UndotreeToggle<CR>
let g:undotree_SetFocusWhenToggle = 1

xmap ga <Plug>(EasyAlign)
nmap ga <Plug>(EasyAlign)

" === EasyMotion Navigation ===
let g:EasyMotion_do_mapping = 0
nmap <leader><leader>w <Plug>(easymotion-w)
nmap <leader><leader>b <Plug>(easymotion-b)
map  <leader><leader>s <Plug>(easymotion-s2)
let g:EasyMotion_smartcase = 1

" === Buffer Management ===
nnoremap <Tab> :bnext<CR>
nnoremap <S-Tab> :bprev<CR>
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>

" === CoC Code Navigation and Actions ===
nmap gd <Plug>(coc-definition)
nmap gr <Plug>(coc-references)
nmap [g <Plug>(coc-diagnostic-prev)
nmap ]g <Plug>(coc-diagnostic-next)
nnoremap K :call CocActionAsync('doHover')<CR>

nmap <leader>rn <Plug>(coc-rename)
nmap <leader>ca <Plug>(coc-codeaction)
nmap <leader>p <Plug>(coc-format)

" === Tmux and Window Navigation ===
nnoremap <silent> <C-h> :TmuxNavigateLeft<CR>:wincmd h<CR>
nnoremap <silent> <C-j> :TmuxNavigateDown<CR>:wincmd j<CR>
nnoremap <silent> <C-k> :TmuxNavigateUp<CR>:wincmd k<CR>:setlocal wrap linebreak nolist nonumber norelativenumber signcolumn=no<CR>
nnoremap <silent> <C-l> :TmuxNavigateRight<CR>:wincmd l<CR>

nnoremap <M-h> :vertical resize -2<CR>
nnoremap <M-j> :resize +2<CR>
nnoremap <M-k> :resize -2<CR>
nnoremap <M-l> :vertical resize +2<CR>

" === Editing Shortcuts ===
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

" === Popup Menu Colors ===
highlight Pmenu guibg=#21252b guifg=#abb2bf
highlight PmenuSel guibg=#61afef guifg=#282c34
highlight PmenuSbar guibg=#2c323c
highlight PmenuThumb guibg=#61afef

" === URL Opening and Read Mode Toggle ===
nnoremap gx :call netrw#BrowseX(expand('<cfile>'), 0)<CR>
xnoremap gx :call netrw#BrowseX(expand('<cfile>'), 0)<CR>
nnoremap <silent> q :setlocal number! relativenumber! signcolumn=yes nowrap nolinebreak list<CR>

" === UltiSnips Snippet Expansion ===
let g:UltiSnipsExpandTrigger="<C-j>"

" === DevIcons Integration ===
let g:webdevicons_enable_nerd_tree = 1
let g:webdevicons_conceal_nerdtree_brackets = 1
