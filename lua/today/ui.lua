local task = require("today.core.task")
local organize = require("today.core.organize")
local util = require("today.util")
local date = require("today.vendor.date")

local ui = {}

ui.options = {
    -- the time at which the today buffer will be automatically refreshed
    automatic_refresh = true,
    buffer = {
        categorizer = {
            active = "daily_agenda",
            options = {
                show_empty_categories = true,
                move_to_done_immediately = false,
                date_format = "natural",
                second_date_format = "monthday"
            },
        },
        filter_tags = nil,
        default_date_format = "human",
    },
}

--- Takes in a function `func` and makes a function which applies `func` to a
-- range of lines.
local function make_ranged_function(...)
    local funcs = { ... }

    return function(start_row, end_row, ...)
        local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, 0)
        local replacement_lines = {}

        for _, line in pairs(lines) do
            if not task.is_task(line) then
                table.insert(replacement_lines, line)
            else
                for _, func in pairs(funcs) do
                    local transformed_line = func(line, ...)
                    if transformed_line ~= nil then
                        transformed_line = task.normalize(transformed_line)
                        table.insert(replacement_lines, transformed_line)
                    end
                end
            end
        end

        vim.api.nvim_buf_set_lines(0, start_row - 1, end_row, 0, replacement_lines)
    end
end

local function with_working_date(func)
    return function(line)
        return func(line, vim.b.today_working_date)
    end
end

local function replace_datespec_with_next(line)
    return task.replace_datespec_with_next(line, vim.b.today_working_date, {
        natural = true,
        default_format = ui.get_buffer_options().default_date_format,
    })
end

ui.task_mark_done = make_ranged_function(
    with_working_date(task.mark_done_with_do_date),
    replace_datespec_with_next
)

ui.task_toggle_done = make_ranged_function(
    with_working_date(task.toggle_done_with_do_date),
    with_working_date(replace_datespec_with_next)
)
ui.task_mark_undone = make_ranged_function(task.mark_undone)
ui.task_remove_datespec = make_ranged_function(task.remove_datespec)
ui.task_set_first_tag = make_ranged_function(task.set_first_tag)
ui.task_remove_first_tag = make_ranged_function(task.remove_first_tag)
ui.task_reschedule = make_ranged_function(task.set_do_date)
ui.task_set_priority = make_ranged_function(task.set_priority)
ui.task_set_do_date = make_ranged_function(task.set_do_date)

ui.task_make_datespec_ymd = make_ranged_function(
    with_working_date(task.make_datespec_ymd)
)

ui.task_make_datespec_natural = make_ranged_function(function(line)
    return task.make_datespec_natural(line, vim.b.today_working_date, {
        natural = true,
        default_format = ui.get_buffer_options().default_date_format,
    })
end)

ui.task_expand_recur = make_ranged_function(
    task.remove_recur_pattern,
    with_working_date(replace_datespec_with_next)
)

function ui.paint_recur_pattern(recur_pattern, start_row, end_row)
    local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, 0)
    local new_lines = task.paint_recur_pattern(
        lines,
        recur_pattern,
        vim.b.today_working_date
    )
    vim.api.nvim_buf_set_lines(0, start_row - 1, end_row, 0, new_lines)
end

function ui.remove_comments(start_row, end_row)
    local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, 0)

    local function keep(line)
        return task.is_task(line) or util.startswith(line, "--:")
    end
    lines = util.filter(keep, lines)
    vim.api.nvim_buf_set_lines(0, start_row - 1, end_row, 0, lines)
end

function ui.get_buffer_options()
    if vim.b.today == nil then
        vim.b.today = vim.deepcopy(ui.options.buffer)
    else
        vim.b.today = vim.tbl_deep_extend("keep", vim.b.today, ui.options.buffer)
    end

    return vim.b.today
end

function ui.organize()
    local was_modified = vim.api.nvim_buf_get_option(0, "modified")
    -- note: the working date will not be set if this is called before ui.update_post_read,
    -- as is the case when called from an ftplugin
    local working_date = vim.b.today_working_date

    -- set up the categorizer
    local categorizer
    local categorizer_key = ui.get_buffer_options().categorizer.active
    if (categorizer_key == nil) or (categorizer_key == "daily_agenda") then
        categorizer = organize.daily_agenda_categorizer(
            working_date,
            ui.get_buffer_options().categorizer.options
        )
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
    local informer = organize.basic_informer({
        working_date = working_date,
        categorizer = categorizer_key,
        filter_tags = filter_tags,
    })

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, 0)

    lines = organize.organize(lines, {
        categorizer = categorizer, filterer = filterer, informer = informer
    })
    vim.api.nvim_buf_set_lines(0, 0, -1, 0, lines)
    vim.api.nvim_buf_set_option(0, "modified", was_modified)

    return #lines
end

function ui.categorize_by_first_tag()
    local opts = ui.get_buffer_options()
    opts.categorizer.active = "first_tag"
    vim.b.today = opts
    ui.organize()
end

function ui.categorize_by_daily_agenda()
    -- will be the empty string if no argument is provided
    local opts = ui.get_buffer_options()
    opts.categorizer.active = "daily_agenda"
    vim.b.today = opts
    ui.organize()
end

function ui.set_filter_tags(tags)
    local opts = ui.get_buffer_options()
    opts.filter_tags = tags
    vim.b.today = opts
    ui.organize()
end

function ui.update_pre_write()
    vim.b.today_cursor = vim.api.nvim_win_get_cursor(0)
    ui.organize()
    ui.task_make_datespec_ymd(1, -1)
    ui.remove_comments(1, -1)
end

function ui.update_post_read()
    vim.b.today_working_date = ui.get_current_time():fmt("%Y-%m-%d")
    local n_lines = ui.organize()
    ui.task_make_datespec_natural(1, -1)

    if vim.b.today_cursor ~= nil then
        if vim.b.today_cursor[1] >= n_lines then
            vim.b.today_cursor = { n_lines, vim.b.today_cursor[2] }
        end
        vim.api.nvim_win_set_cursor(0, vim.b.today_cursor) -- restore the cursor position
    end
end

function ui.follow()
    local cword = vim.fn.expand("<cWORD>")
    if util.startswith(cword, "#") then
        ui.set_filter_tags({ cword })
    end
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
