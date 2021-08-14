--- Display information to the user.
-- An informer is a function that, when called without arguments, returns
-- a list of lines that will be injected into the buffer as comments. Each line should
-- have a "--" preprended in order to make it a comment.

local informers = {}

--- Makes an informer that displays basic information.
-- @param info A table with information to display. Should have keys:
--  "working_date", "categorizer" (a string), and "filter_tags" (a list of strings).
-- @return The informer function.
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
