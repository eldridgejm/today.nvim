--- Functions for managing the user interface.
--
-- A today.nvim buffer is simply a collection of tasks, with at most one task
-- per line (there can be lines that aren't tasks: these are either blank, or are
-- comments). Tasks have associated "do dates", describing when they will be done
-- (er... attempted).
--
-- The user interface works on an "I/O transform" paradigm.
-- When the buffer is read (including on the first read) the `ui.update` function
-- is invoked in "view" mode. This function transforms the buffer by organizing
-- tasks into categories, gathering malformed tasks, applying filters, and so
-- on. It also changes all dates to "natural language"; for example, "tomorrow",
-- or "next wednesday".
--
-- Upon writing a changed buffer, the `ui.update` function is called once again.
-- This time, the buffer is transformed in a way that makes it suitable for storing
-- on disk. Namely, natural dates are converted to static, absolute dates such
-- as "2021-08-13", and reorganized in a standard way.
--
-- The "view" and "write" updates are tied to autocommands. Before a write,
-- the "write" update is performed. After the write, the buffer is re-read and
-- the "view" update is performed.
--
-- A "view" update is performed whenever the buffer organization is significantly
-- changed -- not just when the file is read from disk. For example, the user
-- can change how the tasks are categorized by modifying an option and re-running
-- `ui.update`.
--
-- Dates expressed in relative language are ambiguous without a single point
-- of reference. For example, in order to know what "tomorrow" means, we have
-- to know what today's date is. In today.nvim, the buffer's "working
-- date" serves this purpose. Each buffer stores a buffer-local variable,
-- `b:today_working_date`. This is a YYYY-MM-DD string capturing the
-- buffer's notion of "today". The working date is updated whenever the
-- "view" update is performed.
--
-- Of course, the working date may become out-of-sync. For instance, if neovim
-- is left open overnight without updating, dates will become stale. today.nvim
-- addresses this with a "refresh loop" that checks for stale buffers with
-- out-of-sync working dates and performs a view update on them. The refresh
-- only occurs if the buffer is not modified, as then it is safe to change it.
--
-- The refresh system can be tested by setting the vim-global variable
-- today_time_delta` to be a number of seconds that is used as an offset to the
-- actual system time. A convencience function, `ui.set_current_time`, is provided
-- which allows one to set the wall time to an arbitrary date/time. This is useful
-- to simulate the passing of midnight, for example.
--
local task = require("today.core.task")
local update = require("today.core.update")
local categorizers = require("today.core.categorizers")
local filterers = require("today.core.filterers")
local informers = require("today.core.informers")
local util = require("today.util")
local DateObj = require("today.core.dates.dateobj")
local date = require("today.vendor.date")
local infer = require("today.core.infer")
local linkslib = require("today.core.links")

local ui = {}

-- options ---------------------------------------------------------------------

--- Options.
-- @section

--- Retrieve the buffer-local option table.
function ui.get_buffer_options()
    if vim.b.today == nil then
        vim.b.today = vim.deepcopy(ui.options.buffer_defaults)
    else
        vim.b.today = vim.tbl_deep_extend(
            "keep",
            vim.b.today,
            ui.options.buffer_defaults
        )
    end

    return vim.b.today
end

ui.options = {
    -- the time at which the today buffer will be automatically refreshed
    automatic_refresh = true,
    detect_categorizer = true,
    buffer_defaults = {
        view = {
            categorizer = {
                active = "daily_agenda",
                options = {
                    daily_agenda = {
                        days = 8,
                        show_empty_days = true,
                        move_to_done_immediately = false,
                        date_format = "monthday",
                        second_date_format = "natural",
                        show_remaining_tasks_count = false,
                    },
                    first_tag = {
                        show_remaining_tasks_count = true,
                    },
                },
            },
            filter_tags = nil,
            default_date_format = "datestamp",
        },
        write = {
            categorizer = {
                active = "daily_agenda",
                options = {
                    daily_agenda = {
                        days = 14,
                        show_empty_days = false,
                        date_format = "ymd",
                    },
                    first_tag = {
                        show_remaining_tasks_count = false,
                    },
                },
            },
            filter_tags = nil,
            default_date_format = "ymd",
        },
    },
}

-- taskwise functions ----------------------------------------------------------

--- Task functions.
-- These functions accept a starting line number and an ending line number and
-- modify the corresponding lines of the buffer.
-- @section task

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

--- Helper function that adds the buffer's working date as an argument
-- to a taskwise function.
local function with_working_date(func)
    return function(line)
        return func(line, vim.b.today_working_date)
    end
end

local function replace_datespec_with_next(line)
    return task.replace_datespec_with_next(line, vim.b.today_working_date, {
        natural = true,
        default_format = ui.get_buffer_options().view.default_date_format,
    })
end

--- Mark tasks as done.
ui.task_mark_done = make_ranged_function(
    with_working_date(task.mark_done_with_do_date),
    with_working_date(replace_datespec_with_next)
)

--- Toggle the checkbox.
local _toggle_done = make_ranged_function(
    with_working_date(task.toggle_done_with_do_date),
    with_working_date(replace_datespec_with_next)
)

ui.task_toggle_done = function(line1, line2, update)
    _toggle_done(line1, line2)
    if update ~= 0 then
        ui.update("view")
    end
end

--- Mark task as undone.
ui.task_mark_undone = make_ranged_function(task.mark_undone)

--- Remove the datespec.
ui.task_remove_datespec = make_ranged_function(task.remove_datespec)

--- Set the first tag. Accepts one argument: the tag to add.
ui.task_set_first_tag = make_ranged_function(task.set_first_tag)

--- Remove the first tag.
ui.task_remove_first_tag = make_ranged_function(task.remove_first_tag)

--- Set the priority.
ui.task_set_priority = make_ranged_function(task.set_priority)

--- Set the do date.
ui.task_set_do_date = make_ranged_function(task.set_do_date)

--- Change the datespec to yyyy-mm-dd format.
ui.task_make_datespec_ymd = make_ranged_function(
    with_working_date(task.make_datespec_ymd)
)

--- Change the datespec to natural language.
ui.task_make_datespec_natural = make_ranged_function(function(line)
    return task.make_datespec_natural(line, vim.b.today_working_date, {
        default_format = ui.get_buffer_options().view.default_date_format,
        days_until_absolute = ui.get_buffer_options().view.categorizer.options.daily_agenda.days
            - 1,
    })
end)

--- Simulates "unrolling" the recur sequence. It removes the recur pattern from
-- the task, but creates a new task with the same recur seqeuence and a do-date
-- which is the next date in the sequence.
ui.expand_recur = function(n)
    local row = vim.fn.line(".")
    local t = vim.api.nvim_buf_get_lines(0, row - 1, row, 0)[1]
    if not task.is_task(t) then
        return
    end

    local new_lines = {}
    for _ = 1, n do
        local remainder = task.replace_datespec_with_next(t, vim.b.today_working_date)
        table.insert(new_lines, task.remove_recur_pattern(t))
        t = remainder
    end
    table.insert(new_lines, t)

    print(#new_lines)
    vim.api.nvim_buf_set_lines(0, row - 1, row, 0, new_lines)
end

--- Apply a recur pattern to a range of lines.
function ui.paint_recur(recur_pattern, start_row, end_row)
    local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, 0)
    local new_lines = task.paint_recur_pattern(
        lines,
        recur_pattern,
        vim.b.today_working_date
    )
    vim.api.nvim_buf_set_lines(0, start_row - 1, end_row, 0, new_lines)
end

--- Utilities.
-- @section

--- Places the cursor at the beginning of the line containing the next section.
-- This is useful for placing the cursor on the first section when opning the
-- file for the first time.
function ui.move_to_next_section(first_task)
    vim.fn.search("{{{")
    if first_task then
        vim.fn.search("^[")
    end
end

function ui.follow_link()
    local followfunc = ui.get_buffer_options().follow
    if followfunc == nil then
        return
    end

    local cursor = vim.api.nvim_win_get_cursor(0)
    local line = vim.fn.getline(".")
    local link = linkslib.extract_link(line, cursor[2] + 1)

    vim.fn[followfunc](link)
end

-- buffer updating -------------------------------------------------------------

--- Updating.
-- @section

local function save_cursor()
    vim.b.today_cursor = vim.api.nvim_win_get_cursor(0)
end

local function restore_cursor(n_lines)
    if vim.b.today_cursor ~= nil then
        if vim.b.today_cursor[1] >= n_lines then
            vim.b.today_cursor = { n_lines, vim.b.today_cursor[2] }
        end
        vim.api.nvim_win_set_cursor(0, vim.b.today_cursor) -- restore the cursor position
    end
end

--- Update the buffer by applying categorizer, filterer, etc.
-- This constructs components and calls `update.update`. The options for these
-- components are taken from the buffer-local variable, `b:today`, via
-- `ui.get_buffer_options()`.
--
-- This function operates in one of two modes: "view" or "write". In "view" mode,
-- the buffer is updated in preparation of viewing by a human. In this mode, the
-- active "view" categorizer, filterer, etc. are used. These can be
-- configured in `ui.options.buffer_defaults.view`. In "write" mode, the buffer is updated
-- in preparation for writing to a disk. The active "write" categorizer is used,
-- etc. This can be configured in `ui.options.buffer_defaults.write`.
--
-- @param mode (string) The mode to operate in. Either "view" or "write". Defaults
-- to "view".
function ui.update(mode)
    if mode == nil then
        mode = "view"
    end

    -- if vim.b.today is nil, this is our first update. stop, and
    -- detect the categorizer. detect_categorizer will change the active buffer
    -- in the buffer options, so it is important that this is done before getting
    -- the options below
    if vim.b.today == nil and ui.options.detect_categorizer then
        ui.detect_categorizer()
    end

    local opts = ui.get_buffer_options()[mode]
    assert(opts ~= nil)

    save_cursor()
    if mode == "write" then
        ui.task_make_datespec_ymd(1, -1)
    elseif mode == "view" then
        vim.b.today_working_date = tostring(ui.get_current_date())
    end

    -- save this; we'll restore it in a moment
    local was_modified = vim.api.nvim_buf_get_option(0, "modified")

    -- note: vim.b.working_date will not be set if this is called before ui.update_post_read,
    -- as is the case when called from an ftplugin
    local working_date = vim.b.today_working_date

    -- set up the categorizer
    local categorizer_key = opts.categorizer.active
    local categorizer_options = opts.categorizer.options[categorizer_key]
    categorizer_options["working_date"] = working_date
    local categorizer = categorizers[categorizer_key .. "_categorizer"](
        categorizer_options
    )

    -- set up the filterer
    local filterer
    local filter_tags = opts.filter_tags
    if (filter_tags ~= nil) and (#filter_tags > 0) then
        filterer = filterers.tag_filterer({ tags = filter_tags })
    end

    -- set up the informer
    local informer = informers.basic_informer({
        working_date = working_date,
        categorizer = categorizer_key,
        filter_tags = filter_tags,
    })

    local is_broken = function(t)
        return task.datespec_is_broken(t, working_date)
    end

    local inferrer = function(lines)
        return infer.infer(lines, { working_date = working_date })
    end

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, 0)

    lines = update.update(lines, {
        categorizer = categorizer,
        filterer = filterer,
        informer = informer,
        inferrer = inferrer,
        is_broken = is_broken,
    })

    vim.api.nvim_buf_set_lines(0, 0, -1, 0, lines)
    vim.api.nvim_buf_set_option(0, "modified", was_modified)

    if mode == "view" then
        ui.task_make_datespec_natural(1, -1)
    end
    restore_cursor(#lines)
end

--- Update the buffer to use the first tag categorizer. This will set the active
-- view categorizer and the active write categorizer to "first_tag".
function ui.categorize_by_first_tag()
    local opts = ui.get_buffer_options()
    opts.view.categorizer.active = "first_tag"
    opts.write.categorizer.active = "first_tag"
    vim.b.today = opts
    ui.update()
end

--- Update the buffer to use the daily agenda categorizer. This will set the active
-- view categorizer and the active write categorizer to "daily_agenda".
function ui.categorize_by_daily_agenda()
    local opts = ui.get_buffer_options()
    opts.view.categorizer.active = "daily_agenda"
    opts.write.categorizer.active = "daily_agenda"
    vim.b.today = opts
    ui.update()
end

--- Update the buffer to filter by tags. Accepts a list of tags, each with a
-- `#` prepended. This will only affect the view tags; write tags are left
-- empty.
function ui.set_filter_tags(tags)
    local opts = ui.get_buffer_options()
    opts.view.filter_tags = tags
    vim.b.today = opts
    ui.update()
end

--- Detect the categorization from the buffer. This is useful on first reading
-- the file.
function ui.detect_categorizer()
    local opts = ui.get_buffer_options()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, 0)
    local guess = infer.detect_categorizer(lines)
    if guess ~= nil then
        opts.view.categorizer.active = guess
        opts.write.categorizer.active = guess
        vim.b.today = opts
    end
end

--- Refreshing.
-- @section

local function is_today_buffer(bufnum)
    return vim.api.nvim_buf_get_option(bufnum, "filetype") == "today"
end

--- For every today buffer, if the buffer is not modified, re-read its contents.
-- This triggers a call to `ui.update` via the autocmds.
function ui.refresh_all_buffers()
    local function needs_reload(bufnum)
        if vim.api.nvim_buf_get_option(bufnum, "modified") then
            return false
        end

        local actual_date = ui.get_current_date()
        local buffer_working_date = vim.api.nvim_buf_get_var(
            bufnum,
            "today_working_date"
        )
        buffer_working_date = DateObj:new(buffer_working_date)

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

--- Start the refresh timer loop.
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

--- Stop the refresh timer loop.
function ui.stop_refresh_loop()
    if ui.timer ~= nil then
        ui.timer:close()
        ui.timer = nil
    end
end

--- Stops the refresh timer loop if there are no more today buffers open.
function ui.stop_refresh_loop_if_no_buffers()
    local today_buffers = util.filter(is_today_buffer, vim.api.nvim_list_bufs())
    if #today_buffers == 1 then
        ui.stop_refresh_loop()
    end
end

--- Time. These functions allow for getting and setting the current *wall* time.
-- Each buffer keeps a variable, `today_working_date`, that is a YYYY-MM-DD string
-- representing the current date for the purpose of editing the buffer. When
-- this date is out-of-sync with the wall time (`get_current_date`), the buffer
-- needs to be refreshed.
-- @section

--- Get the current time in seconds since the epoch.
function ui.get_current_time()
    local delta = vim.g.today_time_delta
    if delta == nil then
        delta = 0
    end

    local epoch = date(1970, 1, 1)
    return (date():addseconds(delta) - epoch):spanseconds()
end

--- Get the current date as a DateObj.
function ui.get_current_date()
    local d = date(1970, 1, 1):addseconds(ui.get_current_time())
    return DateObj:new(tostring(d))
end

--- Set the current time. Accepts either the time since the epoch in seconds,
-- or a YYYY-MM-DD HH:MM:SS string.
function ui.set_current_time(s)
    local d
    if type(s) == "number" then
        d = date(1970, 1, 1):addseconds(s)
    elseif type(s) == "string" then
        d = date(s)
    end

    vim.g.today_time_delta = (d - date()):spanseconds()
end

return ui
