task = require('today.core.task')
update = require('today.core.update')


ui = {}


function apply_to_line(func, ...)
    local line = vim.api.nvim_get_current_line()
    local transformed_line = func(line, ...)
    vim.api.nvim_set_current_line(transformed_line)
end


function apply_to_selection(func, ...)
    local _, start_row, _, _ = unpack(vim.fn.getpos("'<"))
    local _, end_row, _ = unpack(vim.fn.getpos("'>"))
    local lines = vim.api.nvim_buf_get_lines(0, start_row-1, end_row, 0)

    local transformed_lines = {}
    for _, line in pairs(lines) do
        local result = func(line, ...)
        table.insert(transformed_lines, result)
    end

    vim.api.nvim_buf_set_lines(0, start_row-1, end_row, 0, transformed_lines)
end


function ui.toggle_done()
    apply_to_line(task.toggle_checkbox)
end


function ui.block_toggle_done()
    apply_to_selection(task.toggle_checkbox)
end


function ui.set_priority(new_priority)
    apply_to_line(task.set_priority, new_priority)
end


function ui.block_set_priority(new_priority)
    apply_to_selection(task.set_priority, new_priority)
end


function ui.update()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, 0)
    vim.api.nvim_buf_set_lines(0, 0, -1, 0, update(lines))
end


return ui
