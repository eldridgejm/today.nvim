--- Functions for sorting groups of tasks.

local util = require("today.util")
local task = require("today.core.task")

local sort = {}

--- Sorting Functions.
-- @section

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
-- the result.
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

--- Comparators.
-- @section

--- Chain comparators to make a single comparator function.
-- Comparators are called in sequence. If the first comparator returns nil (for instance,
-- if there is a tie), the second comparator in called, and so forth. If the last
-- comparator returns nil, then true is returned. This ensures stability.
-- @param chain A list of comparator functions to chain.
-- @return A new comparator function formed by chaining the input comparators.
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

--- Make a comparator that compares tasks according to their do dates, with earlier
-- dates first.
-- @param working_date The working date as a YYYY-MM-DD string or dateObject.
-- @return The comparator function.
function sort.make_do_date_comparator(working_date)
    assert(working_date ~= nil)

    local function comparator(task_x, task_y)
        local x_ds = task.parse_datespec_safe(task_x, working_date)
        local y_ds = task.parse_datespec_safe(task_y, working_date)

        assert(x_ds ~= nil, "nil datespec: " .. task_x)
        assert(y_ds ~= nil, "nil datespec: " .. task_y)

        if x_ds.do_date == y_ds.do_date then
            return nil
        end
        return x_ds.do_date < y_ds.do_date
    end

    return comparator
end

--- Compare tasks according to whether or not they are completed, with completed first.
-- @param task_x The first task.
-- @param task_y The second task.
-- @return The comparator function.
function sort.completed_comparator(task_x, task_y)
    if task.is_done(task_x) == task.is_done(task_y) then
        return nil
    end
    return not task.is_done(task_x)
end

--- Compare tasks according to priority, with higher priorities first.
-- @param task_x The first task.
-- @param task_y The second task.
-- @return The comparator function.
function sort.priority_comparator(task_x, task_y)
    local x_pr = task.get_priority(task_x)
    local y_pr = task.get_priority(task_y)
    if x_pr == y_pr then
        return nil
    end
    return x_pr > y_pr
end



function sort.make_order_comparator(order, on_missing)
    --- Make a comparator that looks for the objects in the "order" list
    -- and returns based on their index. If it is not nil, the "transformer"
    -- is first used to transform the objects before looking into the
    -- "order" list.
    local function get_index_of(obj)
        local ix = util.index_of(order, obj)
        if ix == nil then
            if on_missing ~= nil then
                return on_missing(obj)
            else
                return math.huge
            end
        else
            return ix
        end
    end

    return function(x, y)
        local ix_x = get_index_of(x)
        local ix_y = get_index_of(y)
        return ix_x < ix_y
    end
end

return sort
