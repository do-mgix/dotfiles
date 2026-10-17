
"	configs 	"

" Ativa a quebra de linha visual
set wrap

" Garante que a quebra ocorra entre as palavras, não no meio delas
set linebreak

"permite navegação livre no arquivo"
set virtualedit=onemore

"ativar área de transferência
set clipboard=unnamedplus

"forçar visualização cortada (evita @)"
set display+=lastline 

"corretor ortográfico
set spell
set spelllang=pt_br,en_us

"ativa mouse
set mouse=a   

"impedir cópia com p
xnoremap p "_dP   

"	inicialização

function! s:goyo_enter()
  if executable('tmux') && strlen($TMUX)
    silent !tmux set status off
    silent !tmux list-panes -F '\#F' | grep -q Z || tmux resize-pane -Z
  endif
  set noshowmode
  set noshowcmd
  set scrolloff=999
  Limelight
endfunction

function! s:goyo_leave()
  if executable('tmux') && strlen($TMUX)
    silent !tmux set status on
    silent !tmux resize-pane -Z
  endif
  set showmode
  set showcmd
  set scrolloff=5
  Limelight!
endfunction

autocmd! User GoyoEnter nested call <SID>goyo_enter()
autocmd! User GoyoLeave nested call <SID>goyo_leave()

"	estilo
set background=dark
let g:limelight_conceal_ctermfg = 238

" remove o banner de cabeçalho para mais espaço
let g:netrw_banner = 0

"cores de 24 bits, como no VS Code
set termguicolors

"estilo do spell: reaplicado depois de cada colorscheme, que limparia tudo
function! s:spell_highlights()
	highlight clear SpellBad
	highlight SpellBad ctermfg=white ctermbg=NONE cterm=NONE guifg=#cdd6f4 guibg=NONE gui=NONE

	highlight clear SpellCap
	highlight SpellCap cterm=NONE ctermfg=cyan gui=NONE guifg=#89dceb guisp=NONE

	highlight clear SpellRare
	highlight SpellRare cterm=NONE ctermfg=magenta gui=NONE guifg=#cba6f7 guisp=NONE

	highlight clear SpellLocal
	highlight SpellLocal cterm=NONE ctermfg=NONE gui=NONE guifg=NONE guisp=NONE
endfunction

augroup spellcolors
	autocmd!
	autocmd ColorScheme * call s:spell_highlights()
augroup END

"	identação

"padrão de 2 espaços; o vim-sleuth ajusta quando o arquivo já usa outro estilo
set expandtab
set tabstop=2
set shiftwidth=2
set softtabstop=2
"mantém a identação da linha anterior ao dar enter
set autoindent
"backspace apaga identação, quebras de linha e o início da inserção
set backspace=indent,eol,start

"	plugins visuais


"	configuração remap

" navegação j e k por linhas visuais quando o wrap estiver ativo
"nnoremap <silent> j gj
"nnoremap <silent> k gk   

"	caracteres especiais 
inoremap -- —

"	atalhos		"

"leader vira espaço"
let mapleader = " " 

"abre file search fzf"
nnoremap <leader>f :Files<CR>   

"search by lines"
nnoremap <leader>l :Lines<CR>   

"buffers"
nnoremap <leader>b :Buffers<CR>   

"sair"
nnoremap <leader>q :Explore<CR>   

"source"
nnoremap <leader>r :source %<CR>   

"goyo"
nnoremap <leader>g :Goyo<CR>   

"sair"
nnoremap <leader>t :termi<CR>   

"plugins"
call plug#begin('~/.vim/plugged')

	" Lista de plugins
	Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
	Plug 'junegunn/fzf.vim'
	Plug 'tpope/vim-fugitive'
	Plug 'junegunn/goyo.vim'
	Plug 'junegunn/limelight.vim'
	Plug 'catppuccin/vim', { 'as': 'catppuccin' }
	Plug 'lifepillar/vim-mucomplete'
	Plug 'tpope/vim-dispatch'
	Plug 'romainl/vim-qf'
	Plug 'Yggdroot/indentLine'
	Plug 'tpope/vim-sleuth'
	Plug 'alvan/vim-closetag'

call plug#end()

"plug#end já liga syntax e filetype plugin indent; falta só o tema
silent! colorscheme catppuccin_mocha

"mucomplete: exige menuone no completeopt
set completeopt+=menuone,noselect
set shortmess+=c
"sem bipe durante a completação
set belloff+=ctrlg
"autocompletion ligada ao abrir o vim
let g:mucomplete#enable_auto_at_startup = 1
"tab escreve a opção do menu: a primeira, ou a escolhida com as setas
imap <expr> <Tab> pumvisible() ? (complete_info(['selected']).selected == -1 ? "\<C-n>\<C-y>" : "\<C-y>") : "\<Plug>(MUcompleteFwd)"

"browser-sync: :Serve em html, css e js
augroup browsersync
	autocmd!
	autocmd FileType html,css,javascript command! -buffer Serve :Dispatch browser-sync start --server --files "*.html, *.css, *.js"
augroup END


