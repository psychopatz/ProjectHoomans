-- Harness knowledge adapter composition root.
-- Keep this module path stable for SemanticAdapters and worker callers.

local Provider = {}
Provider.productionQuestRequest = nil

local configureWorldKnowledge = require
    "worker/SemanticAdapters_Knowledge_World"
local configureRuntime = require
    "worker/SemanticAdapters_Knowledge_Runtime"
local configureCognition = require
    "worker/SemanticAdapters_Knowledge_Cognition"
local configureCommands = require
    "worker/SemanticAdapters_Knowledge_Commands"
local configureQuest = require
    "worker/SemanticAdapters_Knowledge_Quest"

function Provider.configure(deps)
    configureWorldKnowledge(deps)
    configureRuntime(deps, Provider)
    configureCognition(deps)
    configureCommands(deps)
    configureQuest(deps, Provider)
end

return Provider
