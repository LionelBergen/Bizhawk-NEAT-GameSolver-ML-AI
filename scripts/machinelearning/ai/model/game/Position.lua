---@class Position
local Position = {}

function Position.new(x, y)
    ---@type Position
    local position = {}
    position.x = x
    position.y = y

    return position
end

return Position