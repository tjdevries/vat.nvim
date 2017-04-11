function! job_object#create(opts) abort
  let obj = {}

  let obj.opts = a:opts
  let obj.__history = []
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
