---@class Network
local Network = {}

local ErrorHandler = require('util.ErrorHandler')
local Logger = require('util.Logger')
local Neuron = require('machinelearning.ai.model.Neuron')
local NeuronType = require('machinelearning.ai.model.NeuronType')

---@return Network
function Network:new()
    ---@type Network
    local network = {}
    self = self or network
    self.__index = self
    setmetatable(network, self)

    ---@type Neuron[]
    network.inputNeurons = {}
    ---@type Neuron
    network.biasNeuron = nil
    ---@type Neuron[]
    network.outputNeurons = {}
    ---@type Neuron[]
    network.processingNeurons = {}

    return network
end

---@param neuron Neuron
function Network:addInputNeuron(neuron)
    self.inputNeurons[#self.inputNeurons + 1] = neuron
end

---@param neuron Neuron
function Network:addOutputNeuron(neuron)
    self.outputNeurons[#self.outputNeurons + 1] = neuron
end

---@param neuron Neuron
function Network:setBiasNeuron(neuron)
    self.biasNeuron = neuron
end

---@return Neuron[]
function Network:getAllNeurons()
    local allNeurons = {}

    for i=1, #self.inputNeurons do
        allNeurons[i] = self.inputNeurons[i]
    end

    allNeurons[#allNeurons + 1] = self.biasNeuron

    for i=1, #self.outputNeurons do
        allNeurons[#allNeurons + i] = self.outputNeurons[i]
    end

    for i=1, #self.processingNeurons do
        allNeurons[#allNeurons + i] = self.processingNeurons[i]
    end

    return allNeurons
end

---@param neuronInfo NeuronInfo
function Network:getOrCreateNeuron(neuronInfo)
    ---@type Neuron
    local neuron

    if neuronInfo.type == NeuronType.INPUT then
        neuron = self.inputNeurons[neuronInfo.index]
    elseif neuronInfo.type == NeuronType.BIAS then
        neuron = self.biasNeuron
    elseif neuronInfo.type == NeuronType.OUTPUT then
        neuron = self.outputNeurons[neuronInfo.index]
    elseif neuronInfo.type == NeuronType.PROCESSING then
        if self.processingNeurons[neuronInfo.index] == nil then
            self.processingNeurons[neuronInfo.index] = Neuron.new()
        end

        neuron = self.processingNeurons[neuronInfo.index]
    else
        ErrorHandler.error('unknown neuronType: ' .. neuronInfo.type)
    end

    if neuron == nil then
        ErrorHandler.error('Cannot find neuron! neuroninfo.type: ' .. neuronInfo.type ..  ' index: ' .. neuronInfo.index)
    end

    return neuron
end

---@param inputs number[]
function Network:setInputValues(inputs)
    if #inputs ~= #self.inputNeurons then
        ErrorHandler.error('invalid inputs size: ' .. #inputs .. ' should be ' .. #self.inputNeurons)
    end

    for i, v in pairs(inputs) do
        self.inputNeurons[i].value = v
    end
end

return Network