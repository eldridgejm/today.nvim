task = require('today.core.task')
categorize = require('today.core.categorize')
sort = require('today.core.sort')


update = {}


function update.pre_write(lines, today)
    local function make_datespec_absolute(line)
        return task.make_datespec_absolute(line, today)
    end

    lines = util.filter(task.is_task, lines)
    lines = util.map(task.normalize, lines)
    lines = util.map(make_datespec_absolute, lines)
    return lines
end


function update.post_read(lines, today)
    local function make_datespec_natural(line)
        return task.make_datespec_natural(line, today)
    end

    lines = util.map(make_datespec_natural, lines)
    sort.by_priority(lines)
    lines = categorize(lines)
    return lines
end


return update
