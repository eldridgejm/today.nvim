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

        it("should have overdue tasks at the top", function()
            -- given
            local lines = {
                "[ ] undone",
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
                "-- overdue (1) {{{",
                "[ ] <2021-01-01> but this isn't",
                "-- }}}",
                "",
                "-- today (1) {{{",
                "[ ] undone",
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
    end)

    describe("single_tag_categorizer", function()
        it("should sort headers alphabetically", function()
            local lines = {
                "this is #one something",
                "this is #two another",
                "and this is a four th",
                "this is #three #one a third",
                "this is another #one",
            }

            local result = organize.organize(lines, organize.first_tag_categorizer())

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

            local result = organize.organize(lines, organize.first_tag_categorizer())

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
    end)
end)
