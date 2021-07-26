local task = require("today.core.task")
local organize = require("today.core.organize")
local util = require("today.core.util")

local date = require("today.vendor.date")

local ui = {}

ui.options = {
    -- the time at which the today buffer will be automatically refreshed
    automatic_refresh = true,
    buffer = {
        categorizer = {
            active = "do_date",
        },
        filter_tags = nil,
    },
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
                result = task.normalize(func(line, ...))
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
ui.task_set_do_date = make_ranged_function(task.set_do_date)

ui.task_make_datespec_absolute = make_ranged_function(function(line)
    return task.make_datespec_absolute(line, date(vim.b.today_working_date))
end)

ui.task_make_datespec_natural = make_ranged_function(function(line)
    return task.make_datespec_natural(line, date(vim.b.today_working_date))
end)

function ui.get_buffer_options()
    if vim.b.today == nil then
        vim.b.today = vim.deepcopy(ui.options.buffer)
    end

    return vim.b.today
end

function ui.organize()
    local was_modified = vim.api.nvim_buf_get_option(0, "modified")

    local working_date = date(vim.b.today_working_date)

    -- set up the categorizer
    local categorizer
    local categorizer_key = ui.get_buffer_options().categorizer.active
    if (categorizer_key == nil) or (categorizer_key == "do_date") then
        categorizer = organize.do_date_categorizer(working_date)
    elseif categorizer_key == "first_tag" then
        categorizer = organize.first_tag_categorizer(working_date)
    else
        error("Categorizer " .. categorizer_key .. " not known.")
    end

    -- set up the filterer
    local filterer
    local filter_tags = ui.get_buffer_options().filter_tags
    if (filter_tags ~= nil) and (#filter_tags > 0) then
        filterer = organize.tag_filterer(vim.b.today.filter_tags)
    end

    -- set up the informer
    local informer = organize.informer({
        working_date = working_date,
        categorizer = categorizer_key,
        filter_tags = filter_tags,
    })

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, 0)
    lines = organize.organize(lines, categorizer, filterer, informer)
    vim.api.nvim_buf_set_lines(0, 0, -1, 0, lines)
    vim.api.nvim_buf_set_option(0, "modified", was_modified)
end

function ui.organize_by_first_tag()
    local opts = vim.b.today
    opts.categorizer.active = "first_tag"
    vim.b.today = opts
    ui.organize()
end

function ui.organize_by_do_date()
    local opts = vim.b.today
    opts.categorizer.active = "do_date"
    vim.b.today = opts
    ui.organize()
end

function ui.set_filter_tags(tags)
    local opts = vim.b.today
    opts.filter_tags = tags
    vim.b.today = opts
    ui.organize()
end

function ui.update_pre_write()
    ui.organize()
    ui.task_make_datespec_absolute(1, -1)
end

function ui.update_post_read()
    vim.b.today_working_date = ui.get_current_time():fmt("%Y-%m-%d")
    ui.organize()
    ui.task_make_datespec_natural(1, -1)
end

local function is_today_buffer(bufnum)
    return vim.api.nvim_buf_get_option(bufnum, "filetype") == "today"
end

--- for every buffer with filetype=today, if the buffer is not modified,
-- re-read its contents
function ui.refresh_all_buffers()
    local function needs_reload(bufnum)
        if vim.api.nvim_buf_get_option(bufnum, "modified") then
            return false
        end

        local actual_date = date(ui.get_current_time():getdate())
        local buffer_working_date = date(date(vim.b.today_working_date):getdate())

        return actual_date ~= buffer_working_date
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

function ui.stop_refresh_loop()
    if ui.timer ~= nil then
        ui.timer:close()
        ui.timer = nil
    end
end

function ui.on_buffer_delete()
    local today_buffers = util.filter(is_today_buffer, vim.api.nvim_list_bufs())
    if #today_buffers == 1 then
        ui.stop_refresh_loop()
    end
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
