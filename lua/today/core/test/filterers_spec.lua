local filterers = require('today.core.filterers')

describe("filterers", function()
        describe("tag_filterer", function()

            it("should accept a task that contains a target tag", function()
                assert.are.equal(
                    filterers.tag_filterer({ "#one", "#two" })("this is a #one test"),
                    true
                )
            end)

            it("should reject a task that does not contain a target tag", function()
                assert.are.equal(
                    filterers.tag_filterer({ "#one", "#two" })("this is a #three test"),
                    false
                )
            end)

            it("should accept a tagless task if 'none' is a target", function()
                assert.are.equal(
                    filterers.tag_filterer({ "none" })("this is a test"),
                    true
                )
            end)


        end)
    end)

