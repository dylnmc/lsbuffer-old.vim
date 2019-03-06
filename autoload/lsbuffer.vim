
if exists('g:lsbuffer_loaded')
	finish
endif

let s:bufnr = 0
let s:lshidden = 0
let s:linenrs = {}
let s:cwd = ''
let s:prevcwd = ''
let s:dirnochange = 0
let s:execmatches = []
let s:projdir = '' " TODO

function! s:savelinenr(cwd, ...)
	if ! s:bufnr
		return
	endif
	let s:linenrs[a:cwd] = a:0 ==# 0 ? getbufinfo(s:bufnr)[0].lnum : a:1
endfunction

function! s:cdprev()
	if empty(s:prevcwd)
		return
	endif
	call lsbuffer#ls(s:prevcwd)
endfunction

function! s:gf(line)
	if a:line =~# '^\n'
		return
	endif
	let l:file = substitute(a:line, '\/*\%(\t\%x00.*\)\?$', '', '')
	if isdirectory(l:file)
		call s:savelinenr(s:cwd)
		call lsbuffer#ls(l:file ==# '..' ? fnamemodify(s:cwd, ':h') : s:cwd.(s:cwd ==# '/' ? '' : '/').l:file)
	else
		while len(s:execmatches)
			call matchdelete(remove(s:execmatches, 0))
		endwhile
		for l:match in filter(getmatches(), { _,match -> match.pattern ==# '\%x00' })
			call matchdelete(l:match.id)
		endfor
		execute 'edit '.escape(l:file, '\')
	endif
endfunction

function! lsbuffer#getcwd()
	return s:cwd
endfunction

function! s:setup_lsbuffer()
	" assume we're in the lsbuffer
	setlocal buftype=nofile nobuflisted filetype=lsbuffer nolist colorcolumn= conceallevel=3 concealcursor=nvic tabstop=20
	file lsbuffer
	call matchadd('Conceal', '\%x00', -1)

	" buffer mappings for lsbuffer
	nnoremap <silent> <buffer> gf :call <sid>gf(getline('.'))<cr>
	nmap <silent> <buffer> <cr> gf
	nmap <silent> <buffer> l gf
	nmap <silent> <buffer> <bs> :call <sid>savelinenr(lsbuffer#getcwd(), line('.'))<bar>call lsbuffer#ls(fnamemodify(lsbuffer#getcwd(), ':h'))<cr>
	nmap <silent> <buffer> h <bs>
	nnoremap <silent> <buffer> - :call <sid>savelinenr(lsbuffer#getcwd(), line('.'))<bar>call <sid>cdprev()<cr>
	nnoremap <buffer> cd :silent lcd<space>
	" nnoremap <silent> <buffer> <leader>d 

	" buffer autocmds for lsbuffer
	augroup LsBuffer
		autocmd! * <buffer>
		" if the cursor moves, update the linenr 
		autocmd CursorMoved <buffer> call <sid>savelinenr(lsbuffer#getcwd(), line('.'))
		" if the directory changes then (if s:dirnochange != 0, then set it to 0, else call lsbuffer#ls())
		autocmd DirChanged <buffer> if s:dirnochange | let s:dirnochange = 0 | else | call lsbuffer#ls(executable('pwd') ? system('pwd -L')[:-2] : getcwd()) | endif
		" reapply conceal for <nul> for new windows
		autocmd WinEnter,BufWinEnter <buffer> if ! len(filter(getmatches(), { _,o -> o.group ==# 'lsbufferNUL' })) | call <sid>setup_lsbuffer() | endif
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
"  a:1: new directory to cd to first (cannot be relative with ..)
"  a:2: 0/1 to not preserve or preserve (resp) current directory
function! lsbuffer#ls(...)
	if empty(s:cwd)
		if executable('pwd')
			let s:cwd = system('pwd -L')[:-2]
		else
			let s:cwd = getcwd()
		endif
	endif

	let l:winprevid = -1
	if a:0 > 1 && str2nr(a:2)
		let l:winprevid = win_getid()
	endif

	if s:bufnr > 0
		" if lsbuffer already created
		if ! (expand('%') ==# 'lsbuffer' && &filetype ==# 'lsbuffer')
			let l:winid = bufwinid(s:bufnr)
			if l:winid ==# -1
				" echom "execute '".(len(undotree().entries) && ! wordcount().bytes ? '' : 's')."buffer '".s:bufnr
				" execute (len(undotree().entries) && ! wordcount().bytes ? '' : 's').'buffer '.s:bufnr
				execute 'sbuffer '.s:bufnr
				" if get(g:, 'break', 0)
				" 	echom 'hit g:break'
				" 	return
				" endif
			else
				call win_gotoid(l:winid)
			endif
		endif
	else
		if len(undotree().entries) && ! wordcount().bytes
			new
		endif
		let s:bufnr = bufnr('')
		call s:setup_lsbuffer()
	endif
	setlocal noreadonly modifiable

	if a:0 > 0 && isdirectory(a:1) " a parameter was passed; `lcd a:1` before `!ls`
		" preserve previous directory
		if s:cwd !=# s:prevcwd
			let s:prevcwd = s:cwd
		endif
		" since this will trigger autocmd DirChanged, temporarily disable
		let s:cwd = a:1
		let s:dirnochange = 1
		silent! execute 'lcd '.s:cwd
	endif

	silent call deletebufline(s:bufnr, 1, '$')
	let l:executables = [[]]
	let l:files = map(filter(sort(split(glob(s:cwd.'/*'), "\n") + (s:lshidden ? split(glob(s:cwd.'/.*'), "\n") : [])), { _,fn -> fnamemodify(fn, ':t') !~# '^\.\.\?\/\?$' }), { _,fn -> isdirectory(fn) ? fnamemodify(fn, ':t').'/' : fnamemodify(fn, ':t') })

	while len(s:execmatches)
		silent! call matchdelete(remove(s:execmatches, 0))
	endwhile
	let l:execmatch = []
	let l:resolves = []
	let l:i = 0
	for l:file in l:files
		if executable(l:file)
			call add(l:execmatch, [l:i + 3, 1, len(l:file)])
			if len(l:execmatch) ==# 8
				call add(s:execmatches, matchaddpos('lsbufferExec', remove(l:execmatch, 0, -1)))
			endif
		endif
		let l:resolve = resolve(l:file)
		if l:file !=# l:resolve.(l:file[-1:] ==# '/' ? '/' : '')
			let l:files[l:i] .= "\t\n -> ".l:resolve
		endif
		let l:i += 1
	endfor
	if len(l:execmatch)
		call add(s:execmatches, matchaddpos('lsbufferExec', l:execmatch))
	endif

	call appendbufline(s:bufnr, 0, ["\n".s:cwd.'/', '../'] + l:files)
	call deletebufline(s:bufnr, '$')

	call setpos('.', [bufnr(''), 1, 1, 1])

	" if previous directory is in the current ls, then jump to this line, else jump to line 3
	call cursor(get(s:linenrs, s:cwd, 3), 1)

	call <sid>savelinenr(s:cwd)

	setl readonly nomodifiable

	if l:winprevid >= 0
		call win_gotoid(l:winprevid)
	endif
endfunction

