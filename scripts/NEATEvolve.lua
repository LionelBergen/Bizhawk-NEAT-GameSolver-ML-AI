-- NEAT ML/AI program designed to be used with Bizhawk emulator
-- Created by Lionel Bergen
local FileUtil = require('util/FileUtil')
local Logger = require('util.Logger')
local GameHandler = require('util/bizhawk/GameHandler')
local Neat = require('machinelearning/ai/Neat')
local Species = require('machinelearning.ai.model.Species')
local Mario = require('util/bizhawk/rom/Mario')
local Validator = require('../util/Validator')

local MODE = {
	MANUAL = 1,
	AI = 2
}

local mode = MODE.MANUAL

local rom = Mario
local saveFileName = 'SMW.state'
local poolFileNamePrefix = 'SuperMario_ML_pools'
local poolFileNamePostfix = poolFileNamePrefix .. ".pool"
local machineLearningProjectName = 'Mario_testing'
local poolSavesFolder = FileUtil.getCurrentDirectory() ..
		'\\..\\machine_learning_outputs\\' .. machineLearningProjectName .. '\\'

local neatMLAI = Neat:new()

-- You can use https://jscolor.com/ to find colours
-- Used for the top bar overlay that displays the gen, speciies etc.
local topOverlayBackgroundColor = 0xD0FFFFFF

-- this is the Programs 'view'
local ProgramViewBoxRadius = 6
local inputSize = (ProgramViewBoxRadius*2+1)*(ProgramViewBoxRadius*2+1)
inputSize = inputSize + 1
local outputSize = #rom.getButtonOutputs()

local TimeoutConstant = 20
local maxNodes = 1000000
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
local controller = {}

local function saveNewBackup(pool, poolGeneration, saveFolderName, filePostfix)
	local newFileName = saveFolderName .. "backup." .. poolGeneration .. "." .. filePostfix
	GameHandler.saveFileFromPool(newFileName, pool)
end

local function sigmoid(x)
	return 2 / (1 + math.exp(-4.9 * x)) - 1
end

local function evaluateCurrent(neatObject)
	local genome = neatObject:getCurrentGenome()

	local inputs = rom.getInputs(ProgramViewBoxRadius)
	controller = neatObject.evaluateNetwork(genome.network, inputSize, inputs, rom.getButtonOutputs(), maxNodes)

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

local function initializeRun(neatObject)
	-- Load the beginning of a level
	GameHandler.loadSavedGame('..\\assets\\savedstates\\' .. saveFileName)
	rightmost = 0
	neatObject.pool.currentFrame = 0
	timeout = TimeoutConstant
	GameHandler.clearJoypad(rom)

	local genome = neatObject:getCurrentGenome()

	neatObject.generateNetwork(genome, inputSize, outputSize, maxNodes)
	Validator.validatePool(neatObject.pool)
	evaluateCurrent(neatObject)
end

local function nextGenome(neatObject)
	local pool = neatObject.pool
	pool.currentGenome = pool.currentGenome + 1
	if pool.currentGenome > #pool.species[pool.currentSpecies].genomes then
		pool.currentGenome = 1
		pool.currentSpecies = pool.currentSpecies + 1
		if pool.currentSpecies > #pool.species then
			neatObject:newGeneration(inputSize, outputSize, maxNodes)
			saveNewBackup(pool, pool.generation, poolSavesFolder, poolFileNamePostfix)
			pool.currentSpecies = 1
		end
	end
end

local function isFitnessMeasured(pool)
	local genome = pool:getCurrentGenome()
	return genome.fitness ~= 0
end

local function displayGenome(genome)
	local network = genome.network
	local cells = {}
	local cell
	local biasCell = {}
	local i = 1
	for dy=-ProgramViewBoxRadius,ProgramViewBoxRadius do
		for dx=-ProgramViewBoxRadius,ProgramViewBoxRadius do
			cell = {}
			cell.x = 50+5 * dx
			cell.y = 70+5 * dy
			cell.value = network.neurons[i].value
			cells[i] = cell
			i = i + 1
		end
	end
	biasCell.x = 80
	biasCell.y = 110
	biasCell.value = network.neurons[inputSize].value
	cells[inputSize] = biasCell

	for o = 1,outputSize do
		cell = {}
		cell.x = 220
		cell.y = 30 + 8 * o
		cell.value = network.neurons[maxNodes + o].value
		cells[maxNodes+o] = cell
		local color
		if cell.value > 0 then
			color = 0xFF0000FF
		else
			color = 0xFF000000
		end
		gui.drawText(223, 24+8*o, rom.getButtonOutputs()[o], color, 9)
	end

	for n,neuron in pairs(network.neurons) do
		cell = {}
		if n > inputSize and n <= maxNodes then
			cell.x = 140
			cell.y = 40
			cell.value = neuron.value
			cells[n] = cell
		end
	end

	for _=1,4 do
		for _,gene in pairs(genome.genes) do
			if gene.enabled then
				local c1 = cells[gene.into]
				local c2 = cells[gene.out]
				if gene.into > inputSize and gene.into <= maxNodes then
					c1.x = 0.75*c1.x + 0.25*c2.x
					if c1.x >= c2.x then
						c1.x = c1.x - 40
					end
					if c1.x < 90 then
						c1.x = 90
					end

					if c1.x > 220 then
						c1.x = 220
					end
					c1.y = 0.75*c1.y + 0.25*c2.y

				end
				if gene.out > inputSize and gene.out <= maxNodes then
					c2.x = 0.25*c1.x + 0.75*c2.x
					if c1.x >= c2.x then
						c2.x = c2.x + 40
					end
					if c2.x < 90 then
						c2.x = 90
					end
					if c2.x > 220 then
						c2.x = 220
					end
					c2.y = 0.25*c1.y + 0.75*c2.y
				end
			end
		end
	end

	gui.drawBox(50-ProgramViewBoxRadius*5-3,
			70-ProgramViewBoxRadius*5-3,
			50+ProgramViewBoxRadius*5+2,
			70+ProgramViewBoxRadius*5+2,0xFF000000,
			0x80808080)
	for n,celln in pairs(cells) do
		if n > inputSize or celln.value ~= 0 then
			local color = math.floor((celln.value+1)/2*256)
			if color > 255 then color = 255 end
			if color < 0 then color = 0 end
			local opacity = 0xFF000000
			if celln.value == 0 then
				opacity = 0x50000000
			end
			color = opacity + color*0x10000 + color*0x100 + color
			if celln.value == 2 then
				color = 0xFF1717FF
			elseif celln.value == 3 then
				color = 0x0F16FFFF
			end
			gui.drawBox(celln.x-2,celln.y-2,celln.x+2,celln.y+2,opacity,color)
		end
	end
	for _,gene in pairs(genome.genes) do
		if gene.enabled then
			local c1 = cells[gene.into]
			local c2 = cells[gene.out]
			local opacity = 0xA0000000
			if c1.value == 0 then
				opacity = 0x20000000
			end

			local color = 0x80-math.floor(math.abs(sigmoid(gene.weight))*0x80)
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
		for mutation,rate in pairs(genome.mutationRates) do
			gui.drawText(100, pos, mutation .. ": " .. rate, 0xFF000000, 10)
			pos = pos + 8
		end
	end
end

local function savePool()
	error('unimplemented')
	--local filename = saveLoadFile
	--writeFile(filename)
end

-- TODO: should pretty much be a function inside Neat; To load a pool/etc from a file
local function loadFile2(filename, neatObject)
	Logger.info('loadfile: ' .. filename)
	local file = io.open(filename, "r")
	local pool = neatObject:createNewPool(outputSize)
	pool.generation = file:read("*number")
	pool.maxFitness = file:read("*number")

	local numSpecies = file:read("*number")
	for _=1,numSpecies do
		local species = Species.new()
		table.insert(pool.species, species)
		species.topFitness = file:read("*number")
		species.staleness = file:read("*number")
		local numGenomes = file:read("*number")
		for _=1,numGenomes do
			local genome = neatObject:createNewGenome()
			table.insert(species.genomes, genome)
			genome.fitness = file:read("*number")
			genome.maxNeuron = file:read("*number")
			local line = file:read("*line")
			while line ~= "done" do
				genome.mutationRates[line] = file:read("*number")
				line = file:read("*line")
			end
			local numGenes = file:read("*number")
			for _=1,numGenes do
				local gene = neatObject:createNewGene()
				table.insert(genome.genes, gene)
				local enabled gene.into, gene.out, gene.weight,
					gene.innovation, enabled =
						file:read("*number", "*number", "*number", "*number", "*number")
				if enabled == 0 then
					gene.enabled = false
				else
					gene.enabled = true
				end
			end
		end
	end
	file:close()

	while isFitnessMeasured(neatObject.pool) do
		nextGenome(neatObject)
	end
	initializeRun(neatObject)
	pool.currentFrame = pool.currentFrame + 1
end

local function loadFile(saveFolderName, neatObject)
	local latestBackupFile = GameHandler.getLatestBackupFile(saveFolderName)
	if latestBackupFile ~= nil then
		Logger.info('attempting to load file for pool...: ' .. latestBackupFile)
		loadFile2(saveFolderName .. latestBackupFile, neatObject)
		Logger.info('loaded backfile: ' .. latestBackupFile)
	else
		Logger.info('No backup file to load from. looked in directory: ' .. saveFolderName .. ' will continue new program')
	end
end

local function loadPool()
	error('unimplemented')
	--local filename = saveLoadFile
	--loadFile(filename)
end

local function playTop(pool)
	Logger.info('playTop')
	local maxfitness = 0
	local maxs, maxg
	for s,species in pairs(pool.species) do
		for g,genome in pairs(species.genomes) do
			if genome.fitness > maxfitness then
				maxfitness = genome.fitness
				maxs = s
				maxg = g
			end
		end
	end

	pool.currentSpecies = maxs
	pool.currentGenome = maxg
	pool.maxFitness = maxfitness
	forms.settext(maxFitnessLabel, "Max Fitness: " .. math.floor(pool.maxFitness))
	initializeRun()
	pool.currentFrame = pool.currentFrame + 1
	return
end

local function onExit()
	forms.destroy(form)
end

if gameinfo.getromname() ~= rom.getRomName() then
	error('Unsupported Game Rom! Please play rom: ' .. rom.getRomName() .. ' Rom currently is: ' .. gameinfo.getromname())
end

local debugMessage = nil
local function debug(message)
	if type(message) == 'string' then
		if string.len(message) > 50 then
			debugMessage = string.sub(message, 0, 20) .. '\n' .. string.sub(message, 20)
		else
			debugMessage = message
		end
	end
end
Logger.setDebugFunction(debug)


Logger.info('starting Mar I/O...')

-- set exit function to destroy the form
event.onexit(onExit)

-- Set the 'showNetowrk' checkbox to true, just while we mess around with it
forms.setproperty(showNetwork, "Checked", true)

-- Load the latest .pool file
loadFile(poolSavesFolder, neatMLAI)

if neatMLAI.pool == nil then
	neatMLAI:initializePool(inputSize, outputSize, maxNodes)
end
initializeRun(neatMLAI)
forms.settext(maxFitnessLabel, "Max Fitness: " .. math.floor(neatMLAI.pool.maxFitness))

while true do
	if not forms.ischecked(hideBanner) then
		gui.drawBox(0, 0, 300, 26, topOverlayBackgroundColor, topOverlayBackgroundColor)
	end

	if (mode == MODE.MANUAL) then
		-- debug
		gui.drawBox(0, 200, 300, 600, topOverlayBackgroundColor, 0x80808080)
		gui.drawText(0, 200, debugMessage, 0xFF000000, nil, 10)
	end

	local pool = neatMLAI.pool
	local genome = pool:getCurrentGenome()

	if forms.ischecked(showNetwork) then
		displayGenome(genome)
	end

	if pool.currentFrame%5 == 0 then
		evaluateCurrent(neatMLAI)
	end

	-- TODO: 'controller' shouldnt have to be a class wide local
	joypad.set(controller)
	-- TODO: 'marioX', 'marioY'
	local marioX, _ = rom:getPositions()
	if marioX > rightmost then
		rightmost = marioX
		timeout = TimeoutConstant
	end

	timeout = timeout - 1

	local timeoutBonus = pool.currentFrame / 4
	if timeout + timeoutBonus <= 0 then
		local fitness = rightmost - pool.currentFrame / 2
		Logger.info('fitness: ' .. fitness)

		-- TODO: this is Super Mario USA specific
		if rightmost > 4816 then
			fitness = fitness + 1000
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