let s:FILE_NAME = "position.temp"

function! s:start_kak(visual, escape_key) range
  au! TermClose *:kak* call s:end_kak()
    
  let file = expand('%')
  let escape_key = a:escape_key
  if ! filereadable(file)
    echoerr 'The current buffer has no associated file'
    return
  endif
 if ! filewritable(file)
    echoerr 'The associated file cannot be written'
    return
  endif
  call s:execute_kak(file, a:visual, a:escape_key)
endfunction

function s:execute_kak(file, visual, escape_key)
  write
  call writefile([line("."),col(".")], s:FILE_NAME)
  let [anchor_line, anchor_column, cursor_line, cursor_column] = s:selection(a:visual)
  let kak_command = '
    \   %s
    \   kak -e "
    \     edit \%%(%s);
    \     select %d.%d,%d.%d;
    \     execute-keys vv;
    \     colorscheme default;
    \     map buffer normal %s :write-quit<ret>;
    \     hook global NormalKey .* \%%{ echo -to-file %s \%%val{cursor_line} \%%val{cursor_char_column} };
    \   "
    \ '
  let options = has('nvim') ? '' : '++curwin ++close'
  let final_input = printf(kak_command, options, a:file, anchor_line, anchor_column, cursor_line, cursor_column, a:escape_key, s:FILE_NAME)
  execute 'terminal' final_input
  startinsert
endfunction 

function! s:end_kak()
  let position = split(readfile(s:FILE_NAME)[0]," ")
  call delete(s:FILE_NAME)
  bd!
  if len(position) > 1
    call cursor(position[0], position[1])
  endif
  
endfunction

function! s:selection(visual)
  if a:visual
    return [line("'<"), col("'<"), line("'>"), col("'>")]
  else
    return [line('.'), col('.'), line('.'), col('.')]
  endif
endfunction

command! -nargs=1 Kakoune call  <SID>start_kak(0, <q-args>)
command! -range -nargs=1 KakouneVisual call  <SID>start_kak(1, <q-args>)
