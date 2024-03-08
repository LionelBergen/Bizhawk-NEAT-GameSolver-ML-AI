-- Import LuaUnit module
local lu = require('lib.luaunit')

local Mario = require('util.bizhawk.rom.super_mario_usa.Mario')
local Position = require('machinelearning.ai.model.game.Position')

-- luacheck: globals TestMario fullTestSuite
TestMario = {}

function TestMario.testConstructor()
    local romA = Mario:new()
    local romB = Mario:new()

    romA.lastPosition = Position.new(100, 100)

    lu.assertFalse(romA == romB)
    lu.assertFalse(romA.lastPosition == romB.lastPosition)
    lu.assertEquals(100, romA.lastPosition.x)
    lu.assertEquals(-1, romB.lastPosition.x)

    lu.assertEquals(-1, romA.rightMost)
end

function TestMario.testReset()
    local rom = Mario:new()

    rom.lastPosition = Position.new(100, 100)
    rom.rightMost = 100
    rom:reset()

    lu.assertEquals(-1, rom.lastPosition.x)
    lu.assertEquals(-1, rom.lastPosition.y)
    lu.assertEquals(-1, rom.rightMost)
end

if not fullTestSuite then
    -- Run the tests
    os.exit(lu.LuaUnit.run())
end