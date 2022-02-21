describe("today.core.headerparser.parse", function()
    local parse = require("today.core.headerparser").parse
    local DateObj = require("today.core.dates").DateObj

    describe("done category parsing", function()

        it("should correctly parse a header starting with the done identifier", function()
            local header = "done {{{"
            local header_info = parse(header, "2022-02-20")
            assert.are.equal(header_info.kind, "done")
        end)

    end)

    describe("do date category parsing", function()

        it("should convert the date to a DateObj", function()
            local header = "<tomorrow> | something {{{"
            local header_info = parse(header, "2022-02-20")
            assert.are.equal(header_info.kind, "do_date")
            assert.are.equal(header_info.do_date, DateObj:new("2022-02-21"))
        end)

        it("should not match if the date string is malformed", function()
            local header = "<skldjasd> | something {{{"
            local header_info = parse(header, "2022-02-20")
            assert.are.equal(header_info.kind, "unmatched")
        end)

    end)

    describe("tag category parsing", function()
        it("should recognize a header starting with a tag", function()
            local header = "#foo {{{"
            local header_info = parse(header, "2022-02-20")
            assert.are.equal(header_info.kind, "tag")
            assert.are.equal(header_info.tag, "foo")
        end)
    end)

    it("should handle extra information", function()
        local header = "#foo | something | else {{{"
        local header_info = parse(header, "2022-02-20")
        assert.are.same(header_info.extra, { "something", "else" })
    end)
end)
