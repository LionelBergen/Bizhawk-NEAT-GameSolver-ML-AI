---@class NeuronInfo
local NeuronInfo = {}

local NeuronType = require('machinelearning.ai.model.NeuronType')

---@param type NeuronType
---@return NeuronInfo
function NeuronInfo.new(index, type)
    ---@type NeuronInfo
    local neuronInfo = {}
    ---@type number
    neuronInfo.index = index or -1
    ---@type NeuronType
    neuronInfo.type = type or NeuronType.PROCESSING

    return neuronInfo
end

---@param neuronInfo NeuronInfo
---@return NeuronInfo
function NeuronInfo.copy(neuronInfo)
    ---@type NeuronInfo
    local neuronInfoCopy = NeuronInfo.new()

    ---@type number
    neuronInfoCopy.index = neuronInfo.index
    ---@type NeuronType
    neuronInfoCopy.type = neuronInfo.type

    return neuronInfoCopy
end

return NeuronInfo