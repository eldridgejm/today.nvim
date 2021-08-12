describe("organize", function()
    organize = require("today.core.organize")

    describe("categorizers", function()
        describe("daily_agenda_categorizer", function()
            it("should organize into days for two weeks from working date", function()
                -- given
                local lines = {
                    "[ ] <2021-07-01> task 1",
                    "[ ] <2021-07-02> task 2",
                    "[ ] <2021-07-03> task 3",
                    "[ ] <2021-07-04> task 4",
                    "[ ] <2021-07-05> task 5",
                    "[ ] <2021-07-06> task 6",
                    "[ ] <2021-07-07> task 7",
                    "[ ] <2021-07-08> task 8",
                    "[ ] <2021-07-09> task 9",
                    "[ ] <2021-07-10> task 10",
                }

                -- when
                local result = organize.organize(lines, {
                    categorizer = organize.daily_agenda_categorizer(
                        "2021-07-01",
                        { show_empty_categories = true }
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
                    "[ ] <2021-07-02> task 2",
                    "-- }}}",
                    "",
                    "-- saturday {{{",
                    "[ ] <2021-07-03> task 3",
                    "-- }}}",
                    "",
                    "-- sunday {{{",
                    "[ ] <2021-07-04> task 4",
                    "-- }}}",
                    "",
                    "-- monday {{{",
                    "[ ] <2021-07-05> task 5",
                    "-- }}}",
                    "",
                    "-- tuesday {{{",
                    "[ ] <2021-07-06> task 6",
                    "-- }}}",
                    "",
                    "-- wednesday {{{",
                    "[ ] <2021-07-07> task 7",
                    "-- }}}",
                    "",
                    "-- next thursday {{{",
                    "[ ] <2021-07-08> task 8",
                    "-- }}}",
                    "",
                    "-- next friday {{{",
                    "[ ] <2021-07-09> task 9",
                    "-- }}}",
                    "",
                    "-- next saturday {{{",
                    "[ ] <2021-07-10> task 10",
                    "-- }}}",
                    "",
                    "-- next sunday {{{",
                    "-- }}}",
                    "",
                    "-- next monday {{{",
                    "-- }}}",
                    "",
                    "-- next tuesday {{{",
                    "-- }}}",
                    "",
                    "-- next wednesday {{{",
                    "-- }}}",
                    "",
                    "-- future {{{",
                    "-- }}}",
                    "",
                    "-- someday {{{",
                    "-- }}}",
                    "",
                    "-- done {{{",
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
                    { categorizer = organize.daily_agenda_categorizer("2021-02-01", {}) }
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
                        categorizer = organize.daily_agenda_categorizer(
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
                        categorizer = organize.daily_agenda_categorizer(
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
                        categorizer = organize.daily_agenda_categorizer(
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

            it("should have a 'someday' category", function()
                -- given
                local lines = {
                    "[ ] undone <someday>",
                    "[x] this is done",
                    "[ ] but this isn't",
                }

                -- when
                local result = organize.organize(lines, {
                    categorizer = organize.daily_agenda_categorizer(
                        "2021-06-01",
                        { show_empty_categories = false }
                    ),
                })

                -- then
                local expected = {
                    "-- today {{{",
                    "[ ] but this isn't",
                    "-- }}}",
                    "",
                    "-- someday {{{",
                    "[ ] <someday> undone",
                    "-- }}}",
                    "",
                    "-- done {{{",
                    "[x] this is done",
                    "-- }}}",
                }
                assert.are.same(result, expected)
            end)

            it("should move malformed tasks to a broken section", function()
                -- given
                local lines = {
                    "[ ] undone <zzz>",
                    "[ ] but this isn't",
                }

                -- when
                local result = organize.organize(
                    lines,
                    { categorizer = organize.daily_agenda_categorizer("2021-06-01", {}) }
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
                    categorizer = organize.daily_agenda_categorizer(
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

            it("should add date to header if option is given", function()
                -- given
                local lines = {
                    "[ ] undone <tomorrow>",
                    "[ ] but this isn't",
                }

                -- when
                local result = organize.organize(lines, {
                    categorizer = organize.daily_agenda_categorizer(
                        "2021-06-01",
                        { show_dates = true }
                    ),
                })

                -- then
                local expected = {
                    "-- today | jun 01 {{{",
                    "[ ] but this isn't",
                    "-- }}}",
                    "",
                    "-- tomorrow | jun 02 {{{",
                    "[ ] <tomorrow> undone",
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
                    categorizer = organize.daily_agenda_categorizer("2021-06-01", {
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
                    categorizer = organize.daily_agenda_categorizer(
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


            it("should respect days_until_future_option", function()
                -- given
                local tasks = {
                    "<today> this is the first one",
                    "<tomorrow> this is the second one #two",
                }

                -- when
                local result = organize.organize(tasks, {
                    categorizer = organize.daily_agenda_categorizer(
                        "2021-06-01",
                        { days_until_future = 1 }
                    ),
                })

                -- then
                local expected = {
                    "-- today {{{",
                    "[ ] <today> this is the first one",
                    "-- }}}",
                    "",
                    "-- future {{{",
                    "[ ] <tomorrow> this is the second one #two",
                    "-- }}}",
                }

                assert.are.same(result, expected)
            end)
        end)

        describe("first_tag_categorizer", function()
            local components = {
                categorizer = organize.first_tag_categorizer("2021-07-04"),
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
                    categorizer = organize.first_tag_categorizer("2021-06-01", {
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
                    categorizer = organize.first_tag_categorizer(
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

        describe("filterers", function()
            describe("tag_filterer", function()
                local categorizer = organize.first_tag_categorizer("2021-10-01")

                it("should accept a task that contains a target tag", function()
                    assert.are.equal(
                        organize.tag_filterer({ "#one", "#two" })("this is a #one test"),
                        true
                    )
                end)

                it("should reject a task that does not contain a target tag", function()
                    assert.are.equal(
                        organize.tag_filterer({ "#one", "#two" })(
                            "this is a #three test"
                        ),
                        false
                    )
                end)

                it("should accept a tagless task if 'none' is a target", function()
                    assert.are.equal(
                        organize.tag_filterer({ "none" })("this is a test"),
                        true
                    )
                end)

                it("should place the hidden tasks at the bottom", function()
                    local tag_filterer = organize.tag_filterer({ "#one" })
                    local tasks = {
                        "this is the first one",
                        "this is the second one #two",
                        "this is the third #one",
                    }
                    local result = organize.organize(
                        tasks,
                        { categorizer = categorizer, filterer = tag_filterer }
                    )

                    assert.are.same(result, {
                        "-- #one {{{",
                        "[ ] this is the third #one",
                        "-- }}}",
                        "",
                        "-- hidden {{{",
                        "[ ] this is the first one",
                        "[ ] this is the second one #two",
                        "-- }}}",
                    })
                end)

                it("should hide all tasks if none match the filter", function()
                    local tag_filterer = organize.tag_filterer({ "#zoomzoom" })
                    local tasks = {
                        "this is the first one",
                        "this is the second one #two",
                        "this is the third #one",
                    }
                    local result = organize.organize(
                        tasks,
                        { categorizer = categorizer, filterer = tag_filterer }
                    )

                    assert.are.same(result, {
                        "-- hidden {{{",
                        "[ ] this is the first one",
                        "[ ] this is the second one #two",
                        "[ ] this is the third #one",
                        "-- }}}",
                    })
                end)
            end)
        end)
    end)
end)
