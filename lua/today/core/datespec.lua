--- Higher-level natural date specification type.

local date = require("today.vendor.date")
local naturaldate = require("today.core.naturaldate")

function default_today(today)
    if today ~= nil then
        today = date(today)
    else
        today = date()
    end
    return today
end


function parse(spec, today)
    -- Parse a date spec string to a date object
    if spec == nil then
        return today
    end

    local do_date = spec:match("<(.*)>")
    if do_date == nil then
        error("Date spec " .. spec .. " is not valid")
    end

    return date(naturaldate.natural_to_absolute(do_date, today))
end

local DateSpec = {}

function DateSpec:new(spec, today)
    today = default_today(today)
    local do_date = parse(spec, today)
    local obj = { do_date = do_date, today = today }
    -- ensure that these are date tables
    assert(do_date.getdate ~= nil, "do_date is not a date object")
    assert(today.getdate ~= nil, "today is not a date object")
    self.__index = self
    return setmetatable(obj, self)
end

function DateSpec:days_away()
    return math.ceil(date.diff(self.do_date, self.today):spandays())
end

function DateSpec:serialize(natural)
    local do_date = self.do_date:fmt("%Y-%m-%d")
    if natural then
        do_date = naturaldate.absolute_to_natural(do_date, self.today)
    end

    return "<" .. do_date .. ">"
end

return DateSpec
