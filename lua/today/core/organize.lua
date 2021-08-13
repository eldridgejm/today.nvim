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

local organize = {}

-- -------------------------------------------------------------------------------------

--- Filter tasks into "good" tasks, hidden tasks, and broken tasks.
local function separate_tasks(tasks, filterer, is_broken)
    local function predicate(t)
        if filterer and filterer(t) then
            return "hidden"
        elseif is_broken(t) then
            return "broken"
        else
            return "good"
        end
    end

    local groups = util.groupby(predicate, tasks)

    return groups["good"], groups["hidden"], groups["broken"]
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

-- -------------------------------------------------------------------------------------

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

--- Organize a set of tasks. This takes in a list of buffer lines and a table of
-- "components" (described below), and reorganizes them by filtering them, putting them
-- into categories, and displaying helpful information in comment lines.
-- The "components" implement the reorganization strategy, and there are four of them:
--
-- `categorizer`: This should be a function which accepts a list of tasks and returns a table
-- mapping "category keys" to lists of tasks.
--
-- `header_formatter`: This should be a function which accepts a category key string and
-- returns the string that will be displayed as the category's header. The header formatter
-- is responsible for adding things like a remaining task count to the header. This component
-- can be nil, in which case the category key is used as the header directly.
--
-- `filterer`: This should be a function which accepts a task string and returns either `True`
-- or `False` depending on whether the task should be kept or hidden, respectively. This
-- can be nil, in which case no tasks are filtered out.
--
-- `is_broken`: A function which accepts a task and returns true if it is broken.
--
-- `informer`: This should be a function which accepts no arguments and returns a list
-- of lines to add to the beginning of the buffer. These lines provide information, for
-- instance, about the current settings. This can be nil, in which case no information
-- is added.
--
-- The organizer's job is simply to reorganize the tasks in the buffer. It will not change
-- any of the tasks by, for instance, normalizing them, altering or adding a datespec,
-- deleting them, or creating new tasks. In particular, functionality for inferring a
-- datespec from membership in a category is contained within another module.
--
-- @param lines A list of lines to organize. Note that this may include lines other than tasks.
-- @param components The different components controlling how the buffer is organized. See
-- above.
-- @return The re-organized lines as a list.
function organize.organize(lines, components)
    if components.header_formatter == nil then
        components.header_formatter = function(key)
            return key
        end
    end

    local head_comments = extract_user_comments(lines)
    local tail_comments = extract_user_comments(util.reverse(lines))

    local tasks = util.filter(task.is_task, lines)
    tasks = util.map(task.normalize, tasks)

    local hidden_tasks, broken_tasks
    tasks, hidden_tasks, broken_tasks = separate_tasks(tasks, components.filterer, components.is_broken)

    local categories = components.categorizer(tasks, hidden_tasks, broken_tasks)
    local category_lines = display_categories(categories, components.header_formatter)

    local result = {}
    if #head_comments > 0 then
        util.put_into(result, head_comments)
        table.insert(result, "")
    end

    if components.informer ~= nil then
        local info_lines = components.informer()
        util.put_into(result, info_lines)
    end

    util.put_into(result, category_lines)

    if #tail_comments > 0 then
        table.insert(result, "")
        util.put_into(result, tail_comments)
    end

    return result
end

return organize
