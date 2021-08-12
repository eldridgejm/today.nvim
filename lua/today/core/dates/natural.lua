--- Convert between dates in absolute and natural (relative) format.  For
-- example, convert "natural" dates like "today", "tomorrow", "3 weeks from now"
-- to the date in YYYY-MM-DD, and vice versa.
-- @submodule core.dates

local DateObj = require("today.core.dates.dateobj")
local util = require("today.util")
local datestrings = require("today.core.dates.strings")

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
-- A rule is itself a table containing two keys by convention: "parse"
-- and "to_natural". "parse" should be a function that takes a string
-- "s" and a DateObj "today" and returns a DateObj that is equivalent to
-- the natural date.
--
-- "to_natural" should either be a function that accepts an absolute date as
-- a DateObj and a DateObj "today" and returns a string
-- representing the date in natural format, or nil. A value of nil for this key
-- signals that there is no conversion from the absolute date to a natural
-- date.
local RULES = {}

-- A function to add a rule table to the set of all rules.
function RULES:add(rule)
    table.insert(
        self,
        { parse = rule.parse, to_natural = rule.to_natural }
    )
end

-- today
RULES:add({
    parse = function(s, today)
        if s == "today" then
            return today
        end
    end,

    to_natural = function(d, today)
        local diff = days_into_future(d, today)
        if diff == 0 then
            return "today"
        end
    end,
})

-- tomorrow
RULES:add({
    parse = function(s, today)
        if (s == "tomorrow") or (s == "tom") then
            return today:add_days(1)
        end
    end,

    to_natural = function(d, today)
        local diff = days_into_future(d, today)
        if diff == 1 then
            return "tomorrow"
        end
    end,
})

-- weekdays

RULES:add({
    parse = function(s, today)
        local week_adder = 0
        if util.startswith(s, "next ") then
            week_adder = 7
            s = s:match("next (%w+)")
        end
        local target_weekday = util.prefix_search(datestrings.WEEKDAYS, s)

        if target_weekday ~= nil then
            local todays_weekday = today:day_of_the_week()

            local delta = (target_weekday - todays_weekday) % 7
            return today:add_days(delta + week_adder)
        end
    end,

    to_natural = function(d, today)
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

            return prefix .. datestrings.WEEKDAYS[target_weekday]
        end
    end,
})

-- k days from now
RULES:add({
    parse = function(s, today)
        local match = s:match("(%d+) day[s]? from now")
        if match ~= nil then
            return today:add_days(match)
        end
    end,

    to_natural = function(d, today)
        local delta = today:days_until(d)
        if delta < math.huge and delta >= 0 then
            return delta .. " days from now"
        end
    end
})

-- k weeks from now
RULES:add({
    parse = function(s, today)
        local match = s:match("(%d+) week[s]? from now")
        if match ~= nil then
            return today:add_days(7 * match)
        end
    end,
})

-- k months from now
RULES:add({
    parse = function(s, today)
        local match = s:match("(%d+) month[s]? from now")
        if match ~= nil then
            return today:add_days(30 * match)
        end
    end,

})

-- next week
RULES:add({
    -- defaults to the next monday
    parse = function(s, today)
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
    parse = function(s, today)
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
    parse = function(s, _)
        if s == "someday" then
            return DateObj:infinite_future()
        end
    end,

    to_natural = function(d, _)
        if tostring(d) == "infinite_future" then
            return "someday"
        end
    end,
})

-- [<Weekday>] <Month> <Day> [<Year>]
-- e.g., mon july 05 2021, jul 4, dec 31 2022, mon july 05

RULES:add({
    -- defaults to the first day of next month
    parse = function(s, today)
        s = s:lower()

        local parts = util.split(s, " ")

        -- if the first part is a weekday, discard it
        -- otherwise, it must be a month
        local offset = 0
        if util.prefix_search(datestrings.WEEKDAYS, parts[1]) then
            offset = 1
        end
        local month = parts[1 + offset]
        local day = parts[2 + offset]
        local year = parts[3 + offset]

        local m = util.prefix_search(datestrings.MONTHS, month)
        local d = tonumber(day)

        local y
        if not year == nil then
            y = tonumber(year)
            if y == nil then return nil end
        end

        if (m == nil) or (d == nil) then return nil
        end

        local this_year, _, _ = today:ymd()

        if y == nil then
            if DateObj:from_ymd(this_year, m, d) < today then
                y = this_year + 1
            else
                y = this_year
            end
        end

        return DateObj:from_ymd(y, m, d)
    end,
})

-- dates in the past

-- yesterday
RULES:add({
    parse = function(s, today)
        if s == "yesterday" then
            return today:add_days(-1)
        end
    end,

    to_natural = function(d, today)
        local diff = days_into_future(d, today)
        if diff == -1 then
            return "yesterday"
        end
    end,
})

-- k days ago
RULES:add({
    parse = function(s, today)
        local match = s:match("(%d+) day[s]? ago")
        if match ~= nil then
            return today:add_days(-match)
        end
    end,

    to_natural = function(d, today)
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
function M.parse(s, today)
    assert(today ~= nil)
    today = DateObj:new(today)

    s = s:lower()

    for _, rule in ipairs(RULES) do
        if rule.parse ~= nil then
            local result = rule.parse(s, today)
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

--- Serialize a DateObj as a natural language string. For instance, if a dateobj
-- contains the date 2021-08-05, and today is 2021-08-04, then to_natural returns "tomorrow".
-- Days in the next two weeks are converted to their weekday name, like "monday" or
-- "next tuesday". Dates after this but within the `options.days_until_absolute` threshold are
-- converted to the format "k days from now". Dates after this are
-- converted to a string in the format specified by `options.default_format`
--
-- @param s The absolute date as a DateObj or as a string in YYYY-MM-DD format.
-- @param today The date used for today, as a YYYY-MM-DD string or a DateObj.
-- @param options An options dictionary. The available options are:
--
-- `days_until_absolute`: (int) A number of days, after which any date is converted to an
-- absolute date as opposed to a natural date.
--
-- `default_format`: (string) This controls what happens if no natural date applies. If this is set to "ymd",
-- the date is serialized in YYYY-MM-DD format. If this is "datestamp", it is serialized
-- in the format of "mon jul 05 2021".
--
-- @return The date in natural form as a string.
function M.to_natural(s, today, options)
    assert(today ~= nil)

    options = util.merge(options,{
            days_until_absolute = 14,
            default_format = "ymd",
        }
        )

    local format_date = function (d)
        if options.default_format == "ymd" then
            return tostring(d)
        elseif options.default_format == "datestamp" then
            return datestrings.to_datestamp(d)
        end
    end

    local d = DateObj:new(s)
    today = DateObj:new(today)

    if (d > today:add_days(options.days_until_absolute)) and (d ~= DateObj:infinite_future()) then
        return format_date(d)
    end

    assert(d.class == "DateObj")
    assert(today.class == "DateObj")

    for _, rule in ipairs(RULES) do
        if rule.to_natural ~= nil then
            local result = rule.to_natural(d, today)
            if result ~= nil then
                return result
            end
        end
    end

    return format_date(d)

end

return M
