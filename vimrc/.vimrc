
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

"fundo transparente por padrão; o fundo do tema só aparece em código aberto pelo <leader>f
let s:prose_filetypes = ['', 'text', 'markdown', 'mail', 'gitcommit']

function! s:transparent_highlights()
	highlight TransparentNormal guifg=#cdd6f4 guibg=NONE ctermbg=NONE
endfunction

function! s:apply_bg()
	let l:prose = index(s:prose_filetypes, &filetype) >= 0
	let l:themed = !l:prose && get(b:, 'themed_bg', 0)
	let &l:wincolor = l:themed ? '' : 'TransparentNormal'
	"em código a coluna de sinais fica sempre aberta, para o texto não pular quando surge um diff
	let &l:signcolumn = l:prose ? 'auto' : 'yes'
	"código vaza para a direita em vez de quebrar a linha; texto continua quebrando
	let &l:wrap = l:prose
endfunction

"abre os arquivos escolhidos no fzf marcando-os para receber o fundo do tema
"a primeira linha é a tecla usada (vazia no enter); ctrl-t/x/v abrem em aba/split/vsplit
let s:files_actions = {'ctrl-t': 'tab split', 'ctrl-x': 'split', 'ctrl-v': 'vsplit'}

function! s:open_from_files(lines)
	if len(a:lines) < 2
		return
	endif
	let l:cmd = get(get(g:, 'fzf_action', s:files_actions), a:lines[0], 'edit')
	if type(l:cmd) != v:t_string
		let l:cmd = 'edit'
	endif
	for l:file in a:lines[1:]
		execute l:cmd fnameescape(l:file)
		let b:themed_bg = 1
		call s:apply_bg()
	endfor
endfunction

function! s:files()
	call fzf#vim#files('', fzf#vim#with_preview({'sink*': function('s:open_from_files')}))
endfunction

augroup themedbg
	autocmd!
	autocmd ColorScheme * call s:transparent_highlights()
	autocmd BufWinEnter,FileType,WinEnter * call s:apply_bg()
augroup END

"rolagem horizontal suave quando a linha passa da tela
set sidescroll=1
set sidescrolloff=5

"	git diff

"cores do diff no estilo do VS Code: fundo tingido, mantendo as cores da sintaxe
function! s:diff_highlights()
	highlight DiffAdd    guifg=NONE    guibg=#2b3b35 gui=NONE
	highlight DiffChange guifg=NONE    guibg=#2a2d40 gui=NONE
	highlight DiffText   guifg=NONE    guibg=#3d4a6b gui=NONE
	highlight DiffDelete guifg=#6c7086 guibg=#3b2833 gui=NONE
	highlight SignColumn guibg=NONE
	highlight GitGutterAdd          guifg=#a6e3a1 guibg=NONE
	highlight GitGutterChange       guifg=#f9e2af guibg=NONE
	highlight GitGutterDelete       guifg=#f38ba8 guibg=NONE
	highlight GitGutterChangeDelete guifg=#fab387 guibg=NONE
endfunction

augroup diffcolors
	autocmd!
	autocmd ColorScheme * call s:diff_highlights()
augroup END

"barras finas na margem, como no VS Code
let g:gitgutter_sign_added = '▎'
let g:gitgutter_sign_modified = '▎'
let g:gitgutter_sign_removed = '▁'
let g:gitgutter_sign_removed_first_line = '▔'
let g:gitgutter_sign_modified_removed = '▎'
"atualiza os sinais 100ms depois de parar de digitar
set updatetime=100

"diff lado a lado e com alinhamento melhor
set diffopt+=vertical,algorithm:histogram,indent-heuristic

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
nnoremap <leader>f :call <SID>files()<CR>

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

"diff do arquivo atual com o último commit, lado a lado"
nnoremap <leader>d :Gvdiffsplit<CR>

"git status do fugitive (s/u para stage/unstage, dv no arquivo abre o diff)"
nnoremap <leader>G :Git<CR>

"sair"
nnoremap <leader>t :termi<CR>   

"plugins"

"o polyglot não detecta identação: isso fica com o vim-sleuth
let g:polyglot_disabled = ['autoindent']

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
	Plug 'jiangmiao/auto-pairs'
	Plug 'airblade/vim-gitgutter'
	Plug 'sheerun/vim-polyglot'

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


