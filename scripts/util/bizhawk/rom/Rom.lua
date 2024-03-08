-- Class meant to be overwritten
-- Supports methods needed to use NEATEvolve AI program
local Rom = {}

local Position = require('machinelearning.ai.model.game.Position')

function Rom:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    self.lastPosition = Position.new(-1, -1)

    return o
end

-- gets the inputs for the AI program.
-- _ = programViewBoxRadius - used to determine how far/wide the program can 'see'
function Rom.getInputs(_)
    error('unimplemented method getInputs')
end

function Rom.getRomName()
    error('unimplemented method getRomName')
end

function Rom.getButtonOutputs()
    error('unimplemented method getButtonOutputs')
end

function Rom.isWin()
    error('unimplemented method isWin')
end

function Rom.isDead()
    error('unimplemented method isDead')
end

-- luacheck: ignore position currentFrame
function Rom.calculateFitness(position, currentFrame)
    error('unimplemented method calculateFitness')
end

function Rom.getTimeoutConstant()
    error('unimplemented method getTimeoutConstant')
end

---@return Position
function Rom.getPosition()
    error('unimplemented method getPosition')
end

-- _ = newPosition
function Rom:hasMovedInProgressingWay(_)
    error('unimplemented method hasMovedInProgressingWay')
end

---@param position Position
function Rom:setLastPosition(position)
    self.lastPosition = position
end

function Rom:reset()
    self.lastPosition = Position.new(-1, -1)
end

function Rom.getWinBonus()
    error('unimplemented method getWinBonus')
end

function Rom.getDeathBonus()
    error('unimplemented method getDeathBonus')
end

function Rom.getNumberOfInputs()
    error('unimplemented method getNumberOfInputs')
end

---@return DisplaySettings
function Rom.getDisplaySettings()
    error('unimplemented method getDisplaySettings')
end

return Rom