local sort = require("today.core.sort")
local task = require("today.core.task")
local util = require("today.core.util")

local function define_groups(today)
    local groups = {}

    local is_done = task.is_done

    local function get_datespec_safe(line)
        return task.get_datespec_safe(line, today)
    end

    groups["done"] = {
        header = "done",
        filter = function(line)
            return is_done(line)
        end,
    }

    groups["undone:overdue"] = {
        header = "overdue",
        filter = function(line)
            return (not is_done(line)) and (get_datespec_safe(line):days_until_do() < 0)
        end,
    }

    groups["undone:today"] = {
        header = "today",
        filter = function(line)
            return (not is_done(line))
                and (get_datespec_safe(line):days_until_do() == 0)
        end,
    }

    groups["undone:tomorrow"] = {
        header = "tomorrow",
        filter = function(line)
            return (not is_done(line))
                and (get_datespec_safe(line):days_until_do() == 1)
        end,
    }

    groups["undone:next_7_days"] = {
        header = "next 7 days",
        filter = function(line)
            local days_from_today = get_datespec_safe(line):days_until_do()
            local is_this_week = (days_from_today <= 7) and (days_from_today >= 2)
            return (not is_done(line)) and is_this_week
        end,
    }

    groups["undone:future"] = {
        header = "future",
        filter = function(line)
            local days_from_today = get_datespec_safe(line):days_until_do()
            return (not is_done(line)) and (days_from_today > 7)
        end,
    }

    return groups
end

local function categorize(lines, today)
    lines = util.filter(task.is_task, lines)
    local groups = define_groups(today)

    local order = {
        "undone:overdue",
        "undone:today",
        "undone:tomorrow",
        "undone:next_7_days",
        "undone:future",
        "done",
    }

    local result = {}
    local function add_line(s)
        table.insert(result, s)
    end

    local function add_lines(to_add)
        for _, line in pairs(to_add) do
            table.insert(result, line)
        end
    end

    for _, key in pairs(order) do
        local group = groups[key]
        local group_lines = util.filter(group.filter, lines)
        sort.by_priority_then_date(group_lines)

        if #group_lines > 0 then
            add_line("-- " .. group.header .. " (" .. #group_lines .. ")" .. " {{{")
            add_lines(group_lines)
            add_line("-- }}}")
            add_line("")
        end
    end

    -- the last line will be blank if any group was processed;
    -- remove it, as it is not necessary
    if #result > 0 then
        table.remove(result)
    end

    return result
end

local function extract_user_comments(lines)
    local comments = {}

    for _, line in pairs(lines) do
        if util.startswith(line, "--:") then
            table.insert(comments, line)
        else
            return comments
        end
    end
    return {}
end

return function(lines, working_date)
    assert(working_date ~= nil)

    local head_comments = extract_user_comments(lines)
    local tail_comments = extract_user_comments(util.reverse(lines))

    local tasks = util.filter(task.is_task, lines)
    tasks = util.map(task.normalize, tasks)
    sort.by_priority_then_date(tasks)
    tasks = categorize(tasks, working_date)

    local result = {}
    if #head_comments > 0 then
        util.put_into(result, head_comments)
        table.insert(result, "")
    end

    util.put_into(result, tasks)

    if #tail_comments > 0 then
        table.insert(result, "")
        util.put_into(result, tail_comments)
    end

    return result
end
