---@class Cell
local Cell = {}
local NeuronType = require('machinelearning.ai.model.NeuronType')

---@param neuronType NeuronType
---@return Cell
function Cell:new(x, y, value, neuronType)
    ---@type Cell
    local cell = {}

    cell.x = x
    cell.y = y
    cell.value = value
    cell.neuronType = neuronType

    return cell
end

return Cell