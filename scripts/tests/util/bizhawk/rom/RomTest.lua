-- Import LuaUnit module
local lu = require('lib.luaunit')

local Rom = require('util.bizhawk.rom.Rom')
local Position = require('machinelearning.ai.model.game.Position')

-- luacheck: globals TestRom fullTestSuite
TestRom = {}

function TestRom.testConstructor()
    local romA = Rom:new()
    local romB = Rom:new()

    romA.lastPosition = Position.new(100, 100)

    lu.assertFalse(romA == romB)
    lu.assertFalse(romA.lastPosition == romB.lastPosition)
    lu.assertEquals(100, romA.lastPosition.x)
    lu.assertEquals(-1, romB.lastPosition.x)
end

function TestRom.testReset()
    local rom = Rom:new()

    rom.lastPosition = Position.new(100, 100)
    rom:reset()

    lu.assertEquals(-1, rom.lastPosition.x)
    lu.assertEquals(-1, rom.lastPosition.y)
end

if not fullTestSuite then
    -- Run the tests
    os.exit(lu.LuaUnit.run())
end