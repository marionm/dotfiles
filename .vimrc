set nocompatible

""" Plugins

set rtp+=~/.vim/bundle/neobundle.vim/
call neobundle#rc(expand('~/.vim/bundle'))
NeoBundleFetch 'Shougo/neobundle.vim'

" General
NeoBundle 'airblade/vim-gitgutter'
NeoBundle 'kana/vim-fakeclip'
NeoBundle 'MarcWeber/vim-addon-local-vimrc'
NeoBundle 'mbbill/undotree'
NeoBundle 'scrooloose/syntastic'
NeoBundle 'terryma/vim-expand-region'
NeoBundle 'terryma/vim-multiple-cursors'
NeoBundle 'tmhedberg/matchit'
NeoBundle 'tpope/vim-commentary'
NeoBundle 'tpope/vim-fugitive'
NeoBundle 'tpope/vim-surround'

" Navigation
NeoBundle 'bogado/file-line'
NeoBundle 'kien/ctrlp.vim'
NeoBundle 'mileszs/ack.vim'
NeoBundle 'scrooloose/nerdtree'

" Visual
NeoBundle 'altercation/vim-colors-solarized'
" NeoBundle 'nathanaelkane/vim-indent-guides'

" Arduino
" NeoBundle 'tclem/vim-arduino'
" NeoBundle 'vim-scripts/Arduino-syntax-file'

" JavaScript
NeoBundle 'jelera/vim-javascript-syntax'
NeoBundle 'lukaszb/vim-web-indent'
NeoBundle 'mxw/vim-jsx'

" Markup
NeoBundle 'tpope/vim-ragtag'
NeoBundle 'Valloric/MatchTagAlways'

" Ruby
NeoBundle 'tpope/vim-endwise'
NeoBundle 'vim-ruby/vim-ruby'



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

" Use ctrl-space for autocompletion
inoremap <C-Space> <C-N>

" Double-tap leader to clear search results
nmap <silent> <leader><leader> :silent :nohlsearch

" Map * and # to begin seaching for current selection
vmap * "*y:/<C-R>*
vmap # "*y:?<C-R>*

" Quickfist list (Ack/ag) navigation
nmap [a :cprevious
nmap ]a :cnext

" Location list navigation, with wraparound
nmap [[ :execute "try\n lprevious\n catch\n ll 99999\n endtry"
nmap ]] :execute "try\n lnext\n catch\n ll 1\n endtry"

" Map F2 to edit .vimrc, F3 to reload it
noremap <F2> :sp $MYVIMRC
noremap <F3> :source $MYVIMRC

" Map \fx to XML formatting with xmllint
noremap <leader>fx :%!xmllint --format -:set ft=xml



""" Function bindings

" Map \be, \d, and \i to framework specific test templates
nmap <leader>be :call BeforeBlock()
nmap <leader>d :call DescribeBlock()
nmap <leader>c :call ContextBlock()
nmap <leader>i :call ItBlock()

" Map \bd to delete all empty buffers
" The set/echo ensures the message is displayed even if an open window is closed
nmap <silent> <leader>bd :let deleted = DeleteEmptyBuffers():echo 'Deleted ' . deleted . ' buffer(s)'

" Map \g to switch colors for screen type
nmap <silent> <leader>g :call SwitchScreenType()



""" Plugin bindings

" Map \a to Ack current word
nmap <leader>a :Ack! <C-R><C-W>

" Map \A to prep Ack for current word
nmap <leader>A :Ack! <C-R><C-W>

" Bindings for Syntastic errors
nmap \E :SyntasticCheck
nmap \e :Errors

" Map \r to reveal in NERDTree
nmap <silent> <leader>r :NERDTreeFind

" Map \n to toggle NERDTree
nmap <silent> <leader>n :NERDTreeToggle

" Map \u to toggle undo tree
nmap <silent> <leader>u :UndotreeToggle

" Use custom Arduino bindings
" let g:vim_arduino_map_keys = 0
" nnoremap <leader>c :call ArduinoCompile()
" nnoremap <leader>d :call ArduinoDeploy()
" nnoremap <leader>s :call ArduinoSerialMonitor()



""" Plugin settings

" Enable automatic population of location list
let syntastic_always_populate_loc_list = 1

" Use ag for Ack (if available)
if executable('ag')
  let g:ackprg = 'ag --vimgrep'
endif



""" Vim settings

filetype plugin indent on
syntax on

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
if version >= 703
  "Map \l to toggle relative line numbering
  nnoremap <silent> <leader>l :if &relativenumber==0set relativenumberelseset norelativenumberendif
endif

set cursorline
set colorcolumn=100
set showmode
" Show buffer number and cursor position in ruler
set ruler
set rulerformat=%=\:b%n\ %l,%c%V\ %P
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
au FileType javascript call JavaScriptFold()
au FileType javascript normal zn
set foldlevelstart=20



""" Appearance

func! Mac()
  return has('unix') && system('uname') == "Darwin\n"
endfunc

func! Linux()
  return has('unix') && system('uname') != "Darwin\n"
endfunc

" Set font based on system
if Mac()
  set guifont=Monaco:h13
endif

func! MatteScreen()
  silent! colorscheme solarized
  set background=dark
  let g:matteScreen=1
endfunc

func! GlossyScreen()
  set background=light
  try
    silent! colorscheme macvim
    highlight Normal guibg=#dfdfdf
    highlight StatusLineNC guibg=DarkSlateGray guifg=Gray70
  catch
  endtry
  let g:matteScreen=0
endfunc

func! SwitchScreenType()
  if g:matteScreen
    call GlossyScreen()
  else
    call MatteScreen()
  end
endfunc

if exists("g:matteScreen")
  "Reset colorscheme after a configuration reload to prevent weirdness
  if g:matteScreen
    call MatteScreen()
  else
    call GlossyScreen()
  endif
else
  "Set initial colorscheme based on configured screen type
  call MatteScreen()
  " call GlossyScreen()
endif



""" Functions

func! BeforeBlock()
  if &filetype == "javascript"
    call feedkeys("obeforeEach(() => {});k=}o  ")
  elseif &filetype == "ruby"
    call feedkeys("obefore dok=}jddko")
  endif
endfunc

func! DescribeBlock()
  if &filetype == "javascript"
    call feedkeys("odescribe('', () => {});k=}f'a")
  elseif &filetype == "ruby"
    call feedkeys("odescribe \"\" dok=}jddkf\"a")
  endif
endfunc

func! ContextBlock()
  call feedkeys("ocontext \"\" dok=}jddkf\"a")
endfunc

func! ItBlock()
  if &filetype == "javascript"
    call feedkeys("oit('', () => {});k=}f'a")
  elseif &filetype == "ruby"
    call feedkeys("oit \"\" dok=}jddkf\"a")
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
