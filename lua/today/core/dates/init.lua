--- Dates
-- @module core.dates
-- @alias dates

local M = {}

local function slurp(m)
    local other_module = require(m)
    for key, member in pairs(other_module) do
        M[key] = member
    end
end

M.DateObj = require("today.core.dates.dateobj")

slurp("today.core.dates.natural")
slurp("today.core.dates.recurring")
slurp("today.core.dates.strings")

return M
