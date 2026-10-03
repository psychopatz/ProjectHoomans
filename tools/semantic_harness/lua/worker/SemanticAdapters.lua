-- Harness implementations of the production semantic/network boundaries.
-- Keep this path stable: ScenarioSession and worker.lua require it directly.

local SemanticAdapters = {}
local Identity = require "worker/SemanticAdapters_Identity"
local Core = require "worker/SemanticAdapters_Core"
local Transport = require "worker/SemanticAdapters_Transport"
local Knowledge = require "worker/SemanticAdapters_Knowledge"

Identity.install(SemanticAdapters)

function SemanticAdapters.configure(context)
    local deps = Core.configure(context, SemanticAdapters)
    Transport.configure(deps)
    Knowledge.configure(deps)
end

return SemanticAdapters
