--- Functions for working with individual task strings.

local util = require("today.core.util")
local DateSpec = require("today.core.datespec")

local task = {}

local function head(line)
    -- the checkbox part of the line
    return task.ensure_checkbox(line):sub(1, 3)
end

local function tail(line)
    -- the "contents" of the line
    return task.ensure_checkbox(line):sub(5)
end

--- Convert a priority number to a string.
local function priority_number_to_string(priority)
    if priority == 0 then
        return ""
    else
        local lookup = { "!", "!!" }
        return lookup[priority]
    end
end

--- Normalization
-- @section

--- Return a version of the task that has a checkbox in front. If the task
-- already has a checkbox, it is left as-is. If not, an empty checkbox is placed
-- at the beginning of the string
-- @param line The task string.
-- @return The new task string.
function task.ensure_checkbox(line)
    local start = string.sub(line, 1, 3)
    if not ((start == "[ ]") or (start == "[x]")) then
        -- strip whitespace on the left
        line = line:match("^%s*(.+)")
        line = "[ ] " .. line
    end
    return line
end

--- Return true/false if the line is a task. A line is a task if it does not
-- start with "--" (it is a comment) and if it is not pure whitespace.
-- @param line The task string.
-- @return Boolean.
function task.is_task(line)
    local is_comment = line:sub(1, 2) == "--"
    local is_blank = not (line:match("^%s*$") == nil)
    return not (is_comment or is_blank)
end

--- Normalize the location of elements within a task string.
-- If the line does not start with a checkbox [ ], [x], add [ ].
-- Move the datespec string (if it exists) to after the checkbox.
-- Move the priority (if it exists) to after the datespec.
-- Finally, add the task definition.
-- @param line The task string
-- @return The new, normalized task string.
function task.normalize(line)
    local start = string.sub(line, 1, 3)
    if not ((start == "[ ]") or (start == "[x]")) then
        start = "[ ]"
    end

    local ds = task.get_datespec_as_string(line)
    local priority = task.get_priority(line)
    local description = task.get_description(line)

    local result = start
    local concat = function(s)
        result = result .. " " .. s
    end

    if ds ~= nil then
        concat(ds)
    end

    if priority ~= 0 then
        concat(priority_number_to_string(priority))
    end

    concat(description)

    return util.strip(result)
end

--- Checkboxes
-- @section

--- Return true/false if the task is done. If the line is not a task,
-- an error is raised. If the line does not have a checkbox, it is considered
-- undone.
-- @param line The task line.
-- @return Boolean.
function task.is_done(line)
    assert(task.is_task(line))

    -- determines whether the line is checked or not
    return head(line) == "[x]"
end

--- Mark a task as done.
-- If the line has no checkbox, one is added at the beginning.
-- @param line The task string.
-- @return The new task string.
function task.mark_done(line)
    line = task.ensure_checkbox(line)
    return "[x] " .. tail(line)
end

--- Mark a task as undone.
-- If the line has no checkbox, one is added at the beginning.
-- @param line The task string.
-- @return The new task string.
function task.mark_undone(line)
    line = task.ensure_checkbox(line)
    return "[ ] " .. tail(line)
end

--- Toggle a tasks checkmark.
-- If the line has no checkbox, one is added at the beginning.
-- @param line The task string.
-- @return The new task string.
function task.toggle_done(line)
    line = task.ensure_checkbox(line)
    if task.is_done(line) then
        return "[ ] " .. tail(line)
    else
        return "[x] " .. tail(line)
    end
end

--- Description and Tags
-- @section description

--- Retrieves the description part of a task string. This includes the tags.
-- @param line The task string.
-- @return The description part.
function task.get_description(line)
    local l = tail(line)
    l = task.remove_datespec(l)
    l = task.remove_priority(l)
    return l
end

--- Retrieves a table of all of the task's tags.
-- @param line The task string.
-- @return A table of tags, as strings, each with `#` prepended.
function task.get_tags(line)
    line = " " .. line .. " "
    local result = {}
    for match in line:gmatch("%s(#[%w-_]+)") do
        table.insert(result, match:lower())
    end
    return result
end

--- Retrieves the first tag, if it exists.
-- @param line The task string.
-- @return The first tag (with a `#` prepended), or `nil` if there is no tag.
function task.get_first_tag(line)
    local tags = task.get_tags(line)
    if #tags == 0 then
        return nil
    else
        return tags[1]
    end
end

--- Priority
-- @section priority

--- Replaces a priority string with a new priority string.
-- @param line The task string.
-- @param new_priority_string The new priority string.
-- @return The new task string.
local function replace_priority_string(line, new_priority_string)
    line = " " .. line .. " "

    local second_space = " "
    if new_priority_string == "" then
        second_space = ""
    end

    local new_line, _ = line:gsub(
        "%s(!+)%s",
        " " .. new_priority_string .. second_space
    )
    return util.strip(new_line)
end

--- Get the priority part of a task as a string of !s.
-- @param line The task string.
-- @return The priority as a string.
function task.get_priority_as_string(line)
    line = " " .. line .. " "
    local match = line:match("%s(!+)%s")
    return match
end

--- Get the priority of a task as a number from 0 to 2.
-- @param line The task string.
-- @return The priority.
function task.get_priority(line)
    -- add spaces to make mathing easier
    local match = task.get_priority_as_string(line)
    if match == nil then
        return 0
    else
        if #match > 2 then
            return 0
        else
            return #match
        end
    end
end

--- Remove the priority part from a task string.
-- @param line The task string.
-- @return The new task string, but without the priority.
function task.remove_priority(line)
    line = " " .. line .. " "
    line = replace_priority_string(line, "")
    return util.strip(line)
end

--- Set the priority of the task.
-- @param line The task string.
-- @param new_priority The new priority as a number from 0-2.
-- @return The new task string with the priority replaced.
function task.set_priority(line, new_priority)
    local old_priority = task.get_priority(line)
    local new_pstring = priority_number_to_string(new_priority)

    if old_priority == 0 then
        return util.strip(line) .. " " .. new_pstring
    else
        return replace_priority_string(line, new_pstring)
    end
end

--- Datespec
-- @section datespec

--- Retrieve the datespec as a DateSpec object. If the task string has no datespec,
-- this will return a "default" datespec with a do date of today.
-- @param line The task string.
-- @param today The date of today as a dateObject or string in YYYY-MM-DD format.
-- @return The DateSpec for the task.
function task.get_datespec_safe(line, today)
    assert(today ~= nil)
    local ds = task.get_datespec_as_string(line)
    -- this implicitly creates a DateSpec with a do-date of today if
    -- there is no datespec string present.
    return DateSpec:new(ds, today)
end

--- Retrieve the datespec as a string from the task string.
-- @param line The task string.
-- @return The datespec string (including angle brackets) or nil if there is
-- no datespec.
function task.get_datespec_as_string(line)
    return line:match("(<.*>)")
end

--- Helper function which replaces a datespec string with a new one.
local function replace_datespec_string(line, new_spec)
    local second_space = " "
    if new_spec == "" then
        second_space = ""
    end

    local new_line, _ = line:gsub("%s?(<.*>)%s*", " " .. new_spec .. second_space)
    return util.rstrip(new_line)
end

--- Replaces a datespec with an absolute datespec. If there is no datespec,
-- this leaves the task unchanged.
-- @param line The task line.
-- @param today The date of today as a string in YYYY-MM-DD format or a dateObject
function task.make_datespec_absolute(line, today)
    local ds = task.get_datespec_safe(line, today)
    if ds == nil then
        return line
    end
    return replace_datespec_string(line, ds:serialize(false))
end

--- Replaces an absolute datespec with a natural datespec. If there is no datespec,
-- this leaves the task unchanged.
-- @param line The task line.
-- @param today The date of today as a string in YYYY-MM-DD format or a dateObject
function task.make_datespec_natural(line, today)
    local ds = task.get_datespec_safe(line, today)
    if ds == nil then
        return line
    end
    return replace_datespec_string(line, ds:serialize(true))
end

--- Remove the datespec from a task string.
-- @param line The task string.
-- @return The new task string.
function task.remove_datespec(line)
    return util.strip(replace_datespec_string(line, ""))
end

--- Set the do date part of a task's datespec.
-- @param line The task string.
-- @param do_date The do date as a string.
-- @return The new tasks string.
function task.set_do_date(line, do_date)
    local new_ds = "<" .. do_date .. ">"
    if line:match("<.*>") == nil then
        return line .. " " .. new_ds
    else
        return replace_datespec_string(line, "<" .. do_date .. ">")
    end
end

function task.replace_datespec_with_next(line, today)
    if task.is_done(line) then
        return nil
    end

    local ds = task.get_datespec_safe(line, today)
    if ds.recur == nil then
        return nil
    end

    return replace_datespec_string(line, ds:next():serialize())
end

return task
