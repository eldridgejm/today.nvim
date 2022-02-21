describe("today.core.bufferparser.parse", function()
    local parse = require("today.core.bufferparser").parse
    local linemap = require("today.core.linemap")

    describe("linemap output", function()

        it("a block node should have a kind attribute", function()
            local lines = {
                "[x] this is a task"
            }

            local lmap, tasktree = parse(lines)

            assert.are.equal(lmap.children[1].size, 1)
            assert.are.equal(lmap.children[1].kind, "task")
        end)

        it("treats an uncheckboxed free line as a task", function()
            local lines = {
                "this is a task"
            }

            local lmap, tasktree = parse(lines)

            assert.are.equal(lmap.children[1].size, 1)
            assert.are.equal(lmap.children[1].kind, "task")
        end)

        it("two tasks should be parsed into two nodes", function()
            local lines = {
                "[x] this is a task",
                "[ ] this is another task"
            }

            local lmap, tasktree = parse(lines)

            assert.are.equal(lmap.children[1].size, 1)
            assert.are.equal(lmap.children[1].kind, "task")
            assert.are.equal(lmap.children[2].size, 1)
            assert.are.equal(lmap.children[2].kind, "task")
        end)

        it("should consider indentation by 4 spaces to be task continuation", function()
            local lines = {
                "[x] this is a task",
                "    ",
                "    this is a continuation of the first task",
                "[ ] this is another task"
            }

            local lmap, tasktree = parse(lines)

            assert.are.equal(#lmap.children, 2)
            assert.are.equal(lmap.children[1].size, 3)
            assert.are.equal(lmap.children[1].kind, "task")
            assert.are.equal(lmap.children[2].size, 1)
            assert.are.equal(lmap.children[2].kind, "task")
        end)

        it("should consider empty lines to be task continuations", function()
            local lines = {
                "[x] this is a task",
                "",
                "    this is a continuation of the first task",
                "[ ] this is another task",
                "    it, too, has multiple lines"
            }

            local lmap, tasktree = parse(lines)

            assert.are.equal(#lmap.children, 2)
            assert.are.equal(lmap.children[1].size, 3)
            assert.are.equal(lmap.children[1].kind, "task")
            assert.are.equal(lmap.children[2].size, 2)
            assert.are.equal(lmap.children[2].kind, "task")
        end)

        it("recognizes comments and makes a node with kind = comment", function()
            local lines = {
                "-- this is a comment",
                "[x] this is a task",
                "[ ] this is another task",
            }

            local lmap, tasktree = parse(lines)

            assert.are.equal(#lmap.children, 3)
            assert.are.equal(lmap.children[1].kind, "comment")
            assert.are.equal(lmap.children[1].size, 1)
        end)

        it("recognizes category headers and makes a section node", function()
            local lines = {
                "{{{ category 1",
                "[x] this is a task",
                "[ ] this is another task",
                "}}}"
            }

            local lmap, tasktree = parse(lines)

            assert.are.equal(#lmap.children, 1)
            assert.are.equal(lmap.children[1].kind, "category")
            assert.are.equal(#lmap.children[1].children, 4)
        end)

        it("ignores nested category headers", function()
            local lines = {
                "{{{ category 1",
                "[x] this is a task",
                "{{{ this should be ignored",
                "[ ] this is another task",
                "}}}"
            }

            local lmap, tasktree = parse(lines)

            assert.are.equal(#lmap.children, 1)
            assert.are.equal(lmap.children[1].kind, "category")
            assert.are.equal(#lmap.children[1].children, 5)
            assert.are.equal(lmap.children[1].children[3].kind, "ignored_category_header")
        end)

        it("ignores unnested category footers", function()
            local lines = {
                "{{{ category 1",
                "[x] this is a task",
                "[ ] this is another task",
                "}}}",
                "}}}" -- this one is extra
            }

            local lmap, tasktree = parse(lines)

            assert.are.equal(#lmap.children, 2)
            assert.are.equal(lmap.children[1].kind, "category")
            assert.are.equal(#lmap.children[1].children, 4)
            assert.are.equal(lmap.children[2], "ignored_category_footer")
        end)

        it("handles a nested category as follows...", function()
            local lines = {
                "{{{ category 1",
                "[x] this is a task",
                "{{{ this will be ignored",
                "[ ] this is another task",
                "}}}",
                "}}}" -- this one is extra
            }

            local lmap, tasktree = parse(lines)

            assert.are.equal(#lmap.children, 2)
            assert.are.equal(lmap.children[1].kind, "category")
            assert.are.equal(#lmap.children[1].children, 5)
            assert.are.equal(lmap.children[1].children[3].kind, "ignored_category_header")
            assert.are.equal(lmap.children[2], "ignored_category_footer")
        end)

        it("handles empty lines", function()
            local lines = {
                "",
                "",
                "{{{ category 1",
                "",
                "[x] this is a task",
                "",
                "[ ] this is another task",
                "}}}",
                ""
            }

            local lmap, tasktree = parse(lines)

            assert.are.equal(#lmap.children, 3)
            assert.are.equal(lmap.children[1].kind, "whitespace")
            assert.are.equal(lmap.children[1].size, 2)

            assert.are.equal(#lmap.children[2].children, 5)
            assert.are.equal(lmap.children[2].children[2].kind, "whitespace")

            assert.are.equal(lmap.children[3].kind, "whitespace")
        end)

        it("handles spaces and tabs", function()
            local lines = {
                "    ",
                "	",
                "{{{ category 1",
                "       ",
                "[x] this is a task",
                "",
                "[ ] this is another task",
                "}}}",
                ""
            }

            local lmap, tasktree = parse(lines)

            assert.are.equal(#lmap.children, 3)
            assert.are.equal(lmap.children[1].kind, "whitespace")
            assert.are.equal(lmap.children[1].size, 2)

            assert.are.equal(#lmap.children[2].children, 5)
            assert.are.equal(lmap.children[2].children[2].kind, "whitespace")

            assert.are.equal(lmap.children[3].kind, "whitespace")
        end)

        it("produces nodes that make a valid linemap", function()
            local lines = {
                "    ",
                "	",
                "{{{ category 1",
                "       ",
                "[x] this is a task",
                "",
                "[ ] this is another task",
                "}}}",
                ""
            }

            local lmap, tasktree = parse(lines)

            assert.are.equal(linemap.find_line(lmap, 3).kind, "category_header")
            assert.are.equal(linemap.find_line(lmap, 1).kind, "whitespace")
            assert.are.equal(linemap.find_line(lmap, 6).kind, "task")

            local tnode = linemap.find_line(lmap, 6)
            local start, finish = linemap.span(lmap, tnode)
            assert.are.equal(start, 5)
            assert.are.equal(finish, 6)
        end)

    end)

    describe("tasktree output", function()

        it("parses tasks", function()
            local lines = {
                "    ",
                "	",
                "{{{ category 1",
                "       ",
                "[x] this is a task",
                "",
                "[ ] this is another task",
                "}}}",
                ""
            }

            local lmap, tasktree = parse(lines)

            assert.are.equal(#tasktree.children, 1)
            assert.are.equal(tasktree.children[1].children[1].done, true)
            assert.are.equal(tasktree.children[1].children[2].done, false)
        end)

        it("links the linemap nodes with the tasktree nodes", function()
            local lines = {
                "    ",
                "	",
                "{{{ category 1",
                "       ",
                "[x] this is a task",
                "",
                "[ ] this is another task",
                "}}}",
                ""
            }

            local lmap, tasktree = parse(lines)

            assert.are.equal(linemap.find_line(lmap, 5).task.done, true)
            assert.are.equal(linemap.find_line(lmap, 7).task.done, false)
        end)

        it("handles multiple categories", function()
            local lines = {
                "    ",
                "	",
                "{{{ category 1",
                "       ",
                "[x] this is a task",
                "",
                "[ ] this is another task",
                "}}}",
                "	",
                "",
                "",
                "{{{ category 2",
                "       ",
                "[x] this is yet another task",
                "",
                "    it has multiple lines",
                "}}}",
                ""
            }

            local lmap, tasktree = parse(lines)

            assert.are.equal(#tasktree.children, 2)
            assert.are.equal(#tasktree.children[2].children, 1)
            assert.are.equal(tasktree.children[2].children[1].done, true)
        end)
    end)

end)
