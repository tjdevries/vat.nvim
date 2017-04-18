
function! vat#display#previous_commands(buffer_id)
  call nvim_buf_set_lines(0, 0, -1, 1, g:vat_buffers[nvim_buf_get_var(44, 'job_object_id')].__history)
endfunction
