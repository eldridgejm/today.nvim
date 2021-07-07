describe("datespec", function()
    DateSpec = require("today.core.datespec")

    describe("new", function()

        it("reads natural language for today", function()
            local ds = DateSpec:new("<today>", "2021-02-01")
            local y, m, d = ds.do_date:getdate()
            assert.are.same({ y, m, d }, { 2021, 2, 1 })
        end)

        it("reads natural language for tomorrow", function()
            local ds = DateSpec:new("<tomorrow>", "2021-02-01")
            local y, m, d = ds.do_date:getdate()
            assert.are.same({ y, m, d }, { 2021, 2, 2 })
        end)
    end)

    describe("days_away", function()
        it("detects actual tomorrow", function()
            local ds = DateSpec:new("<2021-06-10>", "2021-06-09")
            assert.are.equal(ds:days_away(), 1)
        end)

        it("detects actual tomorrow", function()
            local ds = DateSpec:new("<2021-07-02>", "2021-07-01T05:10:59")
            assert.are.equal(ds:days_away(), 1)
        end)

        it("detects not tomorrow", function()
            local ds = DateSpec:new("<2021-06-10>", "2021-06-08")
            assert.are.equal(ds:days_away(), 2)
        end)

        it("detects actual next week", function()
            local ds = DateSpec:new("<2021-06-12>", "2021-06-09")
            assert.are.equal(ds:days_away(), 3)
        end)

        it("detects not tomorrow", function()
            local ds = DateSpec:new("<2021-06-20>", "2021-06-08")
            assert.are.equal(ds:days_away(), 12)
        end)

        it("on date in the past", function()
            local ds = DateSpec:new("<2021-07-01>", "2021-07-08")
            assert.are.equal(ds:days_away(), -7)
        end)
    end)

    describe("serialize", function()
        it("converts a datespec to a string", function()
            assert.are.equal(DateSpec:new("<2021-06-20>"):serialize(), "<2021-06-20>")
        end)

        it("converts to natural language", function()
            assert.are.equal(
                DateSpec:new("<2021-06-20>", "2021-06-20"):serialize(true),
                "<today>"
            )
        end)
    end)
end)
