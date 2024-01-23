-- NEAT ML/AI program designed to be used with Bizhawk emulator
-- Created by Lionel Bergen
local FileUtil = require('util/FileUtil')
local Logger = require('util.Logger')
local GameHandler = require('util/bizhawk/GameHandler')
local Neat = require('machinelearning/ai/Neat')
local Mario = require('util.bizhawk.rom.super_mario_usa.Mario')
local Validator = require('../util/Validator')
local MathUtil = require('util.MathUtil')
local Display = require('display.Display')

local rom = Mario
local saveFileName = 'SMW.state'
local poolFileNamePrefix = 'SuperMario_ML_pools'
local poolFileNamePostfix = poolFileNamePrefix .. ".json"
local machineLearningProjectName = 'Mario_testing'
local poolSavesFolder = FileUtil.getCurrentDirectory() ..
		'\\..\\machine_learning_outputs\\' .. machineLearningProjectName .. '\\'
local seed = 12345
local LEVEL_COMPLETE_FITNESS_BONUS = 1000
local DEATH_FITNESS_BONUS = 0
local evaluateEveryNthFrame = 1

MathUtil.init(seed)

---@type Neat
local neatMLAI = Neat:new()

-- You can use https://jscolor.com/ to find colours
-- Used for the top bar overlay that displays the gen, speciies etc.
local topOverlayBackgroundColor = 0xD0FFFFFF

-- this is the Programs 'view'
local programViewWidth = 13
local programViewHeight = 13
local inputSizeWithoutBiasNode = (programViewWidth * programViewHeight)
local outputSize = #rom.getButtonOutputs()

local TimeoutConstant = 20
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
	---@type Pool
	local pool = neatMLAI.pool
	---@type Genome
	local genome = pool:getCurrentGenome()

	if (pool.currentFrame % evaluateEveryNthFrame) == 0 then
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
		local fitness = rightmost - (pool.currentFrame / 2)

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

	if forms.ischecked(showNetwork) then
		Display.displayGenome(genome, programViewWidth, programViewHeight,
				rom.getButtonOutputs(), forms.ischecked(showMutationRates))
	end

	if not forms.ischecked(hideBanner) then
		gui.drawBox(0, 0, 300, 32, topOverlayBackgroundColor, topOverlayBackgroundColor)

		gui.drawText(0, 0, "Gen " .. pool.generation .. " species " ..
				pool.currentSpecies .. " genome " .. pool.currentGenome ..
				" (" .. math.floor(measured/total*100) .. "%)", 0xFF000000, 11)
		gui.drawText(0, 12, "Fitness: " ..
				math.floor(rightmost - (pool.currentFrame) / 2 - (timeout + timeoutBonus)*2/3), 0xFF000000, 11)
		gui.drawText(100, 12, " Max Fitness: " .. math.floor(pool.maxFitness), 0xFF000000, 11)

		gui.drawText(0, 24, "timeout bonus: " .. timeoutBonus, 0xFF000000, 11)
		gui.drawText(150, 24, "timeout: " .. timeout, 0xFF000000, 11)
	end

	pool.currentFrame = pool.currentFrame + 1
	emu.frameadvance();
end