date = require('today.vendor.date')


DateSpec = {}


function default_today(today)
    if today ~= nil then
        today = date(today)
    else
        today = date()
    end
    return today
end


function is_same_day(d1, d2)
    local y1, m1, d1 = d1:getdate()
    local y2, m2, d2 = d2:getdate()
    return (y1 == y2) and (m1 == m2) and (d1 == d2)
end


function DateSpec:from_string(s)
    local obj = { do_date = date(do_date) }
    self.__index = self
    return setmetatable(obj, self)
end


function DateSpec:new(do_date, today)
    today = default_today(today)

    if do_date == nil then
        do_date = today
    end

    local obj = { do_date = date(do_date) }
    self.__index = self
    return setmetatable(obj, self)
end


function DateSpec:days_from(other_date)
    return math.ceil(date.diff(self.do_date, other_date):spandays())
end


function DateSpec:is_today(today)
    local today = default_today(today)
    return self:days_from(today) == 0
end


function DateSpec:is_future(today)
    local today = default_today(today)
    return self:days_from(today) > 0
end


function DateSpec:is_past(today)
    local today = default_today(today)
    return self:days_from(today) < 0
end


function DateSpec:is_tomorrow(today)
    local today = default_today(today)
    return self:days_from(today) == 1
end


function DateSpec:is_next_week(today)
    local today = default_today(today)
    local difference = self:days_from(today)
    return (difference < 7) and (difference >= 0)
end


function DateSpec:do_in_k_days(k, today)
    local today = default_today(today)
    local tomorrow = today:adddays(k)
    return DateSpec:new(tomorrow, today) 
end


function DateSpec:serialize()
    local y, m, d = self.do_date:getdate()
    return '<' .. y .. '-' .. m .. '-' .. d .. '>'
end


return DateSpec
