--- Filterers.
-- @section

local task = require('today.core.task')
local util = require('today.util')

local filterers = {}

--- Filters by tags.
-- @param target_tags A list of the tags to include.
function filterers.tag_filterer(target_tags)
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


return filterers
