-- Ordered entry point for authored social response pools.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Catalog = PNC.ConvoEngine.ResponseCatalog
if type(Catalog) ~= "table" or type(Catalog.Register) ~= "function" then
    return false
end

require "PNC/ConvoEngine/ResponseCatalog/Social_Core"
require "PNC/ConvoEngine/ResponseCatalog/Social_WorldEvent_Core"
require "PNC/ConvoEngine/ResponseCatalog/CompanionCommands"
require "PNC/ConvoEngine/ResponseCatalog/CombatKill_Core"
require "PNC/ConvoEngine/ResponseCatalog/Social_Conflict"
require "PNC/ConvoEngine/ResponseCatalog/Social_Reactions"
require "PNC/ConvoEngine/ResponseCatalog/Medical"

return true
