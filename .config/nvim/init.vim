set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath=&runtimepath
source ~/.vimrc

" Autoreload this file when saving it
autocmd! bufwritepost init.vim source %

" System clipboard bindings
" TODO: Use C-* instead of D-* for non-osx systems
noremap <D-c> "+y
noremap <D-v> "+p
cnoremap <D-v> <C-r>+
imap <D-v> <C-r>+
noremap <D-t> :tabnew<CR>
noremap <D-s> :w<CR>

" Neovide settings
" TODO: Wrap in neovide check
let g:neovide_cursor_animate_command_line = v:false
let g:neovide_cursor_animate_in_insert_mode = v:false
let g:neovide_cursor_animation_length = 0 " The flag to disable animations in command mode doesn't seem to work
" let g:neovide_cursor_trail_size = 0
" let g:neovide_position_animation_length = 0
" let g:neovide_scroll_animation_far_lines = 0
let g:neovide_scroll_animation_length = 0.00

" Inlined vim-rspec functionality, since the plugin isn't neovim compatible
" TODO: Why doesn't ~/. work here?
let g:rspec_runner = "/Users/mikemarion/.nvim_iterm2_runner"
let g:rspec_command = "rspec --format documentation --profile --order defined"
func! RunRspec(mode)
  let s:is_spec = match(expand("%"), "_spec.rb$") != -1

  if a:mode == "file" && s:is_spec
    let s:rspec_target = expand("%")
  elseif a:mode == "line" && s:is_spec
    let s:rspec_target = expand("%") . ":" . line(".")
  elseif !exists("s:rspec_target")
    return
  endif

  execute "silent ! " . g:rspec_runner . " '" . g:rspec_command . " \"" . s:rspec_target . "\"'"
endfunc
map <Leader>t :call RunRspec("file")<CR>
map <Leader>s :call RunRspec("line")<CR>
map <Leader>p :call RunRspec("last")<CR>
