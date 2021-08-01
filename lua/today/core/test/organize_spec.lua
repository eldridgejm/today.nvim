describe("organize", function()
    organize = require("today.core.organize")

    describe("do_date_categorizer", function()
        describe("default weekly view", function()
            it("should move completed lines to the done category by default", function()
                -- given
                local lines = {
                    "[ ] undone",
                    "[x] this is done",
                    "[ ] but this isn't",
                }

                -- when
                local result = organize.organize(
                    lines,
                    organize.do_date_categorizer("2021-06-01")
                )

                -- then
                local expected = {
                    "-- today (2) {{{",
                    "[ ] undone",
                    "[ ] but this isn't",
                    "-- }}}",
                    "",
                    "-- done (1) {{{",
                    "[x] this is done",
                    "-- }}}",
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
                    local result = organize.organize(
                        lines,
                        organize.do_date_categorizer(
                            "2021-06-01",
                            { move_to_done_immediately = false }
                        )
                    )

                    -- then
                    local expected = {
                        "-- today (3) {{{",
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
                    local result = organize.organize(
                        lines,
                        organize.do_date_categorizer(
                            "2021-06-01",
                            { move_to_done_immediately = false }
                        )
                    )

                    -- then
                    local expected = {
                        "-- today (2) {{{",
                        "[ ] undone",
                        "[ ] but this isn't",
                        "-- }}}",
                        "",
                        "-- done (1) {{{",
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
                        "[x]  this is done",
                        "[ ] but this isn't",
                    }

                    -- when
                    local result = organize.organize(
                        lines,
                        organize.do_date_categorizer(
                            "2021-06-01",
                            { move_to_done_immediately = false }
                        )
                    )

                    -- then
                    local expected = {
                        "-- today (2) {{{",
                        "[ ] undone",
                        "[ ] but this isn't",
                        "-- }}}",
                        "",
                        "-- done (1) {{{",
                        "[x] this is done",
                        "-- }}}",
                    }
                    assert.are.same(result, expected)
                end
            )
            it("should not create a new done category if exists", function()
                -- given
                local lines = {
                    "[ ] undone",
                    "[x] this is done",
                    "[ ] but this isn't",
                    "",
                    "-- done (0) {{{",
                    "-- }}}",
                }

                -- when
                local result = organize.organize(
                    lines,
                    organize.do_date_categorizer("2021-06-01")
                )

                -- then
                local expected = {
                    "-- today (2) {{{",
                    "[ ] undone",
                    "[ ] but this isn't",
                    "-- }}}",
                    "",
                    "-- done (1) {{{",
                    "[x] this is done",
                    "-- }}}",
                }
                assert.are.same(result, expected)
            end)

            it("should have over-do tasks at top of today category", function()
                -- given
                local lines = {
                    "[ ] undone <today>",
                    "[x] this is done",
                    "[ ] but this isn't <2021-01-01>",
                }

                -- when
                local result = organize.organize(
                    lines,
                    organize.do_date_categorizer("2021-02-01")
                )

                -- then
                local expected = {
                    "-- today (2) {{{",
                    "[ ] <2021-01-01> but this isn't",
                    "[ ] <today> undone",
                    "-- }}}",
                    "",
                    "-- done (1) {{{",
                    "[x] this is done",
                    "-- }}}",
                }
                assert.are.same(result, expected)
            end)

            it("should sort by do date within each category", function()
                -- given
                local lines = {
                    "[ ] undone <11 days from now>",
                    "[x] this is done <tomorrow>",
                    "[x] also done <today>",
                    "[ ] but this isn't <10 days from now>",
                }

                -- when
                local result = organize.organize(
                    lines,
                    organize.do_date_categorizer("2021-02-01")
                )

                -- then
                local expected = {
                    "-- next week (2) {{{",
                    "[ ] <10 days from now> but this isn't",
                    "[ ] <11 days from now> undone",
                    "-- }}}",
                    "",
                    "-- done (2) {{{",
                    "[x] <today> also done",
                    "[x] <tomorrow> this is done",
                    "-- }}}",
                }
                assert.are.same(result, expected)
            end)

            it("should sort by do date into this week and next", function()
                -- given
                local lines = {
                    "[ ] undone <thursday>",
                    "[ ] this is done <tomorrow>",
                    "[ ] also done <next wednesday>",
                    "[ ] but this isn't <next friday>",
                }

                -- when
                local result = organize.organize(
                    lines,
                    organize.do_date_categorizer("2021-07-04") -- a sunday
                )

                -- then
                local expected = {
                    "-- rest of this week (2) {{{",
                    "[ ] <tomorrow> this is done",
                    "[ ] <thursday> undone",
                    "-- }}}",
                    "",
                    "-- next week (2) {{{",
                    "[ ] <next wednesday> also done",
                    "[ ] <next friday> but this isn't",
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
                    organize.do_date_categorizer("2021-02-01")
                )

                -- then
                local expected = {
                    "--: this is a user comment",
                    "",
                    "-- today (1) {{{",
                    "[ ] but this isn't",
                    "-- }}}",
                    "",
                    "-- done (1) {{{",
                    "[x] this is done",
                    "-- }}}",
                    "",
                    "--: and so is this",
                }
                assert.are.same(result, expected)
            end)

            it("should show empty categories if option given", function()
                -- given
                local lines = {
                    "[ ] undone",
                    "[x] this is done",
                    "[ ] but this isn't",
                }

                -- when
                local result = organize.organize(
                    lines,
                    organize.do_date_categorizer(
                        "2021-06-01",
                        { show_empty_categories = true, view = "weekly" }
                    )
                )

                -- then
                local expected = {
                    "-- today (2) {{{",
                    "[ ] undone",
                    "[ ] but this isn't",
                    "-- }}}",
                    "",
                    "-- rest of this week (0) {{{",
                    "-- }}}",
                    "",
                    "-- next week (0) {{{",
                    "-- }}}",
                    "",
                    "-- future (0) {{{",
                    "-- }}}",
                    "",
                    "-- someday (0) {{{",
                    "-- }}}",
                    "",
                    "-- done (1) {{{",
                    "[x] this is done",
                    "-- }}}",
                }
                assert.are.same(result, expected)
            end)

            it("should have a 'someday' category", function()
                -- given
                local lines = {
                    "[ ] undone <someday>",
                    "[x] this is done",
                    "[ ] but this isn't",
                }

                -- when
                local result = organize.organize(
                    lines,
                    organize.do_date_categorizer("2021-06-01")
                )

                -- then
                local expected = {
                    "-- today (1) {{{",
                    "[ ] but this isn't",
                    "-- }}}",
                    "",
                    "-- someday (1) {{{",
                    "[ ] <someday> undone",
                    "-- }}}",
                    "",
                    "-- done (1) {{{",
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
                    organize.do_date_categorizer("2021-06-01")
                )

                -- then
                local expected = {
                    "-- broken (1) {{{",
                    "[ ] <zzz> undone",
                    "-- }}}",
                    "",
                    "-- today (1) {{{",
                    "[ ] but this isn't",
                    "-- }}}",
                }
                assert.are.same(result, expected)
            end)
        end)

        describe("daily view", function()
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
                local result = organize.organize(
                    lines,
                    organize.do_date_categorizer(
                        "2021-07-01",
                        { show_empty_categories = true, view = "daily" }
                    )
                )

                -- then
                -- July 01 was a Thursday
                local expected = {
                    "-- today (1) {{{",
                    "[ ] <2021-07-01> task 1",
                    "-- }}}",
                    "",
                    "-- tomorrow (1) {{{",
                    "[ ] <2021-07-02> task 2",
                    "-- }}}",
                    "",
                    "-- saturday (1) {{{",
                    "[ ] <2021-07-03> task 3",
                    "-- }}}",
                    "",
                    "-- sunday (1) {{{",
                    "[ ] <2021-07-04> task 4",
                    "-- }}}",
                    "",
                    "-- monday (1) {{{",
                    "[ ] <2021-07-05> task 5",
                    "-- }}}",
                    "",
                    "-- tuesday (1) {{{",
                    "[ ] <2021-07-06> task 6",
                    "-- }}}",
                    "",
                    "-- wednesday (1) {{{",
                    "[ ] <2021-07-07> task 7",
                    "-- }}}",
                    "",
                    "-- next thursday (1) {{{",
                    "[ ] <2021-07-08> task 8",
                    "-- }}}",
                    "",
                    "-- next friday (1) {{{",
                    "[ ] <2021-07-09> task 9",
                    "-- }}}",
                    "",
                    "-- next saturday (1) {{{",
                    "[ ] <2021-07-10> task 10",
                    "-- }}}",
                    "",
                    "-- next sunday (0) {{{",
                    "-- }}}",
                    "",
                    "-- next monday (0) {{{",
                    "-- }}}",
                    "",
                    "-- next tuesday (0) {{{",
                    "-- }}}",
                    "",
                    "-- next wednesday (0) {{{",
                    "-- }}}",
                    "",
                    "-- future (0) {{{",
                    "-- }}}",
                    "",
                    "-- someday (0) {{{",
                    "-- }}}",
                    "",
                    "-- done (0) {{{",
                    "-- }}}",
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
                    local result = organize.organize(
                        lines,
                        organize.do_date_categorizer(
                            "2021-06-01",
                            { view = "daily", move_to_done_immediately = false }
                        )
                    )

                    -- then
                    local expected = {
                        "-- today (3) {{{",
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
                    local result = organize.organize(
                        lines,
                        organize.do_date_categorizer(
                            "2021-06-01",
                            { view = "daily", move_to_done_immediately = false }
                        )
                    )

                    -- then
                    local expected = {
                        "-- today (2) {{{",
                        "[ ] undone",
                        "[ ] but this isn't",
                        "-- }}}",
                        "",
                        "-- done (1) {{{",
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
                    local result = organize.organize(
                        lines,
                        organize.do_date_categorizer(
                            "2021-06-01",
                            { view = "daily", move_to_done_immediately = false }
                        )
                    )

                    -- then
                    local expected = {
                        "-- today (2) {{{",
                        "[ ] undone",
                        "[ ] but this isn't",
                        "-- }}}",
                        "",
                        "-- done (1) {{{",
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
                local result = organize.organize(
                    lines,
                    organize.do_date_categorizer(
                        "2021-06-01",
                        { show_empty_categories = false, view = "daily" }
                    )
                )

                -- then
                local expected = {
                    "-- today (1) {{{",
                    "[ ] but this isn't",
                    "-- }}}",
                    "",
                    "-- someday (1) {{{",
                    "[ ] <someday> undone",
                    "-- }}}",
                    "",
                    "-- done (1) {{{",
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
                    organize.do_date_categorizer("2021-06-01", { view = "daily" })
                )

                -- then
                local expected = {
                    "-- broken (1) {{{",
                    "[ ] <zzz> undone",
                    "-- }}}",
                    "",
                    "-- today (1) {{{",
                    "[ ] but this isn't",
                    "-- }}}",
                }
                assert.are.same(result, expected)
            end)

        end)
    end)

    describe("first_tag_categorizer", function()
        it("should sort headers alphabetically", function()
            local lines = {
                "this is #one something",
                "this is #two another",
                "and this is a four th",
                "this is #three #one a third",
                "this is another #one",
            }

            local result = organize.organize(
                lines,
                organize.first_tag_categorizer("2021-07-04")
            )

            assert.are.same(result, {
                "-- #one (2) {{{",
                "[ ] this is something #one",
                "[ ] this is another #one",
                "-- }}}",
                "",
                "-- #three (1) {{{",
                "[ ] this is a third #three #one",
                "-- }}}",
                "",
                "-- #two (1) {{{",
                "[ ] this is another #two",
                "-- }}}",
                "",
                "-- other (1) {{{",
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

            local result = organize.organize(
                lines,
                organize.first_tag_categorizer("2021-07-05")
            )

            assert.are.same(result, {
                "-- #one (2) {{{",
                "[ ] this is something #one",
                "[x] this is another #one",
                "-- }}}",
                "",
                "-- #three (1) {{{",
                "[x] this is a third #three #one",
                "-- }}}",
                "",
                "-- #two (1) {{{",
                "[ ] this is another #two",
                "-- }}}",
                "",
                "-- other (2) {{{",
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

            local result = organize.organize(
                lines,
                organize.first_tag_categorizer("2021-07-05")
            )

            assert.are.same(result, {

                "-- #one (3) {{{",
                "[ ] <today> !! this is another #one",
                "[ ] <today> ! and this is a th #one",
                "[ ] <tomorrow> this is something #one",
                "-- }}}",
                "",
                "-- #three (1) {{{",
                "[ ] this is a third #three #one",
                "-- }}}",
                "",
                "-- #two (1) {{{",
                "[ ] this is another #two",
                "-- }}}",
                "",
                "-- other (1) {{{",
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
                local result = organize.organize(
                    lines,
                    organize.first_tag_categorizer("2021-06-01")
                )

                -- then
                local expected = {
                    "-- broken (1) {{{",
                    "[ ] <zzz> undone",
                    "-- }}}",
                    "",
                    "-- other (1) {{{",
                    "[ ] but this isn't",
                    "-- }}}",
                }
                assert.are.same(result, expected)
            end)

    end)

    describe("tag_filterer", function()
        it("should accept a task that contains a target tag", function()
            assert.are.equal(
                organize.tag_filterer({ "#one", "#two" })("this is a #one test"),
                true
            )
        end)

        it("should reject a task that does not contain a target tag", function()
            assert.are.equal(
                organize.tag_filterer({ "#one", "#two" })("this is a #three test"),
                false
            )
        end)

        it("should accept a tagless task if 'none' is a target", function()
            assert.are.equal(organize.tag_filterer({ "none" })("this is a test"), true)
        end)
    end)

    describe("filterer", function()
        local categorizer = organize.first_tag_categorizer("2021-10-01")

        it("should place the hidden tasks at the bottom", function()
            local tag_filterer = organize.tag_filterer({ "#one" })
            local tasks = {
                "this is the first one",
                "this is the second one #two",
                "this is the third #one",
            }
            local result = organize.organize(tasks, categorizer, tag_filterer)

            assert.are.same(result, {
                "-- #one (1) {{{",
                "[ ] this is the third #one",
                "-- }}}",
                "",
                "-- hidden (2) {{{",
                "[ ] this is the first one",
                "[ ] this is the second one #two",
                "-- }}}",
            })
        end)
    end)

    describe("datespec inferrer", function()
        describe("do date categorizer", function()
            it(
                "should not infer datespec for unlabeled items in today category",
                function()
                    -- given
                    local lines = {
                        "-- today (1) {{{",
                        "[ ] task 1",
                        "-- }}}",
                    }

                    -- when
                    local result = organize.organize(
                        lines,
                        organize.do_date_categorizer("2021-07-01")
                    )

                    -- then
                    -- July 01 was a Thursday
                    local expected = {
                        "-- today (1) {{{",
                        "[ ] task 1",
                        "-- }}}",
                    }

                    assert.are.same(result, expected)
                end
            )

            it(
                "should infer tomorrow from rest of this week if tomorrow is in the same week",
                function()
                    -- given
                    local lines = {
                        "-- rest of this week (1) {{{",
                        "[ ] task 1",
                        "-- }}}",
                    }

                    -- when
                    local result = organize.organize(
                        lines,
                        organize.do_date_categorizer(
                            -- this was a monday
                            "2021-07-05"
                        )
                    )

                    -- then
                    -- July 01 was a Thursday
                    local expected = {
                        "-- rest of this week (1) {{{",
                        "[ ] <tomorrow> task 1",
                        "-- }}}",
                    }

                    assert.are.same(result, expected)
                end
            )

            it(
                "should infer today from rest of this week if tomorrow is in the next week",
                function()
                    -- given
                    local lines = {
                        "-- rest of this week (1) {{{",
                        "[ ] task 1",
                        "-- }}}",
                    }

                    -- when
                    local result = organize.organize(
                        lines,
                        organize.do_date_categorizer(
                            -- this was a saturday
                            "2021-07-03"
                        )
                    )

                    -- then
                    -- July 01 was a Thursday
                    local expected = {
                        "-- today (1) {{{",
                        "[ ] <today> task 1",
                        "-- }}}",
                    }

                    assert.are.same(result, expected)
                end
            )

            it("should preserve datespec if it is given", function()
                -- given
                local lines = {
                    "-- next week (1) {{{",
                    "[ ] task 2",
                    "[ ] <today> task 1",
                    "-- }}}",
                }

                -- when
                local result = organize.organize(
                    lines,
                    organize.do_date_categorizer(
                        -- this was a monday
                        "2021-07-05"
                    )
                )

                -- then
                -- July 01 was a Thursday
                local expected = {
                    "-- today (1) {{{",
                    "[ ] <today> task 1",
                    "-- }}}",
                    "",
                    "-- next week (1) {{{",
                    "[ ] <next week> task 2",
                    "-- }}}",
                }

                assert.are.same(result, expected)
            end)

            it("should recognize the end of the section", function()
                -- given
                local lines = {
                    "-- next week (1) {{{",
                    "-- }}}",
                    "[ ] task 2",
                }

                -- when
                local result = organize.organize(
                    lines,
                    organize.do_date_categorizer(
                        -- this was a monday
                        "2021-07-05"
                    )
                )

                -- then
                -- July 01 was a Thursday
                local expected = {
                    "-- today (1) {{{",
                    "[ ] task 2",
                    "-- }}}",
                }

                assert.are.same(result, expected)
            end)

            it("should infer next week in next week", function()
                -- given
                local lines = {
                    "-- next week (1) {{{",
                    "[ ] task 1",
                    "-- }}}",
                }

                -- when
                local result = organize.organize(
                    lines,
                    organize.do_date_categorizer(
                        -- this was a saturday
                        "2021-07-03"
                    )
                )

                -- then
                -- July 01 was a Thursday
                local expected = {
                    "-- next week (1) {{{",
                    "[ ] <next week> task 1",
                    "-- }}}",
                }

                assert.are.same(result, expected)
            end)

            it("should infer 15 days from now in future", function()
                -- given
                local lines = {
                    "-- future (1) {{{",
                    "[ ] task 1",
                    "-- }}}",
                }

                -- when
                local result = organize.organize(
                    lines,
                    organize.do_date_categorizer(
                        -- this was a saturday
                        "2021-07-03"
                    )
                )

                -- then
                -- July 01 was a Thursday
                local expected = {
                    "-- future (1) {{{",
                    "[ ] <15 days from now> task 1",
                    "-- }}}",
                }

                assert.are.same(result, expected)
            end)

            it("should infer someday in someday", function()
                -- given
                local lines = {
                    "-- someday (1) {{{",
                    "[ ] task 1",
                    "-- }}}",
                }

                -- when
                local result = organize.organize(
                    lines,
                    organize.do_date_categorizer(
                        -- this was a saturday
                        "2021-07-03"
                    )
                )

                -- then
                -- July 01 was a Thursday
                local expected = {
                    "-- someday (1) {{{",
                    "[ ] <someday> task 1",
                    "-- }}}",
                }

                assert.are.same(result, expected)
            end)

            it("should infer done in done", function()
                -- given
                local lines = {
                    "-- done (1) {{{",
                    "[ ] task 1",
                    "-- }}}",
                }

                -- when
                local result = organize.organize(
                    lines,
                    organize.do_date_categorizer(
                        -- this was a saturday
                        "2021-07-03"
                    )
                )

                -- then
                -- July 01 was a Thursday
                local expected = {
                    "-- done (1) {{{",
                    "[x] task 1",
                    "-- }}}",
                }

                assert.are.same(result, expected)
            end)

            it("should infer tomorrow in tomorrow", function()
                -- given
                local lines = {
                    "-- tomorrow (1) {{{",
                    "[ ] task 1",
                    "-- }}}",
                }

                -- when
                local result = organize.organize(
                    lines,
                    organize.do_date_categorizer(
                        -- this was a saturday
                        "2021-07-03",
                        { view = "daily" }
                    )
                )

                -- then
                -- July 01 was a Thursday
                local expected = {
                    "-- tomorrow (1) {{{",
                    "[ ] <tomorrow> task 1",
                    "-- }}}",
                }

                assert.are.same(result, expected)
            end)

            it("should infer weekday in weekday", function()
                -- given
                local lines = {
                    "-- friday (1) {{{",
                    "[ ] task 1",
                    "-- }}}",
                }

                -- when
                local result = organize.organize(
                    lines,
                    organize.do_date_categorizer(
                        -- this was a saturday
                        "2021-07-03",
                        { view = "daily" }
                    )
                )

                -- then
                -- July 01 was a Thursday
                local expected = {
                    "-- friday (1) {{{",
                    "[ ] <friday> task 1",
                    "-- }}}",
                }

                assert.are.same(result, expected)
            end)

            it("should be robust to unknown category names", function()
                -- given
                local lines = {
                    "-- what is this? (1) {{{",
                    "[ ] task 1",
                    "-- }}}",
                }

                -- when
                local result = organize.organize(
                    lines,
                    organize.do_date_categorizer(
                        -- this was a saturday
                        "2021-07-03",
                        { view = "daily" }
                    )
                )

                -- then
                -- July 01 was a Thursday
                local expected = {
                    "-- today (1) {{{",
                    "[ ] task 1",
                    "-- }}}",
                }

                assert.are.same(result, expected)
            end)
        end)

        describe("first_tag_categorizer", function()
            it("should infer first tag", function()
                -- given
                local lines = {
                    "-- #personal (1) {{{",
                    "[ ] something",
                    "-- }}}",
                }

                -- when
                local result = organize.organize(
                    lines,
                    organize.first_tag_categorizer("2021-10-10")
                )

                -- then
                -- July 01 was a Thursday
                local expected = {
                    "-- #personal (1) {{{",
                    "[ ] something #personal",
                    "-- }}}",
                }

                assert.are.same(result, expected)
            end)

            it("should only infer if there are no tags currently", function()
                -- given
                local lines = {
                    "-- #personal (1) {{{",
                    "[ ] something #other",
                    "-- }}}",
                }

                -- when
                local result = organize.organize(
                    lines,
                    organize.first_tag_categorizer("2021-10-10")
                )

                -- then
                -- July 01 was a Thursday
                local expected = {
                    "-- #other (1) {{{",
                    "[ ] something #other",
                    "-- }}}",
                }

                assert.are.same(result, expected)
            end)

            it("should handle the 'other' category", function()
                -- given
                local lines = {
                    "-- other (1) {{{",
                    "[ ] something",
                    "-- }}}",
                }

                -- when
                local result = organize.organize(
                    lines,
                    organize.first_tag_categorizer("2021-10-10")
                )

                -- then
                local expected = {
                    "-- other (1) {{{",
                    "[ ] something",
                    "-- }}}",
                }

                assert.are.same(result, expected)
            end)

            it("should handle tasks outside of a category", function()
                -- given
                local lines = {
                    "[ ] something",
                }

                -- when
                local result = organize.organize(
                    lines,
                    organize.first_tag_categorizer("2021-10-10")
                )

                -- then
                local expected = {
                    "-- other (1) {{{",
                    "[ ] something",
                    "-- }}}",
                }

                assert.are.same(result, expected)
            end)
        end)
    end)
end)
