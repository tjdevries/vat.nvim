""
" Create a job_object that we will use to keep lots of information
" about the current job, it's history and other items
function! job_object#create(buffer_id, job_id, window_id, opts) abort  " {{{
  let obj = {}

  let obj.__history = []
  let obj.__history_count = 0
  let obj.__recordings = {}
  let obj.__is_recording = v:false

  let obj.opts = a:opts
  let obj.buffer_id = a:buffer_id
  let obj.job_id = a:job_id
  let obj.window_id = a:window_id
  let obj.add_command = function('job_object#add_command')
  let obj.get_command = function('job_object#get_command')
  let obj.start_suggestions = function('job_object#start_suggestions')

  let obj.start_recording = function('job_object#start_recording')
  let obj.end_recording = function('job_object#end_recording')
  let obj.play_recording = function('job_object#play_recording')

  return obj
endfunction " }}}

""
" Return a list of suggestions from a dictionary based on the input option
" It will only return suggestions that start with the same characters
function! job_object#start_suggestions(option) dict abort  " {{{
  let results = []

  let len_option = len(a:option)

  if len_option == 0
    return self.__history
  endif

  for index in range(len(self.__history))
    let item = self.get_command(index)

    " Skip empty strings
    if item == ''
      continue
    endif

    " Don't bother comparing items that are too long
    if len_option > len(item)
      continue
    endif

    "  TODO: Case sensitive
    if a:option ==? item[0:len_option - 1]
      call insert(results, item)
    endif
  endfor

  return results
endfunction " }}}

""
" Add a command to the history of this job_object
function! job_object#add_command(command) dict abort  " {{{
  if type(a:command) == v:t_string
    let commands = [a:command]
  elseif type(a:command) == v:t_list
    let commands = a:command
  endif

  if empty(a:command)
    return
  endif

  for item in a:command
    " TODO: I'd like to be able to get more accurate time readings
    " \ str2nr(split(execute('py3 import time; print(time.time())'))[0])
    call add(self.__history, {
          \ 'value': item,
          \ 'time': has('python3') ?
              \ localtime()
              \ : localtime(),
          \ })

    let self.__history_count += 1
  endfor
endfunction " }}}

function! job_object#get_command(position) dict abort  " {{{
  return self.__history[a:position].value
endfunction " }}}

function! job_object#set_buffer_job(object)  " {{{
  let b:job_object_id = a:object.job_id
endfunction " }}}

function! job_object#get_buffer_job(...)  " {{{
  let buffer_id = get(a:000, 0, 0)

  try
    let buffer_job_id = nvim_buf_get_var(buffer_id, 'job_object_id')
  catch
    return 0
  endtry

  try
    return g:vat_buffers[buffer_job_id]
  catch
    return 1
  endtry
endfunction " }}}

" TODO: Integrate with deoplete?
function! job_object#buffer_complete() abort  " {{{
  " TODO: Add different complete options
  let line = getline(".")
  let len_line = len(line)
  let suggestions = job_object#get_buffer_job().start_suggestions(line)
  call map(suggestions, 'v:val[' . len_line . ':]')
  call complete(col('.'), suggestions)
  return ''
endfunction " }}}

function! job_object#reset_command() abort  " {{{
  let b:{g:vat#global#var_prefix}_position = 0
endfunction " }}}

function! job_object#previous_command() abort  " {{{
  let b:{g:vat#global#var_prefix}_position =
        \ get(b:, g:vat#global#var_prefix . '_position', 0) - 1
  return job_object#get_buffer_job().get_command(b:{g:vat#global#var_prefix}_position)
endfunction " }}}

function! job_object#next_command() abort  " {{{
  let b:{g:vat#global#var_prefix}_position =
        \ get(b:, g:vat#global#var_prefix . '_position', 0) + 1
  return job_object#get_buffer_job().get_command(b:{g:vat#global#var_prefix}_position)
endfunction " }}}


""
" Add a recording to a job object
function! job_object#add_recording(record) dict abort  " {{{
  let self.__recordings[a:record.name] = a:record
endfunction  " }}}

""
" Start a recording for a job_object
" Records have:
"   .name  The name of the recording
"   .start  The starting command index of the recording
"   .end  The ending command index of the recording
"   .max_timeout  The maximum timeout to wait between commands
"   .commands  Can move the commands
function! job_object#start_recording(...) dict abort  " {{{
  let opts = get(a:000, 0, {})
  if self.__is_recording != v:false
    " TODO: Maybe throw an error here?
    return
  endif


  let record = {}

  " TODO: inputdialog?
  let record.name = has_key(opts, 'name') ? opts.name : input("Name of recording: \n> ")
  let record.start = has_key(opts, 'start') ? opts.start : len(self.__history)
  let record.end = -1

  " TODO: Make this a paramter or see if this is even a reasonable timeout
  let record.max_timeout = has_key(opts, 'max_timeout') ? opts.max_timeout : 5

  let self.__is_recording = record.name
  let self.__recordings[record.name] = record
endfunction  " }}}

""
" Stop a recording for a job_object
function! job_object#end_recording() dict abort  " {{{
  if self.__is_recording == v:false
    return
  endif

  try
    let self.__recordings[self.__is_recording].end = len(self.__history) - 1
  finally
    let self.__is_recording = v:false
  endtry
endfunction  " }}}

""
" Play a recording back
function! job_object#play_recording(...) dict abort  " {{{
  let options = ["Name of recording:"] + map(keys(self.__recordings), 'v:key . ": " . v:val')
  let name = get(a:000, 0, v:false)

  if name == v:false
    let choice = inputlist(options)
    let recording = self.__recordings[keys(self.__recordings)[choice]]
  else
    if !has_key(self.__recordings, name)
      return
    endif

    let recording = self.__recordings[name]
  endif

  echo "Playing " . recording.name

  for index in range(recording.start, recording.end)
    let command = self.__history[index]

    " Wait in between sending the amount specified during recording
    " Minimum of one second of waiting
    if index != recording.end
      let next_command = self.__history[index + 1]
      let wait_time = max([
            \ min([
              \ (next_command.time - command.time),
              \ recording.max_timeout]
              \ ),
            \ 1])
      execute 'sleep ' . wait_time
    endif

    call jobsend(self.job_id, command.value . "\n")
    redraw!
  endfor

  return recording
endfunction  " }}}
