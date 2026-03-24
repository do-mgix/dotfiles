
"	configs 	"

"permite navegação livre no arquivo"
set virtualedit=onemore

""ativar área de transferência""
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

" Autocomando para abrir o Netrw ao iniciar o Vim sem arquivos
autocmd VimEnter * if argc() == 0 | execute 'Explore' | endif

" Autocomando para abrir o Netrw quando o último buffer for fechado
autocmd BufEnter * if winnr('$') == 1 && bufname('$') == '' | execute 'Explore' | endif

"Goyo
autocmd VimEnter * if argc() == 0 && &buftype == '' | Goyo | endif

"	estilo

" remove o banner de cabeçalho para mais espaço
let g:netrw_banner = 0

"estilo do spell
highlight clear SpellBad
highlight SpellBad ctermfg=white ctermbg=NONE cterm=NONE 

highlight clear SpellCap
highlight SpellCap cterm=NONE ctermfg=cyan gui=NONE guisp=NONE

highlight clear SpellRare
highlight SpellRare cterm=NONE ctermfg=magenta gui=NONE guisp=NONE

highlight clear SpellLocal
highlight SpellLocal cterm=NONE ctermfg=NONE gui=NONE guisp=NONE

"	plugins visuais


"	configuração remap

" navegação j e k por linhas visuais quando o wrap estiver ativo
"nnoremap <silent> j gj
"nnoremap <silent> k gk   

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
nnoremap <leader>q :bd<CR>   

"sair"
nnoremap <leader>t :termi<CR>   

"plugins"
call plug#begin()  " Ou call plug#begin('~/.vim/plugged')

	" Lista de plugins
	Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
	Plug 'junegunn/fzf.vim'
	Plug 'tpope/vim-fugitive'
	Plug 'junegunn/goyo.vim'
	Plug 'junegunn/limelight.vim'
	Plug 'hardselius/warlock'

call plug#end()     


