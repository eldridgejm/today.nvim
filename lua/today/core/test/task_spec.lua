describe("today.core.task", function()
    local Task = require("today.core.task").Task
    local dates = require("today.core.dates")

    describe("is_recurring", function()
        it("says the task is not recurring when recur_pattern is nil", function()
            local task = Task:new({
                done = true,
                tags = {},
                priority = 1,
                description = "This is a task.",
                do_date = dates.DateObj:new("2022-02-19"),
                recur_pattern = nil,
            })

            assert.are.equal(task:is_recurring(), false)
        end)

        it("says the task is recurring when recur_pattern is not nil", function()
            local task = Task:new({
                done = true,
                tags = {},
                priority = 1,
                description = "This is a task.",
                do_date = dates.DateObj:new("2022-02-19"),
                recur_pattern = "every monday",
            })

            assert.are.equal(task:is_recurring(), true)
        end)
    end)

    describe("copy", function()
        it("new produces a distinct copy of the original task", function()
            local task = Task:new({
                done = true,
                tags = {},
                priority = 1,
                description = "This is a task.",
                do_date = dates.DateObj:new("2022-02-19"),
                recur_pattern = "every monday",
            })

            local new_task = Task:new(task)
            new_task.done = false
            table.insert(new_task.tags, "foo")

            assert.are.equal(task.done, true)
            assert.are.same(task.tags, {})
        end)
    end)

    describe("next", function()
        it("produces the next task in the sequence as a copy", function()
            local task = Task:new({
                done = true,
                tags = {},
                priority = 1,
                description = "This is a task.",
                do_date = dates.DateObj:new("2022-02-19"),
                recur_pattern = "every monday",
            })

            local new_task = task:next()

            assert.are.equal(new_task.done, true)
            -- 2022-02-19 was a saturday
            assert.are.equal(new_task.do_date, dates.DateObj:new("2022-02-21"))
        end)

        it("returns nil if the task is not recurring", function()
            local task = Task:new({
                done = true,
                tags = {},
                priority = 1,
                description = "This is a task.",
                do_date = dates.DateObj:new("2022-02-19"),
                recur_pattern = nil,
            })

            local new_task = task:next()

            assert.are.equal(new_task, nil)
        end)
    end)
end)
