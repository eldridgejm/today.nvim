describe("Today core module's", function()
    task = require("today.core.task")

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
            local y, m, d = ds.do_date:getdate()
            assert.are.same({ y, m, d }, { 2021, 7, 5 })
        end)

        it("should return today if there is not date string", function()
            local ds = task.get_datespec_safe("[x] tast", "2021-03-05")
            local y, m, d = ds.do_date:getdate()
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
            local result = task.make_datespec_absolute("[x] task")
            assert.are.equal(result, "[x] task")
        end)
    end)

    describe("make datespec natural", function()
        it("should convert today to natural", function()
            local result = task.make_datespec_natural("[x] task <2021-7-4>", "2021-7-4")
            assert.are.equal(result, "[x] task <today>")
        end)

        it("should leave string unchanged if no datespec present", function()
            local result = task.make_datespec_absolute("[x] task")
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
            assert.are.equal(result, "[x] task <tomorrow>")
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
end)
