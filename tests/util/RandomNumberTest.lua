-- Import LuaUnit module
local lu = require('luaunit')

-- Import the RandomNumber class
local RandomNumber = require('RandomNumber')

-- Test the RandomNumber class
TestRandomNumber = {}

---@class RandomNumber
local rng
local firstNumberInSeq = '0.23145237586596'
local secondNumberInSeq = '0.58485671559801'
local hundredthNumberInSeq = '0.43037202063051'

function TestRandomNumber:setUp()
    -- Set a fixed seed value for reproducibility in tests
    rng = RandomNumber:new(12345)
end

-- Function to round a number to a specified decimal place
local function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

function TestRandomNumber:testGenerate()
    -- use tostring method, otherwise the comparison fails between floats
    -- Numbers are based on math.random(), given seed 12345
    lu.assertEquals(tostring(rng:generate()), firstNumberInSeq)
    lu.assertEquals(tostring(rng:generate()), secondNumberInSeq)
end

function TestRandomNumber:testJump()
    rng:jumpToIteration(99)

    lu.assertEquals(tostring(rng:generate()), hundredthNumberInSeq)
end

function TestRandomNumber:testGenerateAndJump()
    for _=1, 50 do
        rng:generate()
    end

    rng:jumpToIteration(99)

    lu.assertEquals(tostring(rng:generate()), hundredthNumberInSeq)
end

function TestRandomNumber:testJumpBackwards()
    for _=1, 50 do
        rng:generate()
    end

    rng:jumpToIteration(1)

    lu.assertEquals(tostring(rng:generate()), secondNumberInSeq)
end

function TestRandomNumber:testJumpZero()
    for _=1, 99 do
        rng:generate()
    end

    -- jump to the iteration 0
    rng:jumpToIteration(0)

    -- Should be 1st
    lu.assertEquals(tostring(rng:generate()), firstNumberInSeq)
end

function TestRandomNumber:testJumpToSameSpot()
    for _=1, 99 do
        rng:generate()
    end

    rng:jumpToIteration(99)

    lu.assertEquals(tostring(rng:generate()), hundredthNumberInSeq)
end

function TestRandomNumber:testReset()
    rng:generate()
    rng:jumpToIteration(105)
    rng:reset(12345)

    lu.assertEquals(tostring(rng:generate()), firstNumberInSeq)
    lu.assertEquals(tostring(rng:generate()), secondNumberInSeq)
end

function TestRandomNumber:testJumpToIterationInvalidArgumentNegative()
    -- Use pcall to catch the error
    local success, errorMessage = pcall(function()
        rng:jumpToIteration(-1)
    end)

    -- Check that pcall was not successful (error was thrown)
    lu.assertFalse(success)

    -- Check that the error message is as expected
    lu.assertStrContains(errorMessage, "Invalid argument")
end

function TestRandomNumber:testJumpToIterationInvalidArgumentNaN()
    -- Use pcall to catch the error
    local success, errorMessage = pcall(function()
        rng:jumpToIteration('11')
    end)

    -- Check that pcall was not successful (error was thrown)
    lu.assertFalse(success)

    -- Check that the error message is as expected
    lu.assertStrContains(errorMessage, "Invalid argument")
end

function TestRandomNumber:testJumpToIterationNilSeed()
    local rngTarget = RandomNumber:new()
    lu.assertNil(rngTarget.seed)

    rngTarget:generate()
    rngTarget:generate()

    rngTarget:jumpToIteration(0)
    lu.assertNil(rngTarget.seed)

    rngTarget:generate()
    rngTarget:generate()
end

function TestRandomNumber:testJumpToIterationWithSeed()
    local rngTarget = RandomNumber:new(1550)
    lu.assertEquals(1550, rngTarget.seed)

    local firstValue = rngTarget:generate()
    local secondValue = rngTarget:generate()

    rngTarget:jumpToIteration(0)
    lu.assertEquals(1550, rngTarget.seed)

    local newValue1 = rngTarget:generate()
    local newValue2 = rngTarget:generate()

    lu.assertEquals(firstValue, newValue1)
    lu.assertEquals(secondValue, newValue2)
end

-- Run the tests
os.exit(lu.LuaUnit.run())