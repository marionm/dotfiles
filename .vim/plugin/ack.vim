" NOTE: You must, of course, install the ack script
"       in your path.
" On Ubuntu:
"   sudo apt-get install ack-grep
" With MacPorts:
"   sudo port install p5-app-ack

function! SetAckCommand()
  if executable('ack-grep')
    let g:ackprg = "ack-grep"
  elseif executable('ack')
    let g:ackprg = "ack"
  else
    echo "Neither 'ack-grep' nor 'ack' found on the path"
    return 0
  endif
  let g:ackprg = g:ackprg . "\\ -H\\ --nocolor\\ --nogroup"
  return 1
endfunction

function! Ack(args)
    if !SetAckCommand()
      return
    endif
    let grepprg_bak=&grepprg
    exec "set grepprg=" . g:ackprg
    execute "silent! grep " . a:args
    botright copen
    let &grepprg=grepprg_bak
    exec "redraw!"
endfunction

function! AckAdd(args)
    if !SetAckCommand()
      return
    endif
    let grepprg_bak=&grepprg
    exec "set grepprg=" . g:ackprg
    execute "silent! grepadd " . a:args
    botright copen
    let &grepprg=grepprg_bak
    exec "redraw!"
endfunction

function! LAck(args)
    if !SetAckCommand()
      return
    endif
    let grepprg_bak=&grepprg
    exec "set grepprg=" . g:ackprg
    execute "silent! lgrep " . a:args
    botright lopen
    let &grepprg=grepprg_bak
    exec "redraw!"
endfunction

function! LAckAdd(args)
    if !SetAckCommand()
      return
    endif
    let grepprg_bak=&grepprg
    exec "set grepprg=" . g:ackprg
    execute "silent! lgrepadd " . a:args
    botright lopen
    let &grepprg=grepprg_bak
    exec "redraw!"
endfunction

command! -nargs=* -complete=file Ack call Ack(<q-args>)
command! -nargs=* -complete=file AckAdd call AckAdd(<q-args>)
command! -nargs=* -complete=file LAck call LAck(<q-args>)
command! -nargs=* -complete=file LAckAdd call LAckAdd(<q-args>)
