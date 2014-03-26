set nocompatible

set rtp+=~/.vim/bundle/neobundle.vim/
call neobundle#rc(expand('~/.vim/bundle'))
NeoBundleFetch 'Shougo/neobundle.vim'

NeoBundle 'altercation/vim-colors-solarized'
NeoBundle 'nathanaelkane/vim-indent-guides'

NeoBundle 'kien/ctrlp.vim'
NeoBundle 'mileszs/ack.vim'
NeoBundle 'scrooloose/nerdtree'

NeoBundle 'tpope/vim-endwise'
NeoBundle 'tpope/vim-surround'

NeoBundle 'gregsexton/MatchTag'
NeoBundle 'lukaszb/vim-web-indent'
NeoBundle 'sukima/xmledit'
NeoBundle 'tclem/vim-arduino'
NeoBundle 'vim-scripts/Arduino-syntax-file'

filetype plugin indent on
syntax on



"Use Q instead of @q to enable easier one-shot macros
noremap Q @q

"Double-tap backslash to clear search results
nmap <silent> <leader>\ :silent :nohlsearch<CR>

"Simplify split navigation
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

"Map jj and jk to escape in insert mode
imap jj <ESC>
imap jk <ESC>

"Map \a to Ack current word
nmap <leader>a :Ack <C-R><C-W><CR>
"Map \A to prep Ack for current word
nmap <leader>A :Ack <C-R><C-W>

"Map F5 to paste mode toggle
set pastetoggle=<F5>

"Use ctrl-space for autocompletion
inoremap <C-Space> <C-N>

"Map \r to reveal in NERDTree
nmap <silent> <leader>r :NERDTreeFind<CR>

"Map \n to toggle NERDTree
nmap <silent> <leader>n :NERDTreeToggle<CR>

"Map \bd to delete all empty buffers
"The set/echo ensures the message is displayed even if an open window is closed
nmap <silent> <leader>bd :let deleted = DeleteEmptyBuffers()<CR>:echo 'Deleted ' . deleted . ' buffer(s)'<CR>

"Map \g to switch colors for screen type
nmap <silent> <leader>g :call SwitchScreenType()<CR>

"Use custom Arduino bindings
let g:vim_arduino_map_keys = 0
nnoremap <leader>c :call ArduinoCompile()<CR>
nnoremap <leader>d :call ArduinoDeploy()<CR>
nnoremap <leader>s :call ArduinoSerialMonitor()<CR>

"Map F2 to edit .vimrc, F3 to reload it
noremap <F2> :sp $MYVIMRC<CR>
noremap <F3> :source $MYVIMRC<CR>

"Open NERDTree at startup, make it smaller, and focus in editing window
" autocmd VimEnter * NERDTree
" autocmd VimEnter * 7winc <
" autocmd VimEnter * wincmd p

"Autoreload _vimrc when saving it
autocmd! bufwritepost .vimrc source %



set hidden
set mouse=a
set encoding=utf-8
set ttyfast

au BufRead,BufNewFile *.pde set filetype=arduino
au BufRead,BufNewFile *.ino set filetype=arduino

set tabstop=2
set shiftwidth=2
set nowrap
set autoindent

"Use tabs
" set noexpandtab
"...or grudgingly conform to other people and use spaces
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
"Show file info at bottom
set ruler 
set rulerformat=%30(%=\:b%n%y%m%r%w\ %l,%c%V\ %P%)
"Show entered partial commands in ruler
set showcmd
"Always show status
set laststatus=2

"Hide toolbar
set guioptions-=T
"Use filename as window title
set title
"Stop vim from setting window title on exit
let &titleold=""

"Simplify external command messages
set shortmess+=filmnrxoOtT
"Allow more command history
set history=1000
"Improve external command tab completion
set wildmenu
set wildmode=list:longest,full

"Improve searching
set ignorecase
set smartcase
set hlsearch
set incsearch

"Improve scrolling and cursor movement
set scrolloff=3
set backspace=indent,eol,start
set whichwrap=b,s,h,l,<,>,[,]
nnoremap <C-e> 3<C-e> 
nnoremap <C-y> 3<C-y> 

"Improve split behavior
set splitbelow
set splitright



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



func! Mac()
  return has('unix') && system('uname') == "Darwin\n"
endfunc

func! Linux()
  return has('unix') && system('uname') != "Darwin\n"
endfunc

"Set font based on system
if Mac()
  set guifont=Monaco:h13
endif



"Enable xml folding
let g:xml_syntax_folding=1
au FileType xml setlocal foldmethod=syntax
set foldlevelstart=20

"Map F12 to a super hacky full-file XML formatting macro
noremap <F12> O<ESC>ggVGgJ:s/> *</>\r</g<CR>:se ft=xml<CR>gg=G



"Consolidate backup files
set backupdir=~/.vimtmp,~/.tmp,~/tmp,/var/tmp,/tmp,c:\tmp
set directory=~/.vimtmp,~/.tmp,~/tmp,/var/tmp,/tmp,c:\tmp

"Enable undo files
if version >= 703
  set undofile
  set undodir=~/.vimtmp,~/.tmp,~/tmp,/var/tmp,/tmp,c:\tmp
endif

