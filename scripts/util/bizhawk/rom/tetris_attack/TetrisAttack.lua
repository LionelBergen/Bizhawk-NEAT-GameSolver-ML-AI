local Rom =  require('util.bizhawk.rom.Rom')
---@class TetrisAttack
local TetrisAttack = Rom:new()
local Button = require('machinelearning.ai.model.game.Button')
local Position = require('machinelearning.ai.model.game.Position')
local TetrisAttackTile = require('util.bizhawk.rom.tetris_attack.TetrisAttackTile')
local TetrisAttackInputType = require('util.bizhawk.rom.tetris_attack.TetrisAttackInputType')
local ErrorHandler = require('util.ErrorHandler')
local Logger = require('util.Logger')

-- luacheck: globals memory

local romGameName = 'Tetris Attack (USA) (En,Ja)'

local timeoutConstant = 1000

-- How many blocks high the game board is
local height = 12
local width = 6
-- 2 for the player input position
local numberOfInputs = (height * width) + 2

-- No need for A+B, since they do the same thing
local buttons = { Button.L, Button.R, Button.UP, Button.DOWN, Button.LEFT, Button.RIGHT, Button.A }

local PLAYER_LEFT_X_MEMORY_POS = 0x0003A4
local PLAYER_LEFT_Y_MEMORY_POS = 0x0003A8

local PLAYER_1_POINTS_MEMORY_POS = 0x00030E

TetrisAttack.lastPointAmount = -1

local function getPoints()
    return memory.read_s16_le(PLAYER_1_POINTS_MEMORY_POS)
end

---@return TetrisAttackTile[]
local function getAllTiles()
    ---@type TetrisAttackTile[]
    local allTiles = {}
    local beginningMemoryAddress = 0x000FAE

    local memoryAddress = beginningMemoryAddress

    for y=1, height do
        for x=1, width do
            local memoryAddressValue = memory.read_u8(memoryAddress)

            ---@type TetrisAttackInputType
            local tileType = TetrisAttackInputType.fromValue(memoryAddressValue)

            if tileType == nil then
                local memoryAddressHex = string.upper(string.format("%x", memoryAddress))
                ErrorHandler.error('Cannot read Tile Type. memoryAddress: '
                        .. memoryAddressHex .. ' value: ' .. memoryAddressValue)
            end

            allTiles[#allTiles + 1] = TetrisAttackTile.new(Position.new(x, y), tileType)

            -- move to next tile
            memoryAddress = memoryAddress + 2
        end

        -- 4 empty addresses, not sure what used for
        memoryAddress = memoryAddress + 4
    end

    return allTiles
end

function TetrisAttack.getRomName()
    return romGameName
end

---@return Button[]
function TetrisAttack.getButtonOutputs()
    return buttons
end

function TetrisAttack:reset()
    self.lastPointAmount = -1
    self.lastPosition = Position.new(-1, -1)
end

---@return Position
function TetrisAttack.getPosition()
    -- Read Signed 16 Little Endian
    local x = memory.read_u8(PLAYER_LEFT_X_MEMORY_POS)
    -- For some reason Y starts at 3. To make things easier, take away 3
    local y = memory.read_u8(PLAYER_LEFT_Y_MEMORY_POS) - 3

    -- TODO:
    if y == 0 then
        y = 1
    end

    return Position.new(x, y)
end

-- Gets an array to be used as inputs for an AI program based on memory values
---@return TetrisAttackInputType[]
function TetrisAttack.getInputs(_, _)
    ---@type TetrisAttackTile[]
    local gameTiles = getAllTiles()
    ---@type TetrisAttackInputType[]
    local inputs = {}
    local position = TetrisAttack.getPosition()
    local positionBlock1, positionBlock2

    for _, gameTile in pairs(gameTiles) do
        inputs[#inputs + 1] = gameTile.tetrisAttackTile
        if gameTile.position.x == position.x and gameTile.position.y == position.y then
            positionBlock1 = gameTile.tetrisAttackTile
        elseif gameTile.position.x == (position.x + 1) and gameTile.position.y == position.y then
            positionBlock2 = gameTile.tetrisAttackTile
        end
    end

    if positionBlock1 == nil or positionBlock2 == nil then
        ErrorHandler.error('position was nil; X: ' .. position.x .. ' Y: ' .. position.y)
    end

    inputs[#inputs + 1] = positionBlock1
    inputs[#inputs + 1] = positionBlock2

    return inputs
end

function TetrisAttack.getTimeoutConstant()
    return timeoutConstant
end

function TetrisAttack:setLastPosition(position)
    self.lastPosition = position
    self.lastPointAmount = getPoints()
end

function TetrisAttack:hasMovedInProgressingWay(_)
    return self.lastPointAmount < getPoints()
end

function TetrisAttack:isWin()
    return false
end

function TetrisAttack:isDead()
    local isDead = true

    for _, v in pairs(getAllTiles()) do
        if v.tetrisAttackTile ~= 0 then
            isDead = false
            break
        end
    end

    return isDead
end

function TetrisAttack.calculateFitness(_, _)
    return getPoints()
end

function TetrisAttack.getNumberOfInputs()
    return numberOfInputs
end

function TetrisAttack.getDeathBonus()
    return -10
end

return TetrisAttack