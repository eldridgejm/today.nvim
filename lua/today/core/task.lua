--- Represents a task.

local dates = require("today.core.dates")
local util = require("today.core.util")

local M = {}

--- Sentinel used to represent a malformed datespec.
M.MALFORMED = { "MALFORMED DATESPEC" }

M.Task = {}

function M.Task:new(tbl)
    local obj = {
        done = tbl.done,
        tags = tbl.tags,
        priority = tbl.priority,
        description = tbl.description,
        do_date = tbl.do_date,
        recur_pattern = tbl.recur_pattern,
    }

    self.__index = self
    return setmetatable(obj, self)
end

function M.Task:copy()
    local new_task = M.Task:new({
        done = self.done,
        tags = {},
        priority = self.priority,
        description = self.description,
        do_date = dates.DateObj:new(self.do_date),
        recur_pattern = self.recur_pattern,
    })

    util.put_into(new_task.tags, self.tags)

    return new_task
end

function M.Task:is_recurring()
    return self.recur_pattern ~= nil
end

--- Create the next task in the sequence.
function M.Task:next()
    if not self:is_recurring() then
        return nil
    end

    local next_task = self:copy()
    next_task.do_date = dates.next(next_task.do_date, next_task.recur_pattern)
    return next_task
end

return M
