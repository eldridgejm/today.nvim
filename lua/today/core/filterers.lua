--- Filter tasks before categorization.
-- A filterer is a function that accepts a task and returns True or False.
-- If True, the task will be removed from the set of tasks before categorization,
-- and therefore "hidden".
--

local task = require("today.core.task")
local util = require("today.util")

local filterers = {}

--- Creates a filterer that filters by tag.
-- @param options A table of options. The valid options are:
--
-- `tags`: (list of string) A list of tags (each with prepended `#`) that should
-- be removed. If this is empty, no tasks are removed.
-- @return The filterer.
function filterers.tag_filterer(options)
    options = util.merge(options, {
        tags = {},
    })

    return function(t)
        local task_tags = task.get_tags(t)
        for _, tag in pairs(task_tags) do
            if util.contains_value(options.tags, tag) then
                return true
            end
        end

        if (#task_tags == 0) and util.contains_value(options.tags, "none") then
            return true
        end

        return false
    end
end

return filterers
