local dates = require("today.core.dates")
local task = require("today.core.task")
local util = require("today.util")

local M = {}

-- A table of rules that are tried one by one when a new category is encountered.
-- When we see a new category, the rule is called with the title of the header. If the
-- rule returns nil, it means that the rule does not apply to that section. Otherwise,
-- it should return a function that accepts a task line and returns the updated task
-- line.
local RULES = {}

function RULES:add(rule)
    table.insert(self, rule)
end

-- done inferrer
RULES:add(function(title)
    if title == "done" then
        return function(t)
            return task.mark_done(t)
        end
    end
end)

-- future (k+ days from now) inferrer
RULES:add(function(title, options)
    local match = title:match("future %((%d+)%+ days from now%)")
    if match ~= nil then
        return function(t)
            -- this is a dummy working date; its value is not important
            local working_date = dates.DateObj:new(options.working_date)
            local ds = task.parse_datespec(t, working_date)
            if ds ~= nil and ds.do_date ~= nil then
                return t
            end

            return task.set_do_date(t, match .. " days from now")
        end
    end
end)

-- do-date inferrer
RULES:add(function(title, options)
    -- this is a dummy working date
    local working_date = options.working_date
    working_date = dates.DateObj:new(working_date)

    local date = dates.parse(title, working_date)

    if date ~= nil then
        return function(t)
            -- if a task in the today section has no datespec, don't give it one
            if date == working_date and task.get_datespec_as_string(t) == nil then
                return t
            end

            -- if the task already has a do date, don't give it one
            local ds = task.parse_datespec(t, working_date)
            if ds ~= nil and ds.do_date ~= nil then
                return t
            end

            return task.set_do_date(t, title)
        end
    end
end)

RULES:add(function(title)
    if util.startswith(title, "#") then
        return function(t)
            -- don't infer if there is already a tag
            if task.get_first_tag(t) ~= nil then
                return nil
            end

            return task.set_first_tag(t, title)
        end
    end
end)

function M.infer(lines, options)
    options = util.merge(options, {})

    assert(options.working_date ~= nil, "Must supply working date option")

    local current_title
    local new_lines = {}
    local task_updater
    for _, line in pairs(lines) do
        local title = line:match("-- ([^|]*).*{{{")
        local end_title = line == "-- }}}"

        if title ~= nil then
            current_title = util.strip(title)
            task_updater = util.first_non_nil(function(rule)
                return rule(current_title, options)
            end, RULES)
        end

        if end_title then
            current_title = nil
            task_updater = nil
        end

        if task.is_task(line) and task_updater then
            local new_line = task_updater(line)
            if new_line ~= nil then
                line = new_line
            end
        end

        table.insert(new_lines, line)
    end

    return new_lines
end

return M
