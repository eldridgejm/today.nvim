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

function util.groupby(keyfn, lst)
    local groups = {}
    for _, x in pairs(lst) do
        local key = keyfn(x)

        if groups[key] == nil then
            groups[key] = {}
        end

        table.insert(groups[key], x)
    end
    return groups
end

function util.keys(tbl)
    local keys = {}
    for key, _ in pairs(tbl) do
        table.insert(keys, key)
    end
    return keys
end

function util.contains_value(tbl, x)
    for _, y in pairs(tbl) do
        if y == x then
            return true
        end
    end
    return false
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

function util.startswith(s, prefix)
    return s:sub(0, #prefix) == prefix
end

function util.reverse(tbl)
    local result = {}
    for i = #tbl, 1, -1 do
        table.insert(result, tbl[i])
    end
    return result
end

function util.put_into(dst_tbl, src_tbl)
    for _, x in pairs(src_tbl) do
        table.insert(dst_tbl, x)
    end
end

return util
