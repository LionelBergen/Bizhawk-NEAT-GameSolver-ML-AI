-- Import LuaUnit module
local lu = require('luaunit')

local GameHandler = require('util.bizhawk.GameHandler')

local mockRom = {
    getButtonOutputs = function()
        return {"A", "B", "Up", "Down", "Left", "Right"}
    end
}

-- Mock the 'joypad' object with a fake implementation for testing
local fakeJoypad = {
    set = function(controller)
        -- Assert that the controller table contains the expected values
        -- You can customize this assertion based on the expected behavior
        assert(controller["P1 A"] == false)
        assert(controller["P1 B"] == false)
        assert(controller["P1 Up"] == false)
        assert(controller["P1 Down"] == false)
        assert(controller["P1 Left"] == false)
        assert(controller["P1 Right"] == false)
    end
}

TestGameHandler = {}

function TestGameHandler:testClearJoypad()
    joypad = fakeJoypad
    GameHandler.clearJoypad(mockRom)
end

if not fullTestSuite then
    -- Run the tests
    os.exit(lu.LuaUnit.run())
end