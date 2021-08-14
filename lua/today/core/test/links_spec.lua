local linkslib = require("today.core.links")

describe("extract_link", function()
    local ex1 = "this is [[a test of]] this thing [[and so on]] junk"

    --  There are seven cases:
    --
    -- xxxxx[[xxxxx]]xxxxx[[xxxxx]]xxxxx
    --   ^  ^   ^   ^  ^      ^      ^
    --   A  B   C   D  E      F      G
    --

    it("should return nil in case A", function()
        local result = linkslib.extract_link(ex1, 1)
        assert.are.equal(result, nil)
    end)

    it("should extract the link in case B", function()
        local result = linkslib.extract_link(ex1, 9)
        assert.are.equal(result, "a test of")
    end)

    it("should extract the link in case C", function()
        local result = linkslib.extract_link(ex1, 13)
        assert.are.equal(result, "a test of")
    end)

    it("should extract the link in case D", function()
        local result = linkslib.extract_link(ex1, 21)
        assert.are.equal(result, "a test of")
    end)

    it("should return nil in case E", function()
        local result = linkslib.extract_link(ex1, 22)
        assert.are.equal(result, nil)
    end)

    it("should return second link in case F", function()
        -- and on the second ]
        local result = linkslib.extract_link(ex1, 43)
        assert.are.equal(result, "and so on")
    end)

    it("should return nil in case G", function()
        -- and on the second ]
        local result = linkslib.extract_link(ex1, 48)
        assert.are.equal(result, nil)
    end)
end)
