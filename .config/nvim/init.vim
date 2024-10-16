set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath=&runtimepath
source ~/.vimrc

" Autoreload this file when saving it
autocmd! bufwritepost init.vim source %
