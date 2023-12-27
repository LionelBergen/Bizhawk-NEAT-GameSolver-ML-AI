---@class Cell
local Cell = {}

---@return Cell
function Cell:new(x, y, value)
    ---@type Cell
    local cell = {}

    cell.x = x
    cell.y = y
    cell.value = value

    return cell
end

return Cell