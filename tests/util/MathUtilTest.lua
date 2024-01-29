-- Import LuaUnit module
local lu = require('luaunit')

-- Import the RandomNumber class
local MathUtil = require('util.MathUtil')

-- Test the RandomNumber class
TestMathUtil = {}

function TestMathUtil:testDistribute()
    local result = MathUtil.distribute(100, 20)

    lu.assertEquals(#result, 20)

    lu.assertEquals(result[1], 19)
    lu.assertEquals(result[2], 9)
    lu.assertEquals(result[3], 8)
    lu.assertEquals(result[4], 8)
    lu.assertEquals(result[5], 7)
    lu.assertEquals(result[6], 7)
    lu.assertEquals(result[7], 6)
    lu.assertEquals(result[8], 6)
    lu.assertEquals(result[9], 5)
    lu.assertEquals(result[10], 5)
    lu.assertEquals(result[11], 4)
    lu.assertEquals(result[12], 4)
    lu.assertEquals(result[13], 3)
    lu.assertEquals(result[14], 3)
    lu.assertEquals(result[15], 2)
    lu.assertEquals(result[16], 2)
    lu.assertEquals(result[17], 1)
    lu.assertEquals(result[18], 1)
    lu.assertEquals(result[19], 0)
    lu.assertEquals(result[20], 0)
end

-- Run the tests
os.exit(lu.LuaUnit.run())