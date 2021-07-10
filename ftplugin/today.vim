nnoremap <buffer> <localleader>` :TodaySetPriority 0<cr>
vnoremap <buffer> <localleader>` :TodaySetPriority 0<cr>
nnoremap <buffer> <localleader>1 :TodaySetPriority 1<cr>
vnoremap <buffer> <localleader>1 :TodaySetPriority 1<cr>
nnoremap <buffer> <localleader>2 :TodaySetPriority 2<cr>
vnoremap <buffer> <localleader>2 :TodaySetPriority 2<cr>

nnoremap <buffer> <localleader>d :exec "TodayToggleDone" <bar> norm j<cr>
vnoremap <buffer> <localleader>d :TodayToggleDone<cr>

nnoremap <buffer> <localleader>rt :exec "TodayReschedule today"<cr>
vnoremap <buffer> <localleader>rt :TodayReschedule today<cr>

nnoremap <buffer> <localleader>rm :exec "TodayReschedule tomorrow"<cr>
vnoremap <buffer> <localleader>rm :TodayReschedule tomorrow<cr>

nnoremap <buffer> <localleader>rw :exec "TodayReschedule next week"<cr>
vnoremap <buffer> <localleader>rw :TodayReschedule next week<cr>

nnoremap <buffer> <localleader>rr :TodayReschedule 
vnoremap <buffer> <localleader>rr :TodayReschedule 

nnoremap <buffer> <localleader>cd :TodayCategorize do_date<cr>
nnoremap <buffer> <localleader>ct :TodayCategorize first_tag<cr>


command -buffer -range TodayMarkDone lua require('today.ui').task_mark_done(<line1>, <line2>)
command -buffer -range TodayMarkUndone lua require('today.ui').task_mark_undone(<line1>, <line2>)
command -buffer -range TodayToggleDone lua require('today.ui').task_toggle_done(<line1>, <line2>)
command -buffer -range TodayMakeDatespecAbsolute lua require('today.ui').task_make_datespec_absolute(<line1>, <line2>)
command -buffer -range TodayMakeDatespecNatural lua require('today.ui').task_make_datespec_natural(<line1>, <line2>)
command -buffer -range -nargs=1 TodayReschedule lua require('today.ui').task_reschedule(<line1>, <line2>, "<args>")
command -buffer -range -nargs=1 TodaySetPriority lua require('today.ui').task_set_priority(<line1>, <line2>, <args>)
command -buffer -range -nargs=1 TodayCategorize let b:today_categorizer="<args>" <bar> lua require('today.ui').organize()


augroup today
    autocmd!
    autocmd BufWritePre <buffer> lua require('today.ui').update_pre_write()
    autocmd BufWinEnter,BufWritePost,FileChangedShellPost <buffer> exec "lua require('today.ui').update_post_read()" | set modified&
    autocmd BufWinEnter <buffer> lua require('today.ui').start_refresh_loop()
    autocmd BufDelete <buffer> lua require('today.ui').on_buffer_delete()
augroup END
