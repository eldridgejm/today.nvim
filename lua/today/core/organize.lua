--- Functions for organizing the tasks in a buffer.
--
-- A buffer should be organized into mutually-exclusive *categories*. Each category is 
-- delimited by a starting category "header" and a trailing "footer". A category header
-- comment is of the form:
--      -- <title> [| <information 1> | <information 2> ...] {{{
-- A footer comment is of the form:
--      -- }}}
-- The term "header" refers to the content of the header comment. For example, given the
-- header comment:
--      -- tomorrow | aug 15 | 1 task {{{
-- the header is the string `"tomorrow | aug 15 | 1 task"`.

local task = require("today.core.task")
local util = require("today.util")
local sort = require("today.core.sort")
local dates = require("today.core.dates")

local organize = {}


--- Merges the keys/values in two tables.
-- @param provided The "new" table that replaces the defaults. If this is nil, the
-- defaults table is copied and returned. If `provided[key]` is nil but is defined in
-- `defaults`, the default value is inserted into `provided`. If a key is in `provided`
-- but not in `defaults`, nothing happens.
-- @param defaults The default values.
-- @returns The new table.
local function merge(provided, defaults)
    local opts = {}

    if provided == nil then
        for key, value in pairs(defaults) do
            opts[key] = value
        end
        return opts
    end

    for key, default_value in pairs(defaults) do
        if provided[key] ~= nil then
            opts[key] = provided[key]
        else
            opts[key] = default_value
        end
    end
    return opts
end

local function construct_header(parts)
    parts = util.filter(function (x) return x ~= nil end, parts)
    return table.concat(parts, " | ")
end


local function count_remaining_tasks(tasks)
    local count = 0
    for _, t in pairs(tasks) do
        if not task.is_done(t) then
            count = count + 1
        end
    end
    return count
end

--- Categorizers.
-- A categorizer is a function that implements a strategy for organizing
-- the tasks into categories. The function should accept a list of tasks (as strings)
-- and should return a list of tables -- each table representing a separate category,
-- and with key/value pairs: "header" (string) the category's header and "tasks" (list
-- of strings) the tasks in the category.
--
-- There is a lot of overlap in the creation of categorizers. To simplify the process,
-- the `make_categorizer_from_components` helper function may be used. It builds a
-- categorizer from several orthogonal component functions.
-- @section

--- Builds a categorizer from components. The required components are:
--
-- `grouper`: Accepts a list of tasks and returns a table whose keys are category "keys"
-- (strings used to describe the category) and whose values are the lists of tasks in each
-- category. Note that category keys need not be headers (though they may be).
--
-- `header_formatter`: Accepts a category key and the list of tasks in the category and 
-- returns a formatter header string. If not provided, the default is to simply use the 
-- category key as the header.
--
-- `category_key_comparator`: Compares category keys for the purpose of ordering between
-- categories. Default behavior is to simply use the standard < operator.
--
-- `task_comparator`: Compares tasks for the purpose of ordering within categories.
--
-- @param components A table with the components listed above.
-- @returns A list of categories, with each category being a table with "header" and "tasks"
-- keys.
function organize.make_categorizer_from_components(components)
    if components.header_formatter == nil then
        components.header_formatter = function (k) return k end
    end

    return function(tasks)
        local groups = components.grouper(tasks)

        local category_keys = util.keys(groups)
        sort.mergesort(category_keys, components.category_key_comparator)

        local result = {}
        for _, category_key in ipairs(category_keys) do
            local group_tasks = groups[category_key]
            sort.mergesort(group_tasks, components.task_comparator)
            local group = {
                header = components.header_formatter(category_key, group_tasks),
                tasks = group_tasks,
            }
            table.insert(result, group)
        end
        return result
    end
end


--- Organizes tasks according to their "do date".
function organize.do_date_categorizer(working_date, options)
    working_date = dates.DateObj:new(working_date)

    options = merge(options, {
        show_empty_categories = false,
        move_to_done_immediately = true,
        days_until_future = 15,
        show_dates = false,
        show_remaining_tasks_count = true
    })

    local function remove_date_from_header(h)
        return h:gsub(" |.*|", "")
    end

    local function category_key_to_date(key)
        local undated = {
            "done",
            "someday",
            "future",
            "broken",
        }

        if util.contains_value(undated, key) then
            return nil
        end

        local date = dates.from_natural(key, working_date)
        return dates.to_month_day(date)
    end

    local order = {}
    for i = 0, 13 do
        local header = dates.to_natural(working_date:add_days(i), working_date)
        table.insert(order, header)
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

            if options.show_empty_categories then
                for _, key in pairs(order) do
                    if groups[key] == nil then
                        groups[key] = {}
                    end
                end
            end
            return groups
        end,

        category_key_comparator = sort.make_order_comparator(order),

        task_comparator = sort.chain_comparators({
            sort.completed_comparator,
            sort.make_do_date_comparator(working_date),
            sort.priority_comparator,
        }),

        header_formatter = function (category_key, category_tasks)
            local date
            local tasks_remaining

            if options.show_dates then
                date = category_key_to_date(category_key)
            end

            if options.show_remaining_tasks_count and category_key ~= "done" then
                tasks_remaining = count_remaining_tasks(category_tasks)
            end

            return construct_header({
                category_key, date, tasks_remaining
            })
        end,

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
function organize.first_tag_categorizer(working_date, options)
    assert(working_date ~= nil)
    working_date = dates.DateObj:new(working_date)

    options = merge(options, {
        show_remaining_tasks_count = true
    })

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

        category_key_comparator = nil,

        task_comparator = function(x, y)
            local cmp = sort.chain_comparators({
                sort.completed_comparator,
                sort.make_do_date_comparator(working_date),
                sort.priority_comparator,
            })
            return cmp(x, y)
        end,

        header_formatter = function (category_key, category_tasks)
            local tasks_remaining

            if options.show_remaining_tasks_count then
                tasks_remaining = count_remaining_tasks(category_tasks)
            end

            return construct_header({
                category_key,
                tasks_remaining
            })
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
        add_line("-- " .. category.header .. " {{{")
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

    local tasks = util.filter(task.is_task, lines)
    tasks = util.map(task.normalize, tasks)

    local hidden_tasks

    if filterer ~= nil then
        local filtered = util.groupby(filterer, tasks)
        tasks = filtered[true] or {}
        hidden_tasks = filtered[false] or {}
    end

    local categories = categorizer(tasks)
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
        table.insert(result, "-- hidden | " .. #hidden_tasks .. " {{{")
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
