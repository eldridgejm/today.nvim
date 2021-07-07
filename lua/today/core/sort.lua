--- Functions for sorting groups of tasks.

local util = require("today.core.util")
local task = require("today.core.task")

local sort = {}

--- Stable sort in decreasing order of priority. Operates in-place.
-- @param tasks The tasks to sort.
function sort.by_priority(tasks)
    function comparator(x, y)
        return task.get_priority(x) >= task.get_priority(y)
    end

    util.mergesort(tasks, comparator)
end

--- Stable sort in decreasing order of priority and date.
-- If two tasks have the same priority, their do-date is used as a tiebreaker.
-- Operates in-place.
-- @param tasks The tasks to sort.
function sort.by_priority_then_date(tasks)
    -- stable sort by priority first, then date
    function comparator(x, y)
        local x_ds = task.get_datespec_safe(x)
        local y_ds = task.get_datespec_safe(y)

        local x_pr = task.get_priority(x)
        local y_pr = task.get_priority(y)

        if x_pr > y_pr then
            return true
        elseif x_pr == y_pr then
            return x_ds.do_date <= y_ds.do_date
        else
            return false
        end
    end

    util.mergesort(tasks, comparator)
end

return sort
