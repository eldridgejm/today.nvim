task = require('today.core.task')
update = require('today.core.update')


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


function ui.update_pre_write()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, 0)
    vim.api.nvim_buf_set_lines(0, 0, -1, 0, update.pre_write(lines))
end


function ui.update_post_read()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, 0)
    vim.api.nvim_buf_set_lines(0, 0, -1, 0, update.post_read(lines))
end


return ui
