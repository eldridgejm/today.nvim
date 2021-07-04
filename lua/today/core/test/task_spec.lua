describe("Today core module's", function()

    task = require('today.core.task')

    describe("set_priority", function()

        it("should add priority to end if nonexistant", function()
            assert.are.equal(
                task.set_priority('testing', 2),
                'testing !!'
            )
        end)

        it("should trim when adding priority", function()
            assert.are.equal(
                task.set_priority('testing   ', 2),
                'testing !!'
            )
        end)

        it("should change existing priority in-place", function()
            assert.are.equal(
                task.set_priority('testing !!', 1),
                'testing !'
            )
        end)
    end)

    describe("normalize", function()

        it("should add a checkbox to a line without one", function()
            assert.are.equal(
                task.normalize("this is a test"),
                "[ ] this is a test"
            )
        end)

        it("should leave line unchanged if checkbox exists", function()
            assert.are.equal(
                task.normalize("[ ] task"),
                "[ ] task"
            )
        end)

    end)

    describe("is_task", function()
        it("should detect a task line", function()
            assert.truthy(
                task.is_task("[x] this is a test")
            )
        end)

        it("should detect a comment", function()
            assert.falsy(
                task.is_task("-- [x] this is a test")
            )
        end)

        it("should detect an empty line", function()
            assert.falsy(
                task.is_task("")
            )
        end)
    end)

    describe("get_datespec", function()
        it("should get the do_date as a DateSpec", function()
            local ds = task.get_datespec("[x] tast <2021-07-5>", '2021-03-05')
            local y, m, d = ds.do_date:getdate()
            assert.are.same({y, m, d}, {2021, 7, 5})
        end)

        it("should return today if there is not date string", function()
            local ds = task.get_datespec("[x] tast", '2021-03-05')
            local y, m, d = ds.do_date:getdate()
            assert.are.same({y, m, d}, {2021, 3, 5})
        end)
    end)

    describe("make datespec absolute", function()
        it("should convert today to absolute", function()
            local result = task.make_datespec_absolute("[x] task <today>", "2021-02-03")
            assert.are.equal(
                result,
                "[x] task <2021-02-03>"
            )
        end)

        it("should convert tomorrow to absolute", function()
            local result = task.make_datespec_absolute("[x] task <tomorrow>", "2021-02-03")
            assert.are.equal(
                result,
                "[x] task <2021-02-04>"
            )
        end)

        it("should not convert absolute dates", function()
            local result = task.make_datespec_absolute("[x] task <2021-1-2>", "2021-02-03")
            assert.are.equal(
                result,
                "[x] task <2021-01-02>"
            )
        end)

        it("should convert weekdays within next 7 days", function()
            local result = task.make_datespec_absolute("[x] task <wednesday>", "2021-07-04")
            assert.are.equal(
                result,
                "[x] task <2021-07-07>"
            )
        end)

        it("should leave string unchanged if no datespec present", function()
            local result = task.make_datespec_absolute("[x] task")
            assert.are.equal(
                result,
                "[x] task"
            )
        end)
    end)

    describe("make datespec natural", function()
        it("should convert today to natural", function()
            local result = task.make_datespec_natural("[x] task <2021-7-4>", "2021-7-4")
            assert.are.equal(
                result,
                "[x] task <today>"
            )
        end)

        it("should convert date within next 7 to natural", function()
            local result = task.make_datespec_natural("[x] task <2021-7-8>", "2021-7-4")
            assert.are.equal(
                result,
                "[x] task <thursday>"
            )
        end)
    end)


    describe("set_do_date", function()
        it("should add a datespec if one does not already exist", function()
            local result = task.set_do_date("[x] task", "tomorrow")
            assert.are.equal(result, "[x] task <tomorrow>")
        end)
    end)


end)
