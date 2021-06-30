describe("core.sort", function()

    sort = require('today.core.sort')

    describe("by_priority", function()
        it("sorts lines by their priority", function()
            -- given
            local lines = {
                "[ ] this is low !",
                "[ ] this is high !!",
                "[ ] this has no priority",
            }

            -- when
            sort.by_priority(lines)

            -- then
            local expected = {
                "[ ] this is high !!",
                "[ ] this is low !",
                "[ ] this has no priority",
            }
            assert.are.same(expected, lines)

        end)
    end)

    describe("by_priority", function()
        it("is stable", function()
            -- given
            local lines = {
                "[ ] this is low !",
                "[ ] 1 this is high !!",
                "[ ] 2 this is high !!",
                "[ ] 3 this is high !!",
                "[ ] this has no priority",
            }

            -- when
            sort.by_priority(lines)

            -- then
            local expected = {
                "[ ] 1 this is high !!",
                "[ ] 2 this is high !!",
                "[ ] 3 this is high !!",
                "[ ] this is low !",
                "[ ] this has no priority",
            }
            assert.are.same(expected, lines)

        end)
    end)
end)
