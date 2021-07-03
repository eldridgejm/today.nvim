describe("datespec", function()
    DateSpec = require('today.core.datespec')

    describe("new", function()
        it("defaults to today", function()
            local ds = DateSpec:new(nil, "2021-02-01")
            local y, m, d = ds.do_date:getdate()
            assert.are.same({y, m, d}, {2021, 2, 1})
        end)
    end)

    describe("is_tomorrow", function()
        it("detects actual tomorrow", function()
            local ds = DateSpec:new('<2021-06-10>', '2021-06-09')
            assert.truthy(ds:is_tomorrow())
        end)

        it("detects actual tomorrow", function()
            local ds = DateSpec:new('<2021-07-02>', '2021-07-01T05:10:59')
            assert.truthy(ds:is_tomorrow())
        end)

        it("detects not tomorrow", function()
            local ds = DateSpec:new('<2021-06-10>', '2021-06-08')
            assert.falsy(ds:is_tomorrow())
        end)
    end)

    describe("is_next_week", function()
        it("detects actual next week", function()
            local ds = DateSpec:new('<2021-06-12>', '2021-06-09')
            assert.truthy(ds:is_next_week())
        end)

        it("detects not tomorrow", function()
            local ds = DateSpec:new('<2021-06-20>', '2021-06-08')
            assert.falsy(ds:is_next_week())
        end)

        it("on date in the past", function()
            local ds = DateSpec:new('<2021-06-20>', '2021-07-08')
            assert.falsy(ds:is_next_week())
        end)
    end)

    describe('serialize', function()
        it('converts a datespec to a string', function()
            assert.are.equal(
                DateSpec:new('<2021-06-20>'):serialize(),
                '<2021-6-20>'
            )
        end)
    end)

    describe('do_in_k_days', function()
        it('returns a datespec with do date of tomorrow', function()
            local ds = DateSpec:new('<2021-08-01>', '2021-07-01')
            local new_ds = ds:do_in_k_days(1)
            assert.are.equal(
                new_ds:serialize(),
                '<2021-7-2>'
            )
        end)
    end)
end)
