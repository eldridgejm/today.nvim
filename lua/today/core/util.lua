--- Utility functions.

local util = {}

--- Return a slice of an list.
-- @param lst The list to slice.
-- @param a The starting index of the slice.
-- @param b The end index. The resulting list will include this element.
function util.slice(lst, a, b)
    local result = {}
    local i = a
    while i < b do
        table.insert(result, lst[i])
        i = i + 1
    end
    return result
end

--- Map a function over a table, returning a table of results.
-- @param fn The function to apply.
-- @param iterable The table to apply it to.
-- @return A table of the results.
function util.map(fn, iterable)
    local result = {}
    for _, x in pairs(iterable) do
        table.insert(result, fn(x))
    end
    return result
end

--- Filter a table.
-- @param predicate The predicate to apply.
-- @param iterable The table to filter
function util.filter(predicate, iterable)
    local result = {}

    for _, x in pairs(iterable) do
        if predicate(x) then
            table.insert(result, x)
        end
    end

    return result
end

--- Remove whitespace from the left of a string.
-- @param s The string to strip.
function util.lstrip(s)
    return s:match("^%s*(.+)")
end

--- Remove whitespace from the right of a string.
-- @param s The string to strip.
function util.rstrip(s)
    return s:match("^(.+%S)%s*$")
end

--- Remove whitespace from the left and right of a string.
-- @param s The string to strip.
function util.strip(s)
    return util.lstrip(util.rstrip(s))
end

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
function util.mergesort(lst, cmp)
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

    util.mergesort(left, cmp)
    util.mergesort(right, cmp)

    merge(left, right, lst, cmp)
end

return util
