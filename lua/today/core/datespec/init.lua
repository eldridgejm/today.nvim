--- A high-level type representing a specification of a task's do date.

local DateObj = require("today.core.datespec.dateobj")
local naturaldate = require("today.core.datespec.natural")
local recurring = require("today.core.datespec.recurring")
local util = require("today.util")

--- Parse a date spec string into its pieces: the do date and the recur string.
-- If the spec is nil, the do date is assumed to be today, and the recur is set to nil.
-- @param spec The specification string.
-- @param today Today's date as a DateObj.
-- @return A pair of the do date as a DateObj and the recur as a string.
local function parse(spec, today)
    if spec == nil then
        return today
    end

    local contents = spec:match("<(.*)>")
    if contents == nil then
        error("Date spec " .. spec .. " is not valid")
    end

    local parts = util.split(contents, "+")
    parts = util.map(util.strip, parts)

    local do_date_string = parts[1]
    local recur_spec = parts[2]

    local do_date = naturaldate.natural_to_absolute(do_date_string, today)

    return do_date, recur_spec
end

--- Representation of a datespec: a do date and recur spec.
-- @type DateSpec
local DateSpec = {}

--- Create a new DateSpec object from a datespec string.
-- A spec string is of the form "< do date +recur spec >". The do date can be a date
-- in YYYY-MM-DD format, or any of several natural forms, like "tomorrow" or
-- "3 days from now".
-- @param spec The specification string. This can be nil, in which case a DateSpec with
-- a "do date" of today is created.
-- @param today The date of today as a DateObj or a string in YYYY-MM-DD format.
function DateSpec:new(spec, today)
    assert(today ~= nil)

    if type(today) == "string" then
        today = DateObj:new(today)
    else
        today = DateObj:_from_luadate_object(today)
    end

    local do_date, recur_spec = parse(spec, today)
    return DateSpec._from_parts(self, do_date, recur_spec, today)
end

function DateSpec._from_parts(self, do_date, recur_spec, today)
    assert(today ~= nil)

    local obj = { do_date = do_date, recur_spec = recur_spec, today = today }
    self.__index = self
    return setmetatable(obj, self)
end

--- Compute how many days until the task is scheduled to be done.
-- @return The number of days as an integer.
function DateSpec:days_until_do()
    return self.today:days_until(self.do_date)
end

--- Convert the datespec into a string.
-- @param natural Boolean: should we use natural language? If false, YYYY-MM-DD
-- format is used.
-- @return The datespec as a string, with angle brackets.
function DateSpec:serialize(natural)
    local pieces = {}

    local do_date = tostring(self.do_date)
    if natural then
        do_date = naturaldate.absolute_to_natural(do_date, self.today)
    end
    table.insert(pieces, do_date)

    if self.recur_spec ~= nil then
        table.insert(pieces, " +" .. self.recur_spec)
    end

    return "<" .. table.concat(pieces, "") .. ">"
end

--- Advance the datespec to the next date according to the recur spec.
-- If the recur spec is nil, then nil is returned.
-- @return The new datespec.
function DateSpec:next()
    if self.recur_spec == nil then
        return nil
    end

    local next_do_date = DateObj:new(recurring.next(self.do_date, self.recur_spec))
    return DateSpec._from_parts(self, next_do_date, self.recur_spec, self.today)
end

return DateSpec
