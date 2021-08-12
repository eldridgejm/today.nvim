local dateslib = require("today.core.dates")
local DateObj = dateslib.DateObj

describe("natural language to date", function()
    describe("today", function()
        it("converts natural language to date", function()
            assert.are.equal(
                dateslib.from_natural("today", DateObj:new("2021-7-5")),
                DateObj:new("2021-07-05")
            )
        end)
    end)

    describe("tomorrow", function()
        it("converts natural language to date", function()
            assert.are.equal(
                dateslib.from_natural("tomorrow", DateObj:new("2021-7-5")),
                DateObj:new("2021-07-06")
            )
        end)

        it("converts tom to tomorrow", function()
            assert.are.equal(
                dateslib.from_natural("tom", DateObj:new("2021-7-5")),
                DateObj:new("2021-07-06")
            )
        end)
    end)

    describe("someday", function()
        it("converts natural language to date", function()
            assert.are.equal(
                dateslib.from_natural("someday", DateObj:new("2021-7-5")),
                DateObj:infinite_future()
            )
        end)
    end)

    describe("weekdays", function()
        -- 2021-07-05 was a Monday

        it("converts natural language to date", function()
            assert.are.equal(
                dateslib.from_natural("tuesday", DateObj:new("2021-07-5")),
                DateObj:new("2021-07-06")
            )
        end)

        it("converts natural language to date", function()
            assert.are.equal(
                dateslib.from_natural("wednesday", DateObj:new("2021-07-05")),
                DateObj:new("2021-07-07")
            )
        end)

        it("converts natural language to date", function()
            assert.are.equal(
                dateslib.from_natural("thursday", DateObj:new("2021-07-05")),
                DateObj:new("2021-07-08")
            )
        end)

        it("converts natural language to date", function()
            assert.are.equal(
                dateslib.from_natural("friday", DateObj:new("2021-07-05")),
                DateObj:new("2021-07-09")
            )
        end)

        it("converts natural language to date", function()
            assert.are.equal(
                dateslib.from_natural("saturday", DateObj:new("2021-07-05")),
                DateObj:new("2021-07-10")
            )
        end)

        it("considers sunday to be today", function()
            -- 7/4 was a sunday
            assert.are.equal(
                dateslib.from_natural("sunday", DateObj:new("2021-07-4")),
                DateObj:new("2021-07-4")
            )
        end)

        it("converts natural language to date", function()
            assert.are.equal(
                dateslib.from_natural("monday", DateObj:new("2021-07-4")),
                DateObj:new("2021-07-5")
            )
        end)

        it("works with weekday abbreviations", function()
            assert.are.equal(
                dateslib.from_natural("m", DateObj:new("2021-07-4")),
                DateObj:new("2021-07-5")
            )
        end)

        it("works with weekday abbreviations", function()
            assert.are.equal(
                dateslib.from_natural("th", DateObj:new("2021-07-5")),
                DateObj:new("2021-07-08")
            )
        end)
    end)

    describe("next (weekday)", function()
        -- for these tests, it is useful to know that 2021-04-04 was a Sunday
        it("should consider next sunday to be a week away", function()
            assert.are.equal(
                dateslib.from_natural("next sunday", DateObj:new("2021-07-04")),
                DateObj:new("2021-07-11")
            )
        end)

        it("should use the second instance of the weekday", function()
            assert.are.equal(
                dateslib.from_natural("next monday", DateObj:new("2021-07-04")),
                DateObj:new("2021-07-12")
            )
        end)

        it("should work with short names", function()
            assert.are.equal(
                dateslib.from_natural("next mon", DateObj:new("2021-07-04")),
                DateObj:new("2021-07-12")
            )
        end)

        it("converts natural language to date", function()
            assert.are.equal(
                dateslib.from_natural("next tuesday", DateObj:new("2021-07-4")),
                DateObj:new("2021-07-13")
            )
        end)

        it("converts natural language to date", function()
            assert.are.equal(
                dateslib.from_natural("next wednesday", DateObj:new("2021-07-04")),
                DateObj:new("2021-07-14")
            )
        end)

        it("converts natural language to date", function()
            assert.are.equal(
                dateslib.from_natural("next thursday", DateObj:new("2021-07-04")),
                DateObj:new("2021-07-15")
            )
        end)

        it("converts natural language to date", function()
            assert.are.equal(
                dateslib.from_natural("next friday", DateObj:new("2021-07-04")),
                DateObj:new("2021-07-16")
            )
        end)

        it("converts natural language to date", function()
            assert.are.equal(
                dateslib.from_natural("next saturday", DateObj:new("2021-07-04")),
                DateObj:new("2021-07-17")
            )
        end)

        it("converts natural language to date", function()
            assert.are.equal(
                dateslib.from_natural("next sunday", DateObj:new("2021-07-4")),
                DateObj:new("2021-07-11")
            )
        end)
    end)

    describe("one week from now", function()
        it("converts 1 week from now", function()
            assert.are.equal(
                dateslib.from_natural("1 week from now", DateObj:new("2021-7-5")),
                DateObj:new("2021-07-12")
            )
        end)

        it("converts 2 weeks from now", function()
            assert.are.equal(
                dateslib.from_natural("2 weeks from now", DateObj:new("2021-7-5")),
                DateObj:new("2021-07-19")
            )
        end)
    end)

    describe("one month from now", function()
        it("converts 1 month from now", function()
            -- adds 30 days
            assert.are.equal(
                dateslib.from_natural("1 month from now", DateObj:new("2021-7-5")),
                DateObj:new("2021-08-04")
            )
        end)

        it("converts 2 months from now", function()
            -- adds 60 days
            assert.are.equal(
                dateslib.from_natural("2 months from now", DateObj:new("2021-7-5")),
                DateObj:new("2021-09-03")
            )
        end)
    end)

    describe("k days from now", function()
        it("converts natural language to date", function()
            assert.are.equal(
                dateslib.from_natural("3 days from now", DateObj:new("2021-7-5")),
                DateObj:new("2021-07-08")
            )
        end)

        it("works with day singular", function()
            assert.are.equal(
                dateslib.from_natural("1 day from now", DateObj:new("2021-7-5")),
                DateObj:new("2021-07-06")
            )
        end)

        it("works with lots of days", function()
            assert.are.equal(
                dateslib.from_natural("10 days from now", DateObj:new("2021-7-5")),
                DateObj:new("2021-07-15")
            )
        end)
    end)

    describe("next week", function()
        it("resolves to next monday", function()
            assert.are.equal(
                dateslib.from_natural("next week", DateObj:new("2021-7-5")),
                DateObj:new("2021-07-12")
            )
        end)
    end)

    describe("next month", function()
        it("resolves to first day of next month", function()
            assert.are.equal(
                dateslib.from_natural("next month", DateObj:new("2021-7-5")),
                DateObj:new("2021-08-01")
            )
        end)
    end)

    describe("datestamp", function()
        it("is case insensitive", function()
            assert.are.equal(
                dateslib.from_natural("mon jul 05 2021", DateObj:new("2021-1-1")),
                DateObj:new("2021-07-5")
            )
        end)

        it("is case insensitive (capitalized)", function()
            assert.are.equal(
                dateslib.from_natural("MoN jUl 05 2021", DateObj:new("2021-1-1")),
                DateObj:new("2021-07-5")
            )
        end)

        it("is doesnt care if the day of week is wrong", function()
            -- july 4 was a sunday
            local actual = dateslib.from_natural("mon jul 04 2021", DateObj:new("2021-1-1"))
            assert.are.equal(
                actual,
                DateObj:new("2021-07-4")
            )
        end)

        it("should infer the year to be the year on the next occurrence of m/d", function()
            -- july 4 was a sunday
            assert.are.same(
                dateslib.from_natural("jan 05", DateObj:new("2021-10-10")),
                DateObj:new("2022-01-05")
            )
        end)

        it("should not care about zero padding", function()
            -- july 4 was a sunday
            assert.are.same(
                dateslib.from_natural("jan 5", DateObj:new("2021-1-1")),
                DateObj:new("2021-01-05")
            )
        end)

        it("should work with long month name", function()
            -- july 4 was a sunday
            assert.are.same(
                dateslib.from_natural("january 5", DateObj:new("2021-1-1")),
                DateObj:new("2021-01-05")
            )
        end)

        it("should work with year as well", function()
            -- july 4 was a sunday
            assert.are.same(
                dateslib.from_natural("january 5 2021", DateObj:new("2021-1-1")),
                DateObj:new("2021-01-05")
            )
        end)

        it("should work with long weekday", function()
            -- july 4 was a sunday
            assert.are.same(
                dateslib.from_natural("monday january 5 2021", DateObj:new("2021-1-1")),
                DateObj:new("2021-01-05")
            )
        end)


    end)

    describe("past dates", function()
        it("resolves yesterday", function()
            assert.are.equal(
                dateslib.from_natural("yesterday", DateObj:new("2021-7-5")),
                DateObj:new("2021-07-04")
            )
        end)

        it("resolves dates in the past", function()
            assert.are.equal(
                dateslib.from_natural("2 days ago", DateObj:new("2021-7-5")),
                DateObj:new("2021-07-03")
            )
        end)

        it("resolves dates in the distant past", function()
            assert.are.equal(
                dateslib.from_natural("398 days ago", DateObj:new("2021-7-5")),
                DateObj:new("2020-06-02")
            )
        end)
    end)

    it("returns nil when given an invalid date", function()
        assert.are.equal(dateslib.from_natural("zzz", DateObj:new("2021-7-5")), nil)
    end)
end)

describe("date to natural language", function()
    it("converts today", function()
        assert.are.equal(
            dateslib.to_natural("2021-7-5", DateObj:new("2021-7-5")),
            "today"
        )
    end)

    it("converts tomorrow date to natural language", function()
        assert.are.equal(
            dateslib.to_natural("2021-7-6", DateObj:new("2021-7-5")),
            "tomorrow"
        )
    end)

    it("converts within 7 days of now to weekdays", function()
        assert.are.equal(
            dateslib.to_natural("2021-7-7", DateObj:new("2021-7-5")),
            "wednesday"
        )
    end)

    it("converts within 7 days of now to weekdays", function()
        assert.are.equal(
            dateslib.to_natural("2021-7-9", DateObj:new("2021-7-5")),
            "friday"
        )
    end)

    it("converts within 7 days of now to weekday", function()
        assert.are.equal(
            dateslib.to_natural("2021-7-11", DateObj:new("2021-7-5")),
            "sunday"
        )
    end)

    it("converts exactly one week away to 'next monday', e.g.", function()
        -- 7/12 was a monday
        assert.are.equal(
            dateslib.to_natural("2021-7-12", DateObj:new("2021-7-5")),
            "next monday"
        )
    end)

    it("converts yesterday", function()
        assert.are.equal(
            dateslib.to_natural("2021-7-4", DateObj:new("2021-7-5")),
            "yesterday"
        )
    end)

    it("converts dates in the past", function()
        assert.are.equal(
            dateslib.to_natural("2021-7-3", DateObj:new("2021-7-5")),
            "2 days ago"
        )
    end)

    it("converts dates in the distant past", function()
        assert.are.equal(
            dateslib.to_natural("2020-6-2", DateObj:new("2021-7-5")),
            "398 days ago"
        )
    end)

    it("converts infinite_future to someday", function()
        assert.are.equal(
            dateslib.to_natural(DateObj:infinite_future(), "2021-07-04"),
            "someday"
        )
    end)

    it("uses YYYY-MM-DD as default default_format", function()
        assert.are.equal(dateslib.to_natural("2021-08-10", "2021-07-04"), "2021-08-10")
    end)

    it("has option to use datestamp as default", function()
        assert.are.equal(
            dateslib.to_natural(
                "2021-08-10",
                "2021-07-04",
                { default_format = "datestamp" }
            ),
            "tue aug 10 2021"
        )
    end)

    it("converts dates from next week using l days from now", function()
        assert.are.equal(
            dateslib.to_natural(
                "2021-07-30",
                "2021-07-04",
                { default_format = "datestamp", days_until_absolute = 100 }
            ),
            "26 days from now"
        )
    end)

    it("obeys options.days_until_absolute", function()
        assert.are.equal(
            dateslib.to_natural(
                "2021-07-08",
                "2021-07-04",
                { days_until_absolute = 3, default_format = "datestamp" }
            ),
            "thu jul 08 2021"
        )
    end)
end)
