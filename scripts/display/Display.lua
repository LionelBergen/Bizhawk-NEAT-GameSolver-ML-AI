local Display = {}

local Cell = require('machinelearning.ai.model.display.Cell')
local NeuronType = require('machinelearning.ai.model.NeuronType')
local MarioInputType = require('util.bizhawk.rom.super_mario_usa.MarioInputType')
local Colour = require('machinelearning.ai.model.display.Colour')
local MathUtil = require('util.MathUtil')
local ErrorHandler = require('util.ErrorHandler')

-- luacheck: globals gui

-- Creates a 2d array of Cell's based on the neurons passed
---@param neurons Neuron[]
---@return Cell[]
function Display.getCells(neurons, width, height, neuronType)
    ---@type Cell[]
    local cells = {}
    local i = 1

    -- display beginning cell at position xStart * cellWidth, yStart * cellHeight
    local xStart = 4
    local yStart = 8
    local cellWidth = 5
    local cellHeight = 5
    local xEnd = xStart + (width - 1)
    local yEnd = yStart + (height - 1)

    if (width * height) > #neurons then
        error('Cannot get CellInputs, values were too large.')
    end

    for dx=xStart,xEnd do
        for dy=yStart,yEnd do
            ---@type Cell
            local cell = Cell:new(cellWidth * dx, cellHeight * dy, neurons[i].value, neuronType)
            cells[#cells + 1] = cell
            i = i + 1
        end
    end

    return cells
end

-- Inline function to filter items
---@param arr Cell[]
---@param neuronType NeuronType
---@return Cell[]
local function filterCellsByNeuronType(arr, neuronType)
    local result = {}
    for _, item in ipairs(arr) do
        if item.neuronType == neuronType then
            table.insert(result, item)
        end
    end
    return result
end

---@param haystack Cell[]
---@param needle NeuronInfo
---@return Cell
local function findCellFromGene(haystack, needle)
    local cells = filterCellsByNeuronType(haystack, needle.type)

    if needle.type == NeuronType.BIAS then
        -- bias has only 1
        return cells[1]
    end

    if cells[needle.index] == nil then
        ErrorHandler.error('cells did not contain an item for type: ' .. needle.type .. ' index: ' .. needle.index)
    end

    return cells[needle.index]
end

---@param genome Genome
---@param programViewWidth number
---@param programViewHeight number
---@param buttonOutputs string[]
---@param showMutationRates boolean
function Display.displayGenome(genome, programViewWidth, programViewHeight, buttonOutputs, showMutationRates)
    ---@type Network
    local network = genome.network
    ---@type Cell[]
    local cells = Display.getCells(network.inputNeurons, programViewWidth, programViewHeight, NeuronType.INPUT)
    -- Bias cell/node is a special input neuron that is always active
    ---@type Cell
    local biasCell = Cell:new(80, 110, network.biasNeuron.value, NeuronType.BIAS)
    cells[#cells + 1] = biasCell

    local numAdjustmentIterations = 4
    local preservationWeight = 0.75
    local explorationWeight = 0.25

    for o,outputNeuron in pairs(network.outputNeurons) do
        ---@type Cell
        local cell = Cell:new()
        local black = 0xFF000000
        local blue = 0xFF0000FF
        cell.x = 220
        cell.y = 30 + 8 * o
        cell.value = outputNeuron.value
        cell.neuronType = NeuronType.OUTPUT
        cells[#cells + 1] = cell
        local color
        if cell.value > 0 then
            color = blue
        else
            color = black
        end
        -- draw the programs outputs (E.G X button). Black if not pressed, blue if pressed
        gui.drawText(223, 24+8*o, buttonOutputs[o], color, 9)
    end

    for _,neuron in pairs(network.processingNeurons) do
        local cell = Cell:new()
        cell.x = 140
        cell.y = 40
        cell.value = neuron.value
        cell.neuronType = NeuronType.PROCESSING
        cells[#cells + 1] = cell
    end

    for _=1, numAdjustmentIterations do
        for _, gene in pairs(genome.genes) do
            if gene.enabled then
                local sourceCell = findCellFromGene(cells, gene.into)
                local targetCell = findCellFromGene(cells, gene.out)

                if sourceCell == nil then
                    ErrorHandler.error('source cell null. type: ' .. gene.into.type .. ' index: ' .. gene.into.index)
                end

                if gene.into.type == NeuronType.OUTPUT or gene.into.type == NeuronType.BIAS then
                    sourceCell.x = (preservationWeight * sourceCell.x) + (explorationWeight * targetCell.x)
                    if sourceCell.x >= targetCell.x then
                        sourceCell.x = sourceCell.x - 40
                    end
                    if sourceCell.x < 90 then
                        sourceCell.x = 90
                    end

                    if sourceCell.x > 220 then
                        sourceCell.x = 220
                    end
                    sourceCell.y = (preservationWeight * sourceCell.y) + (explorationWeight * targetCell.y)
                end

                if gene.out.type == NeuronType.OUTPUT or gene.out.type == NeuronType.BIAS then
                    targetCell.x = explorationWeight * sourceCell.x + preservationWeight * targetCell.x
                    if sourceCell.x >= targetCell.x then
                        targetCell.x = targetCell.x + 40
                    end
                    if targetCell.x < 90 then
                        targetCell.x = 90
                    end
                    if targetCell.x > 220 then
                        targetCell.x = 220
                    end
                    targetCell.y = explorationWeight * sourceCell.y + preservationWeight * targetCell.y
                end
            end
        end
    end

    local lineColour = Colour.BLACK
    local backgroundColour = Colour.GREY
    local startX = 17 -- 50 - (ProgramViewBoxRadius*5) - 3
    local startY = 37 -- 70 - (ProgramViewBoxRadius*5)-3
    local endX = 82 -- 50 + (ProgramViewBoxRadius*5)+2
    local endY = 102 -- 70 + (ProgramViewBoxRadius*5)+2
    -- 17, 37, 82, 102
    --gui.drawBox(int x, int y, int x2, int y2, [luacolor_line], [luacolor_background], [surfacename])
    gui.drawBox(startX,
            startY,
            endX,
            endY,
            lineColour,
            backgroundColour)
    for _, celln in pairs(cells) do
        if celln.neuronType ~= NeuronType.INPUT or celln.value ~= 0 then
            local color = math.floor((celln.value+1)/2*256)
            if color > 255 then color = 255 end
            if color < 0 then color = 0 end
            local opacity = 0xFF000000
            if celln.value == 0 then
                opacity = 0x50000000
            end
            color = opacity + color*0x10000 + color*0x100 + color

            if celln.value == MarioInputType.TILE then
                color = 0xFFFFFFFF
            elseif celln.value == MarioInputType.SPRITE_NORMAL then
                color = 0xFF1717FF
            elseif celln.value == MarioInputType.SPRITE_CARRYABLE then
                color = 0x0F16FFFF
            elseif celln.value == MarioInputType.SPRITE_KICKED then
                color = 0xFF1818FF
            elseif celln.value == MarioInputType.SPRITE_CARRIED then
                color = 0x635A58FF
            elseif celln.value == MarioInputType.SPRITE_EXTENDED then
                color = 0x641DFF80
            elseif celln.value == MarioInputType.SPRITE_POWERUP then
                color = 0xFBFF0BC9
            elseif celln.value ~= 0 and celln.neuronType == NeuronType.INPUT then
                ErrorHandler.error(celln.value .. ' type: ' .. celln.neuronType)
            end

            gui.drawBox(celln.x-2, celln.y-2, celln.x+2, celln.y+2, opacity, color)
        end
    end

    for _,gene in pairs(genome.genes) do
        if gene.enabled then
            local c1 = findCellFromGene(cells, gene.into)
            local c2 = findCellFromGene(cells, gene.out)
            local opacity = 0xA0000000
            if c1.value == 0 then
                opacity = 0x20000000
            end

            local color = 0x80-math.floor(math.abs(MathUtil.sigmoid(gene.weight))*0x80)
            if gene.weight > 0 then
                color = opacity + 0x8000 + 0x10000*color
            else
                color = opacity + 0x800000 + 0x100*color
            end
            gui.drawLine(c1.x+1, c1.y, c2.x-3, c2.y, color)
        end
    end

    gui.drawBox(49,71,51,78,0x00000000,0x80FF0000)

    if showMutationRates then
        local pos = 100
        for mutation,rate in pairs(genome.mutationRates.values) do
            gui.drawText(100, pos, mutation .. ": " .. rate, 0xFF000000, 10)
            pos = pos + 8
        end
    end
end

return Display