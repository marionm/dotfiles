set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath=&runtimepath
source ~/.vimrc

" Autoreload this file when saving it
autocmd! bufwritepost init.vim source %

" Neovide settings
" TODO: Wrap in neovide check
let g:neovide_cursor_animate_command_line = v:false
let g:neovide_cursor_animate_in_insert_mode = v:false
let g:neovide_cursor_animation_length = 0 " The flag to disable animations in command mode doesn't seem to work
" let g:neovide_cursor_trail_size = 0
" let g:neovide_position_animation_length = 0
" let g:neovide_scroll_animation_far_lines = 0
let g:neovide_scroll_animation_length = 0.00
