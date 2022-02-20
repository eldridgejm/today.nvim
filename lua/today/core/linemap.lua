--- Describe the hierarchy of a collection of lines.

local util = require('today.core.util')

local M = {}

function M.find_line(root, line_no)
    for start_line_no, node in M.iter_blocks(root) do
        if line_no >= start_line_no then
            local end_line_no = start_line_no + node.size - 1
            if line_no <= end_line_no then
                return node
            end
        end
    end

    -- we are out of bounds
    return nil
end


function M.size(node)
    if node.children == nil then
        return node.size
    else
        local s = 0
        for _, child in ipairs(node.children) do
            s = s + M.size(child)
        end
        return s
    end
end


function M.first_block_successor(node)
    for node in util.preorder_traversal(node) do
        if node.children == nil then
            return node
        end
    end
end

local function starting_line_number(root, node)
    -- find the starting line by iterating over blocks until we find the
    -- first block successor of this node
    local starting_block = M.first_block_successor(node)
    for start_line_no, node in M.iter_blocks(root) do
        if node == starting_block then
            return start_line_no
        end
    end
end


function M.span(root, node)
    local start_line_no = starting_line_number(root, node)
    local end_line_no = start_line_no + M.size(node) - 1
    return start_line_no, end_line_no
end


--- iterate over line_no, node pairs
function M.iter_blocks (root)
    local traversal = util.preorder_traversal(root)
    local next_line_no = 1

    local function iterator ()
        -- traverse until we find a node with nonzero lines
        while true do
            local cur_line_no = next_line_no
            local node = traversal()

            if node == nil then
                return nil, nil
            end

            if node.size ~= nil then
                next_line_no = next_line_no + node.size
                return cur_line_no, node
            end
        end
    end

    return iterator

end


return M
