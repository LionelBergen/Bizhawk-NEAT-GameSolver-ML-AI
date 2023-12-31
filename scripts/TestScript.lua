local MutationRate = require('machinelearning.ai.model.MutationRate')
local machineLearningProjectName = 'Mario_testing'
local FileUtil = require('util/FileUtil')
local Pool  = require('machinelearning.ai.model.Pool')
local poolSavesFolder = FileUtil.getCurrentDirectory() ..
        '\\..\\machine_learning_outputs\\' .. machineLearningProjectName .. '\\'
local GameHandler = require('util.bizhawk.GameHandler')

console = {}
function console.log(message)
    print(message)
end

---@type Pool
local pool = GameHandler.loadFromFile(poolSavesFolder .. 'backup.14.SuperMario_ML_pools.json', 5)
-- local newFileName = poolSavesFolder .. "backup.123"
-- GameHandler.saveFileFromPool(newFileName, pool)

local function assertTrue(value, message)
    if value == nil then
        error(message or 'expected true but was nil')
    elseif type(value) ~= boolean then
        error(message or 'expected boolean but was: ' .. type(value))
    else
        if not value == true then
            error(message or 'expected true but was: ' .. value)
        end
    end
end

local function assertNotNull(value, message)
    if value == nil then
        error(message or 'expected true but was nil')
    end
end

local function assertNotEquals(value1, value2)
    if value1 == value2 then
        error('value 1: ' .. value1 .. ' was equal to value2: ' .. value2)
    end
end

local function assertEquals(value1, value2)
    if value1 ~= value2 then
        error('value 1: ' .. value1 .. ' was not equal to value2: ' .. value2)
    end
end

-- MutationRate tests
local mutationRate = MutationRate:new()
local mutationRate2 = MutationRate:new(1, 1, 1, 1, 1, 1, 1)
mutationRate:mutate()
mutationRate2:mutate()
assertNotNull(mutationRate.values.connections)
assertNotNull(mutationRate.values.link)
assertNotNull(mutationRate.values.bias)
assertNotNull(mutationRate.values.node)
assertNotNull(mutationRate.values.enable)
assertNotNull(mutationRate.values.disable)
assertNotNull(mutationRate.values.step)

assertNotEquals(mutationRate.values.connections, mutationRate2.values.connections)
assertNotEquals(mutationRate.values.link, mutationRate2.values.link)
assertNotEquals(mutationRate.values.bias, mutationRate2.values.bias)
assertNotEquals(mutationRate.values.node, mutationRate2.values.node)
assertNotEquals(mutationRate.values.enable, mutationRate2.values.enable)
assertNotEquals(mutationRate.values.disable, mutationRate2.values.disable)
assertNotEquals(mutationRate.values.step, mutationRate2.values.step)

mutationRate = MutationRate.copy(mutationRate2)

assertEquals(mutationRate.values.connections, mutationRate2.values.connections)
assertEquals(mutationRate.values.link, mutationRate2.values.link)
assertEquals(mutationRate.values.bias, mutationRate2.values.bias)
assertEquals(mutationRate.values.node, mutationRate2.values.node)
assertEquals(mutationRate.values.enable, mutationRate2.values.enable)
assertEquals(mutationRate.values.disable, mutationRate2.values.disable)
assertEquals(mutationRate.values.step, mutationRate2.values.step)

local function displayAIInputs(width, height)
    local cells = {}
    local i = 1

    -- display beginning cell at position xStart * cellWidth, yStart * cellHeight
    local xStart = 4
    local yStart = 8
    local cellWidth = 5
    local cellHeight = 5
    local xEnd = xStart + (width * 2)
    local yEnd = yStart + (height * 2)

    for dx=xStart,xEnd do
        for dy=yStart,yEnd do
            local cell = {}
            cell.x = (cellWidth * dx)
            cell.y = (cellHeight * dy)
            -- cell.value = network.neurons[i].value
            cells[i] = cell
            i = i + 1
        end
    end

    table.sort(cells, function (a,b)
        if a.x == b.x then
            return a.y < b.y
        else
            return a.x < b.x
        end
    end)
    for _,cell in pairs(cells) do
        --print(cell.x)
        --print(cell.y)
    end

    return cells
end

displayAIInputs(6, 6)

print("passed.")