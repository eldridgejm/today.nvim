--- Assign tasks to categories.
-- A categorizer is a function that implements a strategy for organizing
-- tasks into categories. The function should accept three arguments:
--
-- 1. a list of *good* tasks (as strings)
-- 2. a list of *hidden* tasks (can be nil)
-- 3. a list of *broken* tasks (can be nil)
--
-- It should return a list of tables -- each table representing
-- a separate category, and with key/value pairs: "header" (string) the
-- category's header and "tasks" (list of strings) the tasks in the category.
--
-- A categorizer is responsible for displaying *all* of the categories, including
-- the hidden category, the broken category, and others, such as the category
-- of completed tasks. The categories it creates can be given whatever title is
-- appropriate, however, care should be given to assign a title that gives the
-- inferrer enough information to do its job.

-- The format of the category headers is important. Each category should be
-- delimited by a starting category "header" and a trailing "footer". A category header
-- comment is of the form:
--      -- <title> [| <information 1> | <information 2> ...] {{{
-- A footer comment is of the form:
--      -- }}}
-- The term "header" refers to the content of the header comment. For example, given the
-- header comment:
--      -- tomorrow | aug 15 | 1 task {{{
-- the header is the string `"tomorrow | aug 15 | 1 task"`.
--
-- There is a lot of overlap in the creation of categorizers. To simplify the process,
-- the `make_categorizer_from_components` helper function may be used. It builds a
-- categorizer from several component functions.

local dates = require("today.core.dates")
local task = require("today.core.task")
local sort = require("today.core.sort")
local util = require("today.util")

local categorizers = {}

-- Helpers ---------------------------------------------------------------------

-- Builds a header string out of its parts, separating them with " | "
local function construct_header(parts)
    parts = util.filter(function(x)
        return x ~= nil
    end, parts)
    return table.concat(parts, " | ")
end

-- Counts the undone tasks in the list.
local function count_remaining_tasks(tasks)
    local count = 0
    for _, t in pairs(tasks) do
        if not task.is_done(t) then
            count = count + 1
        end
    end
    return count
end

-- `make_categorizer_from_components` ------------------------------------------

--- Builds a categorizer from components. The required components are:
--
-- `grouper`: Accepts a list of tasks and returns a table whose keys are category "keys"
-- (strings used to describe the category) and whose values are the lists of tasks in each
-- category. Note that category keys need not be headers (though they may be).
--
-- `header_formatter`: Accepts a category key and a list of tasks formats a header string. This
-- is responsible for, e.g., adding a count of undone tasks to the header. If this is
-- nil, the category key is used as the header directly.
--
-- `category_key_comparator`: Compares category keys for the purpose of ordering between
-- categories. Default behavior is to simply use the standard < operator.
--
-- `task_comparator`: Compares tasks for the purpose of ordering within categories.
--
-- Broken and hidden groups are automatically created, but only if they are supplied
-- and non-empty.
--
-- @param components A table with the components listed above.
-- @return A categorizer function.
-- keys.
function categorizers.make_categorizer_from_components(components)
    return function(tasks, hidden_tasks, broken_tasks)
        local groups = components.grouper(tasks)

        if hidden_tasks and #hidden_tasks > 0 then
            groups["hidden"] = hidden_tasks
        end

        if broken_tasks and #broken_tasks > 0 then
            groups["broken"] = broken_tasks
        end

        if components.header_formatter == nil then
            components.header_formatter = function(_, k)
                return k
            end
        end

        local category_keys = util.keys(groups)
        sort.mergesort(category_keys, components.category_key_comparator)

        local result = {}
        for _, category_key in ipairs(category_keys) do
            local category_tasks = groups[category_key]
            sort.mergesort(category_tasks, components.task_comparator)
            local group = {
                header = components.header_formatter(category_key, category_tasks),
                tasks = category_tasks,
            }
            table.insert(result, group)
        end

        return result
    end
end

-- `daily_agenda_categorizer` --------------------------------------------------

--- Makes a categorizer which organizes tasks into a daily agenda by their "do dates".
--
-- The category titles produced by this categorizer are among the following:
--
-- *done*: roughly, tasks that are marked done (see: `move_to_done_immediately`)
--
-- *broken*: broken tasks
--
-- *hidden*: hidden tasks
--
-- *someday*: tasks with a do-date of "someday"
--
-- *future (k+ days from now)*: tasks that are in the "future", according to the
-- value of the `days` option.
--
-- (date): A date parseable by `today.core.dates.parse`, like "today", or "2021-10-23"
-- @param options A table of options. Valid options are:
--
-- `working_date`: (string or DateObj) The working date. This **must** be supplied.
--
-- `date_format`: (string) The format used to display dates. If this is "natural", only the
-- natural language is used, e.g., "tomorrow". If this is "ymd", the yyyy-mm-dd format
-- is used, e.g., "2021-07-04". If this is "timestamp", this is a string of the form
-- "wed jul 04 2021". If this is "monthday", a string of the form "jun 01" is used. Default: natural.
--
-- `second_date_format`: (string or false or nil). The format used to show a 2nd date in the header, right
-- after the first. If this is false or nil, no second date is displayed. For valid values, see the
-- `date_format` option above. This can be used to display a date next to a natural date,
-- e.g., "tomorrow | jul 04"
--
-- `days`: (int) roughly, the number of agenda days to show. See `show_empty_days`
-- below for a qualification on the previous statement. Tasks that occur this
-- many days into the future are placed in the "future" category. For example,
-- if it is Monday, and `days = 3`, then tasks on Mon, Tues, Wed, will be shown,
-- and a task on Thursday will be placed in the "future".
--
-- `show_empty_days`: (bool) If false, days without tasks are not displayed as
-- their own category. If true, exactly `days` day categories will be shown.
--
-- `move_to_done_immediately`: (bool) If false, a task that is marked as complete with a
-- do-date of today is placed in the "today" category; all other completed tasks are placed
-- in the "done" category. If true, all tasks are placed in the "done" category. Default:
-- true.
--
-- `show_remaining_tasks_count`: (bool) If true, a count of remaining tasks is added to the
-- header, after the date (if it is shown). Default: false.
-- @return The categorizer function.
function categorizers.daily_agenda_categorizer(options)
    options = util.merge(options, {
        date_format = "natural",
        second_date_format = false,
        show_empty_days = false,
        days = 7,
        move_to_done_immediately = true,
        show_remaining_tasks_count = false,
    })

    return categorizers.make_categorizer_from_components({
        grouper = function(tasks)
            -- we will key the categories by either "done", "future", "someday",
            -- or the do-date as a ymd string. later we'll convert the key to the
            -- requested date format
            local working_date = dates.DateObj:new(options.working_date)
            local keyfunc = function(t)
                local datespec = task.parse_datespec_safe(t, working_date)

                local days_until_do = working_date:days_until(datespec.do_date)

                local ready_to_move = options.move_to_done_immediately
                    or (days_until_do < 0)

                if task.is_done(t) and ready_to_move then
                    return "done"
                elseif days_until_do == math.huge then
                    return "someday"
                elseif days_until_do >= options.days then
                    return "future"
                elseif days_until_do <= 0 then
                    return tostring(working_date)
                else
                    return tostring(working_date:add_days(days_until_do))
                end
            end

            local groups = util.groupby(keyfunc, tasks)

            if options.show_empty_days then
                local threshold = working_date:add_days(options.days)
                local cursor = dates.DateObj:new(working_date)

                while cursor < threshold do
                    if groups[tostring(cursor)] == nil then
                        groups[tostring(cursor)] = {}
                    end
                    cursor = cursor:add_days(1)
                end
            end
            return groups
        end,

        category_key_comparator = sort.chain_comparators({
            sort.make_order_comparator({ "broken" }, true),
            sort.make_order_comparator({ "done", "hidden" }, false),
            function(x, y)
                return x < y
            end,
        }),

        task_comparator = sort.chain_comparators({
            sort.completed_comparator,
            sort.make_do_date_comparator(options.working_date),
            sort.priority_comparator,
        }),

        header_formatter = function(category_key, category_tasks)
            local title, second_date, tasks_remaining

            local function date_formatter(d, fmt)
                if fmt == "ymd" then
                    return d
                elseif fmt == "natural" then
                    return dates.to_natural(d, options.working_date)
                elseif fmt == "monthday" then
                    return dates.to_month_day(d)
                elseif fmt == "datestamp" then
                    return dates.to_datestamp(d)
                end
            end

            local verbatime = { "broken", "hidden", "done", "someday" }
            if util.contains_value(verbatime, category_key) then
                title = category_key
            elseif category_key == "future" then
                title = "future (" .. options.days .. "+ days from now)"
            else
                title = date_formatter(category_key, options.date_format)

                if options.second_date_format ~= nil then
                    second_date = date_formatter(
                        category_key,
                        options.second_date_format
                    )
                end
            end

            if options.show_remaining_tasks_count and category_key ~= "done" then
                tasks_remaining = count_remaining_tasks(category_tasks)
            end

            return construct_header({
                title,
                second_date,
                tasks_remaining,
            })
        end,
    })
end

-- `first_tag_categorizer` -----------------------------------------------------

--- Makes a categorizer which organizes tasks by their first tag.
--
-- The category titles produced by this categorizer include "broken", 'hidden",
-- "other" (or tasks without tags), and each of the unique first tags, prepended
-- with a `#`.
--
-- @param options A table of options. The options are
--
-- `working_date`: this must be supplied
--
-- `show_remaining_tasks_count`: (bool) If true, a count of remaining tasks is added to the
-- header, after the date (if it is shown). Default: false.
-- @return The categorizer function.
function categorizers.first_tag_categorizer(options)
    options = util.merge(options, {
        show_remaining_tasks_count = false,
    })

    return categorizers.make_categorizer_from_components({

        grouper = function(tasks)
            local keyfunc = function(line)
                if task.parse_datespec_safe(line, options.working_date) == nil then
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

        category_key_comparator = sort.chain_comparators({
            sort.make_order_comparator({ "broken" }, true),
            sort.make_order_comparator({ "hidden" }, false),
            function(x, y)
                return x < y
            end,
        }),

        task_comparator = function(x, y)
            local cmp = sort.chain_comparators({
                sort.completed_comparator,
                sort.make_do_date_comparator(options.working_date),
                sort.priority_comparator,
            })
            return cmp(x, y)
        end,

        header_formatter = function(category_key, category_tasks)
            local tasks_remaining

            if options.show_remaining_tasks_count then
                tasks_remaining = count_remaining_tasks(category_tasks)
            end

            return construct_header({
                category_key,
                tasks_remaining,
            })
        end,
    })
end

return categorizers
