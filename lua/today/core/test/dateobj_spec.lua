DateObj = require("today.core.dateobj")


describe("dateobj", function()

    it("should be creatable from y, m, d", function()
        local date = DateObj:from_ymd(2020, 12, 10)
        assert.are.equal(date, DateObj:from_ymd(2020, 12, 10))
    end)

    it("should be creatable from string", function()
        local date = DateObj:from_string("2021-10-11")
        assert.are.equal(date, DateObj:from_ymd(2021, 10, 11))
    end)

    describe("infinite_future", function()
        it("should serialize to infinite_future", function()
            assert.are.equal(
            tostring(DateObj:infinite_future()),
            "infinite_future"
            )
        end)
    end)

    describe("infinite_past", function()
        it("should serialize to infinite_past", function()
            assert.are.equal(
            tostring(DateObj:infinite_past()),
            "infinite_past"
            )
        end)
    end)

    describe("equals", function()
        it("should work with normal dates", function()
            local ds1 = DateObj:from_ymd(2021, 07, 04)
            local ds2 = DateObj:from_ymd(2021, 07, 04)
            assert.are.equal(ds1, ds2)
        end)

        it("should work with normal unequal dates", function()
            local ds1 = DateObj:from_ymd(2021, 07, 04)
            local ds2 = DateObj:from_ymd(2021, 07, 05)
            assert.are.not_equal(ds1, ds2)
        end)

        it("should work with infinite_future", function()
            local ds1 = DateObj:infinite_future()
            local ds2 = DateObj:infinite_future()
            assert.are.equal(ds1, ds2)
        end)

        it("should return unequal when one is infinite and one is finite", function()
            local ds1 = DateObj:from_ymd(2021, 10, 2)
            local ds2 = DateObj:infinite_future()
            assert.are.not_equal(ds1, ds2)
        end)

        it("should work with infinite_past", function()
            local ds1 = DateObj:infinite_past()
            local ds2 = DateObj:infinite_past()
            assert.are.equal(ds1, ds2)
        end)

        it("should return unequal when one is infinite and one is finite", function()
            local ds1 = DateObj:from_ymd(2021, 10, 2)
            local ds2 = DateObj:infinite_past()
            assert.are.not_equal(ds1, ds2)
        end)
    end)

    describe("add_days", function()
        it("should work with positive deltas", function()
            local ds = DateObj:from_ymd(2020, 10, 5):add_days(1)
            assert.are.equal(ds, DateObj:from_ymd(2020, 10, 6))
        end)
        it("should work with negative deltas", function()
            local ds = DateObj:from_ymd(2020, 10, 5):add_days(-4)
            assert.are.equal(ds, DateObj:from_ymd(2020, 10, 1))
        end)
        it("should work with zero deltas", function()
            local ds = DateObj:from_ymd(2020, 10, 5):add_days(0)
            assert.are.equal(ds, DateObj:from_ymd(2020, 10, 5))
        end)

        it("should return infinite_future when days are added to infinite_future", function()
            local ds = DateObj:infinite_future():add_days(0)
            assert.are.equal(ds, DateObj:infinite_future())
        end)

        it("should return infinite_past when days are added to infinite_past", function()
            local ds = DateObj:infinite_past():add_days(0)
            assert.are.equal(ds, DateObj:infinite_past())
        end)
    end)


    describe("ymd", function()

        it("should return a triple", function()
            local ds = DateObj:from_ymd(2021, 10, 4)
            local y, m, d = ds:ymd()
            assert.are.same({y, m, d}, {2021, 10, 4})
        end)

        it("should return nil if infinite_future", function()
            assert.are.equal(
                DateObj:infinite_future():ymd(),
                nil
                )
        end)

        it("should return nil if infinite_past", function()
            assert.are.equal(
                DateObj:infinite_past():ymd(),
                nil
                )
        end)

    end)

    describe("days_until", function()
        it("should work for days in the future", function()
            local ds = DateObj:from_ymd(2021, 7, 4)
            assert.are.equal(
                ds:days_until(DateObj:from_ymd(2021, 7, 10)),
                6
            )
        end)

        it("should work for days in the past", function()
            local ds = DateObj:from_ymd(2021, 7, 4)
            assert.are.equal(
                ds:days_until(DateObj:from_ymd(2021, 7, 1)),
                -3
            )
        end)

        it("should return -math.huge if self is infinite_future", function()
            local ds1 = DateObj:infinite_future()
            local ds2 = DateObj:from_ymd(2021, 7, 4)
            assert.are.equal(
                ds1:days_until(ds2),
                -math.huge
            )
        end)

        it("should return nil if both infinite_future", function()
            local ds1 = DateObj:infinite_future()
            local ds2 = DateObj:infinite_future()
            assert.are.equal(
                ds1:days_until(ds2),
                nil
            )
        end)

        it("should return math.huge if other is infinite_future", function()
            local ds = DateObj:from_ymd(2021, 7, 4)
            assert.are.equal(
                ds:days_until(DateObj:infinite_future()),
                math.huge
            )
        end)

        it("should return math.huge if self is infinite_past", function()
            local ds1 = DateObj:infinite_past()
            local ds2 = DateObj:from_ymd(2021, 7, 4)
            assert.are.equal(
                ds1:days_until(ds2),
                math.huge
            )
        end)

        it("should return nil if both infinite_past", function()
            local ds1 = DateObj:infinite_past()
            local ds2 = DateObj:infinite_past()
            assert.are.equal(
                ds1:days_until(ds2),
                nil
            )
        end)

        it("should return -math.huge if other is infinite_past", function()
            local ds = DateObj:from_ymd(2021, 7, 4)
            assert.are.equal(
                ds:days_until(DateObj:infinite_past()),
                -math.huge
            )
        end)

        it("should return math.huge infinite_past to infinite_future", function()
            local ds1 = DateObj:infinite_past()
            local ds2 = DateObj:infinite_future()
            assert.are.equal(
                ds1:days_until(ds2),
                math.huge
            )
        end)

        it("should return -math.huge infinite_past to infinite_future", function()
            local ds1 = DateObj:infinite_past()
            local ds2 = DateObj:infinite_future()
            assert.are.equal(
                ds2:days_until(ds1),
                -math.huge
            )
        end)
    end)

end)
