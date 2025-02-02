
-- lua/nquera/init.lua
local query = require("nquera.query")

local M = {}

function M.setup(config)
  query.setup(config)
end

return M
