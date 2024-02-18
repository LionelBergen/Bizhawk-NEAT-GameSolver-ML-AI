-- NEAT ML/AI program designed to be used with Bizhawk emulator
-- Created by Lionel Bergen
local FileUtil = require('util/FileUtil')
local ErrorHandler = require('util.ErrorHandler')
local Logger = require('util.Logger')
local GameHandler = require('util/bizhawk/GameHandler')
local Neat = require('machinelearning/ai/Neat')
local Mario = require('util.bizhawk.rom.super_mario_usa.Mario')
local Validator = require('../util/Validator')
local MathUtil = require('util.MathUtil')
local Display = require('display.Display')
local Forms = require('util.bizhawk.wrapper.Forms')
local GenerationResults = require('machinelearning.ai.model.record.GenerationResults')
local PropertiesSnapshot = require('machinelearning.ai.model.record.PropertiesSnapshot')

---@type Mario
local rom = Mario
local saveFileName = 'SMW.state'
local poolFileNamePrefix = 'SuperMario_ML_pools'
local poolFileNamePostfix = poolFileNamePrefix .. ".json"
local machineLearningProjectName = 'Mario_testing'
local machineLearningProgramRunName = 'never_stale'
local poolSavesFolder = FileUtil.getCurrentDirectory() ..
		'\\..\\machine_learning_outputs\\' .. machineLearningProjectName .. '\\'
local results_save_file_name = machineLearningProgramRunName .. '_results_'
local properties_save_file_name = machineLearningProgramRunName .. '_properties_'
local seed = 12345
local LEVEL_COMPLETE_FITNESS_BONUS = 1000
local DEATH_FITNESS_BONUS = 0
local evaluateEveryNthFrame = 1
local saveSnapshotEveryNthGeneration = 6

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
local currentBackup = 0

-- Declare variables that are defined in Bizhawk already.
-- This is just to satisfy LuaCheck, to make it easier to find actual issues
-- luacheck: globals forms joypad gui emu event gameinfo

---@type Form
local form = Forms.createNewForm(500, 500, "NEAT Program")
local showNetwork = Forms.createCheckbox(form, "SHOW NETWORK:", 5, 30, 148)
local showMutationRates = Forms.createCheckbox(form, "SHOW MUTATION RATES:", 5, 80, 148)
local showBanner = Forms.createCheckbox(form, "SHOW BANNER", 5, 130, 148)
-- local textBoxLoadBackup = Forms.createTextBox(form, "LOAD BACKUP: ", 0, 180, 148)
local Mode = {Manual = 1, Auto = 2}
local mode = Mode.Auto
local controller = {}

if mode == Mode.Manual then
	TimeoutConstant = 200000
end

local function logCurrent()
	Logger.info("Gen " .. neatMLAI.pool.generation .. " species " ..
			neatMLAI.pool.currentSpecies .. " genome " .. neatMLAI.pool.currentGenome
			.. " fitness: " .. neatMLAI.pool:getCurrentGenome().fitness)
end

---@return GenerationResults
local function createGenerationResults()
	---@type GenerationResults
	local generationResults = GenerationResults.create(neatMLAI.pool)

	Logger.info('Generation ' .. generationResults.generation .. ' results: ')
	Logger.info('Number of species: ' .. #generationResults.speciesResults)
	for i, speciesResult in pairs(generationResults.speciesResults) do
		Logger.info('Species ' .. i .. ' Top Fitness: ' ..
				speciesResult.topFitness .. ' Average Fitness: ' .. speciesResult.averageFitness
				.. ' Number Of Genomes: ' .. speciesResult.numberOfGenomes)
	end

	return generationResults
end

---@return PropertiesSnapshot
local function createPropertiesSnapshot()
	local propertiesSnapshot = PropertiesSnapshot.create(neatMLAI)

	return propertiesSnapshot
end

---@param pool Pool
local function saveNewBackup(pool, saveFolderName, filePostfix)
	if mode ~= Mode.Manual then
		local newFileName = saveFolderName .. "backup." .. currentBackup .. "." .. filePostfix
		if FileUtil.fileExists(newFileName) then
			ErrorHandler.error('Backup file already exists!: ' .. newFileName)
		end
		GameHandler.saveFileFromPool(newFileName, pool, { seed = seed, numbersGenerated = MathUtil.getIteration() })
		Logger.info("Saved new backup file: " .. newFileName)
		currentBackup = currentBackup + 1
	end
end

local function transformNetworkOutputs(networkController)
	local newController = {}
	for k, v in pairs(networkController) do
		local newKey = "P1 " .. k

		newController[newKey] = v
	end

	if newController["P1 Left"] and newController["P1 Right"] then
		newController["P1 Left"] = false
		newController["P1 Right"] = false
	end
	if newController["P1 Up"] and newController["P1 Down"] then
		newController["P1 Up"] = false
		newController["P1 Down"] = false
	end

	return newController
end

---@param neatObject Neat
---@param currentGenome Genome
local function evaluateCurrent(neatObject, currentGenome)
	local inputs = rom.getInputs(programViewWidth, programViewHeight)
	local networkController = neatObject.evaluateNetwork(currentGenome.network, inputs, rom.getButtonOutputs())
	networkController = transformNetworkOutputs(networkController)

	return networkController
end

---@param neatObject Neat
local function initializeRun(neatObject)
	-- Load the state file. State file is a bizhawk file. Example is the beginning of a game level
	GameHandler.loadSavedGame('..\\assets\\savedstates\\' .. saveFileName)
	rightmost = 0
	timeout = TimeoutConstant
	GameHandler.clearJoypad(rom)
	neatObject.pool.currentFrame = 0
	local genome = neatObject:getCurrentGenome()

	neatObject.generateNetwork(genome, inputSizeWithoutBiasNode, outputSize)
	Validator.validatePool(neatObject.pool)
end

---@param neatObject Neat
local function nextGenome(neatObject)
	local pool = neatObject.pool
	pool.currentGenome = pool.currentGenome + 1
	-- if we've reached the end of the genomes for the current species
	if pool.currentGenome > #pool:getCurrentSpecies().genomes then
		pool.currentSpecies = pool.currentSpecies + 1
		pool.currentGenome = 1
		-- if we've reached the end of all species
		if pool.currentSpecies > #pool.species then
			---@type GenerationResults
			local generationResults = createGenerationResults()
			Logger.info('---------------- NEW GENERATION! ------------------------')
			neatObject:newGeneration(inputSizeWithoutBiasNode, outputSize)
			saveNewBackup(pool, poolSavesFolder, poolFileNamePostfix)
			pool.currentSpecies = 1
			pool.currentGenome = 1
			Logger.info('Number of species: ' .. #pool.species
					.. ' number of genomes: ' .. pool:getNumberOfGenomes())

			if pool:getNumberOfGenomes() ~= neatObject.generationStartingPopulation then
				error('new generation produced invalid number of genomes: ' .. pool:getNumberOfGenomes())
			end

			if (pool.generation % saveSnapshotEveryNthGeneration == 0) then
				local propertiesSnapshot = createPropertiesSnapshot()
				GameHandler.saveFileFromPropertiesSnapshot(poolSavesFolder ..
						(properties_save_file_name .. pool.generation .. '.snapshot'), propertiesSnapshot)
				GameHandler.saveFileFromGenerationResults(poolSavesFolder ..
						(results_save_file_name .. pool.generation .. '.snapshot'), generationResults)
			end
		end
	end
end

---@param pool Pool
local function isFitnessMeasured(pool)
	local genome = pool:getCurrentGenome()
	return genome.fitness ~= 0
end

---@param neatObject Neat
local function loadFileAndInitialize(filename, neatObject)
	local pool, additionalFields = GameHandler.loadFromFile(filename)
	neatObject.pool = pool
	MathUtil.reset(additionalFields.seed, additionalFields.numbersGenerated)
	while isFitnessMeasured(neatObject.pool) do
		nextGenome(neatObject)
	end
	initializeRun(neatObject)

	Logger.info('Number of species: ' .. #neatMLAI.pool.species
			.. ' number of genomes: ' .. neatMLAI.pool:getNumberOfGenomes())

	Logger.info('---------------------------    --------------------------    --------------------------------')
	Logger.info('---------------------------    Done LoadFileAndinitialize    --------------------------------')
	Logger.info('---------------------------    --------------------------    --------------------------------')
end

---@param neatObject Neat
local function loadFile(saveFolderName, neatObject)
	local latestBackupFile, backupNumber = GameHandler.getLatestBackupFile(saveFolderName)
	if latestBackupFile ~= nil then
		Logger.debug('attempting to load file for pool: ' .. latestBackupFile)
		loadFileAndInitialize(saveFolderName .. latestBackupFile, neatObject)
		Logger.info('loaded backfile: ' .. latestBackupFile)
		currentBackup = backupNumber + 1
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

-- Set the 'showBanner' checkbox to true
forms.setproperty(showBanner, "Checked", true)

-- Load the latest .pool file
loadFile(poolSavesFolder, neatMLAI)

if neatMLAI.pool == nil then
	neatMLAI:initializePool(inputSizeWithoutBiasNode, outputSize)
	Logger.info('Created new pool since no load file was found. Number of species: '
			.. #neatMLAI.pool.species .. ' number of genomes: ' .. neatMLAI.pool:getNumberOfGenomes())
	if neatMLAI.pool:getNumberOfGenomes() ~= neatMLAI.generationStartingPopulation then
		error('invalid number of genomes: ' .. neatMLAI.pool:getNumberOfGenomes())
	end
end
initializeRun(neatMLAI)

while true do
	---@type Pool
	local pool = neatMLAI.pool
	---@type Genome
	local genome = pool:getCurrentGenome()

	if (pool.currentFrame % evaluateEveryNthFrame) == 0 then
		controller = evaluateCurrent(neatMLAI, genome)
	end

	if mode ~= Mode.Manual then
		joypad.set(controller)
	end
	-- TODO: 'marioX', 'marioY'
	local marioX, _ = rom:getPositions()

	-- if we're moving, reset the timeout.
	if marioX > rightmost then
		rightmost = marioX
		timeout = TimeoutConstant
	end

	if timeout <= 0 or rom:isWin() or rom:isDead() then
		local fitness = rom.calculateFitness(rightmost, pool.currentFrame)

		if rom:isWin() then
			fitness = fitness + LEVEL_COMPLETE_FITNESS_BONUS
			Logger.info("---- WIN! -----")
		elseif rom:isDead() then
			fitness = fitness + DEATH_FITNESS_BONUS
		end

		-- We check if fitness is measured using fitness == 0, so ensure we know fitness has been measured already
		if fitness == 0 then
			fitness = -1
		end

		genome.fitness = fitness
		logCurrent()
		pool.currentSpecies = 1
		pool.currentGenome = 1

		if fitness > pool.maxFitness then
			pool.maxFitness = fitness
			saveNewBackup(pool, poolSavesFolder, poolFileNamePostfix)
		end

		-- set 'currentGenome' to one that isn't measured yet
		while isFitnessMeasured(pool) do
			nextGenome(neatMLAI)
		end
		initializeRun(neatMLAI)
	else
		timeout = timeout - 1
		pool.currentFrame = pool.currentFrame + 1
	end

	if forms.ischecked(showNetwork) then
		Display.displayGenome(genome, programViewWidth, programViewHeight,
				rom.getButtonOutputs(), forms.ischecked(showMutationRates))
	end

	if forms.ischecked(showBanner) then
		gui.drawBox(0, 0, 300, 32, topOverlayBackgroundColor, topOverlayBackgroundColor)

		gui.drawText(0, 0, "Gen " .. pool.generation .. " species " ..
				pool.currentSpecies .. " genome " .. pool.currentGenome, 0xFF000000, 11)
		gui.drawText(0, 12, "Fitness: " .. rom.calculateFitness(rightmost, pool.currentFrame), 0xFF000000, 11)
		gui.drawText(100, 12, " Max Fitness: " .. math.floor(pool.maxFitness), 0xFF000000, 11)
	end
	emu.frameadvance();
end