describe("core.sort", function()
    sort = require("today.core.sort")

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

    describe("by_priority_then_date", function()
        it("should break ties as specified", function()
            local lines = {
                "[ ] 1 this is high !! <tomorrow>",
                "[ ] 2 this is high !! <today>",
                "[ ] this is low ! <today>",
                "[ ] 3 this is high !! <tomorrow> #tag1",
                "[ ] 4 this is high !! <tomorrow> #tag2",
                "[ ] this has no priority #tag1",
                "[ ] 5 this is high !! <tomorrow> #tag1",
            }

            sort.by_priority_then_date(lines)

            local expected = {
                "[ ] 2 this is high !! <today>",
                "[ ] 1 this is high !! <tomorrow>",
                "[ ] 3 this is high !! <tomorrow> #tag1",
                "[ ] 4 this is high !! <tomorrow> #tag2",
                "[ ] 5 this is high !! <tomorrow> #tag1",
                "[ ] this is low ! <today>",
                "[ ] this has no priority #tag1",
            }
            assert.are.same(expected, lines)
        end)
    end)
end)
