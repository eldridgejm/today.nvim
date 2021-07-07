local naturaldate = require("today.core.naturaldate")

describe("natural language to date", function()
    describe("today", function()
        it("converts natural language to date", function()
            assert.are.equal(
                naturaldate.natural_to_absolute("today", "2021-7-5"),
                "2021-07-05"
            )
        end)
    end)

    describe("tomorrow", function()
        it("converts natural language to date", function()
            assert.are.equal(
                naturaldate.natural_to_absolute("tomorrow", "2021-7-5"),
                "2021-07-06"
            )
        end)
    end)

    describe("weekdays", function()
        -- 2021-07-05 was a Monday

        it("converts natural language to date", function()
            assert.are.equal(
                naturaldate.natural_to_absolute("tuesday", "2021-07-5"),
                "2021-07-06"
            )
        end)

        it("converts natural language to date", function()
            assert.are.equal(
                naturaldate.natural_to_absolute("wednesday", "2021-07-05"),
                "2021-07-07"
            )
        end)

        it("converts natural language to date", function()
            assert.are.equal(
                naturaldate.natural_to_absolute("thursday", "2021-07-05"),
                "2021-07-08"
            )
        end)

        it("converts natural language to date", function()
            assert.are.equal(
                naturaldate.natural_to_absolute("friday", "2021-07-05"),
                "2021-07-09"
            )
        end)

        it("converts natural language to date", function()
            assert.are.equal(
                naturaldate.natural_to_absolute("saturday", "2021-07-05"),
                "2021-07-10"
            )
        end)

        it("converts natural language to date", function()
            assert.are.equal(
                naturaldate.natural_to_absolute("sunday", "2021-07-5"),
                "2021-07-11"
            )
        end)

        it("converts natural language to date", function()
            assert.are.equal(
                naturaldate.natural_to_absolute("monday", "2021-07-5"),
                "2021-07-12"
            )
        end)

        it("works with weekday abbreviations", function()
            assert.are.equal(
                naturaldate.natural_to_absolute("m", "2021-07-5"),
                "2021-07-12"
            )
        end)

        it("works with weekday abbreviations", function()
            assert.are.equal(
                naturaldate.natural_to_absolute("th", "2021-07-5"),
                "2021-07-08"
            )
        end)
    end)

    describe("one week from now", function()
        it("converts 1 week from now", function()
            assert.are.equal(
                naturaldate.natural_to_absolute("1 week from now", "2021-7-5"),
                "2021-07-12"
            )
        end)

        it("converts 2 weeks from now", function()
            assert.are.equal(
                naturaldate.natural_to_absolute("2 weeks from now", "2021-7-5"),
                "2021-07-19"
            )
        end)
    end)

    describe("one month from now", function()
        it("converts 1 month from now", function()
            -- adds 30 days
            assert.are.equal(
                naturaldate.natural_to_absolute("1 month from now", "2021-7-5"),
                "2021-08-04"
            )
        end)

        it("converts 2 months from now", function()
            -- adds 60 days
            assert.are.equal(
                naturaldate.natural_to_absolute("2 months from now", "2021-7-5"),
                "2021-09-03"
            )
        end)
    end)

    describe("k days from now", function()
        it("converts natural language to date", function()
            assert.are.equal(
                naturaldate.natural_to_absolute("3 days from now", "2021-7-5"),
                "2021-07-08"
            )
        end)

        it("works with day singular", function()
            assert.are.equal(
                naturaldate.natural_to_absolute("1 day from now", "2021-7-5"),
                "2021-07-06"
            )
        end)

        it("works with lots of days", function()
            assert.are.equal(
                naturaldate.natural_to_absolute("10 days from now", "2021-7-5"),
                "2021-07-15"
            )
        end)
    end)

    describe("next week", function()
        it("resolves to next monday", function()
            assert.are.equal(
                naturaldate.natural_to_absolute("next week", "2021-7-5"),
                "2021-07-12"
            )
        end)
    end)

    describe("next month", function()
        it("resolves to first day of next month", function()
            assert.are.equal(
                naturaldate.natural_to_absolute("next month", "2021-7-5"),
                "2021-08-01"
            )
        end)
    end)
end)

describe("date to natural language", function()
    it("converts today", function()
        assert.are.equal(
            naturaldate.absolute_to_natural("2021-7-5", "2021-7-5"),
            "today"
        )
    end)

    it("converts tomorrow date to natural language", function()
        assert.are.equal(
            naturaldate.absolute_to_natural("2021-7-6", "2021-7-5"),
            "tomorrow"
        )
    end)

    it("converts within 7 days of now to weekdays", function()
        assert.are.equal(
            naturaldate.absolute_to_natural("2021-7-7", "2021-7-5"),
            "wednesday"
        )
    end)

    it("converts within 7 days of now to weekdays", function()
        assert.are.equal(
            naturaldate.absolute_to_natural("2021-7-9", "2021-7-5"),
            "friday"
        )
    end)

    it("converts within 7 days of now to weekday", function()
        assert.are.equal(
            naturaldate.absolute_to_natural("2021-7-11", "2021-7-5"),
            "sunday"
        )
    end)

    it("does not convert exactly one week away", function()
        assert.are.equal(
            naturaldate.absolute_to_natural("2021-7-12", "2021-7-5"),
            "2021-07-12"
        )
    end)
end)
