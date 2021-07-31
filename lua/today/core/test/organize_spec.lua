describe("organize", function()
    organize = require("today.core.organize")

    describe("do_date_categorizer", function()
        it("should move completed lines to the end", function()
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

        it("should sort by do date within each section", function()
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
                "-- this week (2) {{{",
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
                organize.do_date_categorizer("2021-02-01" )
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

        it("should show empty sections if option given", function()
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
                    { show_empty_sections = true, view = "weekly" }
                )
            )

            -- then
            local expected = {
                "-- today (2) {{{",
                "[ ] undone",
                "[ ] but this isn't",
                "-- }}}",
                "",
                "-- this week (0) {{{",
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

        it("should have a 'someday' section", function()
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
                    organize.do_date_categorizer("2021-07-01", { show_empty_sections = true, view = "daily" })
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

            it("should have a 'someday' section", function()
                -- given
                local lines = {
                    "[ ] undone <someday>",
                    "[x] this is done",
                    "[ ] but this isn't",
                }

                -- when
                local result = organize.organize(
                    lines,
                    organize.do_date_categorizer("2021-06-01", { show_empty_sections = false, view = "daily" })
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
                "[ ] this is #one something",
                "[ ] this is another #one",
                "-- }}}",
                "",
                "-- #three (1) {{{",
                "[ ] this is #three #one a third",
                "-- }}}",
                "",
                "-- #two (1) {{{",
                "[ ] this is #two another",
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
                "[ ] this is #one something",
                "[x] this is another #one",
                "-- }}}",
                "",
                "-- #three (1) {{{",
                "[x] this is #three #one a third",
                "-- }}}",
                "",
                "-- #two (1) {{{",
                "[ ] this is #two another",
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
                "[ ] <today> ! and this is a #one th",
                "[ ] <tomorrow> this is #one something",
                "-- }}}",
                "",
                "-- #three (1) {{{",
                "[ ] this is #three #one a third",
                "-- }}}",
                "",
                "-- #two (1) {{{",
                "[ ] this is #two another",
                "-- }}}",
                "",
                "-- other (1) {{{",
                "[ ] ok this works",
                "-- }}}",
            })
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
end)
