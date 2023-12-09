local Mario = {}

function Mario.getPositions()
    local marioX = memory.read_s16_le(0x94)
    local marioY = memory.read_s16_le(0x96)

    return marioX, marioY
end

function Mario.getTile(dx, dy)
    x = math.floor((marioX+dx+8)/16)
    y = math.floor((marioY+dy)/16)

    return memory.readbyte(0x1C800 + math.floor(x/0x10)*0x1B0 + y*0x10 + x%0x10)
end

function Mario.getSprites()
    local sprites = {}
    -- https://www.smwcentral.net/?p=memorymap&game=smw&u=0&address=&sizeOperation=%3D&sizeValue=&region[]=ram&type=*&description=koopa
    local spriteByteLength = 12
    local spriteStatusAddress = 0x14C8
    local spriteLowXAddress = 0x00E4
    local spriteHighXAddress = 0x14E0
    local spriteLowYAddress = 0x00D8
    local spriteHighYAddress = 0x14D4
    for slot=0,spriteByteLength - 1 do
        local status = memory.readbyte(spriteStatusAddress+slot)
        -- https://www.smwcentral.net/?p=memorymap&a=detail&game=smw&region=ram&detail=0984148beee5
        if status ~= 0 and status ~= 02 and status ~= 04 then
            -- TODO: why multiply by 256?
            spritex = memory.readbyte(spriteLowXAddress+slot) + memory.readbyte(spriteHighXAddress+slot)*256
            spritey = memory.readbyte(spriteLowYAddress+slot) + memory.readbyte(spriteHighYAddress+slot)*256

            spritevalue = -1
            -- if carryable
            if status == 09 then
                spritevalue = 2
            elseif status == 0x0B then
                spritevalue = 3
            end
            sprites[#sprites+1] = {["x"]=spritex, ["y"]=spritey, ["value"]=spritevalue}
        end
    end

    return sprites
end

function Mario.getExtendedSprites()
    local extended = {}
    for slot=0,11 do
        local number = memory.readbyte(0x170B+slot)
        if number ~= 0 then
            spritex = memory.readbyte(0x171F+slot) + memory.readbyte(0x1733+slot)*256
            spritey = memory.readbyte(0x1715+slot) + memory.readbyte(0x1729+slot)*256
            extended[#extended+1] = {["x"]=spritex, ["y"]=spritey}
        end
    end

    return extended
end

function getInputs()
    local marioCoords = Mario.getPositions()

    sprites = getSprites()
    extended = getExtendedSprites()

    local inputs = {}

    for dy=-ProgramViewBoxRadius*16,ProgramViewBoxRadius*16,16 do
        for dx=-ProgramViewBoxRadius*16,ProgramViewBoxRadius*16,16 do
            inputs[#inputs+1] = 0

            tile = getTile(dx, dy)
            if tile == 1 then
                inputs[#inputs] = 1
            end

            for i = 1,#sprites do
                distx = math.abs(sprites[i]["x"] - (marioX+dx))
                disty = math.abs(sprites[i]["y"] - (marioY+dy))
                value = sprites[i]["value"]
                if distx <= 8 and disty <= 8 then
                    inputs[#inputs] = value
                end
            end

            for i = 1,#extended do
                distx = math.abs(extended[i]["x"] - (marioX+dx))
                disty = math.abs(extended[i]["y"] - (marioY+dy))
                if distx < 8 and disty < 8 then
                    inputs[#inputs] = -1
                end
            end
        end
    end

    return inputs
end

return Mario