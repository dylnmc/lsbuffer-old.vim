
nnoremap <silent> <expr> gf isdirectory(fnamemodify(expand('<cfile>'), ':p')) ? ':call lsbuffer#ls(fnamemodify(expand(''<cfile>''), ':p'))<cr>' : 'gf'
nnoremap <silent> <leader>ls :call lsbuffer#ls()<cr>
nnoremap <silent> <leader>lS :call lsbuffer#ls(executable('pwd') ? system('pwd -L')[:-2] : getcwd())<cr>
command! -bang -bar -nargs=? LsHidden call lsbuffer#setHidden(<q-args>, <bang>0)

" recommended mappings
" nnoremap <silent> <leader>lh :LsHidden!<cr>
" nnoremap <leader>lc :lcd %:p:h/

