local recurring = require("today.core.datespec.recurring")
local DateObj = require("today.core.datespec.dateobj")

describe("next", function()
    it("should recognize daily", function()
        local result = recurring.next("2021-07-04", "daily")
        assert.are.equal(result, DateObj:new("2021-07-05"))
    end)

    it("should recognize daily", function()
        local result = recurring.next("2021-07-04", "every day")
        assert.are.equal(result, DateObj:new("2021-07-05"))
    end)

    it("should recognize weekly", function()
        local result = recurring.next("2021-07-04", "weekly")
        assert.are.equal(result, DateObj:new("2021-07-11"))
    end)

    it("should recognize every week", function()
        local result = recurring.next("2021-07-04", "every week")
        assert.are.equal(result, DateObj:new("2021-07-11"))
    end)

    it("should recognize monthly", function()
        local result = recurring.next("2021-07-04", "monthly")
        assert.are.equal(result, DateObj:new("2021-08-04"))
    end)

    it("should recognize every month", function()
        local result = recurring.next("2021-07-04", "every month")
        assert.are.equal(result, DateObj:new("2021-08-04"))
    end)

    it("should recognize monthly (what happens at end of month?)", function()
        local result = recurring.next("2021-08-31", "monthly")
        assert.are.equal(result, DateObj:new("2021-10-01"))
    end)

    it("should recognize every monday", function()
        local result = recurring.next("2021-07-04", "every monday")
        assert.are.equal(result, DateObj:new("2021-07-05"))
    end)

    it("should recognize every tues", function()
        local result = recurring.next("2021-07-04", "every tues")
        assert.are.equal(result, DateObj:new("2021-07-06"))
    end)

    it("should recognize every mon,wed,fri from monday", function()
        local result = recurring.next("2021-07-05", "every mon, wed,fri")
        assert.are.equal(result, DateObj:new("2021-07-07"))
    end)

    it("should recognize every m,w,f from monday", function()
        local result = recurring.next("2021-07-05", "every m,w,f")
        assert.are.equal(result, DateObj:new("2021-07-07"))
    end)

    it("should recognize every mon,wed,fri from friday", function()
        local result = recurring.next("2021-07-09", "every mon, wed,fri")
        assert.are.equal(result, DateObj:new("2021-07-12"))
    end)

    it("should recognize every sunday on a sunday and move to next week", function()
        local result = recurring.next("2021-07-04", "every sunday")
        assert.are.equal(result, DateObj:new("2021-07-11"))
    end)
end)
