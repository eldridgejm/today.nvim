util = {}


function util.slice(arr, a, b)
    result = {}
    i = a
    while i < b do
        table.insert(result, arr[i])
        i = i + 1
    end
    return result
end


function util.map(fn, iterable)
    local result = {}
    for _, x in pairs(iterable) do
        table.insert(result, fn(x))
    end
    return result
end


function util.filter(predicate, lines)
    local result = {}

    for _, line in pairs(lines) do
        if predicate(line) then
            table.insert(result, line)
        end
    end

    return result
end

function util.lstrip(s)
    return s:match( "^%s*(.+)" )
end


function util.rstrip(s)
    return s:match("^(.+%S)%s*$")
end


function util.strip(s)
    return util.lstrip(util.rstrip(s))
end


function merge(left, right, arr, cmp)
    local left_ix = 1
    local right_ix = 1

    for i=1, #arr do
        if cmp(left[left_ix], right[right_ix]) then
            arr[i] = left[left_ix]
            left_ix = left_ix + 1
        else
            arr[i] = right[right_ix]
            right_ix = right_ix + 1
        end

        if left_ix > #left then
            i = i + 1
            while i <= #arr do
                arr[i] = right[right_ix]
                i = i + 1
                right_ix = right_ix + 1
            end
            break
        end

        if right_ix > #right then
            i = i + 1
            while i <= #arr do
                arr[i] = left[left_ix]
                i = i + 1
                left_ix = left_ix + 1
            end
            break
        end

    end
end


function util.mergesort(arr, cmp)
    if cmp == nil then
        cmp = function(x, y) return x < y end
    end

    if #arr <= 1 then
        return
    end

    local middle = math.floor(#arr / 2)
    local left = util.slice(arr, 1, middle + 1)
    local right = util.slice(arr, middle + 1, #arr + 1)

    util.mergesort(left, cmp)
    util.mergesort(right, cmp)

    merge(left, right, arr, cmp)
end


return util
