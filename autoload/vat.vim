let g:vat_buffers = get(g:, 'vat_buffers', {})

function! s:shared_start(cmd, opts)
  return termopen(a:cmd, a:opts)
endfunction!

function! s:shared_finish(ssh_id, opts)
  let g:vat_buffers[a:ssh_id] = job_object#create(nvim_buf_get_number(0),
        \ a:ssh_id,
        \ nvim_get_current_win(),
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

  inoremap <buffer> <C-CR>
        \ <C-O>:call vat#hard_enter(job_object#get_buffer_job())<CR>

  " TODO: Probably do a more complete deletion
  inoremap <buffer> <up> <c-o>dd<c-r>=job_object#previous_command()<CR>
  inoremap <buffer> <down> <c-o>dd<c-r>=job_object#next_command()<CR>


  " TODO: Make these configurable for users
  execute('inoremap <buffer> <C-N>'
        \ . ' <C-R>=job_object#buffer_complete()<CR>')
  execute('inoremap <buffer> <C-P>'
        \ . ' <C-R>=job_object#buffer_complete()<CR>')

  startinsert
endfunction

function! vat#send_command(command_buffer, term_buffer) abort
  let l:lines = nvim_buf_get_lines(a:command_buffer, 0, -1, 1)
  call jobsend(a:term_buffer, join(l:lines, "\n") . "\n")
  call s:cleanup()
endfunction

""
" Sometimes terminals don't like "\n" items... :'(
" So we try a hard enter.
function! vat#hard_enter(job_object) abort
  let job_id = a:job_object.job_id
  let current_win = nvim_get_current_win()
  let command_string = getline('.') . "<CR>"
  call nvim_set_current_win(g:vat_buffers[job_id].window_id)
  call nvim_input(command_string)
  call timer_start(50, {timer -> execute('call nvim_set_current_win('
        \ . current_win
        \ . ')')})
  call timer_start(100, {timer -> execute("call s:cleanup()")})
  call timer_start(150, {timer -> execute('call nvim_input("i")')})
endfunction

function! s:cleanup() abort
  let l:lines = nvim_buf_get_lines(0, 0, -1, 1)
  call nvim_buf_set_lines(0, 0, -1, 0, [''])
  call job_object#get_buffer_job().add_command(l:lines)
  call job_object#reset_command()
endfunction
