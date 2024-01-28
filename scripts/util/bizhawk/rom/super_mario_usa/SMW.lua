---@class SMW
local SMW = {}

SMW.SPRITE = {
    GOAL_TAPE = 0x7B,
    INVISIBLE_MUSHROOM = 0xC7,
    MUSHROOM = 0x74,
    FLOWER = 0x75,
    STAR = 0x76,
    FEATHER = 0x77,
    MUSHROOM_1_UP = 0x78,
}

function SMW.SPRITE.isPowerUp(value)
    return value == SMW.SPRITE.FEATHER
            or value == SMW.SPRITE.FLOWER
            or value == SMW.SPRITE.MUSHROOM
            or value == SMW.SPRITE.MUSHROOM_1_UP
            or value == SMW.SPRITE.STAR
end


return SMW