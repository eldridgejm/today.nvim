--- Functions for sorting groups of tasks.

local util = require("today.core.util")
local task = require("today.core.task")

local sort = {}

-- Private helper function for mergesort.
local function merge(left, right, lst, cmp)
    local left_ix = 1
    local right_ix = 1

    for i = 1, #lst do
        if cmp(left[left_ix], right[right_ix]) then
            lst[i] = left[left_ix]
            left_ix = left_ix + 1
        else
            lst[i] = right[right_ix]
            right_ix = right_ix + 1
        end

        if left_ix > #left then
            i = i + 1
            while i <= #lst do
                lst[i] = right[right_ix]
                i = i + 1
                right_ix = right_ix + 1
            end
            break
        end

        if right_ix > #right then
            i = i + 1
            while i <= #lst do
                lst[i] = left[left_ix]
                i = i + 1
                left_ix = left_ix + 1
            end
            break
        end
    end
end

--- Sort a list in place with mergesort. This is a stable sort.
-- This accepts a comparator. The comparator should be a function of two
-- arguments, `cmp(x,y)`, returning true if x should come before y in
-- the result..
-- @param lst The table to sort.
-- @param cmp The comparator.
function sort.mergesort(lst, cmp)
    if cmp == nil then
        cmp = function(x, y)
            return x < y
        end
    end

    if #lst <= 1 then
        return
    end

    local middle = math.floor(#lst / 2)
    local left = util.slice(lst, 1, middle + 1)
    local right = util.slice(lst, middle + 1, #lst + 1)

    sort.mergesort(left, cmp)
    sort.mergesort(right, cmp)

    merge(left, right, lst, cmp)
end

function sort.chain_comparators(chain)
    return function(x, y)
        for _, comparator in pairs(chain) do
            local r = comparator(x, y)
            if r == nil then
                goto continue
            else
                return r
            end
            ::continue::
        end
        return true -- for stability
    end
end

function sort.datespec_comparator(working_date)
    assert(working_date ~= nil)

    local function comparator(task_x, task_y)
        local x_ds = task.get_datespec_safe(task_x, working_date).do_date
        local y_ds = task.get_datespec_safe(task_y, working_date).do_date
        if x_ds == y_ds then
            return nil
        end
        return x_ds < y_ds
    end

    return comparator
end

function sort.completed_comparator(task_x, task_y)
    if task.is_done(task_x) == task.is_done(task_y) then
        return nil
    end
    return not task.is_done(task_x)
end

function sort.priority_comparator(task_x, task_y)
    local x_pr = task.get_priority(task_x)
    local y_pr = task.get_priority(task_y)
    if x_pr == y_pr then
        return nil
    end
    return x_pr > y_pr
end

return sort
