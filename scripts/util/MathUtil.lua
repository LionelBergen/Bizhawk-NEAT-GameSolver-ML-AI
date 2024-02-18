-- Used as a global for math and random functions.
---@class MathUtil
local MathUtil = {}

local RandomNumber = require('lib.RepeatableRandomNumber')
---@type RepeatableRandomNumber
local rng = nil

local function reverseList(list)
    local reversedList = {}
    local length = #list

    for i = length, 1, -1 do
        table.insert(reversedList, list[i])
    end

    return reversedList
end


function MathUtil.init(seed)
    rng = RandomNumber:new(seed)
end

function MathUtil.reset(seed, iteration)
    rng = RandomNumber:new(seed)
    rng:jumpToIteration(iteration)
end

function MathUtil.sigmoid(x)
    return 2 / (1 + math.exp(-4.9 * x)) - 1
end

function MathUtil.random(a, b)
    return rng:generate(a, b)
end

function MathUtil.getIteration()
    return rng.count
end

---@param numberOfItemsToDistribute number
---@param distributeToThisMany number
function MathUtil.distribute(numberOfItemsToDistribute, distributeToThisMany)
    local distribution = {}
    local totalProportion = 0

    for i = 1, distributeToThisMany do
        local proportion = i / (distributeToThisMany * (distributeToThisMany + 1) / 2)
        totalProportion = totalProportion + proportion
    end

    local remainingDistribution = numberOfItemsToDistribute

    for i = 1, (distributeToThisMany - 1) do
        local proportion = i / (distributeToThisMany * (distributeToThisMany + 1) / 2)
        local amountToDistribute = math.floor(numberOfItemsToDistribute * proportion / totalProportion)
        remainingDistribution = remainingDistribution - amountToDistribute
        table.insert(distribution, amountToDistribute)
    end

    -- Distribute the remaining amount to the last item
    table.insert(distribution, remainingDistribution)

    return reverseList(distribution)
end

return MathUtil