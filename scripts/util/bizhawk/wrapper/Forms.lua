--[[
    Forms - Lua Class for wrapping Bizhawk's forms library

    Purpose: add documentation from Bizhawk's lua functions documentation
    Also I've found some labels get cut off, the wrapper functions may create multiple to fix this issue
--]]
local Forms = {}

-- luacheck: ignore Form
---@class Form
local Form = {}

local CHECKBOX_WIDTH = 24
local LABEL_HEIGHT = 20

local onClickFunctions = {}

-- luacheck: globals forms

---@param width number
---@param height number
---@param title string
---@param onclose function
---@return Form
function Forms.createNewForm(width, height, title, onclose)
    if title and onclose then
        return forms.newform(width, height, title, onclose)
    elseif title then
        return forms.newform(width, height, title)
    end

    return forms.newform(width, height)
end

---@param form Form
---@param text string
---@param x number
---@param y number
---@param width number
---@param height number
---@return Form
function Forms.createLabel(form, text, x, y, width, height, fixedWidth)
    fixedWidth = fixedWidth or false

    if x and y and width and height then
        return forms.label(form, text, x, y, width, height, fixedWidth)
    elseif x and y and width then
        return forms.label(form, text, x, y, width)
    elseif x and y then
        return forms.label(form, text, x, y)
    elseif x then
        return forms.label(form, text, x)
    end

    return forms.label(form, text)
end

---@param form Form
---@param caption string
---@param x number
---@param y number
---@return Form
function Forms.createCheckbox(form, caption, x, y, captionWidth)
    -- The checkbox in Bizhawk is ~80 wide. We need to draw the label before the checkbox to avoid the checkbox blocking
    -- it. Furthermore, we have to seperate the label from the checkbox to surpass the 80 limit.
    -- "80" is an estimate and the measurment unit is unclear. It's used in bizhawk forms.
    if captionWidth then
        local labelX = x + CHECKBOX_WIDTH
        local labelY = y - 1
        Forms.createLabel(form, caption, labelX, labelY, captionWidth, LABEL_HEIGHT)
    end

    if x and y then
        return forms.checkbox(form, "XXXXXXXXXXXXXXXXXXXXXXXXXX", x, y)
    elseif x then
        return forms.checkbox(form, "XXXXXXXXXXXXXXXXXXXXXXXXX", x)
    else
        return forms.checkbox(form, "XXXXXXXXXXXXXXXXXXXXXXXXX")
    end
end

function Forms.createTextBox(form, caption, x, y, captionWidth)
    if captionWidth then
        local labelX = x
        local labelY = y - 1
        Forms.createLabel(form, caption, labelX, labelY, captionWidth, LABEL_HEIGHT)

        x = x + captionWidth
    end

    if x and y then
        return forms.textbox(form, nil, 20, nil, x, y)
    elseif x then
        return forms.textbox(form, x)
    else
        return forms.textbox(form)
    end
end

---@return number number
function Forms.createButton(form, caption, x, y)
    local functionIndex = #onClickFunctions + 1
    local onclickFunction = function() onClickFunctions[functionIndex]() end
    local width = 150
    local height = 28
    return forms.button(form, caption, onclickFunction, x, y, width, height), functionIndex
end

function Forms.registerOnClickFunction(functionIndex, onclickFunction)
    onClickFunctions[functionIndex] = onclickFunction
end

return Forms