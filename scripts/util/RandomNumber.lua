--[[
    RandomNumber - Lua Class for Generating and Managing Random Numbers

    The RandomNumber class is designed to facilitate the generation of random numbers
    using Lua's built-in math.random function. It includes features for tracking the
    number of generated random numbers and the ability to 'jump' to a specific iteration.
    This functionality is particularly useful for debugging and testing. Example if
    a program is to save its state and 'resume' and we want numbers generated to not
    reset,

    Usage:
    local rng = RandomNumber:new(seed)       -- Instantiate class, 'seed' is optional but suggested
    rng:jumpToIteration(10)                  -- Jump to the 10th iteration. Next generate() method will be the 11th
    rng:generate()                           -- generate a random number
--]]
---@class RandomNumber
local RandomNumber = {}

-- Wrapper for math.random() in case we want to change in the future
local function generateRandomNumber()
    return math.random()
end

---@return RandomNumber
function RandomNumber:new(seed)
    ---@type RandomNumber
    local randomNumber = {}
    self = self or randomNumber
    self.__index = self
    setmetatable(randomNumber, self)

    randomNumber.count = 0

    if seed then
        math.randomseed(seed)
        randomNumber.seed = seed
    end

    return randomNumber
end

-- Reset the RandomNumber object with a new seed.
---@param seed number
function RandomNumber:reset(seed)
    math.randomseed(seed)
    self.count = 0
    self.seed = seed
end

function RandomNumber:generate()
    self.count = self.count + 1
    return generateRandomNumber()
end

-- Jumps to a point in the random number sequence.
-- Warning: Will produce new random seed if no seed was ever given
---@param iteration number
function RandomNumber:jumpToIteration(iteration)
    if type(iteration) ~= "number" or iteration < 0 then
        error("Invalid argument, expected a number 0 or greater: " .. iteration)
    end
    local difference = iteration - self.count

    if difference > 0 then
        for _ = 1, difference do
            generateRandomNumber()
        end
    elseif difference < 0 then
        self = RandomNumber:new(self.seed)
        self:jumpToIteration(iteration)
    end

    self.count = iteration
end

return RandomNumber