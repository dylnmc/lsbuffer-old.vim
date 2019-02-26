
if exists('g:lsbuffer_loaded')
	finish
endif

let s:bufnr = -1
let s:lshidden = 0
let s:linenrs = {}
let s:prevdir = ''
let s:dirnochange = 0

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

function s:setup_lsbuffer()
	" assume we're in the lsbuffer
	setlocal buftype=nofile nobuflisted filetype=lsbuffer number relativenumber nolist colorcolumn=
	file lsbuffer
	let s:bufnr = bufnr('')
	" buffer mappings for lsbuffer
	nnoremap <silent> <expr> <buffer> gf isdirectory(expand('<cfile>')) ? ':call <sid>savelinenr(getcwd(), line(''.''))<bar>call lsbuffer#ls(expand(''<cfile>''))<cr>' : 'gf'
	nmap <silent> <buffer> <cr> gf
	nmap <silent> <buffer> l gf
	nmap <silent> <buffer> <bs> :call <sid>savelinenr(getcwd(), line('.'))<bar>call lsbuffer#ls('..')<cr>
	nmap <silent> <buffer> h <bs>
	nnoremap <silent> <buffer> - :call <sid>savelinenr(getcwd(), line('.'))<bar>call <sid>cdprev()<cr>
	" buffer autocmds for lsbuffer
	augroup LsBuffer
		autocmd! * <buffer>
		" if the cursor moves, update the linenr 
		autocmd CursorMoved <buffer> call <sid>savelinenr(getcwd(), line('.'))
		autocmd DirChanged <buffer> if s:dirnochange | let s:dirnochange = 0 | else | call lsbuffer#ls() | endif
	augroup end
endfunction

function! lsbuffer#ls(...)
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
	call append(0, map(sort(extend(split(glob('*'), "\n"), s:lshidden ? split(glob('.*'), "\n") : ['.', '..'])), { _,fn -> isdirectory(fn) ? fn.'/' : fn }))
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
	" let s:bufnr = bufnr('')
endfunction

