-- Import LuaUnit module
local lu = require('luaunit')

local Network = require('machinelearning.ai.model.Network')
local Neuron = require('machinelearning.ai.model.Neuron')
local NeuronInfo = require('machinelearning.ai.model.NeuronInfo')
local NeuronType = require('machinelearning.ai.model.NeuronType')

-- luacheck: globals console TestNetwork fullTestSuite
TestNetwork = {}

-- To allow ErrorHandler to work
console = {}
function console.log()  end

local function getTestNetwork()
    ---@type Network
    local network = Network:new()

    for _=1, 169 do
        network:addInputNeuron(Neuron.new())
    end

    network:setBiasNeuron(Neuron.new())

    for _=1, 8 do
        network:addOutputNeuron(Neuron.new())
    end

    return network
end

function TestNetwork.testGetOrCreateNeuronInput()
    local network = getTestNetwork()
    local testNeuron = Neuron.new()
    testNeuron.value = -15.56
    network.inputNeurons[150] = testNeuron

    local neuronInfo = NeuronInfo.new(150, NeuronType.INPUT)
    local result = network:getOrCreateNeuron(neuronInfo)

    lu.assertEquals(result, testNeuron)
end

function TestNetwork.testGetOrCreateNeuronInputInvalid()
    local network = getTestNetwork()

    -- Index 170 doesnt exist
    local success, errorMessage = pcall(function()
        local neuronInfo = NeuronInfo.new(170, NeuronType.INPUT)
        network:getOrCreateNeuron(neuronInfo)
    end)

    lu.assertFalse(success)
    lu.assertStrContains(errorMessage, 'Cannot find neuron! neuroninfo.type: 2 index: 170')
end

function TestNetwork.testGetOrCreateNeuronBias()
    local network = getTestNetwork()
    local testNeuron = Neuron.new()
    testNeuron.value = -15.56
    network:setBiasNeuron(testNeuron)

    -- index doesn't matter for the bias neuron
    local neuronInfo = NeuronInfo.new(-150, NeuronType.BIAS)
    local result = network:getOrCreateNeuron(neuronInfo)

    lu.assertEquals(result, testNeuron)
end

function TestNetwork.testGetOrCreateNeuronOutput()
    local network = getTestNetwork()
    local testNeuron = Neuron.new()
    testNeuron.value = -15.56
    network.outputNeurons[5] = testNeuron

    local neuronInfo = NeuronInfo.new(5, NeuronType.OUTPUT)
    local result = network:getOrCreateNeuron(neuronInfo)

    lu.assertEquals(result, testNeuron)
end

function TestNetwork.testGetOrCreateNeuronProcessingExists()
    local network = getTestNetwork()
    local testNeuron = Neuron.new()
    testNeuron.value = -15.56
    network.processingNeurons[1] = testNeuron

    local neuronInfo = NeuronInfo.new(1, NeuronType.PROCESSING)
    local result = network:getOrCreateNeuron(neuronInfo)

    lu.assertEquals(result, testNeuron)
end

function TestNetwork.testGetOrCreateNeuronProcessingNotExists()
    local network = getTestNetwork()

    local neuronInfo = NeuronInfo.new(1, NeuronType.PROCESSING)
    local result = network:getOrCreateNeuron(neuronInfo)

    lu.assertEquals(result, Neuron.new())
end

function TestNetwork.testGetOrCreateNeuronUnknownType()
    local network = getTestNetwork()

    local success, errorMessage = pcall(function()
        local neuronInfo = NeuronInfo.new(1, 5)
        network:getOrCreateNeuron(neuronInfo)
    end)

    lu.assertFalse(success)
    lu.assertStrContains(errorMessage, 'unknown neuronType: 5')
end

if not fullTestSuite then
    -- Run the tests
    os.exit(lu.LuaUnit.run())
end