nnoremap <buffer> <localleader>` :TodayTaskSetPriority 0<cr>
vnoremap <buffer> <localleader>` :TodayTaskSetPriority 0<cr>
nnoremap <buffer> <localleader>1 :TodayTaskSetPriority 1<cr>
vnoremap <buffer> <localleader>1 :TodayTaskSetPriority 1<cr>
nnoremap <buffer> <localleader>2 :TodayTaskSetPriority 2<cr>
vnoremap <buffer> <localleader>2 :TodayTaskSetPriority 2<cr>

nnoremap <buffer> <localleader>d :exec "TodayTaskToggleDone" <bar> norm j<cr>
vnoremap <buffer> <localleader>d :TodayTaskToggleDone<cr>

nnoremap <buffer> <localleader>rt :exec "TodayTaskReschedule today"<cr>
vnoremap <buffer> <localleader>rt :TodayTaskReschedule today<cr>

nnoremap <buffer> <localleader>rm :exec "TodayTaskReschedule tomorrow"<cr>
vnoremap <buffer> <localleader>rm :TodayTaskReschedule tomorrow<cr>

nnoremap <buffer> <localleader>rw :exec "TodayTaskReschedule next week"<cr>
vnoremap <buffer> <localleader>rw :TodayTaskReschedule next week<cr>

nnoremap <buffer> <localleader>rr :TodayTaskReschedule 
vnoremap <buffer> <localleader>rr :TodayTaskReschedule 

nnoremap <buffer> <localleader>cd :TodayCategorizeByDoDate<cr>
nnoremap <buffer> <localleader>ct :TodayCategorizeByFirstTag<cr>


command -buffer -range TodayTaskMarkDone lua require('today.ui').task_mark_done(<line1>, <line2>)
command -buffer -range TodayTaskMarkUndone lua require('today.ui').task_mark_undone(<line1>, <line2>)
command -buffer -range TodayTaskToggleDone lua require('today.ui').task_toggle_done(<line1>, <line2>)
command -buffer -range -nargs=1 TodayTaskReschedule lua require('today.ui').task_reschedule(<line1>, <line2>, "<args>")
command -buffer -range -nargs=1 TodayTaskSetPriority lua require('today.ui').task_set_priority(<line1>, <line2>, <args>)
command -buffer -range -nargs=1 TodayPaintRecurPattern lua require('today.ui').paint_recur_pattern("<args>", <line1>, <line2>)
command -buffer TodayCategorizeByDoDate lua require('today.ui').organize_by_do_date()
command -buffer TodayCategorizeByFirstTag lua require('today.ui').organize_by_first_tag()
command -buffer -nargs=* TodayFilterTags lua require('today.ui').set_filter_tags({<f-args>})


augroup today
    autocmd!
    autocmd BufWritePre <buffer> lua require('today.ui').update_pre_write()
    autocmd BufWinEnter,BufWritePost,FileChangedShellPost <buffer> exec "lua require('today.ui').update_post_read()" | set modified&
    autocmd BufWinEnter <buffer> lua require('today.ui').start_refresh_loop()
    autocmd BufDelete <buffer> lua require('today.ui').on_buffer_delete()
augroup END
