describe("today.core.linemap", function()
    local linemap = require("today.core.linemap")

    describe("find_line", function()
        it("returns the table at the given line", function()
            local b1 = { size = 4 } -- 1, 4
            local b2 = { size = 3 } -- 5, 7
            local b3 = { size = 7 } -- 8, 14
            local b4 = { size = 2 } -- 15, 16
            local b5 = { size = 1 } -- 17

            local s1 = { children = { b1, b2 } }
            local s2 = { children = { b3, b4 } }
            local s3 = { children = { b5 } }

            local root = { children = { s1, s2, s3 } }

            assert.are.equal(linemap.find_line(root, 2), b1)
            assert.are.equal(linemap.find_line(root, 5), b2)
            assert.are.equal(linemap.find_line(root, 8), b3)
            assert.are.equal(linemap.find_line(root, 12), b3)
            assert.are.equal(linemap.find_line(root, 16), b4)
            assert.are.equal(linemap.find_line(root, 17), b5)
        end)

        it("returns nil if line_no is out of bounds", function()
            local b1 = { size = 4 } -- 1, 4
            local b2 = { size = 3 } -- 5, 7
            local b3 = { size = 7 } -- 8, 14
            local b4 = { size = 2 } -- 15, 16
            local b5 = { size = 1 } -- 17

            local s1 = { children = { b1, b2 } }
            local s2 = { children = { b3, b4 } }
            local s3 = { children = { b5 } }

            local root = { children = { s1, s2, s3 } }

            assert.are.equal(linemap.find_line(root, 99), nil)
        end)

        it("works with an empty tree", function()
            local root = { children = {} }

            assert.are.equal(linemap.find_line(root, 99), nil)
        end)
    end)

    describe("size", function()
        it("simply returns a block node's size", function()
            local b1 = { size = 4 } -- 1, 4
            local b2 = { size = 3 } -- 5, 7
            local b3 = { size = 7 } -- 8, 14
            local b4 = { size = 2 } -- 15, 16
            local b5 = { size = 1 } -- 17

            local s1 = { children = { b1, b2 } }
            local s2 = { children = { b3, b4 } }
            local s3 = { children = { b5 } }

            local root = { children = { s1, s2, s3 } }

            assert.are.equal(linemap.size(b2), 3)
            assert.are.equal(linemap.size(b3), 7)
        end)

        it("returns subtree size for inner nodes", function()
            local b1 = { size = 4 } -- 1, 4
            local b2 = { size = 3 } -- 5, 7
            local b3 = { size = 7 } -- 8, 14
            local b4 = { size = 2 } -- 15, 16
            local b5 = { size = 1 } -- 17

            local s1 = { children = { b1, b2 } }
            local s2 = { children = { b3, b4 } }
            local s3 = { children = { b5 } }

            local root = { children = { s1, s2, s3 } }

            assert.are.equal(linemap.size(s1), 7)
            assert.are.equal(linemap.size(s2), 9)
            assert.are.equal(linemap.size(root), 17)
        end)
    end)

    describe("span", function()
        it("computes the start and end line for block nodes", function()
            local b1 = { size = 4 } -- 1, 4
            local b2 = { size = 3 } -- 5, 7
            local b3 = { size = 7 } -- 8, 14
            local b4 = { size = 2 } -- 15, 16
            local b5 = { size = 1 } -- 17

            local s1 = { children = { b1, b2 } }
            local s2 = { children = { b3, b4 } }
            local s3 = { children = { b5 } }

            local root = { children = { s1, s2, s3 } }

            local start, stop = linemap.span(root, b1)
            assert.are.equal(start, 1)
            assert.are.equal(stop, 4)

            local start, stop = linemap.span(root, b3)
            assert.are.equal(start, 8)
            assert.are.equal(stop, 14)
        end)

        it("computes the start and end line for inner nodes", function()
            local b1 = { size = 4 } -- 1, 4
            local b2 = { size = 3 } -- 5, 7
            local b3 = { size = 7 } -- 8, 14
            local b4 = { size = 2 } -- 15, 16
            local b5 = { size = 1 } -- 17

            local s1 = { children = { b1, b2 } }
            local s2 = { children = { b3, b4 } }
            local s3 = { children = { b5 } }

            local root = { children = { s1, s2, s3 } }

            local start, stop = linemap.span(root, s1)
            assert.are.equal(start, 1)
            assert.are.equal(stop, 7)

            local start, stop = linemap.span(root, s2)
            assert.are.equal(start, 8)
            assert.are.equal(stop, 16)

            local start, stop = linemap.span(root, root)
            assert.are.equal(start, 1)
            assert.are.equal(stop, 17)
        end)
    end)
end)
