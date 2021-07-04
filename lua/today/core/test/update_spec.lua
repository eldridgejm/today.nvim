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
end)
