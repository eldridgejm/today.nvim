util = require('today.core.util')
task = require('today.core.task')


sort = {}


function sort.by_priority(lines)
    -- stable sort by priority

    function comparator(x, y)
        return task.get_priority(x) >= task.get_priority(y)
    end

    util.mergesort(lines, comparator)
end


return sort
