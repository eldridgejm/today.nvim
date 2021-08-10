--- Convert between dates in absolute and natural (relative) format.  For
-- example, convert "natural" dates like "today", "tomorrow", "3 weeks from now"
-- to the date in YYYY-MM-DD, and vice versa.
-- @submodule core.dates

local DateObj = require("today.core.dates.dateobj")
local util = require("today.util")

local M = {}

-- Count number of days the date is into the future.
-- @param d The date in question. String or DateObj.
-- @param today The date that should be used for today. String or DateObj.
-- @returns An integer counting the difference in days.
local function days_into_future(d, today)
    d = DateObj:new(d)
    today = DateObj:new(today)

    return today:days_until(d)
end

-- The rules that are applied during conversion.
--
-- A rule is itself a table containing two keys by convention: "from_natural"
-- and "from_absolute". "from_natural" should be a function that takes a string
-- "s" and a DateObj "today" and returns a DateObj that is equivalent to
-- the natural date.
--
-- "from_absolute" should either be a function that accepts an absolute date as
-- a DateObj and a DateObj "today" and returns a string
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
        local week_adder = 0
        if util.startswith(s, "next ") then
            week_adder = 7
            s = s:match("next (%w+)")
        end
        local target_weekday = util.prefix_search(WEEKDAYS, s)

        if target_weekday ~= nil then
            local todays_weekday = today:day_of_the_week()

            local delta = (target_weekday - todays_weekday) % 7
            return today:add_days(delta + week_adder)
        end
    end,

    from_absolute = function(d, today)
        local diff = days_into_future(d, today)
        if (diff > 1) and (diff < 14) then
            local todays_weekday = today:day_of_the_week()
            local target_weekday = todays_weekday + diff
            target_weekday = ((target_weekday - 1) % 7) + 1

            local prefix
            if diff >= 7 then
                prefix = "next "
            else
                prefix = ""
            end

            return prefix .. WEEKDAYS[target_weekday]
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

-- someday
RULES:add({
    -- a date in the infinite future
    from_natural = function(s, _)
        if s == "someday" then
            return DateObj:infinite_future()
        end
    end,

    from_absolute = function(d, _)
        if tostring(d) == "infinite_future" then
            return "someday"
        end
    end,
})

-- <Weekday> <Month> <Day> <Year>
-- e.g., mon july 05 2021

local months = {
    "jan",
    "feb",
    "mar",
    "apr",
    "may",
    "jun",
    "jul",
    "aug",
    "sep",
    "oct",
    "nov",
    "dec",
}

RULES:add({
    -- defaults to the first day of next month
    from_natural = function(s, _)
        s = s:lower()
        local _, m, d, y = s:match("(%l%l%l) (%l%l%l) (%d%d) (%d%d%d%d)")
        if y == nil then
            return nil
        end

        m = util.index_of(months, m)
        return DateObj:from_ymd(y, m, d)
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
-- @param today The date used for today, as a YYYY-MM-DD string or a DateObj.
-- @return The absolute date as a DateObj, or nil if the natural date is invalid.
function M.from_natural(s, today)
    assert(today ~= nil)
    today = DateObj:new(today)

    s = s:lower()

    for _, rule in ipairs(RULES) do
        if rule.from_natural ~= nil then
            local result = rule.from_natural(s, today)
            -- if the result is nil, there is no rule
            if result ~= nil then
                assert(result.class == "DateObj")
                return result
            end
        end
    end

    if not s:match("%d%d%d%d-%d+-%d+") then
        return nil
    end

    return DateObj:new(s)
end

--- Converts a date into a human datestamp of the form "mon jul 05 2021"
function M.to_human_datestamp(date)
    local y, m, d = date:ymd()
    local wd = date:day_of_the_week()

    local days_of_the_week = {
        "sun",
        "mon",
        "tue",
        "wed",
        "thu",
        "fri",
        "sat",
    }

    if d < 10 then
        d = "0" .. d
    end

    wd = days_of_the_week[wd]
    m = months[m]

    return wd .. " " .. m .. " " .. d .. " " .. y
end

--- Convert an absolute date to a natural date.
-- If there is no valid conversion of the absolute date to a natural date,
-- the date is left as a string in YYYY-MM-DD format.
-- @param s The absolute date as a DateObj or as a string in YYYY-MM-DD format.
-- @param today The date used for today, as a YYYY-MM-DD string or a DateObj.
-- @param options An options dictionary. The only option currently is "default_format".
-- This controls what happens if no natural date applies. If this is set to "YYYY-MM-DD",
-- the date is serialized in YYYY-MM-DD format. If this is "human", it is serialized
-- in the format of "mon jul 05 2021".
-- @return The date in natural form as a string.
function M.to_natural(s, today, options)
    assert(today ~= nil)

    if options == nil then
        options = {
            default_format = "YYYY-MM-DD",
        }
    end

    local d = DateObj:new(s)
    today = DateObj:new(today)

    assert(d.class == "DateObj")
    assert(today.class == "DateObj")

    for _, rule in ipairs(RULES) do
        if rule.from_absolute ~= nil then
            local result = rule.from_absolute(d, today)
            if result ~= nil then
                return result
            end
        end
    end

    if options.default_format == "YYYY-MM-DD" then
        return tostring(d)
    elseif options.default_format == "human" then
        return M.to_human_datestamp(d)
    end
end

return M
