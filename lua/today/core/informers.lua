--- Informers.
-- @section

local informers = {}

--- Displays basic information.
-- @param info A table with information to display. Should have keys:
--  "working_date", "categorizer" (a string), and "filter_tags" (a list of strings).
function informers.basic_informer(info)
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

return informers
