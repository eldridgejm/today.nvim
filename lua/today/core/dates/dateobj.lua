--- A date object.
--
-- Represents a triple of (year, month, date). Also allows a special value:
-- infinite_future.
--
-- This is a thin wrapper around the luadate library.
-- @submodule core.dates

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

--- Constructor for DateObjects.
-- @param date A date as a string in YYYY-MM-DD format or "infinite_future",
-- or another DateObject.
-- @return A new DateObject.
function DateObj:new(date)
    if type(date) == "string" then
        if date == "infinite_future" then
            return DateObj:infinite_future()
        end
        return DateObj._create(self, datelib(date))
    elseif date.class == "DateObj" then
        return DateObj._create(self, date._date)
    end
    assert("Invalid date.", date)
end

--- Create a DateObj from a year/month/day triple.
-- @param year The year as an integer.
-- @param month The month as an integer.
-- @param day The day of the month as an integer.
-- @return The DateObj.
function DateObj:from_ymd(year, month, day)
    return DateObj._create(self, datelib(year, month, day))
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

    self.__tostring = function(instance)
        -- if this is infinite_future
        if type(instance._date) == "string" then
            return instance._date
        else
            return instance._date:fmt("%Y-%m-%d")
        end
    end

    self.__lt = function(lhs, rhs)
        local n = lhs:days_until(rhs)
        if n == nil then
            return true
        end
        return n > 0
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
-- @return A triple of integers, or nil if the date is the infinite future.
function DateObj:ymd()
    if self._date == "infinite_future" then
        return nil
    end

    return self._date:getyear(), self._date:getmonth(), self._date:getday()
end

--- Add days to the date, creating a new DateObj.
-- If the current date is the infinite future, the return value will also be
-- the infinite future.
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
-- If both dates are the infinite future, nil is returned. Otherwise, if one of
-- the dates is infinite and the other is finite, +/- math.huge is returned.
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

--- Calculate the number of times we see midnight Sunday between now and the other date.
-- If both dates are the infinite future, nil is returned. Otherwise, if now is finite and
-- the other date is infinite, returns math.huge. Note that the other date must be in
-- the future.
-- @param other The other DateObj.
-- @return The number of days from self to other as an integer.
function DateObj:weeks_until(other)
    if other == DateObj:infinite_future() then
        return math.huge
    end

    if self > other then return nil end

    -- find this saturday
    local todays_weekday = self:day_of_the_week()
    local delta = (7 - todays_weekday) % 7
    local this_saturday = self:add_days(delta)

    local n = 0
    while true do
        if other <= this_saturday then
            return n
        else
            n = n + 1
            this_saturday = this_saturday:add_days(7)
        end
    end
end

--- The day of the week, as an integer starting with Sunday as 1, Monday as 2, etc.
-- @return The day of the week as an integer, or nil if the date is infinite.
function DateObj:day_of_the_week()
    if self._date == "infinite_future" then
        return nil
    end
    return self._date:getweekday()
end

return DateObj
