--- Utility functions.

local util = {}

--- Functional Programming.
-- @section

--- Negate a predicate.
-- @param predicate The predicate function to be negated.
-- @return The predicate function wrapped so that its output is negated.
function util.negate(predicate)
    return function(...)
        return not predicate(...)
    end
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

--- Group elements of a list according to key.
-- This is guaranteed to be stable, in the sense that if x and y are two elements with
-- the same key (and thus in the same group), if x comes before y in the input list,
-- the x comes before y in the list representing their group.
-- @param keyfn A function that accepts an element of the list and returns its key.
-- @param lst The list whose elements will be grouped.
-- @return A table, keyed by group keys, whose values are lists containing the elements
-- of each group.
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

--- Tables.
-- @section

--- Return the keys of a table.
-- @param tbl The table whose keys will be returned.
-- @return A list of the keys.
function util.keys(tbl)
    local keys = {}
    for key, _ in pairs(tbl) do
        table.insert(keys, key)
    end
    return keys
end

--- Check whether the table contains the given key.
-- @param tbl The table whose keys will be checked.
-- @param key The key to look for.
-- @return true or false, whether the table contains the key.
function util.contains_key(tbl, key)
    for y, _ in pairs(tbl) do
        if y == key then
            return true
        end
    end
    return false
end

--- Check whether the table contains the given value.
-- @param tbl The table whose values will be checked.
-- @param value The value to look for.
-- @return true or false, whether the table contains the value.
function util.contains_value(tbl, value)
    for _, y in pairs(tbl) do
        if y == value then
            return true
        end
    end
    return false
end

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

--- Insert the elements from one list into another.
-- Works in place. The source list is not modified, but the destination is.
-- @param dst_lst The recipient.
-- @param src_lst The list whose elements will be copied.
function util.put_into(dst_lst, src_lst)
    for _, x in pairs(src_lst) do
        table.insert(dst_lst, x)
    end
end

--- Reverse a list.
-- @param lst The list to reverse.
-- @return A new list with the elements in the opposite order.
function util.reverse(lst)
    local result = {}
    for i = #lst, 1, -1 do
        table.insert(result, lst[i])
    end
    return result
end

--- Strings.
-- @section

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

--- Check whether the string starts with the prefix.
-- @param s The larger string.
-- @param prefix The prefix to look for.
-- @return true or false, whether the prefix is, uh, a prefix...
function util.startswith(s, prefix)
    return s:sub(1, #prefix) == prefix
end

--- Split a string according to a separator.
-- @param s The string to split.
-- @param sep The separator string.
-- @return A list of the string's component pieces.
function util.split(s, sep)
    if sep == nil then
        sep = "%s"
    end

    local parts = {}
    for match in s:gmatch("([^" .. sep .. "]+)") do
        table.insert(parts, match)
    end
    return parts
end

--- Do a prefix search in a list of strings.
-- This will search the list for an target "x". "x" matches a list element if
-- it is a prefix of the element. If there is only one match, it is returned;
-- else "nil" is returned. The behavior on multiple matches is controlled by require_unique.
-- @param lst The list of strings to search through.
-- @param prefix The prefix string to search for.
-- @param require_unique If true, the function will return nil in the case of multiple matches.
-- Otherwise, the first match is returned.
-- @return The first index in the list which has the prefix. nil if no such index exists.
function util.prefix_search(lst, prefix, require_unique)
    local matches = {}

    for ix, item in ipairs(lst) do
        if util.startswith(item, prefix) then
            table.insert(matches, ix)
        end
    end

    if (#matches > 0) and not require_unique then
        return matches[1]
    else
        return nil
    end
end

--- Performs a linear search.
-- @param lst The table to search.
-- @param target The element to look for.
-- @param cmp A comparator. If nil, == is used.
-- @return The first index of the element, or nil if it does not appear.
function util.index_of(lst, target, cmp)
    if cmp == nil then
        cmp = function(x)
            return x == target
        end
    end

    for i, x in ipairs(lst) do
        if cmp(x) then
            return i
        end
    end
end

return util
