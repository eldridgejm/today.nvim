task = require('today.core.task')
update = require('today.core.update')


ui = {}


function apply_to_line(func, ...)
    local line = vim.api.nvim_get_current_line()
    if not task.is_task(line) then
        return
    end
    local transformed_line = func(line, ...)
    vim.api.nvim_set_current_line(transformed_line)
end


function apply_to_selection(func, ...)
    local _, start_row, _, _ = unpack(vim.fn.getpos("'<"))
    local _, end_row, _ = unpack(vim.fn.getpos("'>"))
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


function taskwise_ui_function(func)
    local func_line = function (...) return apply_to_line(func, ...) end
    local func_block = function (...) return apply_to_selection(func, ...) end
    return func_line, func_block
end


ui.toggle_done, ui.block_toggle_done =
    taskwise_ui_function(task.toggle_checkbox)

ui.set_priority, ui.block_set_priority =
    taskwise_ui_function(task.set_priority)

ui.make_datespec_absolute, ui.block_make_datespec_absolute =
    taskwise_ui_function(task.make_datespec_absolute)

ui.make_datespec_natural, ui.block_make_datespec_natural =
    taskwise_ui_function(task.make_datespec_natural)

ui.set_do_date, ui.block_set_do_date =
    taskwise_ui_function(task.set_do_date)


function ui.update_pre_write()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, 0)
    vim.api.nvim_buf_set_lines(0, 0, -1, 0, update.pre_write(lines))
end


function ui.update_post_read()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, 0)
    vim.api.nvim_buf_set_lines(0, 0, -1, 0, update.post_read(lines))
end


return ui
