describe("today.core.taskparser.parse", function()
    local taskparser = require("today.core.taskparser")
    local dates = require("today.core.dates")
    local MALFORMED = require("today.core.task").MALFORMED

    describe("parsing task completeness", function()
        it("parses a simple task", function()
            local taskstr = "[ ] this is a task"

            local task = taskparser.parse(taskstr, "2022-02-19")

            assert.are.equal(task.done, false)
            assert.are.equal(task.description, "this is a task")
        end)

        it("parses a task without a checkbox as not done", function()
            local taskstr = "this is a task"

            local task = taskparser.parse(taskstr, "2022-02-19")

            assert.are.equal(task.done, false)
            assert.are.equal(task.description, "this is a task")
        end)

        it("parses a task with a checked textbox as done", function()
            local taskstr = "[x] this is a task"

            local task = taskparser.parse(taskstr, "2022-02-19")

            assert.are.equal(task.done, true)
            assert.are.equal(task.description, "this is a task")
        end)

        it("removes extra whitespace around the description", function()
            local taskstr = "[x]     this is a task  "

            local task = taskparser.parse(taskstr, "2022-02-19")

            assert.are.equal(task.done, true)
            assert.are.equal(task.description, "this is a task")
        end)
    end)

    describe("tag parsing", function()
        it("parses tags", function()
            local taskstr = "this is a test #one #two #three"

            local task = taskparser.parse(taskstr, "2022-02-19")

            assert.are.same(task.tags, { "one", "two", "three" })
        end)

        it("returns an empty list if there are no tags", function()
            local taskstr = "there are no tags"

            local task = taskparser.parse(taskstr, "2022-02-19")

            assert.are.same(task.tags, {})
        end)

        it("parses tags scattered throughout the task string", function()
            local taskstr = "#one is the #two and the #three"

            local task = taskparser.parse(taskstr, "2022-02-19")

            assert.are.same(task.tags, { "one", "two", "three" })
        end)

        it("parses tags scattered throughout multiline descriptions", function()
            local taskstr = table.concat({
                "#one is the #two and the #three",
                "and this is another line with #fourth tag",
                "woo! #five",
            }, "\n")

            local task = taskparser.parse(taskstr, "2022-02-19")

            assert.are.same(task.tags, { "one", "two", "three", "fourth", "five" })
        end)

        it("requires tags to have spaces around them", function()
            local taskstr = "#one is the#two and the #three"

            local task = taskparser.parse(taskstr, "2022-02-19")

            assert.are.same(task.tags, { "one", "three" })
        end)

        it("removes tags from the description", function()
            local taskstr = "#one is the #two and the #three"

            local task = taskparser.parse(taskstr, "2022-02-19")

            assert.are.equal(task.description, "is the and the")
        end)

        it("removes tags from multiline descriptions", function()
            local taskstr = table.concat({
                "#one is the #two and the #three",
                "and this is another line with #fourth tag",
                "woo! #five",
            }, "\n")

            local task = taskparser.parse(taskstr, "2022-02-19")

            local expected = table.concat({
                "is the and the",
                "and this is another line with tag",
                "woo!",
            }, "\n")

            assert.are.equal(task.description, expected)
        end)
    end)

    describe("priority parsing", function()
        it("gets priorities", function()
            local taskstr = "this is high priority !!"

            local task = taskparser.parse(taskstr, "2022-02-19")

            assert.are.equal(task.priority, 2)
        end)

        it("assumes a default priority of 0 when none are provided", function()
            local taskstr = "this is high priority"

            local task = taskparser.parse(taskstr, "2022-02-19")

            assert.are.equal(task.priority, 0)
        end)

        it("takes the first priority, if there are multiple", function()
            local taskstr = "this is high priority !! ! !!!"

            local task = taskparser.parse(taskstr, "2022-02-19")

            assert.are.equal(task.priority, 2)
        end)

        it("requires priorities to have space around them", function()
            local taskstr = "this is high priority!!"

            local task = taskparser.parse(taskstr, "2022-02-19")

            assert.are.equal(task.priority, 0)
        end)

        it("gets priorities from multiline descriptions", function()
            local taskstr = table.concat({
                "hey, this is the first line",
                "and this is the second !!",
                "and this is the third",
            }, "\n")

            local task = taskparser.parse(taskstr, "2022-02-19")

            assert.are.equal(task.priority, 2)
        end)

        it("gets priorities that are on their own line", function()
            local taskstr = table.concat({
                "hey, this is the first line",
                "and this is the second",
                "",
                "!!",
            }, "\n")

            local task = taskparser.parse(taskstr, "2022-02-19")

            assert.are.equal(task.priority, 2)
        end)

        it("removes priorities from description", function()
            local taskstr = table.concat({
                "hey, this is the first line",
                "and this is the second",
                "",
                "!!",
            }, "\n")

            local task = taskparser.parse(taskstr, "2022-02-19")

            local expected = table.concat({
                "hey, this is the first line",
                "and this is the second",
            }, "\n")

            assert.are.equal(task.description, expected)
        end)
    end)

    describe("datespec parsing", function()
        -- we will not fully test datespec parsing here; that will be in a separate
        -- spec file

        it("parses the do date into a DateObj", function()
            local taskstr = "<tomorrow> is the task"

            local task = taskparser.parse(taskstr, "2022-02-19")

            assert.are.equal(task.do_date, dates.DateObj:from_ymd(2022, 2, 20))
            assert.are.equal(task.recur_pattern, nil)
        end)

        it("parses the recur pattern", function()
            local taskstr = "<tomorrow +every 2 days> is the task"

            local task = taskparser.parse(taskstr, "2022-02-19")

            assert.are.equal(task.do_date, dates.DateObj:from_ymd(2022, 2, 20))
            assert.are.equal(task.recur_pattern, "every 2 days")
        end)

        it(
            "infers a do_date of infinite past, nil recur, when datespec missing",
            function()
                local taskstr = "is the task"

                local task = taskparser.parse(taskstr, "2022-02-19")

                assert.are.equal(task.recur_pattern, nil)
                assert.are.equal(task.do_date, dates.DateObj:infinite_past())
            end
        )

        it(
            "infers the next date in sequence when recur provided but do date not",
            function()
                local taskstr = "<+every monday> is the task"

                -- 2022-02-19 was a saturday
                local task = taskparser.parse(taskstr, "2022-02-19")

                assert.are.equal(task.recur_pattern, "every monday")
                assert.are.equal(task.do_date, dates.DateObj:from_ymd(2022, 2, 21))
            end
        )

        it("assigns a do_date of MALFORMED when datespec is malformed", function()
            local taskstr = "<sdkladsk> is the task"

            -- 2022-02-19 was a saturday
            local task = taskparser.parse(taskstr, "2022-02-19")

            assert.are.equal(task.recur_pattern, MALFORMED)
            assert.are.equal(task.do_date, MALFORMED)
        end)

        it(
            "assigns a recur pattern of MALFORMED when recur pattern is messed up",
            function()
                local taskstr = "<tomorrow +ksadjsad> is the task"

                -- 2022-02-19 was a saturday
                local task = taskparser.parse(taskstr, "2022-02-19")

                assert.are.equal(task.recur_pattern, MALFORMED)
                assert.are.equal(task.do_date, MALFORMED)
            end
        )

        it("removes datespecs from the description", function()
            local taskstr = "<tomorrow> is the task"

            local task = taskparser.parse(taskstr, "2022-02-19")

            assert.are.equal(task.description, "is the task")
        end)

        it("removes datespecs from multiline description", function()
            local taskstr = table.concat({
                "hey, this is the first line",
                "and this is the second",
                "",
                "<tomorrow>",
            }, "\n")

            local task = taskparser.parse(taskstr, "2022-02-19")

            local expected = table.concat({
                "hey, this is the first line",
                "and this is the second",
            }, "\n")

            assert.are.equal(task.description, expected)
        end)
    end)
end)
