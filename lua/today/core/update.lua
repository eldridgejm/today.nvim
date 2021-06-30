util = require('today.core.util')
categorize = require('today.core.categorize')
sort = require('today.core.sort')


function update(lines)
    lines = util.filter(util.is_task, lines)
    lines = util.map(util.normalize, lines)
    sort.by_priority(lines) 
    lines = categorize(lines)
    return lines
end


return update
