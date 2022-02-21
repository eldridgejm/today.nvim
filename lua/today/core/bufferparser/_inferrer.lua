local util = require("today.core.util")
local Task = require("today.core.task").Task
local dates = require("today.core.dates")
local DateObj = dates.DateObj


local M = {}


local function infer_do_date_from_header(task, header_info)
    if task.do_date == nil then
        task.do_date = header_info.do_date
    end
end


local function infer_tag_from_header(task, header_info)
    if util.index_of(task.tags, header_info.tag) ~= nil then
        -- the tag already appears, so exit
        return
    end
    table.insert(task.tags, 1, header_info.tag)
end

local function infer_done_from_header(task)
    task.done = true
end

--- Given the header info and the task, modify the task as appropriate
function M.infer_from_header(task, header_info)
    task = Task:new(task)

    if header_info.kind == "do_date" then
        infer_do_date_from_header(task, header_info)
    elseif header_info.kind == "tag" then
        infer_tag_from_header(task, header_info)
    elseif header_info.kind == "done" then
        infer_done_from_header(task)
    end

    return task
end


function M.infer_defaults(task, working_date)
    task = Task:new(task)
    working_date = DateObj:new(working_date)

    if task.done == nil then
        task.done = false
    end

    if task.priority == nil then
        task.priority = 0
    end

    if task.do_date == nil and task.recur_pattern == nil then
        task.do_date = working_date
    elseif task.do_date == nil and task.recur_pattern ~= nil then
        -- assign a "next in sequence" do date
        task.do_date = dates.next(working_date:add_days(-1), task.recur_pattern)
    end

    return task
end

return M
