--- Find and extract links of the form [[link/to/somewhere]].

local M = {}

function M.extract_link(line, column)
    -- find the location of:
    --
    --  next start
    --  next end
    --  prev start
    --  prev end
    --
    --  There are seven cases:
    --
    -- xxxxx[[xxxxx]]xxxxx[[xxxxx]]xxxxx
    --   ^  ^   ^   ^  ^      ^      ^
    --   A  B   C   D  E      F      G
    --
    local start_pattern = "[["
    local end_pattern = "]]"

    local function find_next_pair(starting_at)
        local start_ix = line:find(start_pattern, starting_at, true)
        local end_ix = line:find(end_pattern, start_ix, true)
        return start_ix, end_ix
    end

    local cursor = 1
    while cursor <= #line do
        local start_ix, end_ix = find_next_pair(cursor)
        if start_ix == nil or end_ix == nil then
            return nil
        end

        -- end_ix is the index of the *beginning* of the end pattern,
        -- so we offset
        if start_ix <= column and end_ix + #end_pattern - 1 >= column then
            return line:sub(start_ix + #start_pattern, end_ix - #end_pattern + 1)
        end

        cursor = start_ix + 1
    end
end

return M
