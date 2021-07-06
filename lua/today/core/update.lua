DateSpec = require('today.core.datespec')
sort = require('today.core.sort')
task = require('today.core.task')
util = require('today.core.util')


update = {}

local function define_groups(today)

    local groups = {}

    local function is_done(line)
        return task.is_checked(line)
    end

    local function get_datespec(line)
        return task.get_datespec(line, today)
    end

    groups['done'] = {
        header = "done",
        filter = function(line) return is_done(line) end
    }

    groups['undone:overdue'] = {
        header = "overdue",
        filter = function(line) 
            return (not is_done(line)) and (get_datespec(line):days_away() < 0)
        end
    }

    groups['undone:today'] = {
        header = "today",
        filter = function(line) 
            return (not is_done(line)) and (get_datespec(line):days_away() == 0)
        end
    }

    groups['undone:tomorrow'] = {
        header = "tomorrow",
        filter = function(line) 
            return (not is_done(line)) and (get_datespec(line):days_away() == 1)
        end
    }

    groups['undone:next_7_days'] = {
        header = "next 7 days",
        filter = function(line) 
            local days_from_today = get_datespec(line):days_away()
            local is_this_week = (days_from_today <= 7) and (days_from_today >= 2)
            return (not is_done(line)) and is_this_week
        end
    }

    groups['undone:future'] = {
        header = "future",
        filter = function(line)
            local days_from_today = get_datespec(line):days_away()
            return (not is_done(line)) and (days_from_today > 7)
        end
    }

    return groups
end


function categorize(lines, today)
    lines = util.filter(task.is_task, lines)
    local groups = define_groups(today)

    local order = {
        'undone:overdue',
        'undone:today',
        'undone:tomorrow',
        'undone:next_7_days',
        'undone:future',
        'done',
    }

    local result = {}
    function add_line(s)
        table.insert(result, s)
    end

    function add_lines(lines)
        for _, line in pairs(lines) do
            table.insert(result, line)
        end
    end

    for _, key in pairs(order) do
        local group = groups[key]
        local group_lines = util.filter(group.filter, lines)
        sort.by_priority_then_date(group_lines)

        if #group_lines > 0 then
            add_line('-- ' .. group.header .. ' (' .. #group_lines .. ')' .. ' {{{')
            add_lines(group_lines)
            add_line('-- }}}')
            add_line('')
        end
    end

    -- the last line will be blank if any group was processed;
    -- remove it, as it is not necessary
    if #result > 0 then
        table.remove(result)
    end

    return result
end


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
    lines = categorize(lines, today)
    return lines
end



return update
