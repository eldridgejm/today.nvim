describe("util module", function()
    util = require("today.util")

    describe("slice", function()
        it("slices lists", function()
            -- given
            list = { 1, 2, 3, 4, 5 }

            -- then
            assert.are.same(util.slice(list, 1, 4), { 1, 2, 3 })
        end)
    end)

    describe("prefix_search", function()
        it("should return first match", function()
            assert.are.equal(
                util.prefix_search(
                    { "this", "is", "a", "test", "of", "television" },
                    "te"
                ),
                4
            )
        end)

        it("should return nil on no match", function()
            assert.are.equal(
                util.prefix_search(
                    { "this", "is", "a", "test", "of", "television" },
                    "zzz"
                ),
                nil
            )
        end)

        it("should return nil on multiple matches if require_unique is true", function()
            assert.are.equal(
                util.prefix_search(
                    { "this", "is", "a", "test", "of", "television" },
                    "zzz",
                    true
                ),
                nil
            )
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

    describe("split", function()
        it("should split on whitespace by default", function()
            local result = util.split("this is   a\ttest")
            assert.are.same(result, { "this", "is", "a", "test" })
        end)

        it("should accept a separator", function()
            local result = util.split("this,is   a, test", ",")
            assert.are.same(result, { "this", "is   a", " test" })
        end)
    end)

    describe("lstrip", function()
        it("should leave a single char alone", function()
            assert.are.same(util.lstrip("x"), "x")
        end)
    end)

    describe("rstrip", function()
        it("should leave a single char alone", function()
            assert.are.same(util.rstrip("x"), "x")
        end)

        it("should remove whitespace on the right", function()
            assert.are.same(util.rstrip("testing   "), "testing")
        end)
    end)

    describe("strip", function()
        it("should leave a single char alone", function()
            assert.are.same(util.strip("x"), "x")
        end)
    end)
end)
