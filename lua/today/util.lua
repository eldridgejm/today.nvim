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

--- Map a function over a list, returning a list of results.
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

--- Map a function over the keys of a table, transforming them.
-- @param fn The function to apply.
-- @param iterable The table to apply it to.
-- @return A table of the results with keys transformed.
function util.map_keys(fn, table)
    local result = {}
    for key, x in pairs(table) do
        result[fn(key)] = x
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

--- Map the function over the list, stopping and returning at the first non-nil
-- result. If there are no non-nil results, the overall result is nil.
-- @param func The function to apply.
-- @param lst The list to traverse.
-- @return The first non-nil result, or nil if all are nil.
function util.first_non_nil(func, lst)
    for _, x in ipairs(lst) do
        local res = func(x)
        if res ~= nil then
            return res
        end
    end
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
    if lst == nil or #lst == 0 then
        return groups
    end
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

--- Return a minimum element in the list.
-- @param lst The list to search through.
-- @param cmp The comparator to use. Should accept two arguments and return True
-- if the first argument should come before the second. If this is nil, the default
-- built-in < operator is used.
-- @return The minimum.
function util.minimum(lst, cmp)
    if cmp == nil then
        cmp = function(x, y)
            return x < y
        end
    end

    local m = lst[1]
    for i = 1, #lst do
        if cmp(lst[i], m) then
            m = lst[i]
        end
    end
    return m
end

-- Return a maximum element in the list.
-- @param lst The list to search through.
-- @param cmp The comparator to use. Should accept two arguments and return True
-- if the first argument should come before the second. If this is nil, the default
-- built-in < operator is used.
-- @return The maximum.
function util.maximum(lst, cmp)
    if cmp == nil then
        cmp = function(x, y)
            return x < y
        end
    end

    local inverted_cmp = function(x, y)
        return not cmp(x, y)
    end

    return util.minimum(lst, inverted_cmp)
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

--- Merges the keys/values in two tables.
-- @param provided The "new" table that replaces the defaults. If this is nil, the
-- defaults table is copied and returned. If `provided[key]` is nil but is defined in
-- `defaults`, the default value is inserted into `provided`. If a key is in `provided`
-- but not in `defaults`, the key is added to the output table from `provided`.
-- @param defaults The default values.
-- @returns The new table.
function util.merge(provided, defaults)
    local opts = {}

    if provided == nil then
        for key, value in pairs(defaults) do
            opts[key] = value
        end
        return opts
    end

    for key, provided_value in pairs(provided) do
        opts[key] = provided_value
    end

    for key, default_value in pairs(defaults) do
        if provided[key] ~= nil then
            opts[key] = provided[key]
        else
            opts[key] = default_value
        end
    end
    return opts
end

--- Strings.
-- @section

--- Remove whitespace from the left of a string.
-- @param s The string to strip.
function util.lstrip(s)
    if s == "" then
        return ""
    end
    local m = s:match("^%s*(.+)")
    if m == " " then
        return ""
    end
    return m
end

--- Remove whitespace from the right of a string.
-- @param s The string to strip.
function util.rstrip(s)
    if s == "" then
        return ""
    end
    local m = s:match("^(.*%S+)%s*$")
    if m == nil then
        return ""
    end
    return m
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

return util
