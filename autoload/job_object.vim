function! job_object#create(buffer_id, job_id, opts) abort
  let obj = {}

  let obj.opts = a:opts
  let obj.__history = []
  let obj.buffer_id = a:buffer_id
  let obj.job_id = a:job_id
  let obj.add_command = function('job_object#add_command')
  let obj.start_suggestions = function('job_object#start_suggestions')

  return obj
endfunction

function! job_object#start_suggestions(option) dict abort
  let results = []

  let len_option = len(a:option)

  if len_option == 0
    return self.__history
  endif

  for item in self.__history
    if len_option > len(item)
      continue
    endif

    "  TODO: Case sensitive
    if a:option ==? item[0:len_option - 1]
      call add(results, item)
    endif
  endfor

  return results
endfunction

function! job_object#add_command(command) dict abort
  if type(a:command) == v:t_list
    for item in a:command
      call add(self.__history, item)
    endfor
  elseif type(a:command) == v:t_string
    call add(self.__history, a:command)
  endif
endfunction

function! job_object#set_buffer_job(object)
  let b:job_object_id = a:object.job_id
endfunction

function! job_object#get_buffer_job(...)
  " TODO: Get buffer job for a different buffer
  if !has_key(b:, 'job_object_id')
    return v:false
  endif

  if !has_key(g:vat_buffers, b:job_object_id)
    return v:false
  endif

  return g:vat_buffers[b:job_object_id]
endfunction

function! job_object#buffer_complete() abort
  " TODO: Add different complete options
  let line = getline(".")
  let suggestions = job_object#get_buffer_job().start_suggestions(line)
  call map(suggestions, 'v:val[len(line):]')
  call complete(col('.'), suggestions)
  return ''
endfunction
