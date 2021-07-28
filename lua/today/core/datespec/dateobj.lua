--- A date object.
--
-- Represents a triple of (year, month, date). Also allows a special value:
-- infinite_future.
--
-- This is a thin wrapper around the luadate library.

local datelib = require("today.vendor.date")

--- Representation of a date object.
-- @type DateObj
local DateObj = {}

local function either(lhs, rhs, value)
    return (lhs._date == value) or (rhs._date == value)
end

local function both(lhs, rhs, value)
    return (lhs._date == value) and (rhs._date == value)
end

--- Create a DateObj from a year/month/day triple.
-- @param year The year as an integer.
-- @param month The month as an integer.
-- @param day The day of the month as an integer.
-- @return The DateObj.
function DateObj:from_ymd(year, month, day)
    return DateObj._create(self, datelib(year, month, day))
end

--- Create a DateObj from a YYYY-MM-DD string.
-- @param s The date in the form of YYYY-MM-DD.
-- @return The DateObj.
function DateObj:from_string(s)
    return DateObj._create(self, datelib(s))
end

function DateObj:_from_luadate_object(d)
    assert(d ~= nil)
    return DateObj._create(self, datelib(d))
end

--- Create a DateObj representing a date in the infinite future.
function DateObj:infinite_future()
    return DateObj._create(self, "infinite_future")
end

function DateObj._create(self, _date)
    local obj = { _date = _date, class = "DateObj" }
    self.__index = self

    self.__tostring = function()
        -- if this is infinite_future
        if type(obj._date) == "string" then
            return obj._date
        else
            return obj._date:fmt("%Y-%m-%d")
        end
    end

    self.__lt = function(lhs, rhs)
        if both(lhs, rhs, "infinite_future") then
            return false
        end

        if (lhs._date ~= "infinite_future") and (rhs._date == "infinite_future") then
            return true
        end

        return lhs._date < rhs._date
    end

    self.__eq = function(lhs, rhs)
        if either(lhs, rhs, "infinite_future") then
            return both(lhs, rhs, "infinite_future")
        end

        return (
                (lhs._date:getyear() == rhs._date:getyear())
                and (lhs._date:getmonth() == rhs._date:getmonth())
                and (lhs._date:getday() == rhs._date:getday())
            )
    end

    return setmetatable(obj, self)
end

--- Get the year, month, and day of the month as a triple.
function DateObj:ymd()
    if self._date == "infinite_future" then
        return nil
    end

    return self._date:getyear(), self._date:getmonth(), self._date:getday()
end

--- Add days to the date, creating a new DateObj.
-- @param n The number of days to add. Can be negative.
-- @return The new date.
function DateObj:add_days(n)
    if self._date == "infinite_future" then
        return DateObj:infinite_future()
    end

    local new_date = self._date:copy():adddays(n)
    return DateObj:_from_luadate_object(new_date)
end

--- Calculate the number of days between dates.
-- @param other The other DateObj.
-- @return The number of days from self to other as an integer. Can be negative, if other is
-- in the past relative to self.
function DateObj:days_until(other)
    if both(self, other, "infinite_future") then
        return nil
    end

    if self._date == "infinite_future" then
        return -math.huge
    end

    if other._date == "infinite_future" then
        return math.huge
    end

    return math.ceil(datelib.diff(other._date, self._date):spandays())
end

--- The day of the week, as an integer starting with Sunday as 1, Monday as 2, etc.
function DateObj:day_of_the_week()
    if self._date == "infinite_future" then
        return nil
    end
    return self._date:getweekday()
end

return DateObj
