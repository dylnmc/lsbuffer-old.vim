
if exists('g:lsbuffer_loaded')
	finish
endif

let s:bufnr = -1
let s:lshidden = 0
let s:linenrs = {}
let s:prevdir = ''
let s:dirnochange = 0
let s:projdir = ''

function! s:savelinenr(pwd, ...)
	if s:bufnr ==# -1
		return
	endif
	let s:linenrs[a:pwd] = a:0 ==# 0 ? getbufinfo(s:bufnr)[0].lnum : a:1
endfunction

function! s:cdprev()
	if empty(s:prevdir)
		return
	endif
	call lsbuffer#ls(s:prevdir)
endfunction

function! s:gf(line)
	if a:line =~# '^\n'
		return
	endif
	let l:file = substitute(a:line, '\t\%x00.*', '', '')
	if isdirectory(l:file)
		call s:savelinenr(getcwd())
		call lsbuffer#ls(l:file)
	else
		execute 'edit '.escape(l:file, '\')
	endif
endfunction

function! s:setup_lsbuffer()
	" assume we're in the lsbuffer
	setlocal buftype=nofile nobuflisted filetype=lsbuffer number relativenumber nolist colorcolumn= conceallevel=3 concealcursor=nvic
	file lsbuffer
	let s:bufnr = bufnr('')
	" buffer mappings for lsbuffer
	nnoremap <silent> <buffer> gf :call <sid>gf(getline('.'))<cr>
	nmap <silent> <buffer> <cr> gf
	nmap <silent> <buffer> l gf
	nmap <silent> <buffer> <bs> :call <sid>savelinenr(getcwd(), line('.'))<bar>call lsbuffer#ls('..')<cr>
	nmap <silent> <buffer> h <bs>
	nnoremap <silent> <buffer> - :call <sid>savelinenr(getcwd(), line('.'))<bar>call <sid>cdprev()<cr>
	" nnoremap <silent> <buffer> <leader>d 
	" buffer autocmds for lsbuffer
	augroup LsBuffer
		autocmd! * <buffer>
		" if the cursor moves, update the linenr 
		autocmd CursorMoved <buffer> call <sid>savelinenr(getcwd(), line('.'))
		autocmd DirChanged <buffer> if s:dirnochange | let s:dirnochange = 0 | else | call lsbuffer#ls() | endif
	augroup end
endfunction

" parameters:
"  a:arg: empty string if no argument passed, '1' or '0' otherwise; if a:arg is
"         not an empty string, then if set hidden to str2nr(a:arg)
"  a:bang: 1 if bang used after the command; 0 otherwise; if a:arg is an empty
"          string and bang is used after the command, then toggle hidden
" notes:
"  - if a:arg is '0' or '1', then a:bang is not used
"  - if a:arg and a:bang are empty, then simply print the current state
"  - print the state after changingn values as well
"  - if the value changes and lsbuffer is visible in a window, then re-display
"    the buffer by calling lsbuffer#ls('', 1)
function! lsbuffer#setHidden(arg, bang)
	if ! empty(a:arg)
		let s:lshidden = str2nr(a:arg)
	elseif a:bang
		let s:lshidden = ! s:lshidden
	endif
	unsilent echon 'dot files are '.(s:lshidden ? 'SHOWN' : 'HIDDEN')
	if (a:bang || ! empty(a:arg)) && len(filter(range(1, winnr('$')), { _,wn -> bufname(winbufnr(wn)) ==# 'lsbuffer' }))
		call lsbuffer#ls('', 1)
	endif
endfunction

" optional parameters:
"  a:1: new directory to :lcd to first
"  a:2: 0/1 to not preserve or preserve (resp) current directory
function! lsbuffer#ls(...)
	let l:winprevid = 0
	if a:0 > 1 && str2nr(a:2)
		let l:winprevid = win_getid()
	endif

	if bufnr('$') ==# 1 && winnr('$') ==# 1 && len(undotree().entries) ==# 0
		call s:setup_lsbuffer()
	elseif s:bufnr >= 0
		if ! (expand('%') ==# 'lsbuffer' && &filetype ==# 'lsbuffer')
			let l:nr = -1
			for l:n in range(1, winnr('$'))
				if bufname(winbufnr(l:n)) ==# 'lsbuffer' && getwinvar(l:n, '&filetype') ==# 'lsbuffer'
					let l:nr = l:n
					break
				endif
			endfor
			if l:nr >= 0
				execute l:nr.'wincmd w'
			else
				execute 'sbuffer '.s:bufnr
			endif
		endif
	else
		new
		call s:setup_lsbuffer()
	endif
	setlocal noreadonly modifiable

	if a:0 > 0 && isdirectory(a:1) " a parameter was passed; lcd a:1 before ls
		" preserve previous directory
		let s:prevdir = getcwd()
		" since this will trigger autocmd DirChanged, temporarily disable
		let s:dirnochange = 1
		execute 'lcd '.a:1
	endif

	silent %delete
	call append(0, ["\n".getcwd()] + map(sort(extend(split(glob('*'), "\n"), s:lshidden ? split(glob('.*'), "\n") : ['.', '..'])), { _,fn -> isdirectory(fn) ? fn.'/' : fn }))
	delete

	call setpos('.', [bufnr(''), 1, 1, 1])

	let l:pwd = getcwd()

	" if previous directory is in the current ls, then jump to this line
	if ! (empty(s:prevdir) || search('\m^\V'.escape(fnamemodify(s:prevdir, ':t'), '\/').'\m\/\?$'))
		" if previous directory isn't found in current ls, jump to the line that
		" the cursor was on last time we were in this directory; if we weren't
		" here before, default to line 3 (after ./ and ../)
		execute get(s:linenrs, l:pwd, 3)
	endif

	call <sid>savelinenr(l:pwd)

	setl readonly nomodifiable

	if l:winprevid > 0
		call win_gotoid(l:winprevid)
	endif
endfunction

