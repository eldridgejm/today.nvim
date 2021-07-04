task = require('today.core.task')
util = require('today.core.util')
DateSpec = require('today.core.datespec')


function categorize(lines)
    local result = {}
    local groups = {}

    lines = util.filter(task.is_task, lines)

    local is_done = function(x) return task.is_checked(x) end
    local is_not_done = function(x) return not task.is_checked(x) end

    groups['undone'] = util.filter(is_not_done, lines)
    groups['done'] = util.filter(is_done, lines)

    local function is_future(line)
        local ds = task.get_datespec(line)
        return ds:is_future() and (not ds:is_tomorrow())
    end

    local function is_tomorrow(line)
        local ds = task.get_datespec(line)
        return ds:is_tomorrow()
    end

    local function is_doable_today(line)
        local ds = task.get_datespec(line)
        return not ds:is_future()
    end

    groups['undone:today'] = util.filter(is_doable_today, groups['undone'])
    groups['undone:tomorrow'] = util.filter(is_tomorrow, groups['undone'])
    groups['undone:future'] = util.filter(is_future, groups['undone'])

    function concat(lines)
        for _, line in pairs(lines) do
            table.insert(result, line)
        end
    end

    function add_line(s)
        table.insert(result, s)
    end

    concat(groups['undone:today'])

    if #groups['undone:tomorrow'] > 0 then
        add_line("")
        add_line("-- tomorrow (" .. #groups['undone:tomorrow'] .. ") {{{")
        concat(groups['undone:tomorrow'])
        add_line("-- }}}")
    end

    if #groups['undone:future'] > 0 then
        add_line("")
        add_line("-- future (" .. #groups['undone:future'] .. ") {{{")
        concat(groups['undone:future'])
        add_line("-- }}}")
    end

    if #groups['done'] > 0 then
        add_line("")
        add_line("-- done (" .. #groups['done'] .. ") {{{")
        concat(groups['done'])
        add_line("-- }}}")
    end

    return result
end


return categorize
