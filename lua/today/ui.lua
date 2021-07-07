--- The user interface.

local task = require("today.core.task")
local update = require("today.core.update")

local date = require("today.vendor.date")

local ui = {}

ui.options = {
    -- the time at which the today buffer will be automatically refreshed
    refresh_time = nil,
}

--- Takes in a function `func` and makes a function which applies `func` to a
-- range of lines.
local function make_ranged_function(func)
    return function(start_row, end_row, ...)
        local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, 0)

        local transformed_lines = {}
        for _, line in pairs(lines) do
            local result
            if not task.is_task(line) then
                result = line
            else
                result = func(line, ...)
            end
            table.insert(transformed_lines, result)
        end

        vim.api.nvim_buf_set_lines(0, start_row - 1, end_row, 0, transformed_lines)
    end
end

ui.task_mark_done = make_ranged_function(task.mark_done)
ui.task_mark_undone = make_ranged_function(task.mark_undone)
ui.task_toggle_done = make_ranged_function(task.toggle_done)
ui.task_reschedule = make_ranged_function(task.set_do_date)
ui.task_set_priority = make_ranged_function(task.set_priority)
ui.task_make_datespec_absolute = make_ranged_function(task.make_datespec_absolute)
ui.task_make_datespec_natural = make_ranged_function(task.make_datespec_natural)
ui.task_set_do_date = make_ranged_function(task.set_do_date)

function ui.update_pre_write()
    local today = date(vim.b.today_working_date)
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, 0)
    vim.api.nvim_buf_set_lines(0, 0, -1, 0, update.pre_write(lines, today))
end

function ui.update_post_read()
    local today = ui.get_current_time()

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, 0)
    vim.api.nvim_buf_set_lines(0, 0, -1, 0, update.post_read(lines, today))

    vim.b.today_working_date = today:fmt("%Y-%m-%d")
end

local function time_in_seconds(when)
    if when == nil then
        when = ui.get_current_time()
    end
    local hour, min, sec, _ = when:gettime()
    return sec + 60 * min + 3600 * hour
end

function ui.refresh_all_buffers()
    -- for every buffer with filetype=today, if the buffer is not modified,
    -- re-read its contents
    local reload = function()
        vim.cmd("e")
    end

    for _, buffer in pairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_get_option(buffer, "filetype") == "today" then
            if not vim.api.nvim_buf_get_option(buffer, "modified") then
                vim.api.nvim_buf_call(buffer, reload)
            end
        end
    end
end

function ui.start_refresh_loop()
    if ui.timer ~= nil then
        return
    end

    if ui.options.refresh_time == nil then
        return
    end

    local last_time = time_in_seconds(ui.get_current_time())
    local current_time = time_in_seconds(ui.get_current_time())

    ui.timer = vim.loop.new_timer()
    ui.timer:start(
        1000,
        5000,
        vim.schedule_wrap(function()
            current_time = time_in_seconds(ui.get_current_time())
            print(current_time)

            local at_time = ui.options.refresh_time
            if at_time == nil then
                return
            end

            local c1 = (last_time < at_time) and (current_time >= at_time)
            local c2 = (last_time > current_time) and (current_time >= at_time)
            if c1 or c2 then
                print(last_time, current_time, at_time)
                ui.refresh_all_buffers()
            end
            last_time = current_time
        end)
    )
end

function ui.get_current_time()
    local delta = ui.time_delta or 0
    return date():addseconds(delta)
end

ui.time_delta = nil

function ui.set_current_time(d)
    ui.time_delta = (date(d) - date()):spanseconds()
end

return ui
