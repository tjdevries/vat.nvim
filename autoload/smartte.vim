""
" Open a terminal job with some smarter options
function! smartte#open(cmd, opts)
  return termopen(a:cmd, a:opts)
endfunction

function! smartte#ssh(ssh_opts, cmd, opts)
  let s:ssh_id = smartte#open(a:cmd, a:opts)

  let l:user = has_key(a:ssh_opts, 'user') ? a:ssh_opts['user'] . '@' : ''
  let l:host = get(a:ssh_opts, 'host', -1)
  let l:port = has_key(a:ssh_id, 'port') ? '-p ' . a:ssh_opts['port'] : ''

  if l:host != -1
    call jobsend(s:ssh_id, ['ssh ' . l:user . l:host . l:port])
  endif
endfunction

function! smartte#new_command_line()
  botright new | call nvim_win_set_height(0, 10)
  set modifiable
  set buftype=nofile
  set nobuflisted
  set bufhidden=wipe
  startinsert
endfunction

" function! TestTerm()
"   call termopen(&shell, {
"         \ 'on_stdout': {id, data, event -> execute('let g:last_out_result_' . event . ' = ' . string(data))},
"         \ 'on_stderr': {id, data, event -> execute('let g:last_err_result = ' . string(data))},
"         \ }
"         \ )
" endfunction
