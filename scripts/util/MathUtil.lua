-- Used as a global for math and random functions.
local MathUtil = {}

local RandomNumber = require('util.RandomNumber')
---@type RandomNumber
local rng = nil

function MathUtil.init(seed)
    rng = RandomNumber:new(seed)
end

function MathUtil.reset(seed, iteration)
    rng = RandomNumber:new(seed)
    rng:jumpToIteration(iteration)
end

function MathUtil.sigmoid(x)
    return 2 / (1 + math.exp(-4.9 * x)) - 1
end

function MathUtil.random(a, b)
    return rng:generate(a, b)
end

function MathUtil.getIteration()
    return rng.count
end

return MathUtil