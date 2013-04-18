func! Mac()
  return has('unix') && system('uname') == "Darwin\n"
endfunc

func! Linux()
  return has('unix') && system('uname') != "Darwin\n"
endfunc

func! Windows()
  return has('win32')
endfunc

func! Gui()
  return has('gui_running')
endfunc

"Autoreload _vimrc when saving it
autocmd! bufwritepost .vimrc source %

"Map F2 to edit .vimrc, F3 to reload it
noremap <F2> :sp $MYVIMRC<CR>
noremap <F3> :source $MYVIMRC<CR>

"Map F12 to a sort of hacky full-file XML formatting thing
noremap <F12> :se ft=xml<CR>ggVGJ:s/> *</>\r</g<CR>gg=G

"Use Q instead of @q to enable easier one-shot macros
noremap Q @q

"Use ctrl-space for autocompletion
inoremap <C-Space> <C-N>

"Double-tap backslash to clear search results
nmap <silent> <leader>\ :silent :nohlsearch<CR>

"Map \n to toggle NERDTree
nmap <silent> <leader>n :NERDTreeToggle<CR>

"Map \r to reveal in NERDTree
nmap <silent> <leader>r :NERDTreeFind<CR>

"Map \a to Ack current word
nmap <leader>a :Ack <C-R><C-W><CR>
"Map \A to prep Ack for current word
nmap <leader>A :Ack <C-R><C-W>



syntax on
set hidden
set pastetoggle=<F5>

filetype on
filetype plugin on
filetype indent on

set mouse=a

set tabstop=2
set shiftwidth=2
set nowrap
set autoindent

"Use tabs
" set noexpandtab
"...or grudgingly conform to other people and use spaces
set expandtab

"Set up font by system
if Mac()
  set guifont=Menlo\ Regular:h13
elseif Windows()
  set guifont=Courier_New:h10
endif

"Show line numbers
set number
"Show file info at bottom
set ruler 
set rulerformat=%30(%=\:b%n%y%m%r%w\ %l,%c%V\ %P%)
"Show entered partial commands in ruler
set showcmd
"Highlight current line in Mac GUIs
if Mac() && Gui()
  set cursorline
endif

"Hide toolbar
set guioptions-=T
"Use filename as window title
set title

"Simplify external command messages
set shortmess+=filmnrxoOtT
"Allow more command history
set history=1000
"Improved external command tab completion
set wildmenu
set wildmode=list:longest,full

"Improved searching
set ignorecase
set smartcase
set hlsearch
set incsearch

"Improved scrolling and cursor movement
set scrolloff=3
set backspace=indent,eol,start
set whichwrap=b,s,h,l,<,>,[,]
nnoremap <C-e> 3<C-e> 
nnoremap <C-y> 3<C-y> 

"Consolidate backup files
set backupdir=~/.vimtmp,~/.tmp,~/tmp,/var/tmp,/tmp
set directory=~/.vimtmp,~/.tmp,~/tmp,/var/tmp,/tmp

if Gui()
  try
    "Open NERDTree at startup
    autocmd VimEnter * NERDTree
    "Make NERDTree smaller
    "7winc <
    "Focus in editing window instead of NERDTree
    autocmd VimEnter * wincmd p
  catch
  endtry
endif

"Set colorscheme based on system
if Mac()
  "Set background color
  autocmd VimEnter * highlight Normal guibg=#dfdfdf
  "Make file info more readable given above background color
  autocmd VimEnter * highlight StatusLineNC guibg=DarkSlateGray guifg=Gray70
else
  set background=dark
  colorscheme solarized
endif

"Enable xml folding
let g:xml_syntax_folding=1
au FileType xml setlocal foldmethod=syntax
set foldlevelstart=20
