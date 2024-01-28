-- Class meant to be overwritten
-- Supports methods needed to use NEATEvolve AI program
local Rom = {}

function Rom:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
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

-- luacheck: ignore rightmost currentFrame
function Rom.calculateFitness(rightmost, currentFrame)
    error('unimplemented method calculateFitness')
end

return Rom