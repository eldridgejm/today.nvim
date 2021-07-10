local sort = require("today.core.sort")
local task = require("today.core.task")
local util = require("today.core.util")


local function categorize(lines, today)

    local function get_date_key(t)
        local datespec = task.get_datespec_safe(t, today)

        if task.is_done(t) then
            return 'done'
        elseif datespec:days_until_do() < 0 then
            return 'undone:overdue'
        elseif datespec:days_until_do() == 0 then
            return 'undone:today'
        elseif datespec:days_until_do() == 1 then
            return 'undone:tomorrow'
        elseif datespec:days_until_do() <= 7 then
            return 'undone:next_7_days'
        else
            return 'undone:future'
        end
    end

    local tasks = util.filter(task.is_task, lines)
    local groups = util.groupby(get_date_key, tasks)

    local headers = {
        ["undone:overdue"] = "overdue",
        ["undone:today"] = "today",
        ["undone:tomorrow"] = "tomorrow",
        ["undone:next_7_days"] = "next_7_days",
        ["undone:future"] = "future",
        ["done"] = "done" ,
    }

    local presentation_order = {
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

    for _, key in pairs(presentation_order) do
        local group_tasks = groups[key]
        if group_tasks ~= nil then
            sort.by_priority_then_date(group_tasks)

            add_line("-- " .. headers[key] .. " (" .. #group_tasks .. ")" .. " {{{")
            add_lines(group_tasks)
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
