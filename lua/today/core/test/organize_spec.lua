describe("organize", function()
    local organize = require("today.core.organize")
    local categorizers = require('today.core.categorizers')

    describe("filterers", function()
        describe("tag_filterer", function()
            local categorizer = categorizers.first_tag_categorizer("2021-07-04")

            it("should accept a task that contains a target tag", function()
                assert.are.equal(
                    organize.tag_filterer({ "#one", "#two" })("this is a #one test"),
                    true
                )
            end)

            it("should reject a task that does not contain a target tag", function()
                assert.are.equal(
                    organize.tag_filterer({ "#one", "#two" })("this is a #three test"),
                    false
                )
            end)

            it("should accept a tagless task if 'none' is a target", function()
                assert.are.equal(
                    organize.tag_filterer({ "none" })("this is a test"),
                    true
                )
            end)

            it("should place the hidden tasks at the bottom", function()
                local tag_filterer = organize.tag_filterer({ "#one" })
                local tasks = {
                    "this is the first one",
                    "this is the second one #two",
                    "this is the third #one",
                }
                local result = organize.organize(
                    tasks,
                    { categorizer = categorizer, filterer = tag_filterer }
                )

                assert.are.same(result, {
                    "-- #one {{{",
                    "[ ] this is the third #one",
                    "-- }}}",
                    "",
                    "-- hidden {{{",
                    "[ ] this is the first one",
                    "[ ] this is the second one #two",
                    "-- }}}",
                })
            end)

            it("should hide all tasks if none match the filter", function()
                local tag_filterer = organize.tag_filterer({ "#zoomzoom" })
                local tasks = {
                    "this is the first one",
                    "this is the second one #two",
                    "this is the third #one",
                }
                local result = organize.organize(
                    tasks,
                    { categorizer = categorizer, filterer = tag_filterer }
                )

                assert.are.same(result, {
                    "-- hidden {{{",
                    "[ ] this is the first one",
                    "[ ] this is the second one #two",
                    "[ ] this is the third #one",
                    "-- }}}",
                })
            end)
        end)
    end)
end)
