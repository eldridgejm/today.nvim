nnoremap <buffer> <localleader>` :TodayTaskSetPriority 0<cr>
vnoremap <buffer> <localleader>` :TodayTaskSetPriority 0<cr>
nnoremap <buffer> <localleader>1 :TodayTaskSetPriority 1<cr>
vnoremap <buffer> <localleader>1 :TodayTaskSetPriority 1<cr>
nnoremap <buffer> <localleader>2 :TodayTaskSetPriority 2<cr>
vnoremap <buffer> <localleader>2 :TodayTaskSetPriority 2<cr>

nnoremap <buffer> <localleader>d :exec "TodayTaskToggleDone" <bar> norm j<cr>
vnoremap <buffer> <localleader>d :TodayTaskToggleDone<cr>

nnoremap <buffer> <localleader>rt :exec "TodayTaskSetDoDate today"<cr>
vnoremap <buffer> <localleader>rt :TodayTaskSetDoDate today<cr>

nnoremap <buffer> <localleader>rm :exec "TodayTaskSetDoDate tomorrow"<cr>
vnoremap <buffer> <localleader>rm :TodayTaskSetDoDate tomorrow<cr>

nnoremap <buffer> <localleader>rw :exec "TodayTaskSetDoDate next week"<cr>
vnoremap <buffer> <localleader>rw :TodayTaskSetDoDate next week<cr>

nnoremap <buffer> <localleader>rr :TodayTaskSetDoDate 
vnoremap <buffer> <localleader>rr :TodayTaskSetDoDate 

nnoremap <buffer> <localleader>cd :TodayCategorizeDailyAgenda<cr>
nnoremap <buffer> <localleader>ct :TodayCategorizeFirstTag<cr>

nnoremap <buffer> <cr> :lua require('today.ui').follow_link()<cr>


command -buffer -range TodayTaskMarkDone lua require('today.ui').task_mark_done(<line1>, <line2>)
command -buffer -range TodayTaskMarkUndone lua require('today.ui').task_mark_undone(<line1>, <line2>)
command -buffer -range TodayTaskToggleDone lua require('today.ui').task_toggle_done(<line1>, <line2>)
command -buffer -range TodayTaskRemoveDatespec lua require('today.ui').task_remove_datespec(<line1>, <line2>)
command -buffer -range -nargs=1 TodayTaskSetDoDate lua require('today.ui').task_set_do_date(<line1>, <line2>, "<args>")
command -buffer -range -nargs=1 TodayTaskSetPriority lua require('today.ui').task_set_priority(<line1>, <line2>, <args>)
command -buffer -range -nargs=1 TodayTaskSetFirstTag lua require('today.ui').task_set_first_tag(<line1>, <line2>, "<args>")
command -buffer -range TodayTaskRemoveFirstTag lua require('today.ui').task_remove_first_tag(<line1>, <line2>)
command -buffer -nargs=1 TodayExpandRecur lua require('today.ui').expand_recur("<args>")
command -buffer -range -nargs=1 TodayPaintRecur lua require('today.ui').paint_recur("<args>", <line1>, <line2>)
command -buffer TodayCategorizeDailyAgenda lua require('today.ui').categorize_by_daily_agenda()
command -buffer TodayCategorizeFirstTag lua require('today.ui').categorize_by_first_tag()
command -buffer -nargs=* TodayFilterTags lua require('today.ui').set_filter_tags({<f-args>})


if !exists('b:today_autocommands_loaded')
    let b:today_autocommands_loaded = 1
    autocmd BufWritePre <buffer> lua require('today.ui').update("write")
    autocmd BufWinEnter,BufWritePost,FileChangedShellPost <buffer> exec "lua require('today.ui').update('view')" | set modified&
    autocmd BufWinEnter <buffer> lua require('today.ui').start_refresh_loop()
    autocmd BufWinEnter <buffer> exec 'norm gg' | lua require('today.ui').move_to_next_section(true)
    autocmd BufDelete <buffer> lua require('today.ui').stop_refresh_loop_if_no_buffers()
endif
