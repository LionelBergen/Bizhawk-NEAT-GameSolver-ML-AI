local ErrorHandler = {}
local Logger = require('util.Logger')

function ErrorHandler.error(errorMessage)
    -- Print the message along with stacktrace
    Logger.error(errorMessage)

    -- Throw the error
    error(errorMessage)
end

return ErrorHandler