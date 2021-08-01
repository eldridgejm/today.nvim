--- Functions for working with individual task strings.

local util = require("today.util")
local dates = require("today.core.dates")

local DEFAULT_TO_NATURAL_OPTIONS = {
    default_format = "YYYY-MM-DD",
}

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
-- Finally, add the task description, moving all tags to the end.
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
    local tags = task.get_tags(line)

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

    for _, tag in pairs(tags) do
        concat(tag)
    end

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

--- Mark a task as done with a natural do date of the working date.
-- If the line has no checkbox, one is added at the beginning.
-- @param line The task string.
-- @param do_date The date that will be used as the do date. DateObj or string
-- in YYYY-MM-DD format..
-- @param working_date The current working date. If this is nil, this is assumed
-- to be the same as do_date, since that will be the most common case.
-- @return The new task string.
function task.mark_done_with_do_date(line, do_date, working_date)
    do_date = dates.DateObj:new(do_date)

    if working_date == nil then
        working_date = do_date
    end

    line = task.ensure_checkbox(line)
    line = "[x] " .. tail(line)

    do_date = dates.to_natural(do_date, working_date)
    return task.normalize(task.set_do_date(line, tostring(do_date)))
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
        return task.mark_undone(line)
    else
        return task.mark_done(line)
    end
end

--- Toggle a tasks checkmark and adds a do date.
-- If the line has no checkbox, one is added at the beginning.
-- @param line The task string.
-- @param do_date The date that will be used as the do date. DateObj or string.
-- @return The new task string.
function task.toggle_done_with_do_date(line, do_date)
    line = task.ensure_checkbox(line)
    if task.is_done(line) then
        return task.mark_undone(line)
    else
        return task.mark_done_with_do_date(line, do_date)
    end
end
--- Description and Tags
-- @section description

--- Retrieves the description part of a task string. This includes the tags.
-- @param line The task string.
-- @return The description part.
function task.get_description(line)
    local l = tail(line)
    l = task.remove_tags(l)
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
        if not util.contains_value(result, match:lower()) then
            table.insert(result, match:lower())
        end
    end
    return result
end

--- Remove the first tag from a task string.
-- If there are no tags, nothing is done.
-- @param line The task string.
-- @return The new task string, but without the first tag.
function task.remove_first_tag(line)
    line = " " .. line .. " "

    return util.strip(line:gsub("%s+(#[%w-_]+)%s+", " "))
end

--- Remove the tags from a task string.
-- @param line The task string.
-- @return The new task string, but without the tags.
function task.remove_tags(line)
    while true do
        local result = task.remove_first_tag(line)
        if result == line then
            return result
        end
        line = result
    end
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

--- Set the first tag. If there are no tags, this is added to the end. If there
-- are existing tags, they are preserved in their original order. If the tag to be
-- added already exists, it is not duplicated, but it is moved to the front of the
-- tag list. After this call, tags that were scattered around the task will now all
-- be at the end.
-- @param line The task line.
-- @param tag The new tag. It does not need to start with a "#", though it may.
-- It will be case-normalized.
-- @param The new task line with the new tag added as described above.
function task.set_first_tag(line, tag)
    if not util.startswith(tag, "#") then
        tag = "#" .. tag
    end

    local tags = task.get_tags(line)
    local new_line = task.remove_tags(line)
    new_line = new_line .. " " .. tag
    for _, old_tag in pairs(tags) do
        new_line = new_line .. " " .. old_tag
    end
    return task.normalize(new_line)
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

--- Retrieve the datespec as a string from the task string.
-- @param line The task string.
-- @return The datespec string (including angle brackets) or nil if there is
-- no datespec.
function task.get_datespec_as_string(line)
    line = " " .. line .. " "
    return line:match("(<.*>)")
end

function task.get_datespec_string_parts(line)
    local datespec = task.get_datespec_as_string(line)
    if datespec == nil then
        return nil
    end

    local contents = datespec:match("<(.*)>")
    local groups = util.map(util.strip, util.split(contents, "+"))
    return { do_date = groups[1], recur_pattern = groups[2] }
end

--- Retrieve the parsed parts of the datespec, if it exists.
-- @param line The task string.
-- @param working_date The working date as a DateObj or a string in YYYY-MM-DD format.
-- @return A table of the parts of the datespec, including a "do_date" as a DateObj
-- and a "recur_pattern" as a string. If the datespec has no recur pattern, this
-- entry of the table will be nil. If the task's datespec is malformed, the do_date 
-- will be nil. If the task itself has no datespec, nil is returned.
function task.parse_datespec(line, working_date)
    assert(working_date ~= nil)

    local parts = task.get_datespec_string_parts(line)
    if parts == nil then
        return nil
    end

    return {
        do_date = dates.from_natural(parts["do_date"], working_date),
        recur_pattern = parts["recur_pattern"],
    }
end

--- Retrieve the parsed parts of the datespec. As opposed to the "regular" parse_datespec,
-- this will not return nil if there is no datespec, instead, it will return a table
-- where the "do_date" is a DateObj representing the infinite past, and the recur pattern
-- is nil. If the datespec is malformed, the entire return value will be nil. Otherwise, 
-- the behavior is the same.
function task.parse_datespec_safe(line, working_date)
    local ds = task.parse_datespec(line, working_date)

    if ds == nil then
        return { do_date = dates.DateObj:infinite_past(), recur_pattern = nil }
    elseif ds.do_date == nil then
        return nil
    else
        return ds
    end
end

--- Helper function which replaces a datespec string with a new one.
local function replace_datespec_string(line, new_spec)
    if task.get_datespec_as_string(line) == nil then
        line = line .. " < >"
    end

    local second_space = " "
    if new_spec == "" then
        second_space = ""
    end

    local new_line, _ = line:gsub("%s?(<.*>)%s*", " " .. new_spec .. second_space)
    return util.rstrip(new_line)
end

--- Given datespec parts, replaces the current datespec with the new datespec.
-- @param line The task line.
-- @param datespec A table of datespec parts as strings. These will replace the previous
-- datespec parts verbatim.
-- @return The new task line with datespec replaced. If there was originally no datespec,
-- one is inserted.
function task.replace_datespec_string_parts(line, datespec)
    local recur_string
    if datespec.recur_pattern == nil then
        recur_string = ""
    else
        recur_string = " +" .. datespec.recur_pattern
    end

    local new_datespec = "<" .. datespec.do_date .. recur_string .. ">"
    return replace_datespec_string(line, new_datespec)
end

--- Replaces a datespec with an absolute datespec. If there is no datespec,
-- or the datespec is malformed this leaves the task unchanged. If the datespec
-- is <someday>, this leaves it unchanged as well.
-- @param line The task line.
-- @param working_date The date of working_date as a string in YYYY-MM-DD format
function task.make_datespec_absolute(line, working_date)
    local ds = task.parse_datespec(line, working_date)
    if ds == nil or ds.do_date == nil or ds.do_date == dates.DateObj:infinite_future() then
        return line
    end

    ds.do_date = tostring(ds.do_date)
    return task.replace_datespec_string_parts(line, ds)
end

--- Replaces an absolute datespec with a natural datespec. If there is no datespec,
-- this leaves the task unchanged.
-- @param line The task line.
-- @param working_date The date of working_date as a string in YYYY-MM-DD format
-- @param to_natural_options An options dictionary for dates.to_natural
function task.make_datespec_natural(line, working_date, to_natural_options)
    if to_natural_options == nil then
        to_natural_options = DEFAULT_TO_NATURAL_OPTIONS
    end

    local ds = task.parse_datespec(line, working_date)
    if ds == nil or ds.do_date ==nil then
        return line
    end

    ds.do_date = dates.to_natural(ds.do_date, working_date, to_natural_options)
    return task.replace_datespec_string_parts(line, ds)
end

--- Remove the datespec from a task string.
-- @param line The task string.
-- @return The new task string.
function task.remove_datespec(line)
    return util.strip(replace_datespec_string(line, ""))
end

--- Remove the recur pattern from a task string.
-- If there was no recur pattern or no datespec, the line is simply returned.
-- @param line The task string.
-- @return The new task string.
function task.remove_recur_pattern(line)
    local old_ds = task.get_datespec_string_parts(line)
    if old_ds == nil then
        return line
    end
    old_ds.recur_pattern = nil
    return task.replace_datespec_string_parts(line, old_ds)
end

--- Set the do date part of a task's datespec.
-- If there was no datespec, a datespec is added.
-- @param line The task string.
-- @param do_date The do date as a string. This will replace the do date part of
-- the datespec verbatim. For instance, if "working_date" is given, the new datespec will
-- be <working_date ...>
-- @return The new task string. The recur spec, if any, is preserved.
function task.set_do_date(line, do_date)
    local old_ds = task.get_datespec_string_parts(line)
    if old_ds == nil then
        old_ds = { do_date = nil, recur_pattern = nil }
    end
    return task.replace_datespec_string_parts(
        line,
        { do_date = do_date, recur_pattern = old_ds.recur_pattern }
    )
end

--- Set the recur_pattern part of a task's datespec.
-- If there was no datespec, a datespec is added.
-- @param line The task string.
-- @param recur_pattern The do date as a string. This will replace the do date part of
-- the datespec verbatim. For instance, if "working_date" is given, the new datespec will
-- be <working_date ...>
-- @return The new task string. The recur spec, if any, is preserved.
function task.set_recur_pattern(line, recur_pattern)
    local old_ds = task.get_datespec_string_parts(line)
    if old_ds == nil then
        return nil
    end
    return task.replace_datespec_string_parts(
        line,
        { do_date = old_ds.do_date, recur_pattern = recur_pattern }
    )
end

--- Replaces a recurring task's datespec with the next in the sequence.
-- If the the task is done, this returns nil.
-- If the task is not recurring, this returns nil.
-- @param line The task string.
-- @param working_date The working date as a string in YYYY-MM-DD format.
-- @param to_natural_options A dictionary of options for core.dates.to_natural
-- @return The new task string with the datespec replaced (or nil, see above).
function task.replace_datespec_with_next(line, working_date, to_natural_options)
    if task.is_done(line) then
        return nil
    end

    if to_natural_options == nil then
        to_natural_options = DEFAULT_TO_NATURAL_OPTIONS
    end

    local ds = task.parse_datespec_safe(line, working_date)
    if ds.recur_pattern == nil then
        return nil
    end

    local new_do_date = dates.next(ds.do_date, ds.recur_pattern)
    local new_do_date_string = dates.to_natural(
        new_do_date,
        working_date,
        to_natural_options
    )

    return task.replace_datespec_string_parts(
        line,
        { do_date = new_do_date_string, recur_pattern = ds.recur_pattern }
    )
end

--- "Paint" a recur pattern over a list of tasks.
-- This iterates through a sequence of datespecs, assigning each to the next task
-- in the list.
-- @param lines The task lines as a list.
-- @param recur The recur pattern.
-- @param working_date The working date.
-- @return A list of the tasks with new datespecs.
function task.paint_recur_pattern(lines, recur, working_date)
    local cursor_date = dates.DateObj:new(working_date):add_days(-1)
    lines = util.filter(task.is_task, lines)

    local result = {}
    for _, line in ipairs(lines) do
        cursor_date = dates.next(cursor_date, recur)
        local new_line = task.set_do_date(line, tostring(cursor_date))
        new_line = task.remove_recur_pattern(new_line)
        table.insert(result, task.normalize(new_line))
    end

    return result
end

return task
