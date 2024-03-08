-- Import LuaUnit module
local lu = require('lib.luaunit')

local TetrisAttackInputType = require('util.bizhawk.rom.tetris_attack.TetrisAttackInputType')

-- luacheck: globals TestTetrisAttackInputType fullTestSuite
TestTetrisAttackInputType = {}

function TestTetrisAttackInputType.testFromValue()
    lu.assertEquals(TetrisAttackInputType.fromValue(1), TetrisAttackInputType.HEART)
end

if not fullTestSuite then
    -- Run the tests
    os.exit(lu.LuaUnit.run())
end