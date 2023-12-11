local GameHandler = {}

FileUtil = require('../util/FileUtil')
Logger = require('../util/Logger')

-- Load a save game from the relative path specified
function GameHandler.loadSavedGame(fileLocation)
	local currentDir = FileUtil.getCurrentDirectory()
	local fullFilePath = currentDir .. "\\" ..fileLocation
	FileUtil.validateFilePath(fullFilePath)
	
	savestate.load(fullFilePath)
	Logger.info('loaded save game from file: ' .. fullFilePath)
end

-- Gets the latest pool file, based on the number. E.G 'back.40.restofname.pool'
function GameHandler.getLatestBackupFile(poolSavesFolder)
	local listOfAllPoolFiles = FileUtil.scandir(poolSavesFolder)
	local latestBackupNumber = -1
	local latestBackupFile

	for key, value in pairs(listOfAllPoolFiles) do
		local res = value.match(value, [[backup.(%d+)]])
		
		if res ~= nil and latestBackupNumber < tonumber(res) then
			latestBackupNumber = tonumber(res)
			latestBackupFile = value
		end
	end
	
	return latestBackupFile
end


return GameHandler