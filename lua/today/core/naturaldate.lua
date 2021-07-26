--- Convert between dates in absolute and natural (relative) format.  For
-- example, convert "natural" dates like "today", "tomorrow", "3 weeks from now"
-- to the date in YYYY-MM-DD, and vice versa.

local date = require("today.vendor.date")

local naturaldate = {}

-- Count number of days the date is into the future.
-- @param d The date in question. String or dateObject.
-- @param today The date that should be used for today. String or dateObject.
-- @returns An integer counting the difference in days.
local function days_into_future(d, today)
    local diff = math.ceil(date.diff(d, today):spandays())
    return diff
end

-- The rules that are applied during conversion.
--
-- A rule is itself a table containing two keys by convention: "from_natural"
-- and "from_absolute". "from_natural" should be a function that takes a string
-- "s" and a dateObject "today" and returns a dateObject that is equivalent to
-- the natural date.
--
-- "from_absolute" should either be a function that accepts an absolute date as
-- a string in YYYY-MM-DD format and a dateObject "today" and returns a string
-- representing the date in natural format, or nil. A value of nil for this key
-- signals that there is no conversion from the absolute date to a natural
-- date.
local RULES = {}

-- A function to add a rule table to the set of all rules.
function RULES:add(rule)
    table.insert(
        self,
        { from_natural = rule.from_natural, from_absolute = rule.from_absolute }
    )
end

-- today
RULES:add({
    from_natural = function(s, today)
        if s == "today" then
            return today
        end
    end,

    from_absolute = function(d, today)
        local diff = days_into_future(d, today)
        if diff == 0 then
            return "today"
        end
    end,
})

-- tomorrow
RULES:add({
    from_natural = function(s, today)
        if s == "tomorrow" then
            return today:adddays(1)
        end
    end,

    from_absolute = function(d, today)
        local diff = days_into_future(d, today)
        if diff == 1 then
            return "tomorrow"
        end
    end,
})

-- weekdays

-- Do a prefix search in a table of strings.
-- This will search the table for an target "x". "x" matches a table element if
-- it is a prefix of the element.  If there is only one match, it is returned;
-- else "nil" is returned.
local function prefix_search(tbl, x)
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

local WEEKDAYS = {
    "sunday",
    "monday",
    "tuesday",
    "wednesday",
    "thursday",
    "friday",
    "saturday",
}

RULES:add({
    from_natural = function(s, today)
        local target_weekday = prefix_search(WEEKDAYS, s)

        if target_weekday ~= nil then
            local todays_weekday = today:getweekday()

            local delta = (target_weekday - todays_weekday) % 7
            if delta == 0 then
                delta = 7
            end
            return today:adddays(delta)
        end
    end,

    from_absolute = function(d, today)
        local diff = days_into_future(d, today)
        if (diff > 1) and (diff < 7) then
            local todays_weekday = today:getweekday()
            local target_weekday = todays_weekday + diff
            if target_weekday > 7 then
                target_weekday = target_weekday - 7
            end
            return WEEKDAYS[target_weekday]
        end
    end,
})

-- k days from now
RULES:add({
    from_natural = function(s, today)
        local match = s:match("(%d+) day[s]? from now")
        if match ~= nil then
            return today:adddays(match)
        end
    end,
})

-- k weeks from now
RULES:add({
    from_natural = function(s, today)
        local match = s:match("(%d+) week[s]? from now")
        if match ~= nil then
            return today:adddays(7 * match)
        end
    end,
})

-- k months from now
RULES:add({
    from_natural = function(s, today)
        local match = s:match("(%d+) month[s]? from now")
        if match ~= nil then
            return today:adddays(30 * match)
        end
    end,
})

-- next week
RULES:add({
    -- defaults to the next monday
    from_natural = function(s, today)
        if s == "next week" then
            local d = today:adddays(1)
            while d:getweekday() ~= 2 do
                d = d:adddays(1)
            end
            return d
        end
    end,
})

-- next month
RULES:add({
    -- defaults to the first day of next month
    from_natural = function(s, today)
        if s == "next month" then
            local y, m, _ = today:getdate()
            m = (m + 1) % 12
            if m == 0 then
                m = 12
            end
            return date(y, m, 1)
        end
    end,
})

-- dates in the past

-- yesterday
RULES:add({
    from_natural = function(s, today)
        if s == "yesterday" then
            return today:adddays(-1)
        end
    end,

    from_absolute = function(d, today)
        local diff = days_into_future(d, today)
        if diff == -1 then
            return "yesterday"
        end
    end,
})

-- k days ago
RULES:add({
    from_natural = function(s, today)
        local match = s:match("(%d+) day[s]? ago")
        if match ~= nil then
            return today:adddays(-match)
        end
    end,

    from_absolute = function(d, today)
        local diff = days_into_future(d, today)
        if diff < -1 then
            return -diff .. " days ago"
        end
    end,
})

--- Convert a natural date into an absolute date.
-- @param s The natural date as a string. Can be in any case.
-- @param today The date used for today, as a YYYY-MM-DD string or a dateObject.
-- @return The absolute date as a string in YYYY-MM-DD format.
function naturaldate.natural_to_absolute(s, today)
    -- Convert a natural date string to a YYYY-MM-DD date string
    today = date(today)
    s = s:lower()

    for _, rule in ipairs(RULES) do
        if rule.from_natural ~= nil then
            local result = rule.from_natural(s, today)
            -- if the result is nil, there is no rule
            if result ~= nil then
                return result:fmt("%Y-%m-%d")
            end
        end
    end

    return date(s):fmt("%Y-%m-%d")
end

--- Convert an absolute date to a natural date.
-- If there is no valid conversion of the absolute date to a natural date,
-- the date is left as a string in YYYY-MM-DD format.
-- @param s The absolute date as a string in YYYY-MM-DD format.
-- @param today The date used for today, as a YYYY-MM-DD string or a dateObject.
-- @return The date in natural form as a string.
function naturaldate.absolute_to_natural(s, today)
    local d = date(s)
    today = date(today)

    for _, rule in ipairs(RULES) do
        if rule.from_absolute ~= nil then
            local result = rule.from_absolute(d, today)
            if result ~= nil then
                return result
            end
        end
    end

    return d:fmt("%Y-%m-%d")
end

return naturaldate
