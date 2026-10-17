
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

"tema claro escolhido em <leader>4; não dá para usar &background, porque o
"catppuccin_latte força background=dark
function! s:is_light()
	return s:themes[s:theme][1] ==# 'light'
endfunction

"estilo do spell: reaplicado depois de cada colorscheme, que limparia tudo
function! s:spell_highlights()
	highlight clear SpellBad
	"SpellBad com a cor do texto normal, em qualquer tema
	highlight SpellBad ctermfg=white ctermbg=NONE cterm=NONE guifg=NONE guibg=NONE gui=NONE

	"no tema claro, as versões escuras do ciano e do roxo
	let l:light = s:is_light()
	highlight clear SpellCap
	execute 'highlight SpellCap cterm=NONE ctermfg=cyan gui=NONE guisp=NONE guifg=' . (l:light ? '#04a5e5' : '#89dceb')

	highlight clear SpellRare
	execute 'highlight SpellRare cterm=NONE ctermfg=magenta gui=NONE guisp=NONE guifg=' . (l:light ? '#8839ef' : '#cba6f7')

	highlight clear SpellLocal
	highlight SpellLocal cterm=NONE ctermfg=NONE gui=NONE guifg=NONE guisp=NONE
endfunction

augroup spellcolors
	autocmd!
	autocmd ColorScheme * call s:spell_highlights()
augroup END

"fundo do tema escolhido em <leader>1-4 (ver "temas"); NONE usa o fundo do terminal
function! s:background_highlights()
	let l:bg = s:themes[s:theme][2]
	if l:bg ==# ''
		return
	endif
	execute 'highlight Normal ctermbg=NONE guibg=' . l:bg
	highlight FoldColumn guibg=NONE ctermbg=NONE
	highlight Underlined guibg=NONE ctermbg=NONE
endfunction

"texto puro (journal, markdown...) quebra a linha; código vaza para a direita
let s:prose_filetypes = ['', 'text', 'markdown', 'mail', 'gitcommit']

function! s:apply_layout()
	let l:prose = index(s:prose_filetypes, &filetype) >= 0
	"em código a coluna de sinais fica sempre aberta, para o texto não pular quando surge um diff
	let &l:signcolumn = l:prose ? 'auto' : 'yes'
	"<leader>l troca isso por buffer, guardando a escolha em b:wrap
	let &l:wrap = get(b:, 'wrap', l:prose)
endfunction

augroup layout
	autocmd!
	autocmd ColorScheme * call s:background_highlights()
	autocmd BufWinEnter,FileType,WinEnter * call s:apply_layout()
augroup END

"rolagem horizontal suave quando a linha passa da tela
set sidescroll=1
set sidescrolloff=5

"	git diff

"cores do diff no estilo do VS Code: fundo tingido, mantendo as cores da sintaxe
function! s:diff_highlights()
	if s:is_light()
		highlight DiffAdd    guifg=NONE    guibg=#d7f0db gui=NONE
		highlight DiffChange guifg=NONE    guibg=#e1e7f5 gui=NONE
		highlight DiffText   guifg=NONE    guibg=#c3d1f0 gui=NONE
		highlight DiffDelete guifg=#9ca0b0 guibg=#f5d9de gui=NONE
		highlight GitGutterAdd          guifg=#40a02b guibg=NONE
		highlight GitGutterChange       guifg=#df8e1d guibg=NONE
		highlight GitGutterDelete       guifg=#d20f39 guibg=NONE
		highlight GitGutterChangeDelete guifg=#fe640b guibg=NONE
	else
		highlight DiffAdd    guifg=NONE    guibg=#2b3b35 gui=NONE
		highlight DiffChange guifg=NONE    guibg=#2a2d40 gui=NONE
		highlight DiffText   guifg=NONE    guibg=#3d4a6b gui=NONE
		highlight DiffDelete guifg=#6c7086 guibg=#3b2833 gui=NONE
		highlight GitGutterAdd          guifg=#a6e3a1 guibg=NONE
		highlight GitGutterChange       guifg=#f9e2af guibg=NONE
		highlight GitGutterDelete       guifg=#f38ba8 guibg=NONE
		highlight GitGutterChangeDelete guifg=#fab387 guibg=NONE
	endif
	highlight SignColumn guibg=NONE
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
nnoremap <leader>f :Files<CR>

"search by lines"
nnoremap <leader>L :Lines<CR>

"alterna a quebra de linha no buffer atual"
function! s:toggle_wrap()
	let b:wrap = !&l:wrap
	let &l:wrap = b:wrap
endfunction
nnoremap <leader>l :call <SID>toggle_wrap()<CR>

"buffers"
nnoremap <leader>b :Buffers<CR>   

"sair"
nnoremap <leader>q :Explore<CR>   

"source"
nnoremap <leader>r :source %<CR>   

"goyo"
nnoremap <leader>g :Goyo<CR>   

"liga e desliga o diff do arquivo atual com o git, lado a lado"
"o cursor fica no arquivo de verdade, não na cópia do git (onde a margem do gitgutter não aparece)"
function! s:toggle_diff()
	if &diff
		for l:win in range(winnr('$'), 1, -1)
			if bufname(winbufnr(l:win)) =~# '^fugitive://'
				execute l:win 'close'
			endif
		endfor
		diffoff
	else
		Gvdiffsplit
		wincmd p
	endif
endfunction
nnoremap <leader>d :call <SID>toggle_diff()<CR>

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
	Plug 'tomasiser/vim-code-dark'
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

"	temas

"<leader>1 transparente, 2 VS Code, 3 preto, 4 branco
"colorscheme, background e fundo do Normal ('' mantém o fundo do próprio tema)
let s:themes = {
	\ 1: ['catppuccin_mocha', 'dark', 'NONE'],
	\ 2: ['codedark', 'dark', ''],
	\ 3: ['catppuccin_mocha', 'dark', '#000000'],
	\ 4: ['catppuccin_latte', 'light', '#ffffff'],
	\ }
"a escolha fica salva para os próximos vims
let s:theme_file = expand('~/.vim/tema')

function! s:apply_theme(n)
	let s:theme = a:n
	let &background = s:themes[a:n][1]
	execute 'silent! colorscheme' s:themes[a:n][0]
endfunction

function! s:set_theme(n)
	call s:apply_theme(a:n)
	call writefile([a:n], s:theme_file)
endfunction

"plug#end já liga syntax e filetype plugin indent; falta só o tema
let s:theme = filereadable(s:theme_file) ? str2nr(get(readfile(s:theme_file), 0, '1')) : 1
call s:apply_theme(has_key(s:themes, s:theme) ? s:theme : 1)

for s:n in keys(s:themes)
	execute 'nnoremap <silent> <leader>' . s:n . ' :call <SID>set_theme(' . s:n . ')<CR>'
endfor

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


