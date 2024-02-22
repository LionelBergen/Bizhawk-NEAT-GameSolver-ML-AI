-- Import LuaUnit module
local lu = require('lib.luaunit')

local ControllerTransformer = require('util.bizhawk.ControllerTransformer')
local Button = require('machinelearning.ai.model.game.Button')

-- luacheck: globals TestControllerTransformer fullTestSuite
TestControllerTransformer = {}

function TestControllerTransformer.testTransformNetworkOutputs()
    ---@type string[]
    local networkOutputs = {}
    networkOutputs["A"] = true
    networkOutputs["Left"] = true
    local result = ControllerTransformer.transformNetworkOutputs(networkOutputs)

    lu.assertTrue(result["P1 A"])
    lu.assertTrue(result["P1 Left"])
    lu.assertFalse(result["A"])
    lu.assertFalse(result["P1 B"])
end

function TestControllerTransformer.testTransformNetworkOutputsLeftRight()
    ---@type string[]
    local networkOutputs = {}
    networkOutputs["A"] = true
    networkOutputs["Left"] = true
    networkOutputs["Right"] = true
    local result = ControllerTransformer.transformNetworkOutputs(networkOutputs)

    lu.assertTrue(result["P1 A"])
    lu.assertFalse(result["P1 Left"])
    lu.assertFalse(result["P1 Right"])
end

function TestControllerTransformer.testTransformNetworkOutputsButtons()
    ---@type string[]
    local networkOutputs = {}
    networkOutputs[Button.A] = true
    networkOutputs[Button.LEFT] = true
    local result = ControllerTransformer.transformNetworkOutputs(networkOutputs)

    lu.assertTrue(result["P1 A"])
    lu.assertTrue(result["P1 Left"])
    lu.assertFalse(result["A"])
    lu.assertFalse(result["P1 B"])
end

if not fullTestSuite then
    -- Run the tests
    os.exit(lu.LuaUnit.run())
end