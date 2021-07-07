--- Higher-level natural date specification type.

local date = require("today.vendor.date")
local naturaldate = require("today.core.naturaldate")

--- Parse a date spec string to a date object. If the spec is nil, the
-- do date is assumed to be today.
-- @param spec The specification string.
-- @param today Today's date as a dateObject.
-- @return The do date as a dateObject.
local function parse_do_date(spec, today)
    if spec == nil then
        return today
    end

    local do_date = spec:match("<(.*)>")
    if do_date == nil then
        error("Date spec " .. spec .. " is not valid")
    end

    return date(naturaldate.natural_to_absolute(do_date, today))
end

--- Representation of a datespec: a do date and recur pattern.
-- @type DateSpec
local DateSpec = {}

--- Create a new DateSpec object from a datespec string.
-- @param spec The specification string. This can be nil, in which case a DateSpec with
-- do date of today is created.
-- @param today The date of today as a dateObject or a string in YYYY-MM-DD format.
function DateSpec:new(spec, today)
    today = date(today)

    local do_date = parse_do_date(spec, today)

    assert(do_date.getdate ~= nil, "do_date is not a date object")
    assert(today.getdate ~= nil, "today is not a date object")

    local obj = { do_date = do_date, today = today }
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
    local do_date = self.do_date:fmt("%Y-%m-%d")
    if natural then
        do_date = naturaldate.absolute_to_natural(do_date, self.today)
    end

    return "<" .. do_date .. ">"
end

return DateSpec
