local infer = function(lines)
    if components.inferrer == nil then
        return lines
    end

    local current_header = nil
    local new_lines = {}
    for _, line in pairs(lines) do
        local header = line:match("-- (.*) %(%d+%) {{{")
        local end_header = line == "-- }}}"

        if header ~= nil then
            current_header = header
        end

        if end_header then
            current_header = nil
        end

        if task.is_task(line) then
            local new_line = components.inferrer(line, current_header)
            if new_line ~= nil then
                line = new_line
            end
        end

        table.insert(new_lines, line)
    end

    return new_lines
end

local do_date_inferrer = function(t, header)
    if header == "done" then
        return task.mark_done(t)
    end

    if header == nil then
        return nil
    end

    if not util.contains_value(order, header) then
        return nil
    end

    if task.parse_datespec(t, working_date) ~= nil then
        return nil
    end

    local do_date
    header = remove_date_from_header(header)
    if header == "today" then
        -- tasks without datespecs (such as this one) already appear under today.
        -- plus, this prevents the jarring situation where we switch from tag categorizer
        -- to date categorizer, and all of the things without a datespec immediately are
        -- given one
        return nil
    elseif header == "future" then
        do_date = options.days_until_future .. " days from now"
    else
        do_date = header
    end

    return task.set_do_date(t, do_date)
end
