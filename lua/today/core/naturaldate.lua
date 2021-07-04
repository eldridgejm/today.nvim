date = require('today.vendor.date')

naturaldate = {}


function days_into_future(d, today)
    local diff = math.ceil(date.diff(d, today):spandays())
    return diff
end


RULES = {
}

function RULES:add(rule)
    table.insert(self, {from_natural = rule.from_natural, from_date = rule.from_date})
end


-- today
RULES:add {
    from_natural = function(s, today)
        if s == 'today' then
            return today
        end
    end,

    from_date = function(d, today)
        local diff = days_into_future(d, today)
        if diff == 0 then
            return 'today'
        end
    end
}


-- tomorrow
RULES:add {
    from_natural = function(s, today)
        if s == 'tomorrow' then
            return today:adddays(1)
        end
    end,

    from_date = function(d, today)
        local diff = days_into_future(d, today)
        if diff == 1 then
            return 'tomorrow'
        end
    end
}


function _prefix_search(tbl, x)
    local matches = {}

    local function _starts_with(s, pattern)
        return s:sub(1, #pattern) == pattern
    end

    for ix, item in ipairs(tbl) do
        if _starts_with(item, x) then
            table.insert(matches, ix)
        end
    end

    if #matches == 1 then
        return matches[1]
    end
end


-- weekdays
local WEEKDAYS = {
    "sunday",
    "monday",
    "tuesday",
    "wednesday",
    "thursday",
    "friday",
    "saturday",
}

RULES:add {
    from_natural = function(s, today)

        local target_weekday = _prefix_search(WEEKDAYS, s)

        if target_weekday ~= nil then
            local todays_weekday = today:getweekday()

            local delta = (target_weekday - todays_weekday) % 7
            if delta == 0 then
                delta = 7
            end
            return today:adddays(delta)
        end

    end,

    from_date = function(d, today)
        local diff = days_into_future(d, today)
        if (diff > 1) and (diff < 7) then
            local todays_weekday = today:getweekday()
            local target_weekday = todays_weekday + diff
            if target_weekday > 7 then
                target_weekday = target_weekday - 7
            end
            return WEEKDAYS[target_weekday]
        end
    end
}


-- k days from now
RULES:add {
    from_natural = function(s, today)
        local match = s:match('(%d+) day[s]? from now')
        if match ~= nil then
            return today:adddays(match)
        end
    end,
}


-- k weeks from now
RULES:add {
    from_natural = function(s, today)
        local match = s:match('(%d+) week[s]? from now')
        if match ~= nil then
            return today:adddays(7*match)
        end
    end
}


-- k months from now
RULES:add {
    from_natural = function(s, today)
        local match = s:match('(%d+) month[s]? from now')
        if match ~= nil then
            return today:adddays(30*match)
        end
    end
}

-- next week
RULES:add {
    -- defaults to the next monday
    from_natural = function(s, today)
        if s == 'next week' then
            local d = today:adddays(1)
            while d:getweekday() ~= 2 do
                d = d:adddays(1)
            end
            return d
        end
    end,
}

-- next month
RULES:add {
    -- defaults to the first day of next month
    from_natural = function(s, today)
        if s == 'next month' then
            local y, m, d = today:getdate()
            m = (m + 1) % 12
            if m == 0 then
                m = 12
            end
            return date(y, m, 1)
        end
    end,
}


function naturaldate.natural_to_date(s, today)
    today = date(today)
    s = s:lower()

    for _, rule in ipairs(RULES) do
        if rule.from_natural ~= nil then
            result = rule.from_natural(s, today)
            if result ~= nil then
                return result:fmt('%Y-%m-%d')
            end
        end
    end

    return date(s)
end


function naturaldate.date_to_natural(d, today)
    d = date(d)
    today = date(today)

    for _, rule in ipairs(RULES) do
        if rule.from_date ~= nil then
            result = rule.from_date(d, today)
            if result ~= nil then
                return result
            end
        end
    end

    return d:fmt('%Y-%m-%d')
end


return naturaldate
