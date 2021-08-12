describe("infer", function()
    local organize = require("today.core.organize")

    if true then
        return
    end

    describe("do_date inferrer", function()
        it("should not infer datespec for unlabeled items in today category", function()
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
        end)

        it("should preserve datespec if it is given", function()
            -- given
            local lines = {
                "-- tomorrow (1) {{{",
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
                "-- tomorrow (1) {{{",
                "[ ] <tomorrow> task 2",
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
                    {}
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
                    {}
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
                    {}
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

        it("should be robust the date appearing in the header", function()
            -- given
            local lines = {
                "-- today | jun 01 | (1) {{{",
                "[ ] but this isn't",
                "-- }}}",
                "",
                "-- tomorrow | jun 02 | (1) {{{",
                "[ ] <tomorrow> undone",
                "[ ] something",
                "-- }}}",
            }

            -- when
            local result = organize.organize(
                lines,
                organize.do_date_categorizer(
                    -- this was a saturday
                    "2021-06-01",
                    { show_dates = true }
                )
            )

            -- then
            -- July 01 was a Thursday
            local expected = {
                "-- today | jun 01 | (1) {{{",
                "[ ] but this isn't",
                "-- }}}",
                "",
                "-- tomorrow | jun 02 | (2) {{{",
                "[ ] <tomorrow> undone",
                "[ ] <tomorrow> something",
                "-- }}}",
            }

            assert.are.same(result, expected)
        end)
    end)

    describe("tag inferrer", function()
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
