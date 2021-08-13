--- Filterers.
-- @section

local task = require("today.core.task")
local util = require("today.util")

local filterers = {}

function filterers.make_filterer(options, filter)
    local Filterer = {
        options = options,
    }

    local meta = {}

    function meta.__call(self, t)
        return filter(self, t)
    end

    setmetatable(Filterer, meta)

    return Filterer
end

--- Filters by tags.
-- @param target_tags A list of the tags to include.
function filterers.tag_filterer(options)
    local options = util.merge(options, {
        tags = {},
    })

    return filterers.make_filterer(options, function(self, t)
        local task_tags = task.get_tags(t)
        for _, tag in pairs(task_tags) do
            if util.contains_value(self.options.tags, tag) then
                return true
            end
        end

        if (#task_tags == 0) and util.contains_value(self.options.tags, "none") then
            return true
        end

        return false
    end)
end

return filterers
