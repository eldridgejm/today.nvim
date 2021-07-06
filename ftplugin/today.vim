nnoremap <buffer> <localleader>` :TodaySetPriority 0<cr>
vnoremap <buffer> <localleader>` :TodaySetPriority 0<cr>
nnoremap <buffer> <localleader>1 :TodaySetPriority 1<cr>
vnoremap <buffer> <localleader>1 :TodaySetPriority 1<cr>
nnoremap <buffer> <localleader>2 :TodaySetPriority 2<cr>
vnoremap <buffer> <localleader>2 :TodaySetPriority 2<cr>

nnoremap <buffer> <localleader>d :exec "TodayToggleDone" <bar> norm j<cr>
vnoremap <buffer> <localleader>d :TodayToggleDone

nnoremap <buffer> <localleader>rt :exec "TodayReschedule today" <bar> norm j<cr>
vnoremap <buffer> <localleader>rt :TodayReschedule today<cr>

nnoremap <buffer> <localleader>rm :exec "TodayReschedule tomorrow" <bar> norm j<cr>
vnoremap <buffer> <localleader>rm :TodayReschedule tomorrow<cr>

nnoremap <buffer> <localleader>rw :exec "TodayReschedule next week" <bar> norm j<cr>
vnoremap <buffer> <localleader>rw :TodayReschedule next week<cr>

nnoremap <buffer> <localleader>rr :TodayReschedule 
vnoremap <buffer> <localleader>rr :TodayReschedule 


command -buffer -range TodayMarkDone lua require('today.ui').mark_done(<line1>, <line2>)
command -buffer -range TodayMarkUndone lua require('today.ui').mark_undone(<line1>, <line2>)
command -buffer -range TodayToggleDone lua require('today.ui').toggle_done(<line1>, <line2>)
command -buffer -range TodayMakeDatespecAbsolute lua require('today.ui').make_datespec_absolute(<line1>, <line2>)
command -buffer -range TodayMakeDatespecNatural lua require('today.ui').make_datespec_natural(<line1>, <line2>)
command -buffer -range -nargs=1 TodayReschedule lua require('today.ui').reschedule(<line1>, <line2>, "<args>")
command -buffer -range -nargs=1 TodaySetPriority lua require('today.ui').set_priority(<line1>, <line2>, <args>)


augroup today
    autocmd!
    autocmd BufWritePre <buffer> lua require('today.ui').update_pre_write()
    autocmd BufWinEnter,BufWritePost <buffer> exec "lua require('today.ui').update_post_read()" | set modified&
augroup END
