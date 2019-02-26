
" global usage: use these maps/commands anywhere
"   gf              if <cfile> is a directory, open lsbuffer; else, use gf normally
"   <leader>ls      opens the lsbuffer (if already open keep pwd the same, otherwise use pwd of current buffer)
"   <leader>lS      opens the lsbuffer and uses pwd of current buffer
"   :LsHidden 1     show dot files
"   :LsHidden 0     hide dot files
"   :LsHidden!      toggle showing dot files
"   :LsHidden       prints out state
"   <leader>lh      same as :LsHidden! for convenience
"   <leader>lc      lcd to %:p:h (directory of buffer); await return so user can append ".." for example
"
" lsbuffer usage: use these mappings inside the lsbuffer buffer
"   gf      enter the directory or open the file
"   <cr>    same as gf
"   l       same as gf
"   <bs>    lcd ..
"   h       same as <bs>
"   -       lcd to previous directory
"
" notes:
"   don't forget you can use <c-w>f to open the file in a split
"   you can :lcd to anywhere in the lsbuffer, and it will re-ls the new directory

nnoremap <silent> <expr> gf isdirectory(expand('<cfile>')) ? 'call lsbuffer#ls(expand(''<cfile>'')<cr>' : 'gf'
nnoremap <silent> <leader>ls :call lsbuffer#ls()<cr>
nnoremap <silent> <leader>lS :call lsbuffer#ls(getcwd())<cr>
command! -bar -bang -nargs=? LsHidden let s:lshidden = (<bang>s:lshidden || strlen(<q-args>) && str2nr(<q-args>)) | unsilent echon (s:lshidden ? 'dot files are SHOWN' : 'dot files are HIDDEN') | if (<bang>0 || ! empty(<q-args>)) | if len(filter(range(1, winnr('$')), { _,wn -> bufname(winbufnr(wn)) ==# 'lsbuffer' })) | call lsbuffer#ls() | endif | endif

" recommended mappings
" nnoremap <silent> <leader>lh :LsHidden!<cr>
" nnoremap <leader>lc :lcd %:p:h/

