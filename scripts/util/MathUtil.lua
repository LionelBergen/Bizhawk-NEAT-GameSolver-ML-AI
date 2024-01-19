-- Used as a global for math and random functions.
local MathUtil = {}

local RandomNumber = require('util.RandomNumber')
local rng = RandomNumber:new(12345)

function MathUtil.sigmoid(x)
    return 2 / (1 + math.exp(-4.9 * x)) - 1
end

function MathUtil.random(a, b)
    return rng:generate(a, b)
end

return MathUtil