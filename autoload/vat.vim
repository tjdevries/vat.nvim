let g:vat_buffers = get(g:, 'smartte_buffers', {})

""
" Open a terminal job with some smarter options
function! vat#open(cmd, opts)
  return termopen(a:cmd, a:opts)
endfunction

function! vat#ssh(ssh_opts, cmd, opts)
  let l:ssh_id = vat#open(a:cmd, a:opts)

  let l:user = has_key(a:ssh_opts, 'user') ? a:ssh_opts['user'] . '@' : ''
  let l:host = get(a:ssh_opts, 'host', -1)
  let l:port = has_key(a:ssh_id, 'port') ? '-p ' . a:ssh_opts['port'] : ''

  if l:host != -1
    call jobsend(s:ssh_id, ['ssh ' . l:user . l:host . l:port])
  endif

  let g:vat_buffers[l:ssh_id] = job_object#create(a:opts)

  return l:ssh_id
endfunction

function! vat#new_command_line()
  botright new | call nvim_win_set_height(0, 10)
  set modifiable
  set buftype=nofile
  set nobuflisted
  set bufhidden=wipe
  startinsert
endfunction

function! vat#send_command(command_buffer, term_buffer) abort
  let l:lines = nvim_buf_get_lines(a:command_buffer, 0, -1, 1)
  call g:vat_buffers[a:term_buffer].add_command(l:lines)

  let l:result = jobsend(a:term_buffer, l:lines)
endfunction


" function! TestTerm()
"   call termopen(&shell, {
"         \ 'on_stdout': {id, data, event -> execute('let g:last_out_result_' . event . ' = ' . string(data))},
"         \ 'on_stderr': {id, data, event -> execute('let g:last_err_result = ' . string(data))},
"         \ }
"         \ )
" endfunction
