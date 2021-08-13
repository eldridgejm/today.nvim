describe("infer", function()
    local infer = require("today.core.infer")

    describe("do_date inferrer", function()
        it("should not infer datespec for unlabeled items in today category", function()
            -- given
            local lines = {
                "-- today | 1 {{{",
                "[ ] task 1",
                "-- }}}",
            }

            -- when
            local result = infer.infer(lines)

            -- then
            -- July 01 was a Thursday
            local expected = {
                "-- today | 1 {{{",
                "[ ] task 1",
                "-- }}}",
            }

            assert.are.same(result, expected)
        end)

        it("should preserve datespec if it is given", function()
            -- given
            local lines = {
                "-- tomorrow | 1 {{{",
                "[ ] task 2",
                "[ ] <today> task 1",
                "-- }}}",
            }

            -- when
            local result = infer.infer(lines)

            -- then
            -- July 01 was a Thursday
            local expected = {
                "-- tomorrow | 1 {{{",
                "[ ] task 2 <tomorrow>",
                "[ ] <today> task 1",
                "-- }}}",
            }

            assert.are.same(result, expected)
        end)

        it("should recognize the end of the section", function()
            -- given
            local lines = {
                "-- next week | 0 {{{",
                "-- }}}",
                "[ ] task 2",
            }

            -- when
            local result = infer.infer(lines)

            -- then
            -- July 01 was a Thursday
            local expected = {
                "-- next week | 0 {{{",
                "-- }}}",
                "[ ] task 2",
            }

            assert.are.same(result, expected)
        end)

        it("should infer future to be minimum number of days", function()
            -- given
            local lines = {
                "-- future (20+ days from now) | 1 {{{",
                "[ ] task 1",
                "-- }}}",
            }

            -- when
            local result = infer.infer(lines)

            -- then
            -- July 01 was a Thursday
            local expected = {
                "-- future (20+ days from now) | 1 {{{",
                "[ ] task 1 <20 days from now>",
                "-- }}}",
            }

            assert.are.same(result, expected)
        end)

        it("should infer someday in someday", function()
            -- given
            local lines = {
                "-- someday | 1 {{{",
                "[ ] task 1",
                "-- }}}",
            }

            -- when
            local result = infer.infer(lines)

            -- then
            -- July 01 was a Thursday
            local expected = {
                "-- someday | 1 {{{",
                "[ ] task 1 <someday>",
                "-- }}}",
            }

            assert.are.same(result, expected)
        end)

        it("should infer done in done", function()
            -- given
            local lines = {
                "-- done | 1 {{{",
                "[ ] task 1",
                "-- }}}",
            }

            -- when
            local result = infer.infer(lines)

            -- then
            -- July 01 was a Thursday
            local expected = {
                "-- done | 1 {{{",
                "[x] task 1",
                "-- }}}",
            }

            assert.are.same(result, expected)
        end)

        it("should infer tomorrow in tomorrow", function()
            -- given
            local lines = {
                "-- tomorrow | 1 {{{",
                "[ ] task 1",
                "-- }}}",
            }

            -- when
            local result = infer.infer(lines)

            -- then
            -- July 01 was a Thursday
            local expected = {
                "-- tomorrow | 1 {{{",
                "[ ] task 1 <tomorrow>",
                "-- }}}",
            }

            assert.are.same(result, expected)
        end)

        it("should infer weekday in weekday", function()
            -- given
            local lines = {
                "-- friday | 1 {{{",
                "[ ] task 1",
                "-- }}}",
            }

            -- when
            local result = infer.infer(lines)

            -- then
            -- July 01 was a Thursday
            local expected = {
                "-- friday | 1 {{{",
                "[ ] task 1 <friday>",
                "-- }}}",
            }

            assert.are.same(result, expected)
        end)

        it("should be robust to unknown category names", function()
            -- given
            local lines = {
                "-- what is this? | 1 {{{",
                "[ ] task 1",
                "-- }}}",
            }

            -- when
            local result = infer.infer(lines)

            -- then
            -- July 01 was a Thursday
            local expected = {
                "-- what is this? | 1 {{{",
                "[ ] task 1",
                "-- }}}",
            }

            assert.are.same(result, expected)
        end)

        it("should be robust the date appearing in the header", function()
            -- given
            local lines = {
                "-- today | jun 01 | 1 {{{",
                "[ ] but this isn't",
                "-- }}}",
                "",
                "-- tomorrow | jun 02 | 2 {{{",
                "[ ] <tomorrow> undone",
                "[ ] something",
                "-- }}}",
            }

            -- when
            local result = infer.infer(lines)

            -- then
            -- July 01 was a Thursday
            local expected = {
                "-- today | jun 01 | 1 {{{",
                "[ ] but this isn't",
                "-- }}}",
                "",
                "-- tomorrow | jun 02 | 2 {{{",
                "[ ] <tomorrow> undone",
                "[ ] something <tomorrow>",
                "-- }}}",
            }

            assert.are.same(result, expected)
        end)
    end)

    describe("tag inferrer", function()
        it("should infer first tag", function()
            -- given
            local lines = {
                "-- #personal | 1 {{{",
                "[ ] something",
                "-- }}}",
            }

            -- when
            local result = infer.infer(lines)

            -- then
            -- July 01 was a Thursday
            local expected = {
                "-- #personal | 1 {{{",
                "[ ] something #personal",
                "-- }}}",
            }

            assert.are.same(result, expected)
        end)

        it("should only infer if there are no tags currently", function()
            -- given
            local lines = {
                "-- #personal | 1 {{{",
                "[ ] something #other",
                "-- }}}",
            }

            -- when
            local result = infer.infer(lines)

            -- then
            -- July 01 was a Thursday
            local expected = {
                "-- #personal | 1 {{{",
                "[ ] something #other",
                "-- }}}",
            }

            assert.are.same(result, expected)
        end)

        it("should handle the 'other' category", function()
            -- given
            local lines = {
                "-- other | 1 {{{",
                "[ ] something",
                "-- }}}",
            }

            -- when
            local result = infer.infer(lines)

            -- then
            local expected = {
                "-- other | 1 {{{",
                "[ ] something",
                "-- }}}",
            }

            assert.are.same(result, expected)
        end)
    end)
end)
