local MLAIGaming = {}

FileUtil = require('../util/FileUtil')

-- function MLAIGaming::

-- Load a save game from the relative path specified
function MLAIGaming.loadSavedGame(fileLocation)
	local currentDir = FileUtil.getCurrentDirectory()
	local fullFilePath = currentDir .. "\\" ..fileLocation
	FileUtil.validateFilePath(fullFilePath)
	
	savestate.load(fullFilePath)
	console.log('loaded save game from file.')
end

-- Loads the latest pool file, based on the number. E.G 'back.40.restofname.pool'
function MLAIGaming.loadLatestBackup(poolSavesFolder)
	local listOfAllPoolFiles = FileUtil.scandir(poolSavesFolder)
	local latestBackupNumber = -1
	local latestBackupFile

	for key, value in pairs(listOfAllPoolFiles) do
		res = value.match(value, [[backup.(%d+)]])
		
		if res ~= nil and latestBackupNumber < tonumber(res) then
			latestBackupNumber = tonumber(res)
			latestBackupFile = value
		end
		console.log(res)
	end
	
	if latestBackupFile ~= null then
		console.log('attempting to load file for pool...: ' .. latestBackupFile)
		loadFile(poolSavesFolder .. latestBackupFile)
		console.log('loaded backfile: ' .. latestBackupFile)
	else 
		console.log('No backup file to load from. looked in directory: ' .. poolSavesFolder .. ' will continue new program')
	end
end


return MLAIGaming