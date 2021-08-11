--- Functions for organizing a buffer full of tasks.

local task = require("today.core.task")
local util = require("today.util")
local sort = require("today.core.sort")
local dates = require("today.core.dates")

local organize = {}

--- Categorizers.
-- @section

--- Organizes tasks by do date first, then by priority.
-- @param working_date The working date as a string in YYYY-MM-DD format.

function organize.make_categorizer_from_components(components)
    return {
        categorize = function(tasks)
            local groups = components.grouper(tasks)

            local headers = util.keys(groups)
            sort.mergesort(headers, components.header_comparator)

            local result = {}
            for _, header in ipairs(headers) do
                local group_tasks = groups[header]
                sort.mergesort(group_tasks, components.task_comparator)
                local group = {
                    header = header,
                    tasks = group_tasks,
                }
                table.insert(result, group)
            end
            return result
        end,
        infer_from_category = function(lines)
            if components.inferrer == nil then
                return lines
            end

            local current_header = nil
            local new_lines = {}
            for _, line in pairs(lines) do
                local header = line:match("-- (.*) %(%d+%) {{{")
                local end_header = line == "-- }}}"

                if header ~= nil then
                    current_header = header
                end

                if end_header then
                    current_header = nil
                end

                if task.is_task(line) then
                    local new_line = components.inferrer(line, current_header)
                    if new_line ~= nil then
                        line = new_line
                    end
                end

                table.insert(new_lines, line)
            end

            return new_lines
        end,
    }
end

local function merge_options(provided, defaults)
    if provided == nil then
        return defaults
    end

    local opts = {}

    for key, default_value in pairs(defaults) do
        if provided[key] ~= nil then
            opts[key] = provided[key]
        else
            opts[key] = default_value
        end
    end
    return opts
end

function organize.do_date_categorizer(working_date, options)
    working_date = dates.DateObj:new(working_date)

    options = merge_options(options, {
        show_empty_categories = false,
        move_to_done_immediately = true,
        days_until_future = 15,
        show_dates = false,
    })

    local function remove_date_from_header(h)
        return h:gsub(" |.*|", "")
    end

    local function add_date_to_header(header)
        local undated = {
            "done",
            "someday",
            "future",
            "broken",
        }

        if util.contains_value(undated, header) then
            return header
        end

        local date = dates.from_natural(header, working_date)
        return header .. " | " .. dates.to_month_day(date) .. " |"
    end

    local order = {}
    for i = 0, 13 do
        local header = dates.to_natural(working_date:add_days(i), working_date)
        table.insert(order, header)
    end

    if options.show_dates then
        order = util.map(add_date_to_header, order)
    end

    util.put_into(order, {
        "future",
        "someday",
        "done",
    })

    return organize.make_categorizer_from_components({
        grouper = function(tasks)
            local keyfunc = function(t)
                local datespec = task.parse_datespec_safe(t, working_date)

                if datespec == nil then
                    return "broken"
                end

                local days_until_do = working_date:days_until(datespec.do_date)

                local ready_to_move = options.move_to_done_immediately
                    or (days_until_do < 0)

                if task.is_done(t) and ready_to_move then
                    return "done"
                elseif days_until_do <= 0 then
                    return "today"
                elseif days_until_do == math.huge then
                    return "someday"
                elseif days_until_do > 13 then
                    return "future"
                else
                    return dates.to_natural(
                        working_date:add_days(days_until_do),
                        working_date
                    )
                end
            end

            local groups = util.groupby(keyfunc, tasks)

            if options.show_dates then
                groups = util.map_keys(add_date_to_header, groups)
            end

            if options.show_empty_categories then
                for _, key in pairs(order) do
                    if groups[key] == nil then
                        groups[key] = {}
                    end
                end
            end
            return groups
        end,

        header_comparator = sort.make_order_comparator(order),

        task_comparator = sort.chain_comparators({
            sort.completed_comparator,
            sort.make_do_date_comparator(working_date),
            sort.priority_comparator,
        }),

        inferrer = function(t, header)
            if header == "done" then
                return task.mark_done(t)
            end

            if header == nil then
                return nil
            end

            if not util.contains_value(order, header) then
                return nil
            end

            if task.parse_datespec(t, working_date) ~= nil then
                return nil
            end

            local do_date
            header = remove_date_from_header(header)
            if header == "today" then
                -- tasks without datespecs (such as this one) already appear under today.
                -- plus, this prevents the jarring situation where we switch from tag categorizer
                -- to date categorizer, and all of the things without a datespec immediately are
                -- given one
                return nil
            elseif header == "future" then
                do_date = options.days_until_future .. " days from now"
            else
                do_date = header
            end

            return task.set_do_date(t, do_date)
        end,
    })
end

--- Organizes tasks by the first tag present in the tag, then by do date, then priority.
-- @param working_date The working date as a string in YYYY-MM-DD format.
function organize.first_tag_categorizer(working_date)
    assert(working_date ~= nil)
    working_date = dates.DateObj:new(working_date)

    return organize.make_categorizer_from_components({

        grouper = function(tasks)
            local keyfunc = function(line)
                if task.parse_datespec_safe(line, working_date) == nil then
                    return "broken"
                end

                local first_tag = task.get_first_tag(line)
                if first_tag ~= nil then
                    return first_tag
                else
                    return "other"
                end
            end
            return util.groupby(keyfunc, tasks)
        end,

        header_comparator = nil,

        task_comparator = function(x, y)
            local cmp = sort.chain_comparators({
                sort.completed_comparator,
                sort.make_do_date_comparator(working_date),
                sort.priority_comparator,
            })
            return cmp(x, y)
        end,

        inferrer = function(line, header)
            if header == nil then
                return nil
            end

            -- don't infer if there is already a tag
            if task.get_first_tag(line) ~= nil then
                return nil
            end

            if not util.startswith(header, "#") then
                return nil
            end

            return task.set_first_tag(line, header)
        end,
    })
end

local function display_categories(categories)
    local result = {}
    local function add_line(s)
        table.insert(result, s)
    end

    local function add_lines(to_add)
        for _, line in pairs(to_add) do
            table.insert(result, line)
        end
    end

    for _, category in pairs(categories) do
        add_line("-- " .. category.header .. " (" .. #category.tasks .. ")" .. " {{{")
        add_lines(category.tasks)
        add_line("-- }}}")
        add_line("")
    end

    -- the last line will be blank if any category was processed;
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

        local working_date = info.working_date
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

    if categorizer.infer_from_category ~= nil then
        lines = categorizer.infer_from_category(lines)
    end

    local tasks = util.filter(task.is_task, lines)
    tasks = util.map(task.normalize, tasks)

    local hidden_tasks

    if filterer ~= nil then
        local filtered = util.groupby(filterer, tasks)
        tasks = filtered[true] or {}
        hidden_tasks = filtered[false] or {}
    end

    local categories = categorizer.categorize(tasks)
    local category_lines = display_categories(categories)

    local result = {}
    if #head_comments > 0 then
        util.put_into(result, head_comments)
        table.insert(result, "")
    end

    if informer ~= nil then
        local info_lines = informer()
        util.put_into(result, info_lines)
    end

    util.put_into(result, category_lines)

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
