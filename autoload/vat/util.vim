let vat#util#life_cycle#do_not_store = 0
let vat#util#life_cycle#force = 1
let vat#util#life_cycle#session = 2
let vat#util#life_cycle#persist = 3

""
" Prompt the user for some variable that will be used in the current session
"
" @param  scope  buffer, window, global dicts (b:, w:, g:)
" @param  varaible  Name of the variable that will be saved to the scope
" @param  question  The question to ask the user for
" @param  life_cycle  Force a new result on each encounter, Keep for current
"   session or keep indefinitely
function! vat#util#prompt(scope, variable, question, life_cycle) abort
  " TODO: Keep persistent values

  if type(a:scope) != v:t_dict
    return
  endif

  let l:var_name = g:vat#global#var_prefix . a:variable
  let l:prompt_question = g:vat#global#prompt_prefix . a:question

  if !has_key(a:scope, l:var_name) || (a:life_cycle <= g:vat#util#life_cycle#force)
    " Don't even store the value for a do_not_store item
    " This means you could type in a password here or something
    " and not worry about me forgetting to clean up :)
    if a:life_cycle == g:vat#util#life_cycle#do_not_store
      return input(l:prompt_question)
    endif

    let a:scope[l:var_name] = input(l:prompt_question)
  endif

  return a:scope[l:var_name]
endfunction

function! vat#util#input_prompt(scope, variable, question, life_cycle, ...) abort
  let prefix = get(a:000, 0, '')
  let postfix = get(a:000, 1, '')
  call nvim_input(prefix
        \ . vat#util#prompt(a:scope, a:variable, a:question, a:life_cycle)
        \ . postfix
        \ )
endfunction

""
" Gets a variable if it's there,
" otherwise prompts with default values
function! vat#util#get(scope, variable)
  return get(a:scope,
        \ g:vat#global#var_prefix . a:variable,
        \ vat#util#prompt(a:scope,
          \ a:variable,
          \ a:variable . ': ',
          \ g:vat#util#life_cycle#session,
          \ )
        \ )
endfunction

function! vat#util#reset() abort
  for dict in [b:, w:, g:]
    for key in keys(dict)
      if vat#util#starts_with(key, g:vat#global#var_prefix)
        call remove(dict, key)
      endif
    endfor
  endfor
endfunction


function! vat#util#starts_with(string, prefix) abort
  return a:string =~# '\V\^' . escape(a:prefix, '\')
endfunction
