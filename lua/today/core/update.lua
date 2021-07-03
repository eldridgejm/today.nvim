task = require('today.core.task')
categorize = require('today.core.categorize')
sort = require('today.core.sort')


function update(lines)
    lines = util.filter(task.is_task, lines)
    lines = util.map(task.normalize, lines)
    sort.by_priority(lines)
    lines = categorize(lines)
    return lines
end


return update
