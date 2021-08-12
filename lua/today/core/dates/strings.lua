local DateObj = require("today.core.dates.dateobj")

local M = {}

M.WEEKDAYS = {
    "sunday",
    "monday",
    "tuesday",
    "wednesday",
    "thursday",
    "friday",
    "saturday",
}

M.WEEKDAYS_3_CHARS = {
    "sun",
    "mon",
    "tue",
    "wed",
    "thu",
    "fri",
    "sat",
}

M.MONTHS = {
    "january",
    "february",
    "march",
    "april",
    "may",
    "june",
    "july",
    "august",
    "september",
    "october",
    "december",
}

M.MONTHS_3_CHARS = {
    "jan",
    "feb",
    "mar",
    "apr",
    "may",
    "jun",
    "jul",
    "aug",
    "sep",
    "oct",
    "nov",
    "dec",
}

--- Converts a date into a human datestamp of the form "mon jul 05 2021".
function M.to_datestamp(date)
    date = DateObj:new(date)
    local y, m, d = date:ymd()
    local wd = date:day_of_the_week()

    if d < 10 then
        d = "0" .. d
    end

    wd = M.WEEKDAYS_3_CHARS[wd]
    m = M.MONTHS_3_CHARS[m]

    return wd .. " " .. m .. " " .. d .. " " .. y
end

--- Converts a date into a string of the form "jul 05".
function M.to_month_day(date)
    date = DateObj:new(date)
    local _, m, d = date:ymd()

    if d < 10 then
        d = "0" .. d
    end

    m = M.MONTHS_3_CHARS[m]

    return m .. " " .. d
end

return M
