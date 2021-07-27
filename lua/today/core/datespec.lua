--- Higher-level natural date specification type with relative dates and recurring dates.

local date = require("today.vendor.date")
local naturaldate = require("today.core.naturaldate")
local recurring = require("today.core.recurring")
local util = require("today.core.util")

--- Parse a date spec string into its pieces: the do date and the recur string.
-- If the spec is nil, the do date is assumed to be today, and the recur is set to nil.
-- @param spec The specification string.
-- @param today Today's date as a dateObject.
-- @return A pair of the do date as a dateObject and the recur as a string.
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

    local do_date = date(naturaldate.natural_to_absolute(do_date_string, today))

    return do_date, recur_spec
end

--- Representation of a datespec: a do date and recur spec.
-- @type DateSpec
local DateSpec = {}

--- Create a new DateSpec object from a datespec string.
-- @param spec The specification string. This can be nil, in which case a DateSpec with
-- do date of today is created.
-- @param today The date of today as a dateObject or a string in YYYY-MM-DD format.
function DateSpec:new(spec, today)
    -- luacheck: ignore self
    today = date(today)
    local do_date, recur_spec = parse(spec, today)
    return DateSpec._from_parts(self, do_date, recur_spec, today)
end

function DateSpec._from_parts(self, do_date, recur_spec, today)
    today = date(today)

    assert(do_date.getdate ~= nil, "do_date is not a date object")
    assert(today.getdate ~= nil, "today is not a date object")

    local obj = { do_date = do_date, recur_spec = recur_spec, today = today }
    self.__index = self
    return setmetatable(obj, self)
end

--- Compute how many days until the task is scheduled to be done.
-- @return The number of days as an integer.
function DateSpec:days_until_do()
    return math.ceil(date.diff(self.do_date, self.today):spandays())
end

--- Convert the datespec into a string.
-- @param natural Boolean: should we use natural language? If false, YYYY-MM-DD
-- format is used.
-- @return The datespec as a string, with angle brackets.
function DateSpec:serialize(natural)
    local pieces = {}

    local do_date = self.do_date:fmt("%Y-%m-%d")
    if natural then
        do_date = naturaldate.absolute_to_natural(do_date, self.today)
    end
    table.insert(pieces, do_date)

    if self.recur_spec ~= nil then
        table.insert(pieces, " +" .. self.recur_spec)
    end

    return "<" .. table.concat(pieces, "") .. ">"
end

-- Advance the datespec to the next date according to the recur_spec string.
function DateSpec:next()
    if self.recur_spec == nil then
        return nil
    end

    local next_do_date = date(recurring.next(self.do_date, self.recur_spec))

    return DateSpec._from_parts(self, next_do_date, self.recur_spec, self.today)
end

return DateSpec
