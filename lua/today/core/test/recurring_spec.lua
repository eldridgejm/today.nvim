local dateslib = require("today.core.dates")
local DateObj = dateslib.DateObj

describe("next", function()
    it("should recognize daily", function()
        local result = dateslib.next("2021-07-04", "daily")
        assert.are.equal(result, DateObj:new("2021-07-05"))
    end)

    it("should recognize daily", function()
        local result = dateslib.next("2021-07-04", "every day")
        assert.are.equal(result, DateObj:new("2021-07-05"))
    end)

    it("should recognize every other day", function()
        local result = dateslib.next("2021-07-04", "every other day")
        assert.are.equal(result, DateObj:new("2021-07-06"))
    end)

    it("should recognize every k days", function()
        local result = dateslib.next("2021-07-04", "every 4 days")
        assert.are.equal(result, DateObj:new("2021-07-08"))
    end)

    it("should recognize weekly", function()
        local result = dateslib.next("2021-07-04", "weekly")
        assert.are.equal(result, DateObj:new("2021-07-11"))
    end)

    it("should recognize every week", function()
        local result = dateslib.next("2021-07-04", "every week")
        assert.are.equal(result, DateObj:new("2021-07-11"))
    end)

    it("should recognize every other week", function()
        local result = dateslib.next("2021-07-04", "every other week")
        assert.are.equal(result, DateObj:new("2021-07-18"))
    end)

    it("should recognize every k weeks", function()
        local result = dateslib.next("2021-07-04", "every 3 weeks")
        assert.are.equal(result, DateObj:new("2021-07-25"))
    end)

    it("should recognize monthly", function()
        local result = dateslib.next("2021-07-04", "monthly")
        assert.are.equal(result, DateObj:new("2021-08-04"))
    end)

    it("should recognize every month", function()
        local result = dateslib.next("2021-07-04", "every month")
        assert.are.equal(result, DateObj:new("2021-08-04"))
    end)

    it("should recognize every other month", function()
        local result = dateslib.next("2021-07-04", "every other month")
        assert.are.equal(result, DateObj:new("2021-09-04"))
    end)

    it("should recognize every k months", function()
        local result = dateslib.next("2021-07-04", "every 3 months")
        assert.are.equal(result, DateObj:new("2021-10-05"))
    end)

    it("should recognize monthly (what happens at end of month?)", function()
        local result = dateslib.next("2021-08-31", "monthly")
        assert.are.equal(result, DateObj:new("2021-10-01"))
    end)

    it("should recognize every 15th (st,nd,rd)", function()
        local result = dateslib.next("2021-08-31", "every 15th")
        assert.are.equal(result, DateObj:new("2021-9-15"))
    end)

    it("should recognize every 15th (st,nd,rd) if tomorrow", function()
        local result = dateslib.next("2021-09-14", "every 15th")
        assert.are.equal(result, DateObj:new("2021-9-15"))
    end)

    it("should recognize every 15th (st,nd,rd) if today", function()
        local result = dateslib.next("2021-09-15", "every 15th")
        assert.are.equal(result, DateObj:new("2021-10-15"))
    end)

    it("should recognize every monday", function()
        local result = dateslib.next("2021-07-04", "every monday")
        assert.are.equal(result, DateObj:new("2021-07-05"))
    end)

    it("should recognize every tues", function()
        local result = dateslib.next("2021-07-04", "every tues")
        assert.are.equal(result, DateObj:new("2021-07-06"))
    end)

    it("should recognize every mon,wed,fri from monday", function()
        local result = dateslib.next("2021-07-05", "every mon, wed,fri")
        assert.are.equal(result, DateObj:new("2021-07-07"))
    end)

    it("should not recognize every xyz,wed,fri from monday", function()
        local result = dateslib.next("2021-07-05", "every xyz, wed,fri")
        assert.are.equal(result, DateObj:new("2021-07-07"))
    end)

    it("should recognize every m,w,f from monday", function()
        local result = dateslib.next("2021-07-05", "every m,w,f")
        assert.are.equal(result, DateObj:new("2021-07-07"))
    end)

    it("should recognize every mon,wed,fri from friday", function()
        local result = dateslib.next("2021-07-09", "every mon, wed,fri")
        assert.are.equal(result, DateObj:new("2021-07-12"))
    end)

    it("should recognize every sunday on a sunday and move to next week", function()
        local result = dateslib.next("2021-07-04", "every sunday")
        assert.are.equal(result, DateObj:new("2021-07-11"))
    end)

    it("should recognize every year", function()
        local result = dateslib.next("2021-07-04", "every year")
        assert.are.equal(result, DateObj:new("2022-07-04"))
    end)

    it("should recognize every other years", function()
        local result = dateslib.next("2021-07-04", "every other year")
        assert.are.equal(result, DateObj:new("2023-07-04"))
    end)

    it("should recognize every k years", function()
        local result = dateslib.next("2021-07-04", "every 5 years")
        assert.are.equal(result, DateObj:new("2026-07-03"))
    end)
end)
