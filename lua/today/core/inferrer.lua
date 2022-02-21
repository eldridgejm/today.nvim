local M = {}

--- Given the header info and the task, modify the task as appropriate
function M.infer(header_info, task)
    task.do_date = header_info.do_date
    return task
end

return M
