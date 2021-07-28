--- A date object.
--
-- Represents a triple of (year, month, date). Also allows two special values:
-- infinite_future and infinite_past.
--
-- This is a thin wrapper around the luadate library.

local datelib = require("today.vendor.date")

local DateObj = {}

function DateObj:from_ymd(year, month, day)
    return DateObj._create(self, datelib(year, month, day))
end

function DateObj:from_string(s)
    return DateObj._create(self, datelib(s))
end

function DateObj:_from_date(d)
    assert(d ~= nil)
    return DateObj._create(self, datelib(d))
end

function DateObj:infinite_future()
    return DateObj._create(self, "infinite_future")
end

function DateObj:infinite_past()
    return DateObj._create(self, "infinite_past")
end

local function either(lhs, rhs, value)
    return (lhs._date == value) or (rhs._date == value)
end

local function both(lhs, rhs, value)
    return (lhs._date == value) and (rhs._date == value)
end

function DateObj._create(self, _date)
    local obj = { _date = _date }
    self.__index = self

    self.__tostring = function()
        -- if this is infinite_future or infinite_past
        if type(obj._date) == "string" then
            return obj._date
        else
            return obj._date:fmt("%Y-%m-%d")
        end
    end

    self.__eq = function(lhs, rhs)
        if either(lhs, rhs, "infinite_future") then
            return both(lhs, rhs, "infinite_future")
        end

        if either(lhs, rhs, "infinite_past") then
            return both(lhs, rhs, "infinite_past")
        end

        return (
                (lhs._date:getyear() == rhs._date:getyear())
                and (lhs._date:getmonth() == rhs._date:getmonth())
                and (lhs._date:getday() == rhs._date:getday())
            )
    end

    return setmetatable(obj, self)
end

function DateObj:ymd()
    if self:is_infinite() then
        return nil
    end

    return self._date:getyear(), self._date:getmonth(), self._date:getday()
end

function DateObj:is_infinite()
    return (self._date == "infinite_future") or (self._date == "infinite_past")
end

function DateObj:add_days(n)
    if self._date == "infinite_future" then
        return DateObj:infinite_future()
    end

    if self._date == "infinite_past" then
        return DateObj:infinite_past()
    end

    local new_date = self._date:copy():adddays(n)
    return DateObj:_from_date(new_date)
end

function DateObj:days_until(other)
    if both(self, other, "infinite_future") then
        return nil
    end

    if both(self, other, "infinite_past") then
        return nil
    end

    if (self._date == "infinite_future") or (other._date == "infinite_past") then
        return -math.huge
    end

    if (other._date == "infinite_future") or (self._date == "infinite_past") then
        return math.huge
    end

    return math.ceil(datelib.diff(other._date, self._date):spandays())
end

function DateObj:day_of_the_week()
    if self:is_infinite() then
        return nil
    end
    return self._date:getweekday()
end

return DateObj
