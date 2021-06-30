describe("today.core.categorize", function()

    categorize = require('today.core.categorize')

    it("should move completed lines to the end", function()
        -- given
        local lines = {
            "[ ] undone",
            "[x] this is done",
            "[ ] but this isn't"
        }

        -- when
        local result = categorize(lines)

        -- then
        local expected = {
            "[ ] undone",
            "[ ] but this isn't",
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
        local result = categorize(lines)

        -- then
        local expected = {
            "[ ] undone",
            "[ ] but this isn't",
            "",
            "-- done (1) {{{",
            "[x] this is done",
            "-- }}}",
        }
        assert.are.same(result, expected)
    end)

end)
