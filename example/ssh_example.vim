function! SetupExampleBuffer()
  ""
  " I often have many routines that I have to run that are always from the same
  " location
  " They follow the form of <tagname>^<routinename>,
  " So now I can just do <tagname>^<leader><tab> and it will pop up
  inoremap <buffer> <leader><TAB>
              \ <C-O>:call vat#util#input_prompt(b:,
                  \ 'main_routine',
                  \ 'Main routine: ',
                  \ vat#util#life_cycle#session,
                  \ '^',
                  \ )<CR>
endfunction
