describe("util module", function()

    util = require('today.core.util')

    describe("slice", function()

        it("slices lists", function()
            -- given
            list = {1, 2, 3, 4, 5}

            -- then
            assert.are.same(
                util.slice(list, 1, 4),
                {1, 2, 3}
            )
        end)

    end)

    describe("mergesort", function()
        it(", you know, sorts, small lists", function()
            local list = {2, 1, 3}
            util.mergesort(list)
            assert.are.same(
                list,
                {1, 2, 3}
            )
        end)

        it(", you know, sorts", function()
            local list = {4, 5, 1, 2, 9, 6, 10}
            util.mergesort(list)
            assert.are.same(
                list,
                {1, 2, 4, 5, 6, 9, 10}
            )
        end)

        it(", you know, sorts again", function()
            local list = {4, 5, 1, 2, 9, 6}
            util.mergesort(list)
            assert.are.same(
                list,
                {1, 2, 4, 5, 6, 9}
            )
        end)
    end)

end)
