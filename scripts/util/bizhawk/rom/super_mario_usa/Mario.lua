local Rom =  require('util/bizhawk/rom/Rom')
local Mario = Rom:new()
local SMW = require('util.bizhawk.rom.super_mario_usa.SMW')
local Logger = require('util.Logger')
local MarioInputType = require('util.bizhawk.rom.super_mario_usa.MarioInputType')

-- luacheck: globals memory

local romGameName = 'Super Mario World (USA)'
-- No need for both Y and X since they do the same thing.
local buttonNames = {
    "A",
    "B",
    "X",
    "Up",
    "Down",
    "Left",
    "Right",
}
local marioGameTileSize = 16

-- https://www.smwcentral.net/?p=memorymap&game=smw&u=0&address=000095&
local xPositionInMemory = 0x94
local yPositionMemory = 0x96

function Mario.getRomName()
    return romGameName
end

function Mario.getButtonOutputs()
    return buttonNames
end

function Mario.getPositions()
    -- Read Signed 16 Little Endian
    local marioX = memory.read_s16_le(xPositionInMemory)
    local marioY = memory.read_s16_le(yPositionMemory)

    return marioX, marioY
end

function Mario.getTile(offsetX, offsetY)
    local marioX, marioY = Mario.getPositions()

    -- Calculate the adjusted x and y positions based on the offsets and Mario's position
    -- add 8 to the 'x' position to get Mario's center
    local x = math.floor((marioX + offsetX + 8) / marioGameTileSize)
    local y = math.floor((marioY + offsetY) / marioGameTileSize)

    local tileMapStartAddress = 0x1C800
    local numberOfBytesInAColumnOrRow = 0x10

    -- divide x by 16 (0x10), multiply by number of bytes in each column (0x1B0)
    local xColumn = math.floor(x / numberOfBytesInAColumnOrRow) * 0x1B0

    -- Y is multiplied by number of bytes in each row (0x10)
    local yColumn = y * numberOfBytesInAColumnOrRow

    -- Get the top byte in a row, but a specific byte in a column
    return memory.readbyte(tileMapStartAddress + xColumn + yColumn + x % numberOfBytesInAColumnOrRow)
end

function Mario.getSprites()
    local sprites = {}
    -- https://www.smwcentral.net/
    local spriteByteLength = 12
    local spriteStatusAddress = 0x14C8
    local spriteTypeAddress = 0x009e
    local spriteLowXAddress = 0x00E4
    local spriteHighXAddress = 0x14E0
    local spriteLowYAddress = 0x00D8
    local spriteHighYAddress = 0x14D4

    local MUSHROOM_POWER = 116
    local FEATHER_POWERUP = 119

    for slot=0,spriteByteLength - 1 do
        local status = memory.readbyte(spriteStatusAddress+slot)
        local type = memory.readbyte(spriteTypeAddress + slot)
        local normal = 0x08
        local carryable = 0x09
        local kicked = 0x0A
        local carried = 0x0B
        if (status == normal or status == carryable or status == kicked or status == carried) and type ~= SMW.SPRITE.INVISIBLE_MUSHROOM then
            -- multiply by 256 to get the Tile position (16*16 = 256)
            local lowByteX = memory.readbyte(spriteLowXAddress+slot)
            local highByteX = memory.readbyte(spriteHighXAddress+slot) * 256

            local lowByteY = memory.readbyte(spriteLowYAddress+slot)
            local highByteY = memory.readbyte(spriteHighYAddress+slot) * 256

            local spriteX = lowByteX + highByteX
            local spriteY = lowByteY + highByteY
            local spriteValue = -1

            if status == normal then
                if SMW.SPRITE.isPowerUp(type) then
                    spriteValue = MarioInputType.SPRITE_POWERUP
                else
                    spriteValue = MarioInputType.SPRITE_NORMAL
                end
            elseif status == kicked then
                spriteValue = MarioInputType.SPRITE_KICKED
            elseif status == carried then
                spriteValue = MarioInputType.SPRITE_CARRIED
            elseif status == carryable then
                spriteValue = MarioInputType.SPRITE_CARRYABLE
            end

            sprites[#sprites+1] = {["x"] = spriteX, ["y"] = spriteY, ["value"] = spriteValue}
        end
    end

    return sprites
end

function Mario.getExtendedSprites()
    local extended = {}
    local spriteX, spriteY

    for slot=0, 11 do
        local spriteValue = memory.readbyte(0x170B+slot)
        -- if sprite has a value
        if spriteValue ~= 0 then
            -- high values are multiplied by 256 (16 * 16). Lower 8 bits are not
            spriteX = memory.readbyte(0x171F+slot) + (memory.readbyte(0x1733+slot) * 256)
            spriteY = memory.readbyte(0x1715+slot) + (memory.readbyte(0x1729+slot) * 256)
            extended[#extended+1] = {["x"] = spriteX, ["y"] = spriteY}
        end
    end

    return extended
end

function Mario.getInputs(programViewWidth, programViewHeight)
    local tileSize = marioGameTileSize
    local marioX, marioY = Mario.getPositions()

    local sprites = Mario.getSprites()
    local extended = Mario.getExtendedSprites()
    local inputs = {}
    -- take away 1 to account for center
    local halfProgramWidthInTiles = (programViewWidth - 1) / 2
    local halfProgramHeightInTiles = (programViewHeight - 1) / 2
    local distancethreshold = 8
    local totalTileX = halfProgramWidthInTiles * tileSize
    local totalTileY = halfProgramHeightInTiles * tileSize
    local distX, distY, spriteValue, tileValue

    -- increment by 16 from -X to +X
    for offsetX=-totalTileX, totalTileX, tileSize do
        for offsetY=-totalTileY, totalTileY, tileSize do
            inputs[#inputs+1] = 0

            tileValue = Mario.getTile(offsetX, offsetY)
            if tileValue == 1 then
                inputs[#inputs] = MarioInputType.TILE
            end

            for i = 1, #sprites do
                distX = math.abs(sprites[i]["x"] - (marioX + offsetX))
                distY = math.abs(sprites[i]["y"] - (marioY + offsetY))
                spriteValue = sprites[i]["value"]
                if distX <= distancethreshold and distY <= distancethreshold then
                    inputs[#inputs] = spriteValue
                end
            end

            for i = 1, #extended do
                distX = math.abs(extended[i]["x"] - (marioX + offsetX))
                distY = math.abs(extended[i]["y"] - (marioY + offsetY))
                if distX < distancethreshold and distY < distancethreshold then
                    -- TODO: -1 for all extended sprites is not good
                    inputs[#inputs] = MarioInputType.SPRITE_EXTENDED
                end
            end
        end
    end

    return inputs
end

function Mario.isWin()
    local endLevelTimerMemoryLocation = 0x1493
    local endLevelTimer = memory.readbyte(endLevelTimerMemoryLocation)

    return endLevelTimer and endLevelTimer > 1
end

return Mario