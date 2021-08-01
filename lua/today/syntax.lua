local do_date_patterns = {
    "today",
    "\\d\\{4\\}-\\d\\{1,2\\}-\\d\\{1,2\\}",
    "tom",
    "tomorrow",
    "next week",
    "next month",
    "yesterday",
    "someday",
    "\\d\\+ days ago",
    "\\d\\+ days from now",
    "\\d\\+ weeks from now",
    "\\d\\+ months from now",
}

local weekday_prefixes = {
    "monday",
    "monda",
    "mond",
    "mon",
    "mo",
    "m",
    "tuesday",
    "tuesda",
    "tuesd",
    "tues",
    "tue",
    "tu",
    "wednesday",
    "wednesda",
    "wednesd",
    "wednes",
    "wedne",
    "wedn",
    "wed",
    "we",
    "w",
    "thursday",
    "thursda",
    "thursd",
    "thurs",
    "thur",
    "thu",
    "th",
    "friday",
    "frida",
    "frid",
    "fri",
    "fr",
    "f",
    "saturday",
    "saturda",
    "saturd",
    "satur",
    "satu",
    "sat",
    "sa",
    "sunday",
    "sunda",
    "sund",
    "sun",
    "su",
}

for _, prefix in pairs(weekday_prefixes) do
    table.insert(do_date_patterns, prefix)
    table.insert(do_date_patterns, "next " .. prefix)
end

local weekday_short = {
    "mon",
    "tue",
    "wed",
    "thu",
    "fri",
    "sat",
    "sun",
}

local month_short = {
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

for _, weekday in pairs(weekday_short) do
    for _, month in pairs(month_short) do
        local pattern = weekday .. " " .. month .. " \\d\\{1,2\\} \\d\\{4\\}"
        table.insert(do_date_patterns, pattern)
    end
end

local recur_patterns = {
    "every day",
    "every other day",
    "every \\d\\+ days",
    "daily",
    "weekly",
    "every week",
    "every other week",
    "every \\d\\+ weeks",
    "every month",
    "every other month",
    "every \\d\\+ months",
    "monthly",
    "every year",
    "every other year",
    "every \\d\\+ years",
    "yearly",
}

local weekday_pattern = "\\%\\(\\%\\("
    .. table.concat(weekday_prefixes, "\\|")
    .. "\\)\\)"
table.insert(
    recur_patterns,
    "every " .. weekday_pattern .. "\\%(,\\s*" .. weekday_pattern .. "\\)*"
)

return {
    recur_patterns = recur_patterns,
    do_date_patterns = do_date_patterns,
}
