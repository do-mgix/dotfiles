
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

"goyo"
nnoremap <leader>g :Goyo<CR>   

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


