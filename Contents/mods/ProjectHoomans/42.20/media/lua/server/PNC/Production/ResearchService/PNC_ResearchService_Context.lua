-- Shared research repository, event, and network helpers.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ResearchService = PNC.ResearchService or {}
PNC.ResearchService.Internal = PNC.ResearchService.Internal or {}

local Service = PNC.ResearchService
local Repository = PNC.ResearchRepository
local RegistryRepository = PNC.KnowledgeRepository
local Registry = PNC.RecipeKnowledgeRegistry
local Definitions = PNC.ColonyResearchDefinitions

Service.Commands = Service.Commands or {}
Service.Queries = Service.Queries or {}
local EventsBus = PsychopatzCore and PsychopatzCore.Events
local EventTypes = PNC.EventTypes or {}

local function emit(eventType, payload)
    if eventType and EventsBus and EventsBus.emit then
        EventsBus.emit(eventType, payload)
    end
end

local function broadcast(colonyId, factionId, delta)
    delta.colonyId, delta.factionId = tostring(colonyId), tostring(factionId or "")
    if not PNC.Network or not PNC.Network.SendColonyKnowledgeDelta then return end
    if isServer and isServer() and getOnlinePlayers then
        local players = getOnlinePlayers()
        for index = 0, players:size() - 1 do
            local player = players:get(index)
            local faction = PNC.Factions and PNC.Factions.GetPlayerFaction
                and PNC.Factions.GetPlayerFaction(player) or nil
            if faction and tostring(faction.id) == delta.factionId then
                PNC.Network.SendColonyKnowledgeDelta(player, delta)
            end
        end
    elseif getSpecificPlayer then
        local player = getSpecificPlayer(0)
        if player then PNC.Network.SendColonyKnowledgeDelta(player, delta) end
    end
end

local function runtime(colonyId)
    Repository.Get(colonyId)
    return Repository.Runtime[tostring(colonyId or "")]
end

local Internal = Service.Internal
Internal.Emit = emit
Internal.Broadcast = broadcast
Internal.Runtime = runtime

return Internal
