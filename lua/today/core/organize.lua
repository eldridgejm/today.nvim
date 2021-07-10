local task = require("today.core.task")
local util = require("today.core.util")

local organize = {}

function organize.do_date_categorizer(working_date)
    return {
        keyfunc = function(t)
            local datespec = task.get_datespec_safe(t, working_date)

            if task.is_done(t) then
                return "done"
            elseif datespec:days_until_do() < 0 then
                return "undone:overdue"
            elseif datespec:days_until_do() == 0 then
                return "undone:today"
            elseif datespec:days_until_do() == 1 then
                return "undone:tomorrow"
            elseif datespec:days_until_do() <= 7 then
                return "undone:next_7_days"
            else
                return "undone:future"
            end
        end,
        headerfunc = function(key)
            local mapping = {
                ["undone:overdue"] = "overdue",
                ["undone:today"] = "today",
                ["undone:tomorrow"] = "tomorrow",
                ["undone:next_7_days"] = "next_7_days",
                ["undone:future"] = "future",
                ["done"] = "done",
            }
            return mapping[key]
        end,
        orderfunc = function(_)
            return {
                "undone:overdue",
                "undone:today",
                "undone:tomorrow",
                "undone:next_7_days",
                "undone:future",
                "done",
            }
        end,
        comparefunc = function(task_x, task_y)
            local x_ds = task.get_datespec_safe(task_x)
            local y_ds = task.get_datespec_safe(task_y)

            local x_pr = task.get_priority(task_x)
            local y_pr = task.get_priority(task_y)

            if x_pr > y_pr then
                return true
            elseif x_pr == y_pr then
                return x_ds.do_date <= y_ds.do_date
            else
                return false
            end
        end,
    }
end

function organize.first_tag_categorizer()
    return {
        keyfunc = function(t)
            local first_tag = task.get_first_tag(t)
            if first_tag ~= nil then
                return first_tag
            else
                return "other"
            end
        end,
        headerfunc = function(key)
            return key
        end,
        orderfunc = function(keys)
            util.mergesort(keys)
            return keys
        end,
        comparefunc = function(task_x, _)
            return not task.is_done(task_x)
        end,
    }
end

local function categorize(lines, categorizer)
    local tasks = util.filter(task.is_task, lines)
    local groups = util.groupby(categorizer.keyfunc, tasks)

    local result = {}
    local function add_line(s)
        table.insert(result, s)
    end

    local function add_lines(to_add)
        for _, line in pairs(to_add) do
            table.insert(result, line)
        end
    end

    local order = categorizer.orderfunc(util.keys(groups))

    for _, key in pairs(order) do
        local group_tasks = groups[key]
        if group_tasks ~= nil then
            util.mergesort(group_tasks, categorizer.comparefunc)
            local header = categorizer.headerfunc(key)

            add_line("-- " .. header .. " (" .. #group_tasks .. ")" .. " {{{")
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

function organize.organize(lines, categorizer)
    local head_comments = extract_user_comments(lines)
    local tail_comments = extract_user_comments(util.reverse(lines))

    local tasks = util.filter(task.is_task, lines)
    tasks = util.map(task.normalize, tasks)
    tasks = categorize(tasks, categorizer)

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

return organize