--- Parse a buffer into a tree of tasks.

local taskparser = require("today.core.taskparser")
local util = require("today.core.util")
local linemap = require("today.core.linemap")
local inferrer = require("today.core.bufferparser._inferrer")

local M = {}

local function is_comment_line(line)
    return util.startswith(line, "--")
end

local function is_start_of_task(line)
    return util.startswith(line, "[ ]") or util.startswith(line, "[x]")
end

local function is_category_header(line)
    return util.startswith(line, "{{{")
end

local function is_whitespace(line)
    return line:match("^%s*$")
end

local function is_category_footer(line)
    return util.startswith(line, "}}}")
end


local function consume_while(predicate, lines, line_no)
    line_no = line_no + 1
    local size = 1
    while line_no <= #lines and predicate(lines[line_no]) do
        line_no = line_no + 1
        size = size + 1
    end
    return line_no, size
end


local function consume_task(lines, line_no)
    local block = { kind = "task" }

    local function is_task_line_continuation(line)
        return util.startswith(line, "    ") or line == ""
    end

    line_no, block.size = consume_while(is_task_line_continuation, lines, line_no)

    return line_no, block
end


local function consume_category_header(lines, line_no)
    return line_no + 1, { size = 1, kind = "category_header" }
end

local function consume_category_footer(lines, line_no)
    return line_no + 1, { size = 1, kind = "category_footer" }
end


local function consume_comment(lines, line_no)
    local block = { kind = "comment" }
    line_no, block.size = consume_while(is_comment_line, lines, line_no)
    return line_no, block
end


local function consume_whitespace(lines, line_no)
    local block = { kind = "whitespace" }
    line_no, block.size = consume_while(is_whitespace, lines, line_no)
    return line_no, block
end

local function consume(lines)
    local blocks = {}

    local line_no = 1
    while line_no <= #lines do
        local line = lines[line_no]

        if is_category_header(line) then
            line_no, block = consume_category_header(lines, line_no)
        elseif is_category_footer(line) then
            line_no, block = consume_category_footer(lines, line_no)
        elseif is_comment_line(line) then
            line_no, block = consume_comment(lines, line_no)
        elseif is_whitespace(line) then
            line_no, block = consume_whitespace(lines, line_no)
        else
            line_no, block = consume_task(lines, line_no)
        end

        table.insert(blocks, block)
    end

    return blocks
end


local function build_line_map(lines)
    local blocks = consume(lines)
    local root = { children = {}, kind = "root" }

    local parent = root

    for _, block in pairs(blocks) do
        if block.kind == "category_header" then
            -- if we are already nested underneath a category, we shouldn't go
            -- any further; make this an ignored_category_header block
            if parent.kind == "category" then
                block.kind = "ignored_category_header"
                table.insert(parent.children, block)
            else
                local section_node = { children = { block }, kind = "category" }
                table.insert(parent.children, section_node)
                section_node.parent = parent
                parent = section_node
            end
        elseif block.kind == "category_footer" then
            -- we we aren't in a category, this makes no sense -- make this an
            -- ignored_category_footer block
            if parent.kind ~= "category" then
                block = "ignored_category_footer"
                table.insert(parent.children, block)
            else
                table.insert(parent.children, block)
                parent = parent.parent
            end
        else
            table.insert(parent.children, block)
        end
    end

    return root
end


local function build_task_tree_node(lines, lmap_node, parent, working_date)
    local node

    if lmap_node.kind ~= "task" and lmap_node.kind ~= "category" and lmap_node.kind ~= "root" then
        return
    end

    if lmap_node.kind == "task" then
        local task_lines = util.slice(lines, lmap_node.start_line_no, lmap_node.end_line_no)
        local task_text = table.concat(task_lines, "\n")
        node = taskparser.parse(task_text, "2022-02-20")
        node = inferrer.infer_defaults(node, working_date)
        table.insert(parent.children, node)
        lmap_node.task = node
    elseif lmap_node.kind == "category" then
        node = { children = {} }
        for _, lmap_child in pairs(lmap_node.children) do
            build_task_tree_node(lines, lmap_child, node, working_date)
        end
        table.insert(parent.children, node)
    end

end


local function build_task_tree(lines, lmap_root, working_date)
    local root = { children = {} }
    for _, lmap_child in pairs(lmap_root.children) do
        build_task_tree_node(lines, lmap_child, root, working_date)
    end
    return root
end


local function calculate_spans(lmap)
    for start_line_no, node in linemap.iter_blocks(lmap) do
        local end_line_no = start_line_no + node.size - 1
        node.start_line_no = start_line_no
        node.end_line_no = end_line_no
    end
end


function M.parse(lines, working_date)
    local lmap = build_line_map(lines)
    calculate_spans(lmap)
    local tasktree = build_task_tree(lines, lmap, working_date)
    return lmap, tasktree
end


return M
