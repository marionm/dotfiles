set nocompatible

set runtimepath+=~/.vim/bundles/repos/github.com/Shougo/dein.vim
set runtimepath+=/usr/local/opt/fzf

if dein#load_state('~/.vim/bundles')
  call dein#begin('~/.vim/bundles')
  call dein#add('~/.vim/bundles/repos/github.com/Shougo/dein.vim')

  """ Plugins

  " General
  " call dein#add('airblade/vim-gitgutter')
  call dein#add('kana/vim-fakeclip')
  call dein#add('MarcWeber/vim-addon-local-vimrc')
  call dein#add('mbbill/undotree')
  call dein#add('milkypostman/vim-togglelist')
  call dein#add('rhysd/committia.vim')
  call dein#add('terryma/vim-expand-region')
  call dein#add('terryma/vim-multiple-cursors')
  call dein#add('tmhedberg/matchit')
  call dein#add('tpope/vim-commentary')
  call dein#add('tpope/vim-fugitive')
  call dein#add('tpope/vim-repeat')
  call dein#add('tpope/vim-speeddating')
  call dein#add('tpope/vim-surround')
  call dein#add('SirVer/UltiSnips')
  call dein#add('w0rp/ale')

  " Navigation
  call dein#add('bogado/file-line')
  call dein#add('junegunn/fzf')
  call dein#add('junegunn/fzf.vim')
  call dein#add('mhinz/vim-grepper')
  call dein#add('tpope/vim-projectionist')
  call dein#add('tpope/vim-vinegar')

  " Visual
  call dein#add('altercation/vim-colors-solarized')
  " call dein#add('nathanaelkane/vim-indent-guides')

  " Arduino
  " call dein#add('tclem/vim-arduino')
  " call dein#add('vim-scripts/Arduino-syntax-file')

  " Go
  " call dein#add('fatih/vim-go')

  " JavaScript
  call dein#add('kchmck/vim-coffee-script')
  call dein#add('lukaszb/vim-web-indent')
  call dein#add('yuezk/vim-js')
  call dein#add('pangloss/vim-javascript')
  call dein#add('MaxMEllon/vim-jsx-pretty')

  " Markup
  call dein#add('slim-template/vim-slim')
  call dein#add('tpope/vim-ragtag')
  call dein#add('Valloric/MatchTagAlways')

  " Ruby
  call dein#add('thoughtbot/vim-rspec')
  call dein#add('tpope/vim-endwise')
  call dein#add('tpope/vim-rails')
  call dein#add('vim-ruby/vim-ruby')

  " AI
  call dein#add('github/copilot.vim')
  call dein#add('pasky/claude.vim')

  call dein#end()
  call dein#save_state()
endif

if dein#check_install()
  call dein#install()
  helptags ALL
endif

""" Bindings

" Use Q instead of @q to enable easier one-shot macros
noremap Q @q

" Simplify split navigation
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" Map jj and jk to escape in insert mode
imap jj <ESC>
imap jk <ESC>

" Add binding for new vertical window
nmap <C-W>N :vnew

" Map F5 to paste mode toggle
set pastetoggle=<F5>

" Double-tap leader to clear search results
nmap <silent> <leader><leader> :silent :nohlsearch

" Map * and # to begin seaching for current selection
vmap * "*y:/<C-R>*
vmap # "*y:?<C-R>*

" Quickfix list navigation
nmap [a :cprevious<CR>
nmap ]a :cnext<CR>

" Map F2 to edit .vimrc, F3 to reload it
noremap <F2> :tabedit $MYVIMRC<CR>
noremap <F3> :source $MYVIMRC<CR>

" Map \R to redraw the screen in case of a plugin screwup or whathaveyou
nmap <leader>R :redraw!<CR>

" Map \fr to Ruby
nmap <leader>fr :set ft=ruby<CR>

" Map \fx to XML formatting with xmllint
nmap <leader>fx :%!xmllint --format -<CR>:set ft=xml<CR>
vmap <leader>fx :!xmllint --format -<CR>

" Map \fj to JSON formatting with python
nmap <leader>fj :%!python3 -m json.tool<CR>:set ft=javascript<CR>
vmap <leader>fj :!python3 -m json.tool<CR>

" Map \h to a hacky one-line Ruby hash exploder
" autocmd FileType ruby nmap <leader>h 0/\(\w:\\| =>\)<CR>?\((\\|\s\)<CR>a{<CR><ESC>$i}<ESC>i<CR><ESC>k:s/,\s*/,\r/g<CR>=i{:nohlsearch<CR>
" Grudingly exclude the wrapping braces
autocmd FileType ruby nmap <leader>h 0/\(\w:\\| =>\)<CR>?\((\\|\s\)<CR>a<CR><ESC>$i<ESC>a<CR><ESC>k:s/,\s*/,\r/g<CR>j=%:nohlsearch<CR>

" Map \rl to toggle relative line numbers
" nmap <leader>rl :call SetRelativeNumber()<CR>:se

" Map \yv to yank the current Rails migration version number into the system buffer
nmap <leader>yv ggO%02f/lvt_"+yu``



""" Function bindings
nmap <leader>x :call ExtractVariable()

" Map \bd to delete all empty buffers
" The set/echo ensures the message is displayed even if an open window is closed
nmap <silent> <leader>bd :let deleted = DeleteEmptyBuffers():echo 'Deleted ' . deleted . ' buffer(s)'



""" Plugin bindings

" ale
" nmap \e <Plug>(ale_fix)
nmap <silent> [e <Plug>(ale_previous_wrap)
nmap <silent> ]e <Plug>(ale_next_wrap)

" fzf
nnoremap <c-p> :FZF<CR>

" undotree
nmap <silent> <leader>u :UndotreeToggle

" vim-arduino
" let g:vim_arduino_map_keys = 0
" nnoremap <leader>c :call ArduinoCompile()
" nnoremap <leader>d :call ArduinoDeploy()
" nnoremap <leader>s :call ArduinoSerialMonitor()

" vim-fugitive
if &diff
  " Map dh/dl to apply the left (local) and right (remote) chunk for three-way vimdiff
  " TODO: Sort of buggy, would be nice to get this working
  " nmap dh :diffget 1<Bar>diffupdate<CR>
  " nmap dl :diffget 3<Bar>diffupdate<CR>
  " In the meantime...
  nmap gn /====<CR>
  nmap gN ?====<CR>
  nmap gk V/>>>><CR>d?<<<<<CR>dd
  nmap gj V?<<<<<CR>d/>>>><CR>dd

  " Schema syntax is annoyingly slow for 4 panes
  autocmd BufRead,BufNewFile * if expand('%') =~ "schema.rb" | set syntax=off | endif
endif

" vim-grepper
nmap gs <plug>(GrepperOperator)
xmap gs <plug>(GrepperOperator)
nmap <leader>g :Grepper -cword -noprompt<CR>
nmap <leader>G :GrepperAg 

" vim-rspec
map <Leader>s :call RunNearestSpec()<CR>
map <Leader>p :call RunLastSpec()<CR>
map <Leader>t :call RunCurrentSpecFile()<CR>



""" Plugin settings

" ale
let g:ale_lint_on_enter = 0
let g:ale_lint_on_insert_leave = 0
let g:ale_lint_on_text_changed = 'never'
let g:ale_linters = {
\ 'go': ['gotype', 'gofmt'],
\ 'javascript': ['eslint'],
\ 'ruby': ['rubocop', 'ruby']
\ }

" vim-grepper
let g:grepper = {}
let g:grepper.simple_prompt = 1
let g:grepper.tools = ['ag', 'git', 'ack', 'ack-grep', 'grep']

" vim-rspec
" TODO: Make this more generic
let g:rspec_runner="os_x_iterm2"
let g:rspec_command="rspec --order defined {spec}"


""" Vim settings

syntax on
filetype plugin indent on

set hidden
set mouse=a
set encoding=utf-8
set ttyfast

set tabstop=2
set shiftwidth=2
set nowrap
set autoindent
set expandtab

set number
set cursorline
set colorcolumn=101,121
set synmaxcol=225
set showmode
set ruler
" Show entered partial commands in ruler
set showcmd
" Always show status
set laststatus=2

" Hide toolbar
set guioptions-=T
" Use filename as window title
set title
" Stop vim from setting window title on exit
let &titleold=""

" Simplify external command messages
set shortmess+=filmnrxoOtT
" Allow more command history
set history=1000
" Improve external command tab completion
set wildmenu
set wildmode=list:longest,full

" Improve searching
set ignorecase
set smartcase
set hlsearch
set incsearch

" Improve scrolling and cursor movement
set scrolloff=3
set backspace=indent,eol,start
set whichwrap=b,s,h,l,<,>,[,]
nnoremap <C-e> 3<C-e>
nnoremap <C-y> 3<C-y>

" Improve split behavior
set splitbelow
set splitright

" Prevent netrw from clobbering the alternate buffer register
let g:netrw_altfile=1

au BufRead,BufNewFile *.pde set filetype=arduino
au BufRead,BufNewFile *.ino set filetype=arduino

" Some plugin conflicts with git commit message detection; do it manually
autocmd BufNewFile,BufRead *.git/{,modules/**/}{COMMIT_EDIT,MERGE_}MSG set ft=gitcommit

" Autoreload _vimrc when saving it
autocmd! bufwritepost .vimrc source %

" Consolidate backup files
set backupdir=~/.vimtmp,~/.tmp,~/tmp,/var/tmp,/tmp,c:\tmp
set directory=~/.vimtmp,~/.tmp,~/tmp,/var/tmp,/tmp,c:\tmp

" Enable undo files
if version >= 703
  set undofile
  set undodir=~/.vimtmp,~/.tmp,~/tmp,/var/tmp,/tmp,c:\tmp
endif

" Enable XML and JS folding
let g:xml_syntax_folding=1
au FileType xml setlocal foldmethod=syntax
" au FileType javascript call JavaScriptFold()
" au FileType javascript normal zn
set foldlevelstart=20

" Disable ballooneval, even in the face of plugins (i.e. vim-ruby) and MacVim netrw
if has("balloon_eval")
  set balloondelay=100000
  set noballooneval
  setlocal balloonexpr=
end

" Only show relative line numbers in the current buffer and when focused
" augroup numbertoggle
"   autocmd!
"   autocmd BufEnter,FocusGained * call EnableRelativeNumber()
"   autocmd BufLeave,FocusLost * call DisableRelativeNumber()
" augroup END

" func SetRelativeNumber()
"   let relativenumber_set = 1
" endfunc

" func UnsetRelativeNumber()
"   let relativenumber_set = 0
" endfunc

" func EnableRelativeNumber()
"   if relativenumber_set == 1
"     set relativenumber!
"   endif
" endfunc

" func DisableRelativeNumber()
"   set norelativenumber
" endfunc


""" Visual

colorscheme solarized

func! Mac()
  return has('unix') && system('uname') == "Darwin\n"
endfunc

func! Linux()
  return has('unix') && system('uname') != "Darwin\n"
endfunc

" Set font based on system
if Mac()
  set guifont=Monaco:h14
endif



""" Functions

" Assigns the last removed text to a variable named to the last added text
" TODO: Can this be done with UltiSnips too? (either way, do it for JS also)
func! ExtractVariable()
  if &filetype == "ruby"
    call feedkeys("O. = \"")
  endif
endfunc

func! DeleteEmptyBuffers()
  let [deleted, i, highest] = [0, 1, bufnr('$')]

  while i <= highest
    if buflisted(i) && bufname(i) == ''
      try
        exec 'bdelete' i
        let deleted += 1
      catch
      endtry
    endif
    let i += 1
  endwhile

  return deleted
endfunc

" TODO: Can this be read from an environment variable?
let g:claude_api_key = ''
" If your system node is not at least v18, you can set an override to an asdf or whatever installed version here
" let g:copilot_node_command = '/Users/mikemarion/.asdf/installs/nodejs/18.18.2/bin/node'

" DONT CHECK IN (or maybe do?)
" Disable shift-k keyword lookup
nmap K <C-K>
