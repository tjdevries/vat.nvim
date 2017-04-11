let vat#util#life_cycle#force = 0
let vat#util#life_cycle#session = 1
let vat#util#life_cycle#persist = 2


""
" Prompt the user for some variable that will be used in the current session
"
" @param  scope  buffer, window, global dicts
" @param  varaible  Name of the variable that will be saved to the scope
" @param  question  The question to ask the user for
" @param  life_cycle  Force a new result on each encounter, Keep for current
"   session or keep indefinitely
function! vat#util#prompt(scope, variable, question, life_cycle) abort
endfunction
