let g:vat_buffers = get(g:, 'vat_buffers', {})

function! s:shared_start(cmd, opts)
  return termopen(a:cmd, a:opts)
endfunction!

function! s:shared_finish(ssh_id, opts)
  let g:vat_buffers[a:ssh_id] = job_object#create(nvim_buf_get_number(0),
        \ a:ssh_id,
        \ a:opts,
        \ )

  call vat#new_command_line(g:vat_buffers[a:ssh_id])

  return a:ssh_id
endfunction

""
" Open a terminal job with some smarter options
function! vat#open(cmd, opts)
  let ssh_id =  s:shared_start(a:cmd, a:opts)
  return s:shared_finish(ssh_id, a:opts)
endfunction

function! vat#ssh(ssh_opts, cmd, opts)
  let l:ssh_id = s:shared_start(a:cmd, a:opts)

  let l:user = has_key(a:ssh_opts, 'user') ? a:ssh_opts['user'] . '@' : ''
  let l:host = get(a:ssh_opts, 'host', -1)
  let l:port = has_key(a:ssh_opts, 'port') ? '-p ' . a:ssh_opts['port'] : ''

  if l:host != -1
    call jobsend(l:ssh_id, ['ssh ' . l:user . l:host . l:port])
    call timer_start(100, {timer -> execute('call jobsend(' . l:ssh_id . ', "\n")')})
  endif

  return s:shared_finish(l:ssh_id, a:opts)
endfunction

""
" Create the new command line window
" Accept a `job_object` to configure any required paramters
function! vat#new_command_line(current_job)
  botright new | call nvim_win_set_height(0, g:vat#global#win_height)
  set modifiable
  set buftype=nofile
  set nobuflisted
  set bufhidden=wipe

  call nvim_buf_set_name(0, 'vat.nvim : ' . nvim_buf_get_var(a:current_job.buffer_id, 'term_title'))

  "" Save a local var job variable
  call job_object#set_buffer_job(a:current_job)

  "" Map a comamnd for sending results to the terminal job
  execute(printf('inoremap <buffer> <CR>'
        \ . ' <C-O>:call vat#send_command(%s, %s)<CR>',
        \ nvim_buf_get_number(0), a:current_job.job_id)
        \ )

  " TODO: Make these configurable for users
  execute('inoremap <buffer> <C-N>'
        \ . ' <C-R>=job_object#buffer_complete()<CR>')
  execute('inoremap <buffer> <C-P>'
        \ . ' <C-R>=job_object#buffer_complete()<CR>')

  startinsert
endfunction

function! vat#send_command(command_buffer, term_buffer) abort
  let l:lines = nvim_buf_get_lines(a:command_buffer, 0, -1, 1)
  call g:vat_buffers[a:term_buffer].add_command(l:lines)
  let l:result = jobsend(a:term_buffer,
        \ join(l:lines, "\n") . "\n"
        \ )

  call nvim_buf_set_lines(a:command_buffer, 0, -1, 0, [''])
endfunction



















" function! TestTerm()
"   call termopen(&shell, {
"         \ 'on_stdout': {id, data, event -> execute('let g:last_out_result_' . event . ' = ' . string(data))},
"         \ 'on_stderr': {id, data, event -> execute('let g:last_err_result = ' . string(data))},
"         \ }
"         \ )
" endfunction
