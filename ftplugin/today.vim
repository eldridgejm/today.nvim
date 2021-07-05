nnoremap <buffer> <localleader>` :lua require('today.ui').set_priority(0)<cr>
vnoremap <buffer> <localleader>` :lua require('today.ui').block_set_priority(0)<cr>
nnoremap <buffer> <localleader>1 :lua require('today.ui').set_priority(1)<cr>
vnoremap <buffer> <localleader>1 :lua require('today.ui').block_set_priority(1)<cr>
nnoremap <buffer> <localleader>2 :lua require('today.ui').set_priority(2)<cr>
vnoremap <buffer> <localleader>2 :lua require('today.ui').block_set_priority(2)<cr>

nnoremap <buffer> <localleader>d :exec "lua require('today.ui').toggle_done()" <bar> norm j<cr>
vnoremap <buffer> <localleader>d :lua require('today.ui').block_toggle_done()<cr>

nnoremap <buffer> <localleader>rt :exec "lua require('today.ui').set_do_date('tomorrow')" <bar> norm j<cr>
vnoremap <buffer> <localleader>rt :lua require('today.ui').block_set_do_date('tomorrow')<cr>

nnoremap <buffer> <localleader>rn :exec "lua require('today.ui').set_do_date('today')" <bar> norm j<cr>
vnoremap <buffer> <localleader>rn :lua require('today.ui').block_set_do_date('today')<cr>

nnoremap <buffer> <localleader>rw :exec "lua require('today.ui').set_do_date('next week')" <bar> norm j<cr>
vnoremap <buffer> <localleader>rw :lua require('today.ui').block_set_do_date('next week')<cr>

nnoremap <buffer> <localleader>rr ^f<ci<
vnoremap <buffer> <localleader>rr :s/<.*>/<><left>

augroup today
    autocmd!
    autocmd BufWritePre *.today lua require('today.ui').update_pre_write()
    autocmd BufWinEnter,BufWritePost *.today exec "lua require('today.ui').update_post_read()" | set modified&
augroup END
