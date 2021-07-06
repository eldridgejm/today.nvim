task = require('today.core.task')
util = require('today.core.util')
update = require('today.core.update')
date = require('today.vendor.date')


ui = {}


function make_ranged_function(func)
    -- takes in a function `func` and makes a function which applies
    -- `func` to a range of lines
    return function (start_row, end_row, ...)
        local lines = vim.api.nvim_buf_get_lines(0, start_row-1, end_row, 0)

        local transformed_lines = {}
        for _, line in pairs(lines) do
            local result = ""
            if not task.is_task(line) then
                result = line
            else
                result = func(line, ...)
            end
            table.insert(transformed_lines, result)
        end

        vim.api.nvim_buf_set_lines(0, start_row-1, end_row, 0, transformed_lines)
    end
end


ui.mark_done = make_ranged_function(task.mark_done)
ui.mark_undone = make_ranged_function(task.mark_undone)
ui.toggle_done = make_ranged_function(task.toggle_done)
ui.reschedule = make_ranged_function(task.set_do_date)
ui.set_priority = make_ranged_function(task.set_priority)
ui.make_datespec_absolute = make_ranged_function(task.make_datespec_absolute)
ui.make_datespec_natural = make_ranged_function(task.make_datespec_natural)
ui.set_do_date = make_ranged_function(task.set_do_date)


function ui.update_pre_write(today)
    if today == nil then
        today = date(vim.b.today_working_date)
    else
        today = date(today)
    end

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, 0)
    vim.api.nvim_buf_set_lines(0, 0, -1, 0, update.pre_write(lines, today))
end


function ui.update_post_read(today)
    if today == nil then
        today = date()
    else
        today = date(today)
    end

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, 0)
    vim.api.nvim_buf_set_lines(0, 0, -1, 0, update.post_read(lines, today))

    vim.b.today_working_date = today:fmt('%Y-%m-%d')
end


function time_in_seconds(date)
    local hour, min, sec, _ = date:gettime()
    return sec + 60 * min + 3600 * hour
end


function ui.refresh_all_buffers()
    -- for every buffer with filetype=today, if the buffer is not modified,
    -- re-read its contents
    local reload = function()
        vim.cmd("e")
    end

    for _, buffer in pairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_get_option(buffer, 'filetype') == 'today' then
            if not vim.api.nvim_buf_get_option(buffer, 'modified') then
                vim.api.nvim_buf_call(buffer, reload)
            end
        end
    end
end


function ui.start_refresh_loop(at_time, now)
    if ui.timer ~= nil then
        return
    end

    if now == nil then
        now = date
    end

    if at_time == nil then
        at_time = time_in_seconds(now()) + 10
    end

    local last_time = time_in_seconds(now())
    local current_time = time_in_seconds(now())

    ui.timer = vim.loop.new_timer()
    ui.timer:start(1000, 5000, vim.schedule_wrap(function()
        current_time = time_in_seconds(now())
        if (last_time < at_time) and (current_time >= at_time) then
            print(last_time, current_time, at_time)
            ui.refresh_all_buffers() 
        end
        last_time = current_time
    end))
end


return ui
