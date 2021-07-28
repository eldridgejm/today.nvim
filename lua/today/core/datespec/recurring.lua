--- Find the next date in a sequence of recurring dates.

local DateObj = require("today.core.datespec.dateobj")
local util = require("today.util")

local recurring = {}

-- Each rule has two functions: a "match" function and an "advance" function.
-- The "match" function should look at the recur specification and return
-- nil if the rule does not apply. Otherwise, whatever the match function
-- returns will be passed to the "advance" function, along with the date to
-- advance as a dateobj. It should return a dateobj representing the date,
-- advanced to the next recurring date. This design makes it efficient
-- to check the validity of a recur spec by looping through the "match"
-- functions of each rule.
local RULES = {}

-- A function to add a rule table to the set of all rules.
function RULES:add(rule)
    table.insert(self, rule)
end

--- Constructs a simple match function that checks if the recur spec is a certain string.
local function string_matcher(...)
    local strings = { ... }
    return function(recur)
        for _, s in ipairs(strings) do
            if recur == s then
                return s
            end
        end
        return nil
    end
end

-- daily, every day
RULES:add({
    match = string_matcher("daily", "every day"),

    advance = function(today)
        return today:add_days(1)
    end,
})

-- weekly
RULES:add({
    match = string_matcher("weekly", "every week"),

    advance = function(today)
        return today:add_days(7)
    end,
})

-- monthly
RULES:add({
    match = string_matcher("monthly", "every month"),

    advance = function(today)
        return today:add_days(31)
    end,
})

-- every monday, tuesday, etc.
local DAYS_OF_THE_WEEK = {
    "sunday",
    "monday",
    "tuesday",
    "wednesday",
    "thursday",
    "friday",
    "saturday",
}

RULES:add({
    match = function(recur)
        local remainder = recur:match("every ([%l, ]+)")
        if remainder ~= nil then
            local parts = util.split(remainder, ",")
            parts = util.map(util.strip, parts)
            return util.map(function(p)
                return util.prefix_search(DAYS_OF_THE_WEEK, p)
            end, parts)
        end
    end,

    advance = function(today, target_weekdays)
        local advanced_date = today:add_days(1)
        while true do
            if
                util.contains_value(target_weekdays, advanced_date:day_of_the_week())
            then
                return advanced_date
            end
            advanced_date = advanced_date:add_days(1)
        end
    end,
})

--- Find the next date in the sequence.
-- Valid recur specifications are "daily", "every day", "weekly", "every week", "monthly",
-- "every month", and specifications of the form "every mon, wed, fri", "every tues".
-- The latter do prefix matching, so the full day of the week does not need to be given.
-- @param today The current date as a dateObject or a YYYY-MM-DD string.
-- @param recur_spec The recur specification. See above.
-- @return The next date as a YYYY-MM-DD string. However, if the recur_spec was invalid,
-- this will return nil.
function recurring.next(today, recur_spec)
    if type(today) == "string" then
        today = DateObj:from_string(today)
    end

    assert(today.class == "DateObj")

    for _, rule in ipairs(RULES) do
        local match = rule.match(recur_spec)
        if match ~= nil then
            return tostring(rule.advance(today, match))
        end
    end

    return nil
end

return recurring
