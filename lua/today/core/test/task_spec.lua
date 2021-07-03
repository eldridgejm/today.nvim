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

    describe("get_date_spec", function()
        it("should return today's date if there is not date string", function()
            local ds = task.get_date_spec("[x] tast", '2021-03-05')
            local y, m, d = ds.do_date:getdate()
            assert.are.same(
                {y, m, d},
                {2021, 3, 5}
            )
        end)

        it("should parse the date", function()
            local spec = task.get_date_spec("[x] something <2021-05-03>")
            local y, m, d = spec.do_date:getdate()
            assert.are.same({y, m, d}, {2021, 5, 3})
        end)
    end)


end)
