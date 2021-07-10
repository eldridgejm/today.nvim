local task = require("today.core.task")
local update = require("today.core.update")
local util = require("today.core.util")

local date = require("today.vendor.date")

local ui = {}

ui.options = {
    -- the time at which the today buffer will be automatically refreshed
    automatic_refresh = true,
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

    local function is_today_buffer(bufnum)
        return vim.api.nvim_buf_get_option(bufnum, "filetype") == "today"
    end

    local function needs_reload(bufnum)
        if vim.api.nvim_buf_get_option(0, "modified") then
            return false
        end

        local current_date = date(ui.get_current_time():getdate())
        local buffer_working_date = date(date(vim.b.today_working_date):getdate())

        return current_date ~= buffer_working_date
    end

    local today_buffers = util.filter(is_today_buffer, vim.api.nvim_list_bufs())
    local reload_buffers = util.filter(needs_reload, today_buffers)

    for _, buffer in pairs(reload_buffers) do
        print("today buffers refreshed due to date change")
        vim.api.nvim_buf_call(buffer, function()
            vim.cmd("e")
        end)
    end
end

function ui.start_refresh_loop()
    if ui.timer ~= nil then
        return
    end

    if not ui.options.automatic_refresh then
        return
    end

    ui.timer = vim.loop.new_timer()
    ui.timer:start(
        1000,
        5000,
        vim.schedule_wrap(function()
            ui.refresh_all_buffers()
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
