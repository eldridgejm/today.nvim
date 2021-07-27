describe("datespec", function()
    DateSpec = require("today.core.datespec")

    local function assert_date_equals(dateobj, expected_date)
        local y, m, d = dateobj:getdate()
        assert.are.same({ y, m, d }, expected_date)
    end

    describe("new", function()
        it("reads natural language for today", function()
            local ds = DateSpec:new("<today>", "2021-02-01")
            assert_date_equals(ds.do_date, { 2021, 2, 1 })
        end)

        it("reads natural language for tomorrow", function()
            local ds = DateSpec:new("<tomorrow>", "2021-02-01")
            assert_date_equals(ds.do_date, { 2021, 2, 2 })
        end)
    end)

    describe("days_until_do", function()
        it("detects actual tomorrow", function()
            local ds = DateSpec:new("<2021-06-10>", "2021-06-09")
            assert.are.equal(ds:days_until_do(), 1)
        end)

        it("detects actual tomorrow", function()
            local ds = DateSpec:new("<2021-07-02>", "2021-07-01T05:10:59")
            assert.are.equal(ds:days_until_do(), 1)
        end)

        it("detects not tomorrow", function()
            local ds = DateSpec:new("<2021-06-10>", "2021-06-08")
            assert.are.equal(ds:days_until_do(), 2)
        end)

        it("detects actual next week", function()
            local ds = DateSpec:new("<2021-06-12>", "2021-06-09")
            assert.are.equal(ds:days_until_do(), 3)
        end)

        it("detects not tomorrow", function()
            local ds = DateSpec:new("<2021-06-20>", "2021-06-08")
            assert.are.equal(ds:days_until_do(), 12)
        end)

        it("on date in the past", function()
            local ds = DateSpec:new("<2021-07-01>", "2021-07-08")
            assert.are.equal(ds:days_until_do(), -7)
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

        it("preserves the recur string", function()
            assert.are.equal(
                DateSpec:new("<2021-06-20 +daily>", "2021-06-20"):serialize(true),
                "<today +daily>"
            )
        end)
    end)

    describe("recurring", function()
        it("should should default to nil if no recur string present", function()
            local ds = DateSpec:new("<2021-07-04>", "2021-07-01")
            assert.are.equal(ds.recur_spec, nil)
        end)

        it("should parse the recur string", function()
            local ds = DateSpec:new("<2021-07-04 +daily>", "2021-07-01")
            assert.are.equal(ds.recur_spec, "daily")
        end)

        it("should parse the recur string if do date is natural", function()
            local ds = DateSpec:new("<tomorrow +daily>", "2021-07-01")
            assert.are.equal(ds.recur_spec, "daily")
        end)

        describe("next", function()
            it("should return the next datespec", function()
                local ds = DateSpec:new("<2021-07-04 +daily>", "2021-07-01")
                assert_date_equals(ds:next().do_date, { 2021, 7, 5 })
            end)

            it("should return the next datespec with same recur", function()
                local ds = DateSpec:new("<2021-07-04 +daily>", "2021-07-01")
                assert.are.equal(ds.recur_spec, "daily")
            end)

            it("should return the next datespec with same today", function()
                local ds = DateSpec:new("<2021-07-04 +daily>", "2021-07-01")
                assert_date_equals(ds:next().today, { 2021, 7, 1 })
            end)

            it("should return nil if recur is nil", function()
                local ds = DateSpec:new("<2021-07-04>", "2021-07-01")
                assert.are.equal(ds:next(), nil)
            end)

            it("should recognize daily", function()
                local ds = DateSpec:new("<2021-07-04 +daily>", "2021-07-01")
                assert_date_equals(ds:next().do_date, { 2021, 7, 5 })
            end)

            it("should recognize weekly", function()
                local ds = DateSpec:new("<2021-07-04 +weekly>", "2021-07-01")
                assert_date_equals(ds:next().do_date, { 2021, 7, 11 })
            end)

            it("should recognize monthly", function()
                local ds = DateSpec:new("<2021-07-04 +monthly>", "2021-07-01")
                assert_date_equals(ds:next().do_date, { 2021, 8, 4 })
            end)

            it("should recognize every monday", function()
                local ds = DateSpec:new("<2021-07-04 +every monday>", "2021-07-01")
                assert_date_equals(ds:next().do_date, { 2021, 7, 5 })
            end)
        end)
    end)
end)
