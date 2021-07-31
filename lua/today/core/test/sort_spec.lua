describe("core.sort", function()
    sort = require("today.core.sort")

    describe("mergesort", function()
        it(", you know, sorts, small lists", function()
            local list = { 2, 1, 3 }
            sort.mergesort(list)
            assert.are.same(list, { 1, 2, 3 })
        end)

        it(", you know, sorts", function()
            local list = { 4, 5, 1, 2, 9, 6, 10 }
            sort.mergesort(list)
            assert.are.same(list, { 1, 2, 4, 5, 6, 9, 10 })
        end)

        it(", you know, sorts again", function()
            local list = { 4, 5, 1, 2, 9, 6 }
            sort.mergesort(list)
            assert.are.same(list, { 1, 2, 4, 5, 6, 9 })
        end)
    end)

    describe("chain_comparators", function()
        local function by_1(x, y)
            if x[1] == y[1] then
                return nil
            end
            return x[1] < y[1]
        end

        local function by_2(x, y)
            if x[2] == y[2] then
                return nil
            end
            return x[2] < y[2]
        end

        local function by_3(x, y)
            if x[3] == y[3] then
                return nil
            end
            return x[3] < y[3]
        end

        it("should fall through on a tie", function()
            local chain = sort.chain_comparators({ by_1, by_2 })
            assert.truthy(chain({ 1, 2, 3 }, { 1, 4, 5 }))
        end)

        it("should fall through on a tie, again", function()
            local chain = sort.chain_comparators({ by_1, by_2 })
            assert.falsy(chain({ 1, 2, 3 }, { 1, 0, 5 }))
        end)

        it("should return false if equal", function()
            local chain = sort.chain_comparators({ by_1, by_2 })
            assert.are.equal(chain({ 1, 2, 3 }, { 1, 2, 3 }), true)
        end)
    end)

    describe("make_order_comparator", function()
        local order = { "beta", "gamma", "alpha", "epsilon" }

        describe("it places alpha after gamma", function()
            assert.is.falsy(sort.make_order_comparator(order)("alpha", "gamma"))
        end)

        describe("it places alpha before epsilon", function()
            assert.is.truthy(sort.make_order_comparator(order)("alpha", "epsilon"))
        end)

        describe("it does not place alpha before alpha", function()
            assert.is.falsy(sort.make_order_comparator(order)("alpha", "alpha"))
        end)
    end)
end)
