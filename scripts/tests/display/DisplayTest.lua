-- Import LuaUnit module
local lu = require('luaunit')

-- Import the Display class
local Display = require('display.Display')
local Neuron = require('machinelearning.ai.model.Neuron')
local NeuronType = require('machinelearning.ai.model.NeuronType')

-- Test the Display class
TestDisplay = {}

local function getTestInputs()
    local neuronInputs = {}

    for _=1, 13 do
        for _=1, 13 do
            neuronInputs[#neuronInputs+1] = Neuron.new()
        end
    end

    return neuronInputs
end

function TestDisplay:testGetCellsEmpty()
    local testInputs = getTestInputs()
    lu.assertEquals(#testInputs, 169)

    local results = Display.getCells(testInputs, 13, 13, NeuronType.INPUT)

    lu.assertEquals(#results, 169)

    for _, cell in pairs(results) do
        lu.assertEquals(cell.neuronType, NeuronType.INPUT)
        lu.assertEquals(cell.value, 0)
    end
end

function TestDisplay:testGetCells()
    local testInputs = getTestInputs()
    testInputs[104].value = 2
    testInputs[105].value = 2
    testInputs[106].value = 2
    testInputs[107].value = 2
    testInputs[111].value = 3
    lu.assertEquals(#testInputs, 169)

    local results = Display.getCells(testInputs, 13, 13, NeuronType.INPUT)

    lu.assertEquals(#results, 169)
    lu.assertEquals(results[103].value, 0)
    lu.assertEquals(results[104].value, 2)
    lu.assertEquals(results[105].value, 2)
    lu.assertEquals(results[106].value, 2)
    lu.assertEquals(results[107].value, 2)
    lu.assertEquals(results[111].value, 3)
    lu.assertEquals(results[112].value, 0)

    lu.assertEquals(results[50].x, 35)
    lu.assertEquals(results[50].y, 90)

    lu.assertEquals(results[100].x, 55)
    lu.assertEquals(results[100].y, 80)
end

if not fullTestSuite then
    -- Run the tests
    os.exit(lu.LuaUnit.run())
end