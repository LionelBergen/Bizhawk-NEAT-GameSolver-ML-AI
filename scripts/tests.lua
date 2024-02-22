local lu = require('lib.luaunit')

-- luacheck: globals fullTestSuite
-- Set so that tests don't exit
fullTestSuite = true

require('tests.display.DisplayTest')
require('tests.machinelearning.ai.model.GeneTest')
require('tests.machinelearning.ai.model.GenomeTest')
require('tests.machinelearning.ai.NeatTest')
require('tests.machinelearning.ai.NetworkTest')
require('tests.machinelearning.ai.PoolTest')
require('tests.util.bizhawk.GameHandlerTest')
require('tests.util.GenomeUtilTest')
require('tests.util.MathUtilTest')

os.exit(lu.LuaUnit.run())