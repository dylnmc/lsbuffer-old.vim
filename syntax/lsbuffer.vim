
if exists('b:current_syntax')
    finish
endif

let b:current_syntax = 'lsbuffer'

syntax match lsbufferDirectory "\m^.*\/\ze\t\%x00\|^.*\/$"
syntax match lsbufferComment "\m\%x00.*"

highlight link lsbufferDirectory Directory
highlight link lsbufferComment Comment
highlight link lsbufferExec String

