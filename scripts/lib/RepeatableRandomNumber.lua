--[[
    RepeatableRandomNumber - Lua Class for Generating and Managing Random Numbers

    The RepeatableRandomNumber class is designed to facilitate the generation of random numbers
    using Lua's built-in math.random function. It includes features for tracking the
    number of generated random numbers and the ability to 'jump' to a specific iteration.
    This functionality is particularly useful for debugging and testing. Example if
    a program is to save its state and 'resume' and we want numbers generated to not
    reset.

    Usage:
    local rng = RepeatableRandomNumber:new(seed)       -- Instantiate class, 'seed' is optional but suggested
    rng:jumpToIteration(10)                  -- Jump to the 10th iteration. Next generate() method will be the 11th
    rng:generate()                           -- generate a random number
--]]
---@class RepeatableRandomNumber
local RepeatableRandomNumber = {}

--- Wrapper for math.random() in case we want to change in the future
local function generateRandomNumber(m, n)
    if m and n then
        return math.random(m, n)
    elseif m then
        return math.random(m)
    end

    return math.random()
end

---@return RepeatableRandomNumber
function RepeatableRandomNumber:new(seed)
    ---@type RepeatableRandomNumber
    local randomNumber = {}
    self = self or randomNumber
    self.__index = self
    setmetatable(randomNumber, self)

    randomNumber.iteration = 0
    randomNumber.seed = seed or os.time()

    math.randomseed(randomNumber.seed)

    return randomNumber
end

--- Reset the RepeatableRandomNumber object with a new seed.
---@param seed number
function RepeatableRandomNumber:reset(seed)
    math.randomseed(seed)
    self.iteration = 0
    self.seed = seed
end

--- Generates a random number and increments iteration
--- Calls `math.random()` to generate the random number
---@param m number
---@param n number
---@return number
function RepeatableRandomNumber:generate(m, n)
    self.iteration = self.iteration + 1
    return generateRandomNumber(m, n)
end

--- Jumps to a point in the random number sequence.
--- Iteration can be taken from another `RepeatableRandomNumber:getIteration`
--- Warning: Will produce new random seed if no seed was ever given
---@param iteration number
function RepeatableRandomNumber:jumpToIteration(iteration)
    if type(iteration) ~= "number" or iteration < 0 then
        error("Invalid argument, expected a number 0 or greater but was: " .. (iteration or 'nil'))
    end
    local difference = iteration - self.iteration

    if difference > 0 then
        for _ = 1, difference do
            generateRandomNumber()
        end
    elseif difference < 0 then
        self = RepeatableRandomNumber:new(self.seed)
        self:jumpToIteration(iteration)
    end

    self.iteration = iteration
end

--- Returns the current iteration
---@return number
function RepeatableRandomNumber:getIteration()
    return self.iteration
end

return RepeatableRandomNumber