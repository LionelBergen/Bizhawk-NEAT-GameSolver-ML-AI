-- NEAT ML/AI program designed to be used with Bizhawk emulator
-- Created by Lionel Bergen
local FileUtil = require('util/FileUtil')
local Logger = require('util.Logger')
local GameHandler = require('util/bizhawk/GameHandler')
local Neat = require('machinelearning/ai/Neat')
local Species = require('machinelearning.ai.model.Species')
local Cell = require('machinelearning.ai.model.display.Cell')
local Mario = require('util.bizhawk.rom.super_mario_usa.Mario')
local Validator = require('../util/Validator')
local Colour = require('machinelearning.ai.model.display.Colour')
local NeuronType = require('machinelearning.ai.model.NeuronType')
local MathUtil = require('util.MathUtil')
local MarioInputType = require('util.bizhawk.rom.super_mario_usa.MarioInputType')

local rom = Mario
local saveFileName = 'SMW.state'
local poolFileNamePrefix = 'SuperMario_ML_pools'
local poolFileNamePostfix = poolFileNamePrefix .. ".json"
local machineLearningProjectName = 'Mario_testing'
local poolSavesFolder = FileUtil.getCurrentDirectory() ..
		'\\..\\machine_learning_outputs\\' .. machineLearningProjectName .. '\\'
local seed = 12345
local LEVEL_COMPLETE_FITNESS_BONUS = 1000
local DEATH_FITNESS_BONUS = -50

MathUtil.init(seed)

---@type Neat
local neatMLAI = Neat:new()

-- You can use https://jscolor.com/ to find colours
-- Used for the top bar overlay that displays the gen, speciies etc.
local topOverlayBackgroundColor = 0xD0FFFFFF

-- TODO: get rid of 'ProgramViewBoxRadius'.. It's not as user friendly as 'width' and 'height'.
-- this is the Programs 'view'
local ProgramViewBoxRadius = 6
local programViewWidth = 13
local programViewHeight = 13
local inputSizeWithoutBiasNode = (programViewWidth * programViewHeight)
local inputSize = inputSizeWithoutBiasNode + 1
local outputSize = #rom.getButtonOutputs()

local TimeoutConstant = 20
local newNodeIndexStart = 1000000
local rightmost = 0
local timeout = 0

-- Declare variables that are defined in Bizhawk already.
-- This is just to satisfy LuaCheck, to make it easier to find actual issues
-- luacheck: globals forms joypad gui emu event gameinfo

local form = forms.newform(200, 260, "Fitness")
local maxFitnessLabel = forms.label(form, "Max Fitness: nil", 5, 8)
local showNetwork = forms.checkbox(form, "Show Map", 5, 30)
local showMutationRates = forms.checkbox(form, "Show M-Rates", 5, 52)
--local restartButton = forms.button(form, "Restart", initializePool, 5, 77)
--local saveButton = forms.button(form, "Save", savePool, 5, 102)
--local loadButton = forms.button(form, "Load", loadPool, 80, 102)
--local saveLoadLabel = forms.label(form, "Save/Load:", 5, 129)
--local playTopButton = forms.button(form, "Play Top", playTop, 5, 170)
local hideBanner = forms.checkbox(form, "Hide Banner", 5, 190)
local Mode = {Manual = 1, Auto = 2}
local mode = Mode.Auto
local controller = {}

if mode == Mode.Manual then
	TimeoutConstant = 200000
end

---@param pool Pool
local function saveNewBackup(pool, poolGeneration, saveFolderName, filePostfix)
	if mode ~= Mode.Manual then
		local newFileName = saveFolderName .. "backup." .. poolGeneration .. "." .. filePostfix
		GameHandler.saveFileFromPool(newFileName, pool, { seed = seed, numbersGenerated = MathUtil.getIteration() })
	end
end

---@param neatObject Neat
local function evaluateCurrent(neatObject)
	local genome = neatObject:getCurrentGenome()

	local inputs = rom.getInputs(programViewWidth, programViewHeight)
	controller = neatObject.evaluateNetwork(genome.network, inputs, rom.getButtonOutputs())

	if mode ~= Mode.Manual then
		if controller["P1 Left"] and controller["P1 Right"] then
			controller["P1 Left"] = false
			controller["P1 Right"] = false
		end
		if controller["P1 Up"] and controller["P1 Down"] then
			controller["P1 Up"] = false
			controller["P1 Down"] = false
		end


		joypad.set(controller)
	end
end

---@param neatObject Neat
local function initializeRun(neatObject)
	-- Load the beginning of a level
	GameHandler.loadSavedGame('..\\assets\\savedstates\\' .. saveFileName)
	rightmost = 0
	neatObject.pool.currentFrame = 0
	timeout = TimeoutConstant
	GameHandler.clearJoypad(rom)
	local genome = neatObject:getCurrentGenome()

	neatObject.generateNetwork(genome, inputSizeWithoutBiasNode, outputSize)
	Validator.validatePool(neatObject.pool)
	evaluateCurrent(neatObject)
end

---@param neatObject Neat
local function nextGenome(neatObject)
	local pool = neatObject.pool
	pool.currentGenome = pool.currentGenome + 1
	if pool.currentGenome > #pool.species[pool.currentSpecies].genomes then
		pool.currentGenome = 1
		pool.currentSpecies = pool.currentSpecies + 1
		if pool.currentSpecies > #pool.species then
			neatObject:newGeneration(inputSizeWithoutBiasNode, outputSize)
			saveNewBackup(pool, pool.generation, poolSavesFolder, poolFileNamePostfix)
			pool.currentSpecies = 1
		end
	end
end

---@param pool Pool
local function isFitnessMeasured(pool)
	local genome = pool:getCurrentGenome()
	return genome.fitness ~= 0
end

---@param network Network
---@return Cell[]
local function getCellInputs(network, width, height)
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

	---@type Neuron[]
	local neurons = network.inputNeurons

	if (width * height) > #neurons then
		error('Cannot get CellInputs, values were too large.')
	end

	for dx=xStart,xEnd do
		for dy=yStart,yEnd do
			---@type Cell
			local cell = Cell:new()
			cell.x = (cellWidth * dx)
			cell.y = (cellHeight * dy)
			cell.value = neurons[i].value
			cell.neuronType = NeuronType.INPUT
			cells[i] = cell
			i = i + 1
		end
	end

	return cells
end

-- TODO: Shouldn't be in this class. Maybe a 'dispaly' handler util class
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
		Logger.info('------------------- ERROR: -------------------------')
		Logger.info(cells)
		Logger.info(needle.type .. ' index: ' .. needle.index)
		error(1)
	end

	return cells[needle.index]
end

---@param genome Genome
local function displayGenome(genome)
	---@type Network
	local network = genome.network
	---@type Cell[]
	local cells = getCellInputs(network, programViewWidth, programViewHeight)
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
		gui.drawText(223, 24+8*o, rom.getButtonOutputs()[o], color, 9)
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
					Logger.error('source cell null. heres type: ' .. gene.into.type .. ' and index: ' .. gene.into.index)
					error(1)
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
	--gui.drawBox(int x, int y, int x2, int y2, [luacolor line = nil], [luacolor background = nil], [string surfacename = nil])
	gui.drawBox(startX,
			startY,
			endX,
			endY,
			lineColour,
			backgroundColour)
	for n, celln in pairs(cells) do
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
				error(celln.value .. ' type: ' .. celln.neuronType)
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

	if forms.ischecked(showMutationRates) then
		local pos = 100
		for mutation,rate in pairs(genome.mutationRates.values) do
			gui.drawText(100, pos, mutation .. ": " .. rate, 0xFF000000, 10)
			pos = pos + 8
		end
	end
end

local function savePool()
	error('unimplemented')
end

local function loadPool()
	error('unimplemented')
end

local function playTop(pool)
	error('unimplemented')
end

---@param neatObject Neat
local function loadFileAndInitialize(filename, neatObject)
	local pool, additionalFields = GameHandler.loadFromFile(filename, outputSize)
	neatObject.pool = pool
	MathUtil.reset(additionalFields.seed, additionalFields.numbersGenerated)
	Logger.info('current genome?: ' .. pool.currentGenome)
	while isFitnessMeasured(neatObject.pool) do
		nextGenome(neatObject)
	end
	initializeRun(neatObject)
	pool.currentFrame = pool.currentFrame + 1
end

---@param neatObject Neat
local function loadFile(saveFolderName, neatObject)
	local latestBackupFile = GameHandler.getLatestBackupFile(saveFolderName)
	if latestBackupFile ~= nil then
		Logger.info('attempting to load file for pool...: ' .. latestBackupFile)
		loadFileAndInitialize(saveFolderName .. latestBackupFile, neatObject)
		Logger.info('loaded backfile: ' .. latestBackupFile)
	else
		Logger.info('No backup file to load from. looked in directory: ' .. saveFolderName .. ' will continue new program')
	end
end

local function onExit()
	forms.destroy(form)
end

if gameinfo.getromname() ~= rom.getRomName() then
	error('Unsupported Game Rom! Please play rom: ' .. rom.getRomName() .. ' Rom currently is: ' .. gameinfo.getromname())
end

Logger.info('starting Mar I/O...')

-- set exit function to destroy the form
event.onexit(onExit)

-- Set the 'showNetowrk' checkbox to true, just while we mess around with it
forms.setproperty(showNetwork, "Checked", true)

-- Load the latest .pool file
loadFile(poolSavesFolder, neatMLAI)

if neatMLAI.pool == nil then
	neatMLAI:initializePool(inputSizeWithoutBiasNode, outputSize)
end
initializeRun(neatMLAI)

forms.settext(maxFitnessLabel, "Max Fitness: " .. math.floor(neatMLAI.pool.maxFitness))

while true do
	if not forms.ischecked(hideBanner) then
		gui.drawBox(0, 0, 300, 26, topOverlayBackgroundColor, topOverlayBackgroundColor)
	end

	---@type Pool
	local pool = neatMLAI.pool
	---@type Genome
	local genome = pool:getCurrentGenome()

	if forms.ischecked(showNetwork) then
		displayGenome(genome)
	end

	if pool.currentFrame%5 == 0 then
		evaluateCurrent(neatMLAI)
	end

	-- TODO: 'controller' shouldnt have to be a class wide local
	if mode ~= Mode.Manual then
		joypad.set(controller)
	end
	-- TODO: 'marioX', 'marioY'
	local marioX, _ = rom:getPositions()
	if marioX > rightmost then
		rightmost = marioX
		timeout = TimeoutConstant
	end

	timeout = timeout - 1

	local timeoutBonus = pool.currentFrame / 4

	if rom:isWin() or rom:isDead() then
		timeout = -timeoutBonus
	end
	if timeout + timeoutBonus <= 0 then
		local fitness = rightmost - pool.currentFrame / 2

		if rom:isWin() then
			fitness = fitness + LEVEL_COMPLETE_FITNESS_BONUS
		elseif rom:isDead() then
			fitness = fitness - DEATH_FITNESS_BONUS
		end
		if fitness == 0 then
			fitness = -1
		end
		genome.fitness = fitness

		if fitness > pool.maxFitness then
			pool.maxFitness = fitness
			forms.settext(maxFitnessLabel, " Max Fitness: " .. math.floor(pool.maxFitness))
			saveNewBackup(pool, pool.generation, poolSavesFolder, poolFileNamePostfix)
		end

		Logger.info("Gen " .. pool.generation .. " species " ..
				pool.currentSpecies .. " genome " .. pool.currentGenome .. " fitness: " .. fitness)
		pool.currentSpecies = 1
		pool.currentGenome = 1
		while isFitnessMeasured(pool) do
			nextGenome(neatMLAI)
		end
		initializeRun(neatMLAI)
	end

	local measured = 0
	local total = 0
	for _,s in pairs(pool.species) do
		for _,g in pairs(s.genomes) do
			total = total + 1
			if g.fitness ~= 0 then
				measured = measured + 1
			end
		end
	end
	if not forms.ischecked(hideBanner) then
		gui.drawText(0, 0, "Gen " .. pool.generation .. " species " ..
				pool.currentSpecies .. " genome " .. pool.currentGenome ..
				" (" .. math.floor(measured/total*100) .. "%)", 0xFF000000, 11)
		gui.drawText(0, 12, "Fitness: " ..
				math.floor(rightmost - (pool.currentFrame) / 2 - (timeout + timeoutBonus)*2/3), 0xFF000000, 11)
		gui.drawText(100, 12, " Max Fitness: " .. math.floor(pool.maxFitness), 0xFF000000, 11)
	end

	pool.currentFrame = pool.currentFrame + 1
	emu.frameadvance();
end