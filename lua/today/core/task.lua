util = require('today.core.util')
DateSpec = require('today.core.datespec')


task = {}


function head(line)
    -- the checkbox part of the line
    return task.ensure_checkbox(line):sub(1, 3)
end


function tail(line)
    -- the "contents" of the line
    return task.ensure_checkbox(line):sub(5)
end


function task.ensure_checkbox(line)
    local start = string.sub(line, 1, 3)
    if not ((start == "[ ]") or (start == "[x]")) then
        -- strip whitespace on the left
        line = line:match( "^%s*(.+)" )
        line = "[ ] " .. line
    end
    return line
end


function task.normalize(line)
    -- if the line does not start with a checkbox [ ], [x], add [ ]
    -- move the datespec string to after the checkbox
    -- move the priority to after the datespec
    -- finally, add the task definition

    local start = string.sub(line, 1, 3)
    if not ((start == "[ ]") or (start == "[x]")) then
        start = "[ ]"
    end

    local ds = task.get_datespec_as_string(line)
    local priority = task.get_priority(line)
    local description = task.get_description(line)

    local result = start
    local concat = function(s) result = result .. " " .. s end

    if ds ~= nil then
        concat(ds)
    end

    if priority ~= 0 then
        concat(priority_as_string(priority))
    end

    concat(description)

    return util.strip(result)

end


function task.is_task(line)
    local is_comment = line:sub(1, 2) == '--'
    local is_blank = not (line:match("^%s*$") == nil)
    return not (is_comment or is_blank)
end


function task.get_description(line)
    local l = tail(line)
    l = task.remove_datespec(l)
    l = task.remove_priority(l)
    return l
end


function task.is_done(line)
    if not task.is_task(line) then
        return line
    end

    -- determines whether the line is checked or not
    return head(line) == "[x]"
end


function task.mark_done(line)
    if not task.is_task(line) then
        return line
    end

    local line = task.ensure_checkbox(line)
    return "[x] " .. tail(line)
end


function task.mark_undone(line)
    if not task.is_task(line) then
        return line
    end

    local line = task.ensure_checkbox(line)
    return "[ ] " .. tail(line)
end


function task.toggle_done(line)
    if not task.is_task(line) then
        return line
    end

    local line = task.ensure_checkbox(line)
    if task.is_done(line) then
        return "[ ] " .. tail(line)
    else
        return "[x] " .. tail(line)
    end
end


function priority_as_string(priority)
    if priority == 0 then 
        return ""
    else
        local lookup = {"!", "!!"}
        return lookup[priority]
    end
end


function replace_priority_string(line, new_priority)
    line = " " .. line .. " "

    local second_space = " "
    if new_priority == "" then
        second_space = ""
    end

    local new_line, number_of_matches = line:gsub("%s(!+)%s", " " .. new_priority .. second_space)
    return util.strip(new_line)
end


function task.get_priority_as_string(line)
    local line = ' ' .. line .. ' '
    local match = line:match('%s(!+)%s')
    return match
end


function task.get_priority(line)
    -- add spaces to make mathing easier
    local match = task.get_priority_as_string(line)
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



function task.remove_priority(line)
    line = " " .. line .. " "
    line = replace_priority_string(line, "")
    return util.strip(line)
end


function task.set_priority(line, new_priority)
    if not task.is_task(line) then
        return line
    end

    local old_priority = task.get_priority(line)

    -- add space to make matching easier
    line = util.strip(line) .. ' '
    local new_line = ''

    if old_priority == 0 then
        new_line = line .. priority_as_string(new_priority)
    else
        local old_pstring = priority_as_string(old_priority)
        local new_pstring = priority_as_string(new_priority)
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


function task.get_datespec(line, today)
    local ds = task.get_datespec_as_string(line)
    return DateSpec:new(ds, today)
end


function task.get_datespec_as_string(line, today)
    return line:match("(<.*>)")
end


function replace_datespec_string(line, new_spec)
    local second_space = " "
    if new_spec == "" then
        second_space = ""
    end

    local new_line, number_of_matches = line:gsub("%s?(<.*>)%s*", " " .. new_spec .. second_space)
    return util.rstrip(new_line)
end


function task.make_datespec_absolute(line, today)
    local ds = task.get_datespec(line, today)
    return replace_datespec_string(line, ds:serialize(false))
end


function task.make_datespec_natural(line, today)
    local ds = task.get_datespec(line, today)
    return replace_datespec_string(line, ds:serialize(true))
end


function task.remove_datespec(line)
    return util.strip(replace_datespec_string(line, ""))
end


function task.set_do_date(line, do_date)
    local new_ds = '<' .. do_date .. '>'
    if line:match("<.*>") == nil then
        return line .. ' ' .. new_ds
    else
        return replace_datespec_string(line, '<' .. do_date .. '>')
    end
end


return task
