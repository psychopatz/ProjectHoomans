local T = require "tests/support/test"
T.addPackagePaths()

PNC = {}
local FactionEvents = require "PNC/Core/Factions/PNC_FactionEvents"
T.falsy(PNC.Factions, "event vocabulary loaded authoritative faction state")
local EventBus = require "PsychopatzCore/Events/PC_EventBus"
local function copy(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for key, child in pairs(value) do out[key] = copy(child) end
    return out
end
local first = { id = "first", status = "active", revision = 1, relations = {} }
local second = { id = "second", status = "active", revision = 1, relations = {} }
first.relations.second = { state = "neutral", revision = 1 }
second.relations.first = { state = "neutral", revision = 1 }
local authority, registryRevision, phase = true, 0, "initial"
local Internal = {
    authority = function() return authority end,
    copy = copy,
    relationPair = function() return first, second end,
    currentRelation = function(faction, id) return faction.relations[id] end,
    appendAudit = function() end,
    touchFaction = function(faction) faction.revision = faction.revision + 1 end,
    touchRegistry = function() registryRevision = registryRevision + 1 end,
    reconcilePair = function() phase = "reconciled" end,
}
local Factions = { Internal = Internal, EnsureLoaded = function() end }
PNC.Factions = Factions
PNC.Core = {}
PNC.FactionTypes = {
    AreEqual = function(a, b) return a.state == b.state and a.revision == b.revision end,
}
PNC.FactionDiplomacyMath = { ResolveState = function(relation) return relation.state end }
T.load("ProjectHoomans", "server",
    "PNC/Factions/FactionService/PNC_FactionService_TreatyMutation.lua")
local mutateTreaty = Internal.mutateTreaty

local publications, loads = {}, 0
local Adapter = {
    Load = function() loads = loads + 1 end,
    Save = function() end,
    PublishIncident = function(a, b, kind, result, at)
        T.equal(phase, "reconciled", "fact arrived before faction commit")
        T.truthy(registryRevision > 0, "fact arrived before registry revision")
        publications[#publications + 1] = {
            first = a, second = b, kind = kind, relation = result.relation, at = at,
        }
    end,
}
PNC.WorldKnowledge = Adapter
-- The bridge may use public faction methods, but cannot inspect private state.
PNC.Factions = setmetatable({}, { __index = function(_, key)
    T.falsy(key == "Internal", "Knowledge accessed faction internals")
    return Factions[key]
end })
T.load("ProjectHoomans", "server", "PNC/WorldKnowledge/PNC_WorldKnowledge_Server.lua")
PNC.Factions = Factions
T.equal(Internal.mutateTreaty, mutateTreaty, "Knowledge replaced the owner mutation")
T.equal(EventBus.getListenerCount(FactionEvents.TREATY_CHANGED), 1)

local options = { worldAgeHours = 200 }
local function war(forward, reverse)
    forward.state, reverse.state = "hostile", "hostile"
    return true
end
local ok, reason, relation = mutateTreaty("first", "second", "war", options, war)
T.truthy(ok)
T.equal(reason, "war")
T.equal(relation.state, "hostile")
T.equal(#publications, 1)
T.equal(publications[1].first, "first")
T.equal(publications[1].second, "second")
T.equal(publications[1].kind, "war")
T.equal(publications[1].at, 200)
T.falsy(publications[1].relation == first.relations.second,
    "fact exposed canonical mutable relation")
ok, reason = mutateTreaty("first", "second", "war", options, war)
T.falsy(ok)
T.equal(reason, "unchanged")
T.equal(#publications, 1, "unchanged treaty announced a fact")
ok, reason = mutateTreaty("first", "second", "rejected", options,
    function() return false, "rejected" end)
T.falsy(ok)
T.equal(reason, "rejected")
authority = false
ok, reason = mutateTreaty("first", "second", "war", options, war)
T.falsy(ok)
T.equal(reason, "not_authority")
T.equal(#publications, 1, "rejected mutation announced a fact")

authority = true
local errors = 0
EventBus.onListenerError = function() errors = errors + 1 end
EventBus.subscribe(FactionEvents.TREATY_CHANGED,
    function() error("observer unavailable") end, "failure-test")
ok, reason, relation = mutateTreaty("first", "second", "peace", options,
    function(forward, reverse)
        forward.state, reverse.state = "friendly", "friendly"
        return true
    end)
T.truthy(ok, "observer failure changed committed mutation")
T.equal(reason, "peace")
T.equal(relation.state, "friendly")
T.equal(errors, 1)
T.equal(#publications, 2)
T.load("ProjectHoomans", "server", "PNC/WorldKnowledge/PNC_WorldKnowledge_Server.lua")
T.equal(loads, 1)
T.equal(EventBus.getListenerCount(FactionEvents.TREATY_CHANGED), 2,
    "bridge reinitialization duplicated its subscription")
T.finish("pnc_faction_treaty_fact_event_smoke")
