---@class DisplaySettings
local DisplaySettings = {}

---@param orientation Orientation
---@return DisplaySettings
function DisplaySettings.new(orientation, width, height)
    ---@type DisplaySettings
    local displaySettings = {}

    displaySettings.orientation = orientation
    displaySettings.width = width
    displaySettings.height = height

    return displaySettings
end

return DisplaySettings