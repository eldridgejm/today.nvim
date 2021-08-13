local organize = require('today.core.organize')
local categorizers = require('today.core.categorizers')


describe("categorizers", function()
    describe("daily_agenda_categorizer", function()
        it("should show empty days if asked", function()
            -- given
            local lines = {
                "[ ] <2021-07-01> task 1",
                "[ ] <2021-07-03> task 10", -- 10 == 2 in binary
            }

            -- when
            local result = organize.organize(lines, {
                categorizer = categorizers.daily_agenda_categorizer(
                    "2021-07-01",
                    { show_empty_days = true }
                ),
            })

            -- then
            -- July 01 was a Thursday
            local expected = {
                "-- today {{{",
                "[ ] <2021-07-01> task 1",
                "-- }}}",
                "",
                "-- tomorrow {{{",
                "-- }}}",
                "",
                "-- saturday {{{",
                "[ ] <2021-07-03> task 10", -- 10 == 2 in binary
                "-- }}}",
                "",
                "-- sunday {{{",
                "-- }}}",
                "",
                "-- monday {{{",
                "-- }}}",
                "",
                "-- tuesday {{{",
                "-- }}}",
                "",
                "-- wednesday {{{",
                "-- }}}",
            }
            assert.are.same(result, expected)
        end)

        it("should show as many empty days as option.days", function()
            -- given
            local lines = {
                "[ ] <2021-07-01> task 1",
                "[ ] <2021-07-03> task 10", -- 10 == 2 in binary
            }

            -- when
            local result = organize.organize(lines, {
                categorizer = categorizers.daily_agenda_categorizer(
                    "2021-07-01",
                    { days = 3, show_empty_days = true }
                ),
            })

            -- then
            -- July 01 was a Thursday
            local expected = {
                "-- today {{{",
                "[ ] <2021-07-01> task 1",
                "-- }}}",
                "",
                "-- tomorrow {{{",
                "-- }}}",
                "",
                "-- saturday {{{",
                "[ ] <2021-07-03> task 10", -- 10 == 2 in binary
                "-- }}}",
            }
            assert.are.same(result, expected)
        end)

        it("should place days outside of range into hidden", function()
            -- given
            local lines = {
                "[ ] <2021-07-01> task 1",
                "[ ] <2021-07-03> task 10", -- 10 == 2 in binary
            }

            -- when
            local result = organize.organize(lines, {
                categorizer = categorizers.daily_agenda_categorizer(
                    "2021-07-01",
                    { days = 1, show_empty_days = true }
                ),
            })

            -- then
            -- July 01 was a Thursday
            local expected = {
                "-- today {{{",
                "[ ] <2021-07-01> task 1",
                "-- }}}",
                "",
                "-- hidden {{{",
                "[ ] <2021-07-03> task 10", -- 10 == 2 in binary
                "-- }}}",
            }
            assert.are.same(result, expected)
        end)

        it("should keep user comments at the beginning and end", function()
            -- given
            local lines = {
                "--: this is a user comment",
                "[x] this is done",
                "[ ] but this isn't",
                "--: and so is this",
            }

            -- when
            local result = organize.organize(
                lines,
                { categorizer = categorizers.daily_agenda_categorizer("2021-02-01", {}) }
            )

            -- then
            local expected = {
                "--: this is a user comment",
                "",
                "-- today {{{",
                "[ ] but this isn't",
                "-- }}}",
                "",
                "-- done {{{",
                "[x] this is done",
                "-- }}}",
                "",
                "--: and so is this",
            }
            assert.are.same(result, expected)
        end)

        it(
            "should put done tasks in do date category if move_to_done_immediately=false",
            function()
                -- given
                local lines = {
                    "[ ] undone",
                    "[x] <today> this is done",
                    "[ ] but this isn't",
                }

                -- when
                local result = organize.organize(lines, {
                    categorizer = categorizers.daily_agenda_categorizer(
                        "2021-06-01",
                        { view = "daily", move_to_done_immediately = false }
                    ),
                })

                -- then
                local expected = {
                    "-- today {{{",
                    "[ ] undone",
                    "[ ] but this isn't",
                    "[x] <today> this is done",
                    "-- }}}",
                }
                assert.are.same(result, expected)
            end
        )

        it(
            "should put done tasks in done category if move_to_done_immediately=false but they are old",
            function()
                -- given
                local lines = {
                    "[ ] undone",
                    "[x] <yesterday> this is done",
                    "[ ] but this isn't",
                }

                -- when
                local result = organize.organize(lines, {
                    categorizer = categorizers.daily_agenda_categorizer(
                        "2021-06-01",
                        { view = "daily", move_to_done_immediately = false }
                    ),
                })

                -- then
                local expected = {
                    "-- today {{{",
                    "[ ] undone",
                    "[ ] but this isn't",
                    "-- }}}",
                    "",
                    "-- done {{{",
                    "[x] <yesterday> this is done",
                    "-- }}}",
                }
                assert.are.same(result, expected)
            end
        )

        it(
            "should put done tasks in done category if move_to_done_immediately=false but they are undated",
            function()
                -- given
                local lines = {
                    "[ ] undone",
                    "[x] this is done",
                    "[ ] but this isn't",
                }

                -- when
                local result = organize.organize(lines, {
                    categorizer = categorizers.daily_agenda_categorizer(
                        "2021-06-01",
                        { view = "daily", move_to_done_immediately = false }
                    ),
                })

                -- then
                local expected = {
                    "-- today {{{",
                    "[ ] undone",
                    "[ ] but this isn't",
                    "-- }}}",
                    "",
                    "-- done {{{",
                    "[x] this is done",
                    "-- }}}",
                }
                assert.are.same(result, expected)
            end
        )

        it("should move malformed tasks to a broken section", function()
            -- given
            local lines = {
                "[ ] undone <zzz>",
                "[ ] but this isn't",
            }

            -- when
            local result = organize.organize(
                lines,
                { categorizer = categorizers.daily_agenda_categorizer("2021-06-01", {}) }
            )

            -- then
            local expected = {
                "-- broken {{{",
                "[ ] <zzz> undone",
                "-- }}}",
                "",
                "-- today {{{",
                "[ ] but this isn't",
                "-- }}}",
            }
            assert.are.same(result, expected)
        end)

        it("should not show count remaining if option is false", function()
            -- given
            local lines = {
                "[ ] undone <tomorrow>",
                "[ ] but this isn't",
            }

            -- when
            local result = organize.organize(lines, {
                categorizer = categorizers.daily_agenda_categorizer(
                    "2021-06-01",
                    { show_remaining_tasks_count = false }
                ),
            })

            -- then
            local expected = {
                "-- today {{{",
                "[ ] but this isn't",
                "-- }}}",
                "",
                "-- tomorrow {{{",
                "[ ] <tomorrow> undone",
                "-- }}}",
            }
            assert.are.same(result, expected)
        end)

        it("should use ymd date if requested", function()
            -- given
            local lines = {
                "[ ] undone <tomorrow>",
                "[ ] but this isn't",
            }

            -- when
            local result = organize.organize(lines, {
                categorizer = categorizers.daily_agenda_categorizer(
                    "2021-06-01",
                    { date_format = "ymd" }
                ),
            })

            -- then
            local expected = {
                "-- 2021-06-01 {{{",
                "[ ] but this isn't",
                "-- }}}",
                "",
                "-- 2021-06-02 {{{",
                "[ ] <tomorrow> undone",
                "-- }}}",
            }
            assert.are.same(result, expected)
        end)

        it("should use datestamp if requested", function()
            -- given
            local lines = {
                "[ ] undone <tomorrow>",
                "[ ] but this isn't",
            }

            -- when
            local result = organize.organize(lines, {
                categorizer = categorizers.daily_agenda_categorizer(
                    "2021-06-01",
                    { date_format = "datestamp" }
                ),
            })

            -- then
            local expected = {
                "-- tue jun 01 2021 {{{",
                "[ ] but this isn't",
                "-- }}}",
                "",
                "-- wed jun 02 2021 {{{",
                "[ ] <tomorrow> undone",
                "-- }}}",
            }
            assert.are.same(result, expected)
        end)

        it("should use monthday if requested", function()
            -- given
            local lines = {
                "[ ] undone <tomorrow>",
                "[ ] but this isn't",
            }

            -- when
            local result = organize.organize(lines, {
                categorizer = categorizers.daily_agenda_categorizer(
                    "2021-06-01",
                    { date_format = "monthday" }
                ),
            })

            -- then
            local expected = {
                "-- jun 01 {{{",
                "[ ] but this isn't",
                "-- }}}",
                "",
                "-- jun 02 {{{",
                "[ ] <tomorrow> undone",
                "-- }}}",
            }
            assert.are.same(result, expected)
        end)

        it("should use a second date in header if requested", function()
            -- given
            local lines = {
                "[ ] undone <tomorrow>",
                "[ ] but this isn't",
                "testing <40 days from now>",
            }

            -- when
            local result = organize.organize(lines, {
                categorizer = categorizers.daily_agenda_categorizer(
                    "2021-06-01",
                    { date_format = "monthday", second_date_format = "ymd" }
                ),
            })

            -- then
            local expected = {
                "-- jun 01 | 2021-06-01 {{{",
                "[ ] but this isn't",
                "-- }}}",
                "",
                "-- jun 02 | 2021-06-02 {{{",
                "[ ] <tomorrow> undone",
                "-- }}}",
                "",
                "-- hidden {{{",
                "[ ] <40 days from now> testing",
                "-- }}}",
            }
            assert.are.same(result, expected)
        end)

        it("should add count of remaining if option given", function()
            -- given
            local lines = {
                "[ ] undone <tomorrow>",
                "[ ] but this isn't",
                "[x] <today> and this is done",
            }

            -- when
            local result = organize.organize(lines, {
                categorizer = categorizers.daily_agenda_categorizer("2021-06-01", {
                    move_to_done_immediately = false,
                    show_remaining_tasks_count = true,
                }),
            })

            -- then
            local expected = {
                "-- today | 1 {{{",
                "[ ] but this isn't",
                "[x] <today> and this is done",
                "-- }}}",
                "",
                "-- tomorrow | 1 {{{",
                "[ ] <tomorrow> undone",
                "-- }}}",
            }
            assert.are.same(result, expected)
        end)

        it("should show count for hidden category, if option given", function()
            -- given
            local tasks = {
                "this is the first one",
                "this is the second one #two",
                "this is the third #one",
            }

            -- when
            local result = organize.organize(tasks, {
                categorizer = categorizers.daily_agenda_categorizer(
                    "2021-06-01",
                    { show_remaining_tasks_count = true }
                ),
                filterer = organize.tag_filterer({ "#one" }),
            })

            -- then
            local expected = {
                "-- today | 1 {{{",
                "[ ] this is the third #one",
                "-- }}}",
                "",
                "-- hidden | 2 {{{",
                "[ ] this is the first one",
                "[ ] this is the second one #two",
                "-- }}}",
            }

            assert.are.same(result, expected)
        end)
    end)

    describe("first_tag_categorizer", function()
        local components = {
            categorizer = categorizers.first_tag_categorizer("2021-07-04"),
        }

        it("should sort headers alphabetically", function()
            local lines = {
                "this is #one something",
                "this is #two another",
                "and this is a four th",
                "this is #three #one a third",
                "this is another #one",
            }

            local result = organize.organize(lines, components)

            assert.are.same(result, {
                "-- #one {{{",
                "[ ] this is something #one",
                "[ ] this is another #one",
                "-- }}}",
                "",
                "-- #three {{{",
                "[ ] this is a third #three #one",
                "-- }}}",
                "",
                "-- #two {{{",
                "[ ] this is another #two",
                "-- }}}",
                "",
                "-- other {{{",
                "[ ] and this is a four th",
                "-- }}}",
            })
        end)
        it("should place done items last", function()
            local lines = {
                "[x] this is #three #one a third",
                "[x] this is another #one",
                "this is #one something",
                "this is #two another",
                "[x] ok this works",
                "and this is a four th",
            }

            local result = organize.organize(lines, components)

            assert.are.same(result, {
                "-- #one {{{",
                "[ ] this is something #one",
                "[x] this is another #one",
                "-- }}}",
                "",
                "-- #three {{{",
                "[x] this is a third #three #one",
                "-- }}}",
                "",
                "-- #two {{{",
                "[ ] this is another #two",
                "-- }}}",
                "",
                "-- other {{{",
                "[ ] and this is a four th",
                "[x] ok this works",
                "-- }}}",
            })
        end)
        it("should order by do date then priority", function()
            local lines = {
                "[ ] this is #three #one a third",
                "this is #one something <tomorrow>",
                "and this is a #one th <today> !",
                "[ ] this is another #one <today> !!",
                "this is #two another",
                "[ ] ok this works",
            }

            local result = organize.organize(lines, components)

            assert.are.same(result, {

                "-- #one {{{",
                "[ ] <today> !! this is another #one",
                "[ ] <today> ! and this is a th #one",
                "[ ] <tomorrow> this is something #one",
                "-- }}}",
                "",
                "-- #three {{{",
                "[ ] this is a third #three #one",
                "-- }}}",
                "",
                "-- #two {{{",
                "[ ] this is another #two",
                "-- }}}",
                "",
                "-- other {{{",
                "[ ] ok this works",
                "-- }}}",
            })
        end)

        it("should move malformed tasks to a broken section", function()
            -- given
            local lines = {
                "[ ] undone <zzz>",
                "[ ] but this isn't",
            }

            -- when
            local result = organize.organize(lines, components)

            -- then
            local expected = {
                "-- broken {{{",
                "[ ] <zzz> undone",
                "-- }}}",
                "",
                "-- other {{{",
                "[ ] but this isn't",
                "-- }}}",
            }
            assert.are.same(result, expected)
        end)

        it("should add count of remaining if option given", function()
            -- given
            local lines = {
                "[x] this is #three #one a third",
                "[x] this is another #one",
                "this is #one something",
                "this is #two another",
                "[x] ok this works",
                "and this is a four th",
            }

            -- when
            local result = organize.organize(lines, {
                categorizer = categorizers.first_tag_categorizer("2021-06-01", {
                    show_remaining_tasks_count = true,
                }),
            })

            -- then
            local expected = {
                "-- #one | 1 {{{",
                "[ ] this is something #one",
                "[x] this is another #one",
                "-- }}}",
                "",
                "-- #three | 0 {{{",
                "[x] this is a third #three #one",
                "-- }}}",
                "",
                "-- #two | 1 {{{",
                "[ ] this is another #two",
                "-- }}}",
                "",
                "-- other | 1 {{{",
                "[ ] and this is a four th",
                "[x] ok this works",
                "-- }}}",
            }

            assert.are.same(result, expected)
        end)

        it("should show count for hidden category, if option given", function()
            -- given
            local tasks = {
                "this is the first one",
                "this is the second one #two",
                "this is the third #one",
            }

            -- when
            local result = organize.organize(tasks, {
                categorizer = categorizers.first_tag_categorizer(
                    "2021-06-01",
                    { show_remaining_tasks_count = true }
                ),
                filterer = organize.tag_filterer({ "#one" }),
            })

            -- then
            local expected = {
                "-- #one | 1 {{{",
                "[ ] this is the third #one",
                "-- }}}",
                "",
                "-- hidden | 2 {{{",
                "[ ] this is the first one",
                "[ ] this is the second one #two",
                "-- }}}",
            }

            assert.are.same(result, expected)
        end)
    end)
end)
