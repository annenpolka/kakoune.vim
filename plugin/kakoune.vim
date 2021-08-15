function s:call(visual, escape_key)
  if has('nvim')
    au! TermClose *:kak* call feedkeys("i")
  endif
  let file = expand('%')
  if ! filereadable(file)
    echoerr 'The current buffer has no associated file'
    return
  endif
  if ! filewritable(file)
    echoerr 'The associated file cannot be written'
    return
  endif
  write
  let [anchor_line, anchor_column, cursor_line, cursor_column] = s:selection(a:visual)
  let command = '
    \ terminal %s
    \   kak -e "
    \     edit \%%(%s);
    \     select %d.%d,%d.%d;
    \     colorscheme default;
    \     map buffer normal %s :write-quit<ret>;
    \   "
    \ '
  let options = has('nvim') ? '' : '++curwin ++close'
  execute printf(command, options, file, anchor_line, anchor_column, cursor_line, cursor_column, escape_key)
  startinsert
endfunction

function s:selection(visual)
  if a:visual
    return [line("'<"), col("'<"), line("'>"), col("'>")]
  else
    return [line('.'), col('.'), line('.'), col('.')]
  endif
endfunction

nnoremap <Plug>(Kakoune) :call <SID>call(0)<CR>
vnoremap <Plug>(Kakoune) :<C-U>call <SID>call(1)<CR>

command! -nargs=1 Kakoune call  <SID>call(0, <q-args>)
command! -nargs=1 KakouneVisual call  <SID>call(1, <q-args>)
