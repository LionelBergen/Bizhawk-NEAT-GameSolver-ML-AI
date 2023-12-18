local MutationRate = require('machinelearning.ai.model.MutationRate')

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
local mutationRate = MutationRate.new()
local mutationRate2 = MutationRate.new(1, 1, 1, 1, 1, 1, 1)
assertNotNull(mutationRate.connections)
assertNotNull(mutationRate.link)
assertNotNull(mutationRate.bias)
assertNotNull(mutationRate.node)
assertNotNull(mutationRate.enable)
assertNotNull(mutationRate.disable)
assertNotNull(mutationRate.step)

assertNotEquals(mutationRate.connections, mutationRate2.connections)
assertNotEquals(mutationRate.link, mutationRate2.link)
assertNotEquals(mutationRate.bias, mutationRate2.bias)
assertNotEquals(mutationRate.node, mutationRate2.node)
assertNotEquals(mutationRate.enable, mutationRate2.enable)
assertNotEquals(mutationRate.disable, mutationRate2.disable)
assertNotEquals(mutationRate.step, mutationRate2.step)

mutationRate = MutationRate.copy(mutationRate2)

assertEquals(mutationRate.connections, mutationRate2.connections)
assertEquals(mutationRate.link, mutationRate2.link)
assertEquals(mutationRate.bias, mutationRate2.bias)
assertEquals(mutationRate.node, mutationRate2.node)
assertEquals(mutationRate.enable, mutationRate2.enable)
assertEquals(mutationRate.disable, mutationRate2.disable)
assertEquals(mutationRate.step, mutationRate2.step)

print("passed.")