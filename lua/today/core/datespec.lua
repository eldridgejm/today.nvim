date = require('today.vendor.date')
naturaldate = require('today.core.naturaldate')


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
    -- Parse a date spec string to a date object
    if spec == nil then
        return today
    end

    local do_date = spec:match('<(.*)>')
    if do_date == nil then
        error('Date spec ' .. spec .. ' is not valid')
    end

    return date(naturaldate.natural_to_date(do_date, today))

end


function DateSpec:new(spec, today)
    today = default_today(today)
    local do_date = parse(spec, today)
    local obj = { do_date = do_date, today = today }
    -- ensure that these are date tables
    assert(do_date.getdate ~= nil, 'do_date is not a date object')
    assert(today.getdate ~= nil, 'today is not a date object')
    self.__index = self
    return setmetatable(obj, self)
end


function DateSpec:days_from(other_date)
    other_date = date(other_date)
    return math.ceil(date.diff(self.do_date, other_date):spandays())
end


function DateSpec:is_future()
    return self:days_from(self.today) > 0
end


function DateSpec:is_past()
    return self:days_from(self.today) < 0
end


function DateSpec:is_today()
    return self:days_from(self.today) == 0
end


function DateSpec:is_tomorrow()
    return self:days_from(self.today) == 1
end


function DateSpec:is_this_week()
    local difference = self:days_from(self.today)
    return (difference < 7) and (difference >= 0)
end


function DateSpec:serialize(natural)
    local do_date = self.do_date:fmt('%Y-%m-%d')
    if natural then
        do_date = naturaldate.date_to_natural(do_date, self.today)
    end

    return '<' .. do_date .. '>'
end


return DateSpec
