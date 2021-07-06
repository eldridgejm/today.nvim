describe("update", function()
    update = require('today.core.update')

    describe("pre_write", function()
        it("should make date specs absolute", function()
            lines = {
                "[x] this is something",
                "[x] and so is this <today>"
            }
            result = update.pre_write(lines, "2021-07-04")
            assert.are.same(
                result,
                {
                    "[x] this is something",
                    "[x] and so is this <2021-07-04>"
                }
            )
        end)
    end)

    describe("post_read", function()

        it("should move completed lines to the end", function()
            -- given
            local lines = {
                "[ ] undone",
                "[x] this is done",
                "[ ] but this isn't"
            }

            -- when
            local result = update.post_read(lines)

            -- then
            local expected = {
                "-- today (2) {{{",
                "[ ] undone",
                "[ ] but this isn't",
                "-- }}}",
                "",
                "-- done (1) {{{",
                "[x] this is done",
                "-- }}}"
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
                "-- }}}"
            }

            -- when
            local result = update.post_read(lines)

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
            local result = update.post_read(lines, "2021-02-01")

            -- then
            local expected = {
                "-- overdue (1) {{{",
                "[ ] but this isn't <2021-01-01>",
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
            local result = update.post_read(lines, "2021-02-01")

            -- then
            local expected = {
                "-- future (2) {{{",
                "[ ] but this isn't <2021-02-11>",
                "[ ] undone <2021-02-12>",
                "-- }}}",
                "",
                "-- done (2) {{{",
                "[x] also done <today>",
                "[x] this is done <tomorrow>",
                "-- }}}",
            }
            assert.are.same(result, expected)
        end)
    end)
end)
