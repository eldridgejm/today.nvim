nnoremap <buffer> <localleader>` :lua require('today.ui').set_priority(0)<cr>
nnoremap <buffer> <localleader>1 :lua require('today.ui').set_priority(1)<cr>
nnoremap <buffer> <localleader>2 :lua require('today.ui').set_priority(2)<cr>

vnoremap <buffer> <localleader>` :lua require('today.ui').block_set_priority(0)<cr>
vnoremap <buffer> <localleader>1 :lua require('today.ui').block_set_priority(1)<cr>
vnoremap <buffer> <localleader>2 :lua require('today.ui').block_set_priority(2)<cr>

nnoremap <buffer> <localleader>d :lua require('today.ui').toggle_done()<cr>
vnoremap <buffer> <localleader>d :lua require('today.ui').block_toggle_done()<cr>

augroup today
    autocmd!
    autocmd BufWritePre *.today lua require('today.ui').update()
augroup END
