--[[
    RandomNumber - Lua Class for Generating and Managing Random Numbers

    The RandomNumber class is designed to facilitate the generation of random numbers
    using Lua's built-in math.random function. It includes features for tracking the
    number of generated random numbers and the ability to 'jump' to a specific iteration.
    This functionality is particularly useful for debugging and testing. Example if
    a program is to save its state and 'resume' and we want numbers generated to not
    reset,

    Usage:
    local rng = RandomNumber.new()           -- Generate a random number
    RandomNumber:jumpToIteration(10)         -- (optionally), Jump to the 10th iteration.
--]]
---@class RandomNumber
local RandomNumber = {}

-- Wrapper for math.random() in case we want to change in the future
local function generateRandomNumber()
    return math.random()
end

---@return RandomNumber
function RandomNumber.new()
    ---@type RandomNumber
    local randomNumberInstance = {}

    randomNumberInstance.count = 0

    return randomNumberInstance
end

function RandomNumber:generate()
    self.count = self.count + 1
    return generateRandomNumber()
end

---@param iteration number
function RandomNumber:jumpToIteration(iteration)
    for _ = 1, iteration do
        generateRandomNumber()
    end

    self.count = iteration
end

return RandomNumber