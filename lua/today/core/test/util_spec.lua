describe("util module", function()
    util = require("today.core.util")

    describe("slice", function()
        it("slices lists", function()
            -- given
            list = { 1, 2, 3, 4, 5 }

            -- then
            assert.are.same(util.slice(list, 1, 4), { 1, 2, 3 })
        end)
    end)

    describe("groupby", function()
        it("creates a table of groups", function()
            local function get_key(s)
                return #s
            end

            local lst = {
                "aaa",
                "c",
                "bb",
                "bbb",
                "ddd",
                "ee",
                "aaa",
            }

            local result = util.groupby(get_key, lst)
            local expected = {}
            expected[3] = { "aaa", "bbb", "ddd", "aaa" }
            expected[1] = { "c" }
            expected[2] = { "bb", "ee" }

            assert.are.same(result, expected)
        end)
    end)
end)
