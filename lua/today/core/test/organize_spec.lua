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
                "-- future (2) {{{",
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
                organize.do_date_categorizer("2021-02-01", { natural = false })
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
                    { show_empty_sections = true }
                )
            )

            -- then
            local expected = {
                "-- today (2) {{{",
                "[ ] undone",
                "[ ] but this isn't",
                "-- }}}",
                "",
                "-- tomorrow (0) {{{",
                "-- }}}",
                "",
                "-- next 7 days (0) {{{",
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
                organize.do_date_categorizer(
                    "2021-06-01"
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
