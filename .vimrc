set nocompatible

""" Plugins

set rtp+=~/.vim/bundle/neobundle.vim/
call neobundle#rc(expand('~/.vim/bundle'))
NeoBundleFetch 'Shougo/neobundle.vim'

" General
NeoBundle 'kana/vim-fakeclip'
NeoBundle 'scrooloose/syntastic'
NeoBundle 'terryma/vim-expand-region'
NeoBundle 'terryma/vim-multiple-cursors'
NeoBundle 'tmhedberg/matchit'
NeoBundle 'tpope/vim-commentary'
NeoBundle 'tpope/vim-surround'

" Navigation
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
nmap <C-W>N :vnew<CR>

" Map F5 to paste mode toggle
set pastetoggle=<F5>

" Use ctrl-space for autocompletion
inoremap <C-Space> <C-N>

" Double-tap backslash to clear search results
nmap <silent> <leader>\ :silent :nohlsearch<CR>

" Map * and # to begin seaching for current selection
vmap * "*y:/<C-R>*<CR>
vmap # "*y:?<C-R>*<CR>

" Quickfist list (Ack) navigation
nmap [a :cprevious<CR>
nmap ]a :cnext<CR>

" Location list navigation, with wraparound
nmap [[ :execute "try\n lprevious\n catch\n ll 99999\n endtry"<CR>
nmap ]] :execute "try\n lnext\n catch\n ll 1\n endtry"<CR>

" Map F2 to edit .vimrc, F3 to reload it
noremap <F2> :sp $MYVIMRC<CR>
noremap <F3> :source $MYVIMRC<CR>

" Map F10 to a super hacky angular test injection helper
noremap <F10> ^"iy$Ilet <ESC>A;<ESC>o<CR>beforeEach(inject((<CR>_<C-R>i_<CR>) => {<ESC>k:s/, /_, _/g<CR>jo<C-R>i, <ESC>:s/\(\$\?\w*\), /\1 = _\1_;\r/g<CR>O}));<ESC>Vgg= 

" Map F11 to a super hacky full-file Ruby object formatting macro
noremap <F11> O<ESC>ggVGgJ:%s/{/{\r/g<CR>:%s/}/\r}/g<CR>:%s/,/,\r/g<CR>:%s/=>/ => /g<CR>:se ft=ruby<CR>gg=G

" Map F12 to a super hacky full-file XML formatting macro
noremap <F12> O<ESC>ggVGgJ:s/> *</>\r</g<CR>:se ft=xml<CR>gg=G



""" Function bindings

" Map \be, \d, and \i to framework specific test templates
nmap <leader>be :call BeforeBlock()<CR>
nmap <leader>d :call DescribeBlock()<CR>
nmap <leader>i :call ItBlock()<CR>

" Map \bd to delete all empty buffers
" The set/echo ensures the message is displayed even if an open window is closed
nmap <silent> <leader>bd :let deleted = DeleteEmptyBuffers()<CR>:echo 'Deleted ' . deleted . ' buffer(s)'<CR>

" Map \g to switch colors for screen type
nmap <silent> <leader>g :call SwitchScreenType()<CR>



""" Plugin bindings

" Map \a to Ack current word
nmap <leader>a :Ack <C-R><C-W><CR>

" Map \A to prep Ack for current word
nmap <leader>A :Ack <C-R><C-W>

" Bindings for Syntastic errors
nmap \E :SyntasticCheck<CR>
nmap \e :Errors<CR>

" Map \r to reveal in NERDTree
nmap <silent> <leader>r :NERDTreeFind<CR>

" Map \n to toggle NERDTree
nmap <silent> <leader>n :NERDTreeToggle<CR>

" Use custom Arduino bindings
" let g:vim_arduino_map_keys = 0
" nnoremap <leader>c :call ArduinoCompile()<CR>
" nnoremap <leader>d :call ArduinoDeploy()<CR>
" nnoremap <leader>s :call ArduinoSerialMonitor()<CR>



""" Settings

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

" Use tabs
" set noexpandtab
" ...or grudgingly conform to other people and use spaces
set expandtab

set number
if version >= 703
  "Default to relative line numbers
  " set relativenumber
  "Map \l to toggle relative line numbering
  nnoremap <silent> <leader>l :if &relativenumber==0<CR>set relativenumber<CR>else<CR>set norelativenumber<CR>endif<CR>
endif

set cursorline
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



" Set ctrlp exclusions
" If it isn't working, run :ClearAllCtrlPCaches
let g:ctrlp_custom_ignore = 'bower_components/\|node_modules/\|cordova\|dist\|deployer/'

" Make syntastic a bit more permissive for HTML and AngularJS
let g:syntastic_html_tidy_ignore_errors = [
  \ 'escaping malformed URI reference',
  \ 'proprietary attribute',
  \ 'missing <',
  \ 'trimming empty <',
  \ '<img> lacks "',
  \ '<bb-', '</bb-',
  \ '<nc-', '</nc-',
  \ '<ng-include>', '</ng-include>',
  \ '<ng-transclude>', '</ng-transclude>'
\ ]

let g:syntastic_javascript_checkers = ['jsxhint']

" Enable automatic population of location list
let syntastic_always_populate_loc_list = 1

" Open NERDTree at startup, make it smaller, and focus in editing window
" autocmd VimEnter * NERDTree
" autocmd VimEnter * 7winc <
" autocmd VimEnter * wincmd p



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
    call feedkeys("odescribe '' dok=}jddkf'a")
  endif
endfunc

func! ItBlock()
  if &filetype == "javascript"
    call feedkeys("oit('', () => {});k=}f'a")
  elseif &filetype == "ruby"
    call feedkeys("oit '' dok=}jddkf'a")
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

" Map \be, \d, and \is to Jasmine test templates
" nmap <leader>be obeforeEach(() => {<CR>});<ESC>k=}o  
" nmap <leader>d o<CR>describe('', () => {<CR>});<ESC>k=}f'a
" nmap <leader>i o<CR>it('', () => {<CR>});<ESC>k=}f'a

