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


function parse(spec, today)
    if spec == nil then
        return today
    end

    local do_date = spec:match('<(.*)>')
    if do_date == nil then
        error('Date spec ' .. spec .. ' is not valid')
    end

    if spec == '<today>' then
        return today
    elseif spec == '<tomorrow>' then
        return today:adddays(1)
    else
        -- the spec contains a date string
        return date(do_date)
    end
end


function DateSpec:new(spec, today)
    today = default_today(today)
    local do_date = parse(spec, today)
    local obj = { do_date = do_date, today = today }
    self.__index = self
    return setmetatable(obj, self)
end


function DateSpec:days_from(other_date)
    return math.ceil(date.diff(self.do_date, other_date):spandays())
end


function DateSpec:is_today()
    return self:days_from(self.today) == 0
end


function DateSpec:is_future()
    return self:days_from(self.today) > 0
end


function DateSpec:is_past()
    return self:days_from(self.today) < 0
end


function DateSpec:is_tomorrow()
    return self:days_from(self.today) == 1
end


function DateSpec:is_next_week()
    local difference = self:days_from(self.today)
    return (difference < 7) and (difference >= 0)
end


function DateSpec:do_in_k_days(k)
    local tomorrow = self.today:adddays(k)
    local y, m, d = tomorrow:getdate()
    local spec = '<' .. y .. '-' .. m .. '-' .. d .. '>'
    return DateSpec:new(spec, self.today) 
end


function DateSpec:serialize()
    local y, m, d = self.do_date:getdate()
    return '<' .. y .. '-' .. m .. '-' .. d .. '>'
end


return DateSpec
