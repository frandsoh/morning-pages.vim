"==============================================================================
"   Description: Zen-room like environment to print morning pages from
"							  'The way of artist' book. By Gaspar Chilingarov
"               2016-03-08:	first public release
"==============================================================================


" XXX still requires speedup and more caching

if !exists('g:morning_pages_load')
  let g:morning_pages_load = 1
endif

augroup morning_pages_settings
  autocmd!
  autocmd BufRead *.mp.md call MorningPages#settings()
  autocmd InsertEnter,InsertChange,InsertLeave *.mp.md call MorningPages#setStatusLine()
  autocmd InsertCharPre *.mp.md call s:playTypewriterSound()
  autocmd CursorMovedI *.mp.md call s:playTypewriterLineFeed()
augroup END

" The desired column width.  Defaults to 100
if !exists( "g:morning_pages_width" )
    let g:morning_pages_width = 100
endif

" The desired typed word count (roughtly 3 pages of text)
if !exists( "g:morning_pages_words" )
    let g:morning_pages_words = 750
endif

" Path where to store morning pages
if !exists( "g:morning_pages_basePath" )
    let g:morning_pages_basePath = expand("~") . "/.vim-morning-pages"
endif

" The GUI background color.  Defaults to "black"
if !exists( "g:morning_pages_guibackground" )
    let g:morning_pages_guibackground = "#202020"
endif

" The cterm background color.  Defaults to "bg"
if !exists( "g:morning_pages_ctermbackground" )
    let g:morning_pages_ctermbackground = "bg"
endif

" Turn on/off sound settings
if !exists( "g:morning_pages_sound" )
    let g:morning_pages_sound = 1
endif

" Tells morning pages what to consider _word_
if !exists( "g:morning_pages_word_pattern" )
  let g:morning_pages_word_pattern = "\\<\\([a-zA-Z\\u0100-\\uFFFF]\\|-\\|'\\)\\+\\>"
"	let g:morning_pages_word_pattern = "\\<\\(\\w\\|-\\|'\\)\\+\\>"
endif


function! s:MkNonExDir(file)
  let dir=fnamemodify(a:file, ':h')
  if !isdirectory(dir)
    call mkdir(dir, 'p')
  endif
endfunction

function! MorningPages#load()
  let year = strftime("%Y")
  let date=strftime("%Y-%m-%d")
  let dayTime = strftime("%H")

  " support writing two entries a day - morning and evening
  if (dayTime < 12)
    let dayTime = "morning"
  else
    let dayTime = "evening"
  endif

  let fileName = g:morning_pages_basePath . "/" . year . "/" . date . "-" . dayTime . ".mp.md"

  if (filereadable(fileName))
    exec "edit" fileName
  else
    call s:MkNonExDir(fileName)
    exec "enew"
    exec "write" fileName
    call s:loadingSound()
  endif

  call MorningPages#settings()
endfunc

" code is stolen from vim-zenroom
function! s:is_the_screen_wide_enough()
    return winwidth( winnr() ) >= g:morning_pages_width
endfunction

function! s:sidebar_size()
    return ( winwidth( winnr() ) - g:morning_pages_width - 2 ) / 2
endfunction

function! MorningPages#settings()
  if s:is_the_screen_wide_enough()
    let s:sidebar = s:sidebar_size()

  " Create the left sidebar
    exec( "silent leftabove " . s:sidebar . "vsplit new" )
    setlocal noma
    setlocal nocursorline
    setlocal nonumber
    silent! setlocal norelativenumber
    wincmd l
    " Create the right sidebar
    exec( "silent rightbelow " . s:sidebar . "vsplit new" )
    setlocal noma
    setlocal nocursorline
    setlocal nonumber
    silent! setlocal norelativenumber
    wincmd h
    exec( "silent vertical resize " . g:morning_pages_width )
  endif

  if has('gui_running')
    let l:highlightbgcolor = "guibg=" . g:morning_pages_guibackground
    let l:highlightfgbgcolor = "guifg=" . g:morning_pages_guibackground . " " . l:highlightbgcolor
  else
    let l:highlightbgcolor = "ctermbg=" . g:morning_pages_ctermbackground
    let l:highlightfgbgcolor = "ctermfg=" . g:morning_pages_ctermbackground . " " . l:highlightbgcolor
  endif
  exec( "hi Normal " . l:highlightbgcolor )
  exec( "hi VertSplit " . l:highlightfgbgcolor )
  exec( "hi NonText " . l:highlightfgbgcolor )
  exec( "hi StatusLine " . l:highlightfgbgcolor )
  exec( "hi StatusLineNC " . l:highlightfgbgcolor )
  set t_mr=""
  set fillchars+=vert:\

  set guioptions-=m  "menu bar
  set guioptions-=T  "toolbar
  set guioptions-=r  "scrollbar

  set wrap
  call MorningPages#setStatusLine()
endfunc

function! MorningPages#setStatusLine()
"	http://vim.wikia.com/wiki/Xterm256_color_names_for_console_Vim
"	hi x094_Orange4 ctermfg=94 guifg=#875f00 "rgb=135,95,0
"	hi x178_Gold3 ctermfg=178 guifg=#d7af00 "rgb=215,175,0
"

  hi statusline guibg=#222222 ctermfg=0 guifg=Black ctermbg=0
  hi User1 ctermfg=3 guifg=#d7af00 guibg=#222222
  hi User2 ctermfg=1 ctermbg=0 guifg=#d70000 guibg=#222222
  hi User3 ctermfg=0 ctermbg=2 guifg=#000000 guibg=#88ff00


  set statusline=
  set statusline+=%1*  "switch to todo highlight
  set statusline+=\ \ \ \ \ \ \ \ \ \
  set statusline+=%-30{BufferName()}

  let wc=WordCount()
  if (wc > g:morning_pages_words)
    set statusline+=%3*
  else
    set statusline+=%2*
  endif
  set statusline+=%10{WordCount()}
  set statusline+=%*       "switch back to normal statusline highlight
  set laststatus=2
endfunction


"-------------- word count ---------------
" from http://stackoverflow.com/questions/114431/fast-word-count-function-in-vim/120386#120386

"returns the count of how many words are in the entire file excluding the current line
"updates the buffer variable Global_Word_Count to reflect this
function! WordCount()
  if (expand("%") == "new")
    return ''
  endif

  let data = []
  "get lines above and below current line unless current line is first or last
  let data = getline(1, "$")
  let count_words = 0
  let pattern = g:morning_pages_word_pattern
  for str in data
    let count_words = count_words + NumPatternsInString(str, pattern)
  endfor
  let b:Global_Word_Count = count_words
  return count_words
endfunction

function! BufferName()
  if (expand("%") == "new")
    return ''
  else
    return substitute(expand("%:t"), "-\\|\\(.mp.md\\)", " ", "g")
  endif
endfunction

"returns the number of patterns found in a string
function! NumPatternsInString(str, pat)
    let i = 0
    let num = -1
    while i != -1
        let num = num + 1
        let i = matchend(a:str, a:pat, i)
    endwhile
    return num
endfunction

let s:soundPath = fnamemodify(resolve(expand('<sfile>:p')), ':h') . "/../sounds/"
let s:soundPlayer = "/usr/bin/afplay"

function! s:loadingSound()
  call PlaySound("page_load.wav")
endfunction

function! s:playTypewriterSound()
  let char=v:char
  let fileName = "soundslikewillem__" . char .".wav"
  "	call confirm("char ".char."   ".fileName)
  if (char == "\n")
    call PlaySound("enter.wav")
  elseif filereadable(s:soundPath . fileName)
    call PlaySound(fileName)
  else
    call PlaySound("soundslikewillem__e.wav")
  endif
endfunction

let s:recordedLine = line(".")
function! s:playTypewriterLineFeed()
  if line(".") != s:recordedLine
    let nextLine = line(".") - s:recordedLine
    let s:recordedLine = line(".")
    if (col(".") == 1 || strlen(substitute(getline("."), "^ *$", "", "g")) == 0) && nextLine == 1
      call PlaySound("enter.wav")
    endif
  endif
endfunction

function! PlaySound(soundName)
  if g:morning_pages_sound
    silent! call system(s:soundPlayer . " " . s:soundPath . a:soundName . " >/dev/null &")
  endif
endfunction

" Create a `VimroomToggle` command:
command! -nargs=0 MorningPages call MorningPages#load()
"
"
"
" vim:ts=2:sw=2:sts=2
