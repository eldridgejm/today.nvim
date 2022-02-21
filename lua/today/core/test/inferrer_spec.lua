describe("today.core.inferrer", function()
    local inferrer = require("today.core.inferrer")
    local Task = require("today.core.task").Task
    local DateObj = require("today.core.dates").DateObj

    describe("do_date header", function()

        it("should replace a nil do date", function()
            local header_info = {
                kind = "do_date",
                do_date = DateObj:new("2022-20-21")
            }

            local task = Task:new({
                done = true,
                tags = {},
                priority = 2,
                description = "This is a test.",
                do_date = nil,
                recur_pattern = nil
            })

            local task = inferrer.infer(header_info, task)

            assert.are.equal(task.do_date, DateObj:new("2022-20-21"))
        end)

    end)
end)
