---@class TetrisAttackTile
local TetrisAttackTile = {}

local Position = require('machinelearning.ai.model.game.Position')
local TetrisAttackInputType = require('util.bizhawk.rom.tetris_attack.TetrisAttackInputType')

---@param position Position
---@param tileType TetrisAttackInputType
function TetrisAttackTile.new(position, tileType)
    local tetrisAttackTile = {}
    tetrisAttackTile.position = position or Position.new(-1, -1)
    tetrisAttackTile.tetrisAttackTile = tileType

    return tetrisAttackTile
end

return TetrisAttackTile