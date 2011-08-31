"Autoreload _vimrc when saving it
autocmd! bufwritepost .vimrc source %

"Map F2 to edit .vimrc, F3 to reload it
noremap <F3> :sp $MYVIMRC<CR>
noremap <F2> :source $MYVIMRC<CR>

"Map F12 to a sort of hacky full-file XML formatting thing
noremap <F12> :se ft=xml<CR>ggVGJ:s/> *</>\r</g<CR>gg=G

"Use Q instead of @q to enable easier one-shot macros
noremap Q @q

"Use ctrl-space for autocompletion
inoremap <C-Space> <C-N>

"Double-tap backslash to clear search results
nmap <silent> <leader>\ :silent :nohlsearch<CR>

"Use \h to preview markdown in browser with Hammer
nmap <silent> <leader>h :Hammer<CR>



syntax on
set hidden

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
if has('unix')
  if system('uname') == "Darwin\n"
    set guifont=Menlo\ Regular:h13
  endif
elseif has('win32')
  set guifont=Courier_New:h10
endif

"Show line numbers
set number
"Show file info at bottom
set ruler 
set rulerformat=%30(%=\:b%n%y%m%r%w\ %l,%c%V\ %P%)
"Show entered partial commands in ruler
set showcmd
"Highlight current line in GUIs
if has('gui_running')
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

try
  "Include file matching plugin (use with \t)
  runtime macros/matchit.vim
  "Show the file matching plugin at the top
  let g:CommandTMatchWindowAtTop=1
  "Make the directory tree refresh itself automatically in normal use
  nmap <silent> <leader>t :CommandTFlush<CR>:CommandT<CR>
catch
endtry

if has('gui_running')
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

"Set background color
autocmd VimEnter * highlight Normal guibg=#dfdfdf
"Make file info more readable given above background color
autocmd VimEnter * highlight StatusLineNC guibg=DarkSlateGray guifg=Gray70

"Enable xml folding
let g:xml_syntax_folding=1
au FileType xml setlocal foldmethod=syntax
