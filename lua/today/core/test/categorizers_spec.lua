local categorizers = require("today.core.categorizers")

describe("categorizers", function()
    describe("daily_agenda_categorizer", function()
        it("should show empty days if asked", function()
            -- given
            local tasks = {
                "[ ] <2021-07-01> task 1",
                "[ ] <2021-07-03> task 10", -- 10 == 2 in binary
            }

            -- when
            local result = categorizers.daily_agenda_categorizer(
                "2021-07-01",
                { show_empty_days = true }
            )(tasks)

            -- then
            -- July 01 was a Thursday
            local expected = {
                {
                    header = "today",
                    tasks = {
                        "[ ] <2021-07-01> task 1",
                    },
                },
                {
                    header = "tomorrow",
                    tasks = {},
                },
                {
                    header = "saturday",
                    tasks = {
                        "[ ] <2021-07-03> task 10", -- 10 == 2 in binary
                    },
                },
                { header = "sunday", tasks = {} },
                { header = "monday", tasks = {} },
                { header = "tuesday", tasks = {} },
                { header = "wednesday", tasks = {} },
            }
            assert.are.same(result, expected)
        end)

        it("should show as many empty days as option.days", function()
            -- given
            local tasks = {
                "[ ] <2021-07-01> task 1",
                "[ ] <2021-07-03> task 10", -- 10 == 2 in binary
            }

            -- when
            local result = categorizers.daily_agenda_categorizer(
                "2021-07-01",
                { days = 3, show_empty_days = true }
            )(tasks)

            -- then
            -- July 01 was a Thursday
            local expected = {

                {
                    header = "today",
                    tasks = {
                        "[ ] <2021-07-01> task 1",
                    },
                },

                { header = "tomorrow", tasks = {} },

                {
                    header = "saturday",
                    tasks = {
                        "[ ] <2021-07-03> task 10", -- 10 == 2 in binary
                    },
                },
            }
            assert.are.same(result, expected)
        end)

        it("should place days outside of range into hidden", function()
            -- given
            local tasks = {
                "[ ] <2021-07-01> task 1",
                "[ ] <2021-07-03> task 10", -- 10 == 2 in binary
            }

            -- when
            local result = categorizers.daily_agenda_categorizer(
                "2021-07-01",
                { days = 1, show_empty_days = true }
            )(tasks)

            -- then
            -- July 01 was a Thursday
            local expected = {

                {
                    header = "today",
                    tasks = {
                        "[ ] <2021-07-01> task 1",
                    },
                },

                {
                    header = "hidden",
                    tasks = {
                        "[ ] <2021-07-03> task 10", -- 10 == 2 in binary
                    },
                },
            }
            assert.are.same(result, expected)
        end)

        it(
            "should put done tasks in do date category if move_to_done_immediately=false",
            function()
                -- given
                local tasks = {
                    "[ ] undone",
                    "[x] <today> this is done",
                    "[ ] but this isn't",
                }

                -- when
                local result = categorizers.daily_agenda_categorizer(
                    "2021-06-01",
                    { view = "daily", move_to_done_immediately = false }
                )(tasks)

                -- then
                local expected = {

                    {
                        header = "today",
                        tasks = {
                            "[ ] undone",
                            "[ ] but this isn't",
                            "[x] <today> this is done",
                        },
                    },
                }
                assert.are.same(result, expected)
            end
        )

        it(
            "should put done tasks in done category if move_to_done_immediately=false but they are old",
            function()
                -- given
                local tasks = {
                    "[ ] undone",
                    "[x] <yesterday> this is done",
                    "[ ] but this isn't",
                }

                -- when
                local result = categorizers.daily_agenda_categorizer(
                    "2021-06-01",
                    { view = "daily", move_to_done_immediately = false }
                )(tasks)

                -- then
                local expected = {

                    {
                        header = "today",
                        tasks = {
                            "[ ] undone",
                            "[ ] but this isn't",
                        },
                    },

                    {
                        header = "done",
                        tasks = {
                            "[x] <yesterday> this is done",
                        },
                    },
                }
                assert.are.same(result, expected)
            end
        )

        it(
            "should put done tasks in done category if move_to_done_immediately=false but they are undated",
            function()
                -- given
                local tasks = {
                    "[ ] undone",
                    "[x] this is done",
                    "[ ] but this isn't",
                }

                -- when
                local result = categorizers.daily_agenda_categorizer(
                    "2021-06-01",
                    { view = "daily", move_to_done_immediately = false }
                )(tasks)

                -- then
                local expected = {

                    {
                        header = "today",
                        tasks = {
                            "[ ] undone",
                            "[ ] but this isn't",
                        },
                    },

                    {
                        header = "done",
                        tasks = {
                            "[x] this is done",
                        },
                    },
                }
                assert.are.same(result, expected)
            end
        )

        it("should move move tasks to a broken section", function()
            -- given
            local tasks = {
                "[ ] but this isn't",
            }

            local broken_tasks = {
                "[ ] undone <zzz>",
            }

            -- when
            local result = categorizers.daily_agenda_categorizer("2021-06-01", {})(
                tasks,
                nil,
                broken_tasks
            )

            -- then
            local expected = {

                {
                    header = "broken",
                    tasks = {
                        "[ ] undone <zzz>",
                    },
                },

                {
                    header = "today",
                    tasks = {
                        "[ ] but this isn't",
                    },
                },
            }
            assert.are.same(result, expected)
        end)

        it("should not show count remaining if option is false", function()
            -- given
            local tasks = {
                "[ ] undone <tomorrow>",
                "[ ] but this isn't",
            }

            -- when
            local result = categorizers.daily_agenda_categorizer(
                "2021-06-01",
                { show_remaining_tasks_count = false }
            )(tasks)

            -- then
            local expected = {

                {
                    header = "today",
                    tasks = {
                        "[ ] but this isn't",
                    },
                },

                {
                    header = "tomorrow",
                    tasks = {
                        "[ ] undone <tomorrow>",
                    },
                },
            }
            assert.are.same(result, expected)
        end)

        it("should use ymd date if requested", function()
            -- given
            local tasks = {
                "[ ] undone <tomorrow>",
                "[ ] but this isn't",
            }

            -- when
            local result = categorizers.daily_agenda_categorizer(
                "2021-06-01",
                { date_format = "ymd" }
            )(tasks)

            -- then
            local expected = {

                {
                    header = "2021-06-01",
                    tasks = {
                        "[ ] but this isn't",
                    },
                },

                {
                    header = "2021-06-02",
                    tasks = {
                        "[ ] undone <tomorrow>",
                    },
                },
            }
            assert.are.same(result, expected)
        end)

        it("should use datestamp if requested", function()
            -- given
            local tasks = {
                "[ ] undone <tomorrow>",
                "[ ] but this isn't",
            }

            -- when
            local result = categorizers.daily_agenda_categorizer(
                "2021-06-01",
                { date_format = "datestamp" }
            )(tasks)

            -- then
            local expected = {

                {
                    header = "tue jun 01 2021",
                    tasks = {
                        "[ ] but this isn't",
                    },
                },

                {
                    header = "wed jun 02 2021",
                    tasks = {
                        "[ ] undone <tomorrow>",
                    },
                },
            }
            assert.are.same(result, expected)
        end)

        it("should use monthday if requested", function()
            -- given
            local tasks = {
                "[ ] undone <tomorrow>",
                "[ ] but this isn't",
            }

            -- when
            local result = categorizers.daily_agenda_categorizer(
                "2021-06-01",
                { date_format = "monthday" }
            )(tasks)

            -- then
            local expected = {

                {
                    header = "jun 01",
                    tasks = {
                        "[ ] but this isn't",
                    },
                },

                {
                    header = "jun 02",
                    tasks = {
                        "[ ] undone <tomorrow>",
                    },
                },
            }
            assert.are.same(result, expected)
        end)

        it("should use a second date in header if requested", function()
            -- given
            local tasks = {
                "[ ] undone <tomorrow>",
                "[ ] but this isn't",
                "testing <40 days from now>",
            }

            -- when
            local result = categorizers.daily_agenda_categorizer(
                "2021-06-01",
                { date_format = "monthday", second_date_format = "ymd" }
            )(tasks)

            -- then
            local expected = {

                {
                    header = "jun 01 | 2021-06-01",
                    tasks = {
                        "[ ] but this isn't",
                    },
                },

                {
                    header = "jun 02 | 2021-06-02",
                    tasks = {
                        "[ ] undone <tomorrow>",
                    },
                },

                {
                    header = "hidden",
                    tasks = {
                        "testing <40 days from now>",
                    },
                },
            }
            assert.are.same(result, expected)
        end)

        it("should add count of remaining if option given", function()
            -- given
            local tasks = {
                "[ ] undone <tomorrow>",
                "[ ] but this isn't",
                "[x] <today> and this is done",
            }

            -- when
            local result = categorizers.daily_agenda_categorizer("2021-06-01", {
                move_to_done_immediately = false,
                show_remaining_tasks_count = true,
            })(tasks)

            -- then
            local expected = {

                {
                    header = "today | 1",
                    tasks = {
                        "[ ] but this isn't",
                        "[x] <today> and this is done",
                    },
                },

                {
                    header = "tomorrow | 1",
                    tasks = {
                        "[ ] undone <tomorrow>",
                    },
                },
            }
            assert.are.same(result, expected)
        end)

        it("should show count for hidden category, if option given", function()
            -- given
            local tasks = {
                "this is the first one",
            }

            local hidden_tasks = {
                "this is the second one #two",
                "this is the third #one",
            }

            -- when
            local result = categorizers.daily_agenda_categorizer(
                "2021-06-01",
                { show_remaining_tasks_count = true }
            )(tasks, hidden_tasks)

            -- then
            local expected = {

                {
                    header = "today | 1",
                    tasks = {
                        "this is the first one",
                    },
                },

                {
                    header = "hidden | 2",
                    tasks = {
                        "this is the second one #two",
                        "this is the third #one",
                    },
                },
            }
            assert.are.same(result, expected)
        end)
    end)

    describe("first_tag_categorizer", function()
        local components = {
            categorizer = categorizers.first_tag_categorizer("2021-07-04"),
        }

        it("should sort headers alphabetically", function()
            local tasks = {
                "this is #one something",
                "this is #two another",
                "and this is a four th",
                "this is #three #one a third",
                "this is another #one",
            }

            local result = categorizers.first_tag_categorizer("2021-10-10")(tasks)

            assert.are.same(result, {

                {
                    header = "#one",
                    tasks = {
                        "this is #one something",

                        "this is another #one",
                    },
                },

                {
                    header = "#three",
                    tasks = {
                        "this is #three #one a third",
                    },
                },

                {
                    header = "#two",
                    tasks = {
                        "this is #two another",
                    },
                },

                {
                    header = "other",
                    tasks = {
                        "and this is a four th",
                    },
                },
            })
        end)
        it("should place done items last", function()
            local tasks = {
                "[x] this is #three #one a third",
                "[x] this is another #one",
                "this is #one something",
                "this is #two another",
                "[x] ok this works",
                "and this is a four th",
            }

            local result = categorizers.first_tag_categorizer("2021-10-10")(tasks)

            assert.are.same(result, {

                {
                    header = "#one",
                    tasks = {
                        "this is #one something",
                        "[x] this is another #one",
                    },
                },

                {
                    header = "#three",
                    tasks = {
                        "[x] this is #three #one a third",
                    },
                },

                {
                    header = "#two",
                    tasks = {
                        "this is #two another",
                    },
                },

                {
                    header = "other",
                    tasks = {
                        "and this is a four th",
                        "[x] ok this works",
                    },
                },
            })
        end)
        it("should order by do date then priority", function()
            local tasks = {
                "[ ] this is #three #one a third",
                "[ ] this is #one something <tomorrow>",
                "[ ] and this is a #one th <today> !",
                "[ ] this is another #one <today> !!",
                "[ ] this is #two another",
                "[ ] ok this works",
            }

            local result = categorizers.first_tag_categorizer("2021-10-10")(tasks)

            assert.are.same(result, {

                {
                    header = "#one",
                    tasks = {
                        "[ ] this is another #one <today> !!",
                        "[ ] and this is a #one th <today> !",
                        "[ ] this is #one something <tomorrow>",
                    },
                },

                {
                    header = "#three",
                    tasks = {
                        "[ ] this is #three #one a third",
                    },
                },

                {
                    header = "#two",
                    tasks = {
                        "[ ] this is #two another",
                    },
                },

                {
                    header = "other",
                    tasks = {
                        "[ ] ok this works",
                    },
                },
            })
        end)

        it("should move malformed tasks to a broken section", function()
            -- given
            local tasks = {
                "[ ] undone <zzz>",
                "[ ] but this isn't",
            }

            -- when
            local result = categorizers.first_tag_categorizer("2021-10-10")(
                tasks,
                nil,
                broken_tasks
            )

            -- then
            local expected = {

                {
                    header = "broken",
                    tasks = {
                        "[ ] undone <zzz>",
                    },
                },

                {
                    header = "other",
                    tasks = {
                        "[ ] but this isn't",
                    },
                },
            }
            assert.are.same(result, expected)
        end)

        it("should add count of remaining if option given", function()
            -- given
            local tasks = {
                "[x] this is #three #one a third",
                "[x] this is another #one",
                "[ ] this is #one something",
                "[ ] this is #two another",
                "[x] ok this works",
                "[ ] and this is a four th",
            }

            -- when
            local result = categorizers.first_tag_categorizer("2021-06-01", {
                show_remaining_tasks_count = true,
            })(tasks)

            -- then
            local expected = {

                {
                    header = "#one | 1",
                    tasks = {
                        "[ ] this is #one something",
                        "[x] this is another #one",
                    },
                },

                {
                    header = "#three | 0",
                    tasks = {
                        "[x] this is #three #one a third",
                    },
                },

                {
                    header = "#two | 1",
                    tasks = {
                        "[ ] this is #two another",
                    },
                },

                {
                    header = "other | 1",
                    tasks = {
                        "[ ] and this is a four th",
                        "[x] ok this works",
                    },
                },
            }

            assert.are.same(result, expected)
        end)

        it("should show count for hidden category, if option given", function()
            -- given
            local tasks = {
                "this is the first one",
            }

            local hidden_tasks = {
                "this is the second one #two",
                "this is the third #one",
            }

            -- when
            local result = categorizers.first_tag_categorizer(
                "2021-06-01",
                { show_remaining_tasks_count = true }
            )(tasks, hidden_tasks)
            -- then
            local expected = {

                {
                    header = "other | 1",
                    tasks = {
                        "this is the first one",
                    },
                },

                {
                    header = "hidden | 2",
                    tasks = {
                        "this is the second one #two",
                        "this is the third #one",
                    },
                },
            }

            assert.are.same(result, expected)
        end)
    end)
end)
