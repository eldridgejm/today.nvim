--- Parse a category header into its component pieces

local dates = require("today.core.dates")
local util = require("today.core.util")

local M = {}


local function parse_done_header(header)

    if not header:match("^done") then
        return nil
    end

    return { kind = "done" }

end


local function parse_do_date_header(header, working_date)

    local match = header:match("^<(.*)> ")
    if match == nil then
        return nil
    end

    local match_as_date = dates.parse(match, working_date)

    if match_as_date == nil then
        return nil
    end

    return {
        kind = "do_date",
        do_date = match_as_date
    }

end


local function parse_tag_header(header)

    local match = header:match("^#([%w-_]+) ")
    if match == nil then
        return nil
    end

    return {
        kind = "tag",
        tag = match
    }
end


local PARSERS = {
    parse_done_header,
    parse_do_date_header,
    parse_tag_header
}


local function decimate(header)
    local pieces = util.split(header, " | ")
    local head = pieces[1]
    table.remove(pieces, 1)
    for i, entry in ipairs(pieces) do
        pieces[i] = util.strip(entry)
    end
    return head, pieces
end


function M.parse(header, working_date)
    -- remove the "{{{"
    header = header:sub(1, -4)
    local head, extra = decimate(header)

    for _, parser in pairs(PARSERS) do
        local result = parser(header, working_date)
        if result ~= nil then

            result.head = head
            result.extra = extra
            return result
        end
    end

    return {
        kind = "unmatched",
        head = head,
        extra = extra
    }


end

return M
