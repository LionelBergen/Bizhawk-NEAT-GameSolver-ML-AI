---@class TetrisAttackInputType
local TetrisAttackInputType = {
    EMPTY = 0,
    HEART = 1,
    SQUARE = 2,
    TRIANGLE = 3,
    STAR = 4,
    DIAMOND = 5,
}

function TetrisAttackInputType.fromValue(value)
    for k, v in pairs(TetrisAttackInputType) do
        if v == value then
            return v
        end
    end

    return nil
end

return TetrisAttackInputType