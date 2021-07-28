--- Convert between dates in absolute and natural (relative) format.  For
-- example, convert "natural" dates like "today", "tomorrow", "3 weeks from now"
-- to the date in YYYY-MM-DD, and vice versa.

local DateObj = require("today.core.datespec.dateobj")
local util = require("today.util")

local naturaldate = {}

-- Count number of days the date is into the future.
-- @param d The date in question. String or dateObject.
-- @param today The date that should be used for today. String or dateObject.
-- @returns An integer counting the difference in days.
local function days_into_future(d, today)
    return today:days_until(d)
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
        if (s == "tomorrow") or (s == "tom") then
            return today:add_days(1)
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
        local target_weekday = util.prefix_search(WEEKDAYS, s)

        if target_weekday ~= nil then
            local todays_weekday = today:day_of_the_week()

            local delta = (target_weekday - todays_weekday) % 7
            if delta == 0 then
                delta = 7
            end
            return today:add_days(delta)
        end
    end,

    from_absolute = function(d, today)
        local diff = days_into_future(d, today)
        if (diff > 1) and (diff < 7) then
            local todays_weekday = today:day_of_the_week()
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
            return today:add_days(match)
        end
    end,
})

-- k weeks from now
RULES:add({
    from_natural = function(s, today)
        local match = s:match("(%d+) week[s]? from now")
        if match ~= nil then
            return today:add_days(7 * match)
        end
    end,
})

-- k months from now
RULES:add({
    from_natural = function(s, today)
        local match = s:match("(%d+) month[s]? from now")
        if match ~= nil then
            return today:add_days(30 * match)
        end
    end,
})

-- next week
RULES:add({
    -- defaults to the next monday
    from_natural = function(s, today)
        if s == "next week" then
            local d = today:add_days(1)
            while d:day_of_the_week() ~= 2 do
                d = d:add_days(1)
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
            local y, m, _ = today:ymd()
            m = (m + 1) % 12
            if m == 0 then
                m = 12
            end
            return DateObj:from_ymd(y, m, 1)
        end
    end,
})

-- dates in the past

-- yesterday
RULES:add({
    from_natural = function(s, today)
        if s == "yesterday" then
            return today:add_days(-1)
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
            return today:add_days(-match)
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
    s = s:lower()

    for _, rule in ipairs(RULES) do
        if rule.from_natural ~= nil then
            local result = rule.from_natural(s, today)
            -- if the result is nil, there is no rule
            if result ~= nil then
                return tostring(result)
            end
        end
    end

    return tostring(DateObj:from_string(s))
end

--- Convert an absolute date to a natural date.
-- If there is no valid conversion of the absolute date to a natural date,
-- the date is left as a string in YYYY-MM-DD format.
-- @param s The absolute date as a string in YYYY-MM-DD format.
-- @param today The date used for today, as a YYYY-MM-DD string or a dateObject.
-- @return The date in natural form as a string.
function naturaldate.absolute_to_natural(s, today)
    local d = s
    if type(s) == "string" then
        d = DateObj:from_string(s)
    end

    assert(d.class == "DateObj")

    for _, rule in ipairs(RULES) do
        if rule.from_absolute ~= nil then
            local result = rule.from_absolute(d, today)
            if result ~= nil then
                return result
            end
        end
    end

    return tostring(d)
end

return naturaldate
