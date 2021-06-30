util = require('today.core.util')


task = {}



function head(line)
    -- the checkbox part of the line
    return task.ensure_checkbox(line):sub(1, 3)
end


function tail(line)
    -- the "contents" of the line
    return task.ensure_checkbox(line):sub(5)
end


function task.is_checked(line)
    -- determines whether the line is checked or not
    return head(line) == "[x]"
end


function task.toggle_checkbox(line)
    local line = task.ensure_checkbox(line)
    if task.is_checked(line) then
        return "[ ] " .. tail(line)
    else
        return "[x] " .. tail(line)
    end
end


function task.get_priority(line)
    -- add spaces to make mathing easier
    local line = ' ' .. line .. ' '
    local match = line:match('%s(!+)%s')
    if match == nil then
        return 0
    else
        if #match > 2 then
            return 0
        else
            return #match
        end
    end
end


function task.priority_as_string(priority)
    if priority == 0 then 
        return ""
    else
        local lookup = {"!", "!!"}
        return lookup[priority]
    end
end


function task.set_priority(line, new_priority)
    local old_priority = task.get_priority(line)

    -- add space to make matching easier
    line = util.strip(line) .. ' '
    local new_line = ''

    if old_priority == 0 then
        new_line = line .. task.priority_as_string(new_priority)
    else
        local old_pstring = task.priority_as_string(old_priority)
        local new_pstring = task.priority_as_string(new_priority)
        local pattern = "%s+(" .. old_pstring .. ")%s+"

        local replacement = ""
        if new_priority == 0 then
            replacement = " "
        else
            replacement = " " .. new_pstring .. " "
        end

        new_line = line:gsub(pattern, replacement)
    end

    return util.strip(new_line)
end


function task.transform(lines)
    local result = {}
    local groups = {}
    groups['undone'] = {}
    groups['done'] = {}

    for _, line in pairs(lines) do
        if task.is_checked(line) then
            table.insert(groups['done'], line)
        else
            table.insert(groups['undone'], line)
        end
    end

    for _, line in pairs(groups['undone']) do
        table.insert(result, line)
    end

    for _, line in pairs(groups['done']) do
        table.insert(result, line)
    end

    return result
end


return task
