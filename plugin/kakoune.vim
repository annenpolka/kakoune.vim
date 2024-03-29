let s:POSITION_FILE_NAME = "position.temp"

function! s:start_kak(visual, options, ...) range
  let option_list = split(a:options, " ")
  
  let escape_key = exists("g:kak_escape_key") ? g:kak_escape_key : "<esc>"
  let operator_key = get(option_list, 0, "")
  let select_mode = get(a:, 1, "")
  
  au! TermClose *:kak* call s:end_kak()

  let file = expand('%')
  if !filereadable(file)
    echoerr 'The current buffer has no associated file'
    return
  endif
 if !filewritable(file)
    echoerr 'The associated file cannot be written'
    return
  endif
  call s:execute_kak(file, a:visual, escape_key, operator_key, select_mode)
endfunction

function s:execute_kak(file, visual, escape_key, operator_key, select_mode)
  write
  let [anchor_line, anchor_column, cursor_line, cursor_column] = s:selection(a:visual)
  call writefile([anchor_line .. "." .. anchor_column .. ","
        \     .. cursor_line .. "." .. cursor_column], s:POSITION_FILE_NAME)
  let kak_command_start = 'kak -e "'
  let kak_edit_file = printf('edit \%%(%s); ', a:file)
  let kak_select = printf('select %d.%d,%d.%d; ', anchor_line, anchor_column, cursor_line, cursor_column)
  let kak_colorscheme = 'colorscheme default; '
  let kak_map_escape = printf('map buffer normal %s :write-quit<ret>; ', a:escape_key)
  let kak_cursor_hook = printf('hook global NormalKey .* \%%{ echo -to-file %s \%%val{selection_desc} }; ', s:POSITION_FILE_NAME)
  let kak_centerize_command = "execute-keys vv;"
  let kak_command_end = '"'

  let kak_command_body = kak_edit_file .
        \                kak_select .
        \                kak_colorscheme .
        \                kak_map_escape .
        \                kak_cursor_hook .
        \                kak_centerize_command
  
  if a:operator_key != ''
    let kak_operator_command = printf("execute-keys %s", a:operator_key)
    let kak_command_body = kak_command_body .
          \                kak_operator_command
  endif

  let kak_s_mode_command = ""
  if a:select_mode == "inner"
    let kak_s_mode_command = "execute-keys <A-i>"
  elseif a:select_mode == "outer"
    let kak_s_mode_command = "execute-keys <A-a>"
  endif
  if kak_s_mode_command != ""
    let kak_command_body = kak_command_body .
          \                kak_s_mode_command
  endif
  
  let final_input = kak_command_start .
        \           kak_command_body .
        \           kak_command_end
  execute 'terminal' final_input
  startinsert
  
endfunction

function! s:end_kak()
  let positions = split(readfile(s:POSITION_FILE_NAME)[0], ",")
  bd!
  if positions[0] ==? positions[1]
    let position_set = split(positions[0], "\\.")
    call cursor(position_set[0], position_set[1])
  else
    let start_position = split(positions[0], "\\.")
    let end_position = split(positions[1], "\\.")
    call setpos("'<", [bufnr(), start_position[0], start_position[1]])
    call setpos("'>", [bufnr(), end_position[0], end_position[1]])
    normal! gv
  endif

  call delete(s:POSITION_FILE_NAME)
endfunction

function! s:selection(visual)
  if a:visual
    return [line("'<"), col("'<"), line("'>"), col("'>")]
  else
    return [line('.'), col('.'), line('.'), col('.')]
  endif
endfunction

command! -nargs=* Kakoune call  <SID>start_kak(0, <q-args>)
command! -nargs=* KakouneSelectInner call  <SID>start_kak(0, <q-args>, "inner")
command! -nargs=* KakouneSelectOuter call  <SID>start_kak(0, <q-args>, "outer")
command! -range -nargs=* KakouneVisual call  <SID>start_kak(1, <q-args>)
