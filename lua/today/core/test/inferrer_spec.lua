describe("today.core.inferrer", function()
    local inferrer = require("today.core.inferrer")
    local Task = require("today.core.task").Task
    local DateObj = require("today.core.dates").DateObj

    describe("infer_from_header", function()

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

                local task = inferrer.infer_from_header(task, header_info)

                assert.are.equal(task.do_date, DateObj:new("2022-20-21"))
            end)

            it("should not replace a non-nil do date", function()
                local header_info = {
                    kind = "do_date",
                    do_date = DateObj:new("2022-20-21")
                }

                local task = Task:new({
                    done = true,
                    tags = {},
                    priority = 2,
                    description = "This is a test.",
                    do_date = DateObj:new("2000-01-01"),
                    recur_pattern = nil
                })

                local task = inferrer.infer_from_header(task, header_info)

                assert.are.equal(task.do_date, DateObj:new("2000-01-01"))
            end)

            it("should not replace existing recur pattern", function()
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
                    recur_pattern = "every 3 days"
                })

                local task = inferrer.infer_from_header(task, header_info)

                assert.are.equal(task.do_date, DateObj:new("2022-20-21"))
                assert.are.equal(task.recur_pattern, "every 3 days")
            end)

        end)

        describe("tag header", function()
            it("should add the tag to beginning if it doesn't already appear in the task", function()
                local header_info = {
                    kind = "tag",
                    tag = "foo"
                }

                local task = Task:new({
                    done = true,
                    tags = {"one", "two"},
                    priority = 2,
                    description = "This is a test.",
                    do_date = nil,
                    recur_pattern = "every 3 days"
                })

                local task = inferrer.infer_from_header(task, header_info)

                assert.are.same(task.tags, {"foo", "one", "two"})
            end)

            it("should not add the tag if it already appears", function()
                local header_info = {
                    kind = "tag",
                    tag = "foo"
                }

                local task = Task:new({
                    done = true,
                    tags = {"foo", "bar"},
                    priority = 2,
                    description = "This is a test.",
                    do_date = nil,
                    recur_pattern = "every 3 days"
                })

                local task = inferrer.infer_from_header(task, header_info)

                assert.are.same(task.tags, {"foo", "bar"})
            end)
        end)

        describe("done category", function()
            it("should check the task as done if is undone", function()
                local header_info = {
                    kind = "done",
                }

                local task = Task:new({
                    done = false,
                    tags = {"foo", "bar"},
                    priority = 2,
                    description = "This is a test.",
                    do_date = nil,
                    recur_pattern = "every 3 days"
                })

                local task = inferrer.infer_from_header(task, header_info)

                assert.are.same(task.done, true)
            end)

            it("should check the task as done if done is nil", function()
                local header_info = {
                    kind = "done",
                }

                local task = Task:new({
                    done = nil,
                    tags = {"foo", "bar"},
                    priority = 2,
                    description = "This is a test.",
                    do_date = nil,
                    recur_pattern = "every 3 days"
                })

                local task = inferrer.infer_from_header(task, header_info)

                assert.are.same(task.done, true)
            end)
        end)
    end)

    describe("infer_defaults", function()

        it("should assign a default done of false", function()
            local task = Task:new({
                done = nil,
                tags = {"foo", "bar"},
                priority = 2,
                description = "This is a test.",
                do_date = nil,
                recur_pattern = "every 3 days"
            })

            local task = inferrer.infer_defaults(task, "2022-02-20")

            assert.are.same(task.done, false)
        end)

        it("should assign a default priority of 0", function()
            local task = Task:new({
                done = nil,
                tags = {"foo", "bar"},
                priority = nil,
                description = "This is a test.",
                do_date = nil,
                recur_pattern = "every 3 days"
            })

            local task = inferrer.infer_defaults(task, "2022-02-20")

            assert.are.same(task.priority, 0)
        end)

        it("should assign a do_date of today if both do_date and recur are nil", function()
            local task = Task:new({
                done = nil,
                tags = {"foo", "bar"},
                priority = nil,
                description = "This is a test.",
                do_date = nil,
                recur_pattern = nil
            })

            local task = inferrer.infer_defaults(task, "2022-02-20")

            assert.are.same(task.do_date, DateObj:new("2022-02-20"))
            assert.are.same(task.recur_pattern, nil)
        end)

        it("should leave things alone if do_date is provided by recur is nil", function()
            local task = Task:new({
                done = nil,
                tags = {"foo", "bar"},
                priority = nil,
                description = "This is a test.",
                do_date = DateObj:new("2022-02-01"),
                recur_pattern = nil
            })

            local task = inferrer.infer_defaults(task, "2022-02-20")

            assert.are.same(task.do_date, DateObj:new("2022-02-01"))
            assert.are.same(task.recur_pattern, nil)
        end)

        it("should assign a next in sequence do_date if none provided and recur is given", function()
            local task = Task:new({
                done = nil,
                tags = {"foo", "bar"},
                priority = nil,
                description = "This is a test.",
                do_date = nil,
                recur_pattern = "every wed"
            })

            -- 2022-02-20 is a sunday
            local task = inferrer.infer_defaults(task, "2022-02-20")

            assert.are.same(task.do_date, DateObj:new("2022-02-23"))
            assert.are.same(task.recur_pattern, "every wed")
        end)

    end)

end)
