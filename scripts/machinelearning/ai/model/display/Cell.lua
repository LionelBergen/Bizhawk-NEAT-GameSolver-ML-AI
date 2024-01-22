---@class Cell
local Cell = {}

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