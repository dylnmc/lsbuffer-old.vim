
nnoremap <silent> <expr> gf isdirectory(expand(expand('<cfile>'))) ? ':call lsbuffer#ls(expand(expand(''<cfile>'')))<cr>' : 'gf'
nnoremap <silent> <leader>ls :call lsbuffer#ls()<cr>
nnoremap <silent> <leader>lS :call lsbuffer#ls(getcwd())<cr>
command! -bang -bar -nargs=? LsHidden call lsbuffer#setHidden(<q-args>, <bang>0)
" command! -bang -bar -nargs=? LsHidden echom '<'.(!<bang>+0)
" recommended mappings
" nnoremap <silent> <leader>lh :LsHidden!<cr>
" nnoremap <leader>lc :lcd %:p:h/

