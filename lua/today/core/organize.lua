--- Functions for organizing a buffer full of tasks.

local task = require("today.core.task")
local util = require("today.util")
local sort = require("today.core.sort")

local organize = {}

--- Categorizers.
-- @section

--- Organizes tasks by do date first, then by priority.
-- @param working_date The working date as a string in YYYY-MM-DD format.
function organize.do_date_categorizer(working_date, options)
    if options == nil then
        options = {
            show_empty_sections = false,
        }
    end

    local sections = {
        ["undone:today"] = "today",
        ["undone:tomorrow"] = "tomorrow",
        ["undone:next_7_days"] = "next 7 days",
        ["undone:future"] = "future",
        ["done"] = "done",
    }

    local order = {
        "undone:today",
        "undone:tomorrow",
        "undone:next_7_days",
        "undone:future",
        "done",
    }

    return {
        headerfunc = function(key)
            return sections[key]
        end,
        orderfunc = function(_)
            return order
        end,
        comparefunc = sort.chain_comparators({
            sort.make_do_date_comparator(working_date),
            sort.priority_comparator,
        }),
        groupfunc = function(tasks)
            local keyfunc = function(t)
                local datespec = task.get_datespec_safe(t, working_date)

                if task.is_done(t) then
                    return "done"
                elseif datespec:days_until_do() <= 0 then
                    return "undone:today"
                elseif datespec:days_until_do() == 1 then
                    return "undone:tomorrow"
                elseif datespec:days_until_do() <= 7 then
                    return "undone:next_7_days"
                else
                    return "undone:future"
                end
            end
            local groups = util.groupby(keyfunc, tasks)

            if options.show_empty_sections then
                for key, _ in pairs(sections) do
                    if groups[key] == nil then
                        groups[key] = {}
                    end
                end
            end

            return groups
        end,
    }
end

--- Organizes tasks by the first tag present in the tag, then by do date, then priority.
-- @param working_date The working date as a string in YYYY-MM-DD format.
function organize.first_tag_categorizer(working_date)
    return {
        groupfunc = function(tasks)
            local keyfunc = function(t)
                local first_tag = task.get_first_tag(t)
                if first_tag ~= nil then
                    return first_tag
                else
                    return "other"
                end
            end
            return util.groupby(keyfunc, tasks)
        end,

        headerfunc = function(key)
            return key
        end,
        orderfunc = function(keys)
            sort.mergesort(keys)
            return keys
        end,
        comparefunc = sort.chain_comparators({
            sort.completed_comparator,
            sort.make_do_date_comparator(working_date),
            sort.priority_comparator,
        }),
    }
end

local function categorize(lines, categorizer)
    local tasks = util.filter(task.is_task, lines)
    local groups = categorizer.groupfunc(tasks)

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
            sort.mergesort(group_tasks, categorizer.comparefunc)
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

--- Filterers.
-- @section

--- Filters by tags.
-- @param target_tags A list of the tags to include.
function organize.tag_filterer(target_tags)
    return function(t)
        local task_tags = task.get_tags(t)
        for _, tag in pairs(task_tags) do
            if util.contains_value(target_tags, tag) then
                return true
            end
        end

        if (#task_tags == 0) and util.contains_value(target_tags, "none") then
            return true
        end

        return false
    end
end

--- Informers.
-- @section

--- Displays basic information.
-- @param info A table with information to display. Should have keys:
--  "working_date", "categorizer" (a string), and "filter_tags" (a list of strings).
function organize.basic_informer(info)
    return function()
        local lines = {}

        local working_date = info.working_date:fmt("%A %B %d")
        table.insert(lines, "-- working date: " .. working_date)
        table.insert(lines, "-- categorizer: " .. info.categorizer)

        if (info.filter_tags ~= nil) and (#info.filter_tags > 0) then
            local all_tags = table.concat(info.filter_tags, " ")
            table.insert(lines, "-- filter tags: " .. all_tags)
        end

        table.insert(lines, "")

        return lines
    end
end

--- organize().
-- @section

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

--- Organize a set of tasks for display or writing to a file.
-- @param lines A list of lines to organize.
-- @param categorize The categorizer used to group lines.
-- @param filterer The filterer used to hide lines.
-- @param informer The informer used to add information lines.
-- @return The organized lines.
function organize.organize(lines, categorizer, filterer, informer)
    local head_comments = extract_user_comments(lines)
    local tail_comments = extract_user_comments(util.reverse(lines))

    local tasks = util.filter(task.is_task, lines)
    tasks = util.map(task.normalize, tasks)

    local hidden_tasks

    if filterer ~= nil then
        local filtered = util.groupby(filterer, tasks)
        tasks = filtered[true]
        hidden_tasks = filtered[false]
    end

    tasks = categorize(tasks, categorizer)

    local result = {}
    if #head_comments > 0 then
        util.put_into(result, head_comments)
        table.insert(result, "")
    end

    if informer ~= nil then
        local info_lines = informer()
        util.put_into(result, info_lines)
    end

    util.put_into(result, tasks)

    if hidden_tasks ~= nil then
        table.insert(result, "")
        table.insert(result, "-- hidden (" .. #hidden_tasks .. ") {{{")
        util.put_into(result, hidden_tasks)
        table.insert(result, "-- }}}")
    end

    if #tail_comments > 0 then
        table.insert(result, "")
        util.put_into(result, tail_comments)
    end

    return result
end

return organize
