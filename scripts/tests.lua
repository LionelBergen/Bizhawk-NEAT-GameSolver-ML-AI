local lu = require('luaunit')

-- luacheck: globals fullTestSuite
-- Set so that tests don't exit
fullTestSuite = true

require('tests.util.MathUtilTest')
require('tests.util.GenomeUtilTest')
require('tests.util.bizhawk.GameHandlerTest')
require('tests.machinelearning.ai.model.GeneTest')
require('tests.machinelearning.ai.model.GenomeTest')
require('tests.machinelearning.ai.NeatTest')
require('tests.machinelearning.ai.NetworkTest')
require('tests.machinelearning.ai.PoolTest')
require('tests.display.DisplayTest')

os.exit(lu.LuaUnit.run())