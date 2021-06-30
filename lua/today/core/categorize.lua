task = require('today.core.task')
util = require('today.core.util')


function categorize(lines)
    local result = {}
    local groups = {}

    lines = util.filter(task.is_task, lines)

    local is_done = function(x) return task.is_checked(x) end
    local is_not_done = function(x) return not task.is_checked(x) end

    groups['undone'] = util.filter(is_not_done, lines)
    groups['done'] = util.filter(is_done, lines)

    function concat(lines)
        for _, line in pairs(lines) do
            table.insert(result, line)
        end
    end

    function add_line(s)
        table.insert(result, s)
    end

    concat(groups['undone'])
    add_line("")
    add_line("-- done (" .. #groups['done'] .. ") {{{")
    concat(groups['done'])
    add_line("-- }}}")

    return result
end


return categorize
