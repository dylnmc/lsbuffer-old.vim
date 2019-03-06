lsbuffer.vim
============

uh. yep.

## global usage

use these maps/commands anywhere

| map/command   | description                                                                                   |
| ---           | ---                                                                                           |
| `gf`          | if <cfile> is a directory, open *lsbuffer;* else, use `gf` normally                           |
| `<leader>ls`  | opens the *lsbuffer* (if already open keep pwd the same, otherwise use pwd of current buffer) |
| `<leader>lS`  | opens the *lsbuffer* and uses pwd of current buffer                                           |
| `:LsHidden 1` | *show* dot files                                                                              |
| `:LsHidden 0` | *hide* dot files                                                                              |
| `:LsHidden!`  | *toggle* showing dot files                                                                    |
| `:LsHidden`   | prints out state                                                                              |

## lsbuffer usage

use these mappings inside the lsbuffer buffer

| map/command | description                          |
| ---         | ---                                  |
| `gf`        | enter the directory or open the file |
| `<cr>`      | same as gf                           |
| `l`         | same as gf                           |
| `<bs>`      | lcd ..                               |
| `h`         | same as <bs>                         |
| `-`         | lcd to previous directory            |
| `cd`        | type `:silent lcd `                  |

## recommended mappings

| map/command  | description                             |
| ---          | ---                                     |
| `<leader>lh` | same as `:LsHidden!` for convenience    |
| `<leader>lc` | types `:lcd %:p:h/` and awaits a `<cr>` |

## notes

- don't forget you can use `<c-w>f` to open the file in a split
- you can `:lcd` to anywhere in the lsbuffer, and it will re-*ls* the new directory

## TODO

- allow for "freezing" a directory and *ls*ing relative to that directory
    - use `p` ("Project directory")
    - use `P` for browsing all Project directories
- testing and bug finding/fixing ... test it out! submit an issue!

