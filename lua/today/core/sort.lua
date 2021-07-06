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


function sort.by_priority_then_date(lines)
    -- stable sort by priority first, then date
    function comparator(x, y)
        local x_ds = task.get_datespec(x)
        local y_ds = task.get_datespec(y)

        local x_pr = task.get_priority(x)
        local y_pr = task.get_priority(y)

        if x_pr > y_pr then
            return true
        elseif x_pr == y_pr then
            return x_ds.do_date <= y_ds.do_date
        else
            return false
        end
    end

    util.mergesort(lines, comparator)
end


return sort
