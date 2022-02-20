--- Represents a task.

local dates = require("today.core.dates")
local util = require("today.core.util")

local M = {}

--- Sentinel used to represent a malformed datespec.
M.MALFORMED = { "MALFORMED DATESPEC" }

M.Task = {}

--- Create a new `Task` object.
--
-- @param tbl_or_task An existing task to be copied, or a table with the following entries:
--
--  - `done`: True/false, whether the task is completed
--  - `tags`: A table of tags without prepended #s.
--  - `priority`: A number between 0 and 2 representing task urgency.
--  - `description`: A (possibly-multiline) string description.
--  - `do_date`: A `core.dates.DateObj` representing the "do date".
--  - `recur_pattern`: A string (or nil) for the recur pattern.
--
-- @return A `Task` object.
function M.Task:new(tbl_or_task)
    local new_task = {
        done = tbl_or_task.done,
        tags = {},
        priority = tbl_or_task.priority,
        description = tbl_or_task.description,
        do_date = tbl_or_task.do_date,
        recur_pattern = tbl_or_task.recur_pattern,
    }

    util.put_into(new_task.tags, tbl_or_task.tags)

    self.__index = self
    return setmetatable(new_task, self)
end

--- Is the task recurring?
-- return True/false.
function M.Task:is_recurring()
    return self.recur_pattern ~= nil
end

--- Create the next task in the sequence.
-- @return The next task.
function M.Task:next()
    if not self:is_recurring() then
        return nil
    end

    local next_task = M.Task:new(self)
    next_task.do_date = dates.next(next_task.do_date, next_task.recur_pattern)
    return next_task
end

return M
