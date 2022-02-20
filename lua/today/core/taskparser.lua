--- Parses a textual representation of a task into a Task object.

local util = require("today.core.util")
local dates = require("today.core.dates")
local Task = require("today.core.task").Task
local MALFORMED = require("today.core.task").MALFORMED

local M = {}

-- helper functions ------------------------------------------------------------

--- Check if the checkbox at the beginning of the task string is checked or not.
-- If there is no checkbox, this will return "false", as if there is a checbox
-- that is unchecked.
-- @param taskstr The task string.
-- @return true or false, depending on if the task is checked off
local function is_checkbox_checked(taskstr)
    local head = taskstr:sub(1, 3)

    if head == "[x]" then
        return true
    else
        -- this also handles the case where there is no checkbox
        return false
    end
end

--- Removes the checkbox from the task string, if present.
-- @param taskstr The task as a string.
-- @return The task string, without the checkbox.
local function remove_checkbox(taskstr)
    return taskstr:gsub("^%[[x ]%]", "")
end

--- Get a list of all of the task's tags.
-- This preserves tag order. If there are no tags, an empty list is returned.
-- Tags are returned without a leading #.
-- @param taskstr The task as a string.
-- @return list of tags as strings.
local function get_tags(taskstr)
    taskstr = " " .. taskstr .. " "
    local result = {}
    local seen = {}
    for match in taskstr:gmatch("%s#([%w-_]+)") do
        match = match:lower()

        if not seen[match] then
            table.insert(result, match)
            seen[match] = true
        end
    end
    return result
end

--- Removes the tags from the task string, if present
-- @param taskstr The task as a string.
-- @return The task string without the tags.
local function remove_tags(taskstr)
    local taskstr = " " .. taskstr .. " "
    return taskstr:gsub("%s(#[%w-_]+)", "")
end

--- Get the priority of a task as a number from 0 to 2.
-- If no priority is provided, a default of 0 is returned.
-- @param taskstr The task string.
-- @return The priority as a number: 0, 1, or 2.
local function get_priority(taskstr)
    -- add spaces to make mathing easier
    taskstr = " " .. taskstr .. " "
    local match = taskstr:match("%s(!+)%s")

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
-- @param taskstr The task string.
-- @return The new task string, but without the priority.
local function remove_priority(taskstr)
    taskstr = " " .. taskstr .. " "
    return taskstr:gsub("%s(!+)%s", "")
end

--- Retrieves the parts of a datespec as strings.
-- @param taskstr The task string.
-- @return A table with keys `do_date` and `recur_pattern`. If there is no
-- datespec, returns nil. If there is no do_date, but there is a recur pattern,
-- the do_date will be nil. If there is no recur pattern, but there is a do
-- date, then the recur_pattern will be nil.
local function get_datespec_string_parts(taskstr)
    taskstr = " " .. taskstr .. " "
    local datespec = taskstr:match("(<.*>)")

    if datespec == nil then
        return nil
    end

    local function strip_if_not_nil(s)
        if s == nil then
            return s
        else
            return util.strip(s)
        end
    end

    local do_date = datespec:match("<([^%+]*)%+?.*>")
    local recur_pattern = datespec:match("<[^%+]*%+(.*)>")

    if do_date == "" then
        do_date = nil
    end
    return {
        do_date = strip_if_not_nil(do_date),
        recur_pattern = strip_if_not_nil(recur_pattern),
    }
end

--- Retrieve the parsed parts of the datespec.
--
-- If the datespec is missing, this will infer a do_date of infinite_past, and
-- a recur_pattern of nil.
--
-- If the datespec is malformed, this will return MALFORMED for both the do_date
-- and the recur_pattern.
--
-- The following assumes there is a datespec:
--
-- If there is a do_date but no recur spec, the recur spec is set to nil.
--
-- If there is no do_date, but there *is* a recur spec, the do date is set to
-- the next day in the sequence of dates given by the recur spec, using the
-- day before the working date as a starting point.
--
-- @param taskstr The task as a string.
-- @param working_date The working date as a DateObj (or a yyyy-mm-dd string).
-- @return A table with two keys: do_date and recur_pattern, whose values are set
-- as per the above.
local function parse_datespec(taskstr, working_date)
    assert(working_date ~= nil, "Must supply working date")
    working_date = dates.DateObj:new(working_date)

    local parts = get_datespec_string_parts(taskstr)

    if parts == nil then
        -- there was no datespec at all
        return {
            do_date = dates.DateObj:infinite_past(),
            recur_pattern = nil,
        }
    end

    -- try to parse the do_date; it could be malformed
    if parts.do_date ~= nil then
        parts.do_date = dates.parse(parts["do_date"], working_date)

        if parts.do_date == nil then
            return {
                do_date = MALFORMED,
                recur_pattern = MALFORMED,
            }
        end
    end

    if parts.recur_pattern ~= nil then
        if not dates.validate_recur_pattern(parts.recur_pattern) then
            return {
                do_date = MALFORMED,
                recur_pattern = MALFORMED,
            }
        end
    end

    -- at this point, at least one of the parts of the datespec has been parsed
    -- successfully. it is possible that one of the other parts was not provided

    if parts.do_date == nil and parts.recur_pattern ~= nil then
        -- the do_date wasn't provided, but a recur pattern was
        return {
            do_date = dates.next(working_date:add_days(-1), parts.recur_pattern),
            recur_pattern = parts.recur_pattern,
        }
    else
        -- the do_date was provided, and a recur pattern was or wasn't (doesn't
        -- matter which)
        return parts
    end
end

--- Remove the datespec from a task string.
-- @param taskstr The task string.
-- @return The task string without the datespec.
local function remove_datespec(taskstr)
    taskstr = " " .. taskstr .. " "
    return taskstr:gsub("%s?(<.*>)%s*", "")
end

--- Retrieve the description from a task string.
-- @param taskstr The task string.
-- @return The description part of a task string.
local function get_description(taskstr)
    local t
    t = remove_checkbox(taskstr)
    t = remove_tags(t)
    t = remove_priority(t)
    t = remove_datespec(t)
    return util.strip(t)
end

-- parse -----------------------------------------------------------------------

--- Parses the text representation of a task into a Task object.
--
-- The following defaults are enforced:
--
--  - If a task has no checkbox, it is assumed to be undone.
--  - If a task has no explicity priority, it is assumed to have a priority of 0.
--  - If a task has no datespec, a `do_date` of the infinite past is assumed, and
--    a `recur_pattern` of nil is assigned.
--  - If a task has a datespec with a `do_date` but no `recur_pattern`, a
--  `recur_pattern` of
--    nil is assigned.
--  - If a task has a datespec with no `do_date` but a `recur_pattern`, a do date is
--    assigned by taking the next date in the sequence defined by the recur
--    patter, starting with the `working_date`. For example, if the working date is
--    Friday, and the `recur_pattern` is "every monday", the do date is set to the
--    coming monday. If the `recur_pattern` were "every friday", the `do_date` would be
--    set to the working date.
--
-- If the do date or the recur patter are malformed, both are given a value of
-- `core.task.MALFORMED`.
--
-- @param taskstr The task as a string.
-- @param working_date A DateObj representing the current date.
-- @return A `Task` object.
function M.parse(taskstr, working_date)
    assert(working_date ~= nil, "Must supply working date.")
    working_date = dates.DateObj:new(working_date)

    local datespec = parse_datespec(taskstr, working_date)

    return Task:new({
        done = is_checkbox_checked(taskstr),
        description = get_description(taskstr),
        tags = get_tags(taskstr),
        priority = get_priority(taskstr),
        do_date = datespec.do_date,
        recur_pattern = datespec.recur_pattern,
    })
end

return M
