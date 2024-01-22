local ErrorHandler = {}
local Logger = require('util.Logger')

function ErrorHandler.error(error)
    Logger.error(error)
    error(error)
end

return ErrorHandler