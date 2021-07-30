local DateObj = require("today.core.datespec.dateobj")

describe("Today core module's", function()
    local task = require("today.core.task")

    describe("is_done", function()
        it("should consider a task without a checkbox to be undone", function()
            assert.falsy(task.is_done("this is not done"))
        end)
    end)

    describe("set_priority", function()
        it("should add priority to end if nonexistant", function()
            assert.are.equal(task.set_priority("testing", 2), "testing !!")
        end)

        it("should trim when adding priority", function()
            assert.are.equal(task.set_priority("testing   ", 2), "testing !!")
        end)

        it("should change existing priority in-place", function()
            assert.are.equal(task.set_priority("testing !!", 1), "testing !")
        end)
    end)

    describe("get_priority_as_string", function()
        it("should not get confused by other !s", function()
            assert.are.equal(task.get_priority_as_string("[x] !! testing!"), "!!")
        end)

        it("should work with priority at end of string", function()
            assert.are.equal(task.get_priority_as_string("[x] testing !!"), "!!")
        end)

        it("should return nil if no priority", function()
            assert.are.equal(task.get_priority_as_string("[x] testing"), nil)
        end)
    end)

    describe("remove_priority", function()
        it("should have proper whitespace if no priority", function()
            local line = "[x] no priority!"
            assert.are.equal(task.remove_priority(line), "[x] no priority!")
        end)

        it("should remove the priority at beginning", function()
            local line = "[x] !! this is a test!"
            assert.are.equal(task.remove_priority(line), "[x] this is a test!")
        end)

        it("should remove the priority in middle", function()
            local line = "[x] this is !! a test!"
            assert.are.equal(task.remove_priority(line), "[x] this is a test!")
        end)

        it("should remove the priority at end", function()
            local line = "[x] this is a test! !!"
            assert.are.equal(task.remove_priority(line), "[x] this is a test!")
        end)
    end)

    describe("normalize", function()
        it("should add a checkbox to a line without one", function()
            assert.are.equal(task.normalize("this is a test"), "[ ] this is a test")
        end)

        it("should leave line unchanged if checkbox exists", function()
            assert.are.equal(task.normalize("[ ] task"), "[ ] task")
        end)

        it("should move the datespec to the beginning", function()
            assert.are.equal(
                task.normalize("[ ] this <2020-10-10> is nice"),
                "[ ] <2020-10-10> this is nice"
            )
        end)

        it("should be idempotent if already normalized", function()
            local result = task.normalize("[x] <today> !! testing", "2021-02-03")
            assert.are.equal(result, "[x] <today> !! testing")
        end)
    end)

    describe("is_task", function()
        it("should detect a task line", function()
            assert.truthy(task.is_task("[x] this is a test"))
        end)

        it("should detect a comment", function()
            assert.falsy(task.is_task("-- [x] this is a test"))
        end)

        it("should detect an empty line", function()
            assert.falsy(task.is_task(""))
        end)
    end)

    describe("get_description", function()
        it("should extract the description", function()
            assert.are.equal(
                task.get_description("[x] this is <2021-10-01> a !! test"),
                "this is a test"
            )
        end)
    end)

    describe("get_tags", function()
        it("should retrieve all tags in order of appearance", function()
            assert.are.same(
                task.get_tags("testing #one #two is not #three"),
                { "#one", "#two", "#three" }
            )
        end)
        it("should allow numbers/hyphens/underscores in the tag", function()
            assert.are.same(
                task.get_tags("testing #one-same #two22 and this #three_ok"),
                { "#one-same", "#two22", "#three_ok" }
            )
        end)
        it("should normalize tags to lower case", function()
            assert.are.same(
                task.get_tags("testing #ONE #TwO is not #Three"),
                { "#one", "#two", "#three" }
            )
        end)
    end)

    describe("get_first_tag", function()
        it("should retrieve the first tag", function()
            assert.are.equal(
                task.get_first_tag("testing #one #two is not #three"),
                "#one"
            )
        end)
        it("should return nil if no tags", function()
            assert.are.equal(task.get_first_tag("this has no tags!"), nil)
        end)
    end)

    describe("get_datespec_safe", function()
        it("should get the do_date as a DateSpec", function()
            local ds = task.get_datespec_safe("[x] tast <2021-07-5>", "2021-03-05")
            local y, m, d = ds.do_date:ymd()
            assert.are.same({ y, m, d }, { 2021, 7, 5 })
        end)

        it("should return today if there is not date string", function()
            local ds = task.get_datespec_safe("[x] tast", "2021-03-05")
            local y, m, d = ds.do_date:ymd()
            assert.are.same({ y, m, d }, { 2021, 3, 5 })
        end)
    end)

    describe("make datespec absolute", function()
        it("should convert today to absolute", function()
            local result = task.make_datespec_absolute("[x] task <today>", "2021-02-03")
            assert.are.equal(result, "[x] task <2021-02-03>")
        end)

        it("should leave string unchanged if no datespec present", function()
            local result = task.make_datespec_absolute("[x] task", "2021-02-03")
            assert.are.equal(result, "[x] task")
        end)

        it("should convert tomorrow to absolute", function()
            local result = task.make_datespec_absolute(
                "[x] task <tomorrow>",
                "2021-02-03"
            )
            assert.are.equal(result, "[x] task <2021-02-04>")
        end)

        it("should work if date in canonical position", function()
            local result = task.make_datespec_absolute(
                "[x] <today> testing",
                "2021-02-03"
            )
            assert.are.equal(result, "[x] <2021-02-03> testing")
        end)

        it("should not convert absolute dates", function()
            local result = task.make_datespec_absolute(
                "[x] task <2021-1-2>",
                "2021-02-03"
            )
            assert.are.equal(result, "[x] task <2021-01-02>")
        end)

        it("should convert weekdays within next 7 days", function()
            local result = task.make_datespec_absolute(
                "[x] task <wednesday>",
                "2021-07-04"
            )
            assert.are.equal(result, "[x] task <2021-07-07>")
        end)

        it("should leave string unchanged if no datespec present", function()
            local result = task.make_datespec_absolute("[x] task", "2021-07-05")
            assert.are.equal(result, "[x] task")
        end)
    end)

    describe("make datespec natural", function()
        it("should convert today to natural", function()
            local result = task.make_datespec_natural("[x] task <2021-7-4>", "2021-7-4")
            assert.are.equal(result, "[x] task <today>")
        end)

        it("should leave string unchanged if no datespec present", function()
            local result = task.make_datespec_absolute("[x] task", "2021-12-12")
            assert.are.equal(result, "[x] task")
        end)

        it("should convert date within next 7 to natural", function()
            local result = task.make_datespec_natural("[x] task <2021-7-8>", "2021-7-4")
            assert.are.equal(result, "[x] task <thursday>")
        end)
    end)

    describe("set_do_date", function()
        it("should add a datespec if one does not already exist", function()
            local result = task.set_do_date("[x] task", "tomorrow")
            assert.are.equal(result, "[x] <tomorrow> task")
        end)

        it("should preserve any recur spec", function()
            local result = task.set_do_date("[x] <today +every day> task", "tomorrow")
            assert.are.equal(result, "[x] <tomorrow +every day> task")
        end)

        it("should normalize", function()
            local result = task.set_do_date("<today +every day> task", "tomorrow")
            assert.are.equal(result, "[ ] <tomorrow +every day> task")
        end)
    end)

    describe("remove_datespec", function()
        it("should remove datespec at end of line", function()
            local line = "[x] this is <2021-10-10>"
            assert.are.equal(task.remove_datespec(line), "[x] this is")
        end)

        it("should remove datespec in middle of task", function()
            local line = "[x] this is <2021-10-10> a datespec"
            assert.are.equal(task.remove_datespec(line), "[x] this is a datespec")
        end)
    end)

    describe("replace_datespec_with_next", function()
        it("should advance the date", function()
            local line = "[ ] this is <2021-10-10 +daily> a datespec"
            assert.are.equal(
                task.replace_datespec_with_next(line, "2020-10-01"),
                "[ ] <2021-10-11 +daily> this is a datespec"
            )
        end)

        it("should use natural dates", function()
            local line = "[ ] this is <2021-10-10 +daily> a datespec"
            assert.are.equal(
                task.replace_datespec_with_next(line, "2021-10-10"),
                "[ ] <tomorrow +daily> this is a datespec"
            )
        end)
    end)


    describe("get_datespec_string_parts", function()

        it("returns nil if there is no datespec", function()
            assert.are.equal(
                task.get_datespec_string_parts("[ ] this has no datespec"),
                nil
            )
        end)

        it("returns parts as strings with no parsing", function()
            assert.are.same(
                task.get_datespec_string_parts("[ ] <tomorrow +every day> this has a datespec"),
                { do_date = "tomorrow", recur_pattern = "every day" }
            )
        end)


        it("returns nil for recur if there is none", function()
            assert.are.same(
                task.get_datespec_string_parts("[ ] <2021-10-10> this has a datespec"),
                { do_date = "2021-10-10", recur_pattern = nil }
            )
        end)
    end)


    describe("parse_datespec", function()
        it("returns nil if there is no datespec", function()
            assert.are.equal(
                task.parse_datespec("[ ] this should return nil"),
                nil
            )
        end)

        it("returns the do date as a DateObj, recur pattern as string", function()
            assert.are.same(
                task.parse_datespec("[ ] <2021-10-10 +every week> this has a datespec"),
                { do_date = DateObj:new("2021-10-10"), recur_pattern = "every week" }
            )
        end)


        it("returns nil for recur if it is missing", function()
            assert.are.same(
                task.parse_datespec("[ ] <2021-10-10> this has a datespec"),
                { do_date = DateObj:new("2021-10-10"), recur_pattern = nil}
            )
        end)


        it("works for natural do dates", function()
            assert.are.same(
                task.parse_datespec("[ ] <tomorrow> this has a datespec", "2021-07-04"),
                { do_date = DateObj:new("2021-07-05"), recur_pattern = nil}
            )
        end)
    end)
end)
