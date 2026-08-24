if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NPCKnowledge = PNC.NPCKnowledge or {}
PNC.NPCKnowledge.Internal = PNC.NPCKnowledge.Internal or {}

local Knowledge = PNC.NPCKnowledge
local Internal = Knowledge.Internal
local Core = PNC.Core
local Registry = PNC.Registry
local PlayerCharacters = PNC.PlayerCharacters
local Relationships = PNC.Relationships
local EntityRef = PNC.EntityRef
local Definitions = PNC.KnowledgeDescriptors
local Providers = PNC.KnowledgeProviders
local Resolvers = PNC.KnowledgeResolvers
local Sources = PNC.KnowledgeEvidenceSources
local Shared = PNC.KnowledgeRegistry


local KEY = "PNC_NPCKnowledge"
local SCHEMA = 1
local MAX_EVIDENCE_PER_NPC = 64
local MAX_EVIDENCE_PER_DESCRIPTOR = 16
local MAX_JOURNAL = 64
local MAX_MANUAL_NOTES = 16
local MAX_MANUAL_LENGTH = 512

Knowledge.Registry = Knowledge.Registry or { schemaVersion = SCHEMA, byCharacter = {}, revision = 0 }
Knowledge.Loaded = Knowledge.Loaded == true
Knowledge.Dirty = Knowledge.Dirty == true

local function now(value)
    value = tonumber(value)
    if value ~= nil then return math.max(0, value) end
    local time = getGameTime and getGameTime() or nil
    return time and time.getWorldAgeHours and math.max(0, tonumber(time:getWorldAgeHours()) or 0) or 0
end

local function deepCopy(value)
    if Core and Core.DeepCopy then return Core.DeepCopy(value) end
    if type(value) ~= "table" then return value end
    local out = {}
    for key, item in pairs(value) do out[key] = deepCopy(item) end
    return out
end

local function validID(value)
    return Shared and Shared.IsID and Shared.IsID(value)
end

local function safeString(value, limit)
    if type(value) ~= "string" or value == "" or #value > (limit or 128)
        or string.find(value, "%c") then return nil end
    return value
end

-- Knowledge is keyed by the persistent player-character UUID, never by a
-- transient IsoPlayer instance or username.  Lifecycle callbacks normally
-- establish this binding first, but client commands can race those callbacks
-- during single-player startup and multiplayer reconnects.  Resolve it at the
-- authoritative boundary and commit a newly recovered/created identity before
-- storing knowledge under it.
local function characterUUIDForPlayer(player, callback)
    if not PNC.PlayerContext or not PNC.PlayerContext.Resolve then
        return nil, "character_identity_service_unavailable"
    end
    local context, reason = PNC.PlayerContext.Resolve(
        player, callback or "npc_knowledge"
    )
    if not context then
        return nil, reason or "character_identity_unavailable"
    end
    return context.characterUUID
end


Internal.now = now
Internal.deepCopy = deepCopy
Internal.validID = validID
Internal.safeString = safeString
Internal.characterUUIDForPlayer = characterUUIDForPlayer
Internal.KEY = KEY
Internal.SCHEMA = SCHEMA
Internal.MAX_EVIDENCE_PER_NPC = MAX_EVIDENCE_PER_NPC
Internal.MAX_EVIDENCE_PER_DESCRIPTOR = MAX_EVIDENCE_PER_DESCRIPTOR
Internal.MAX_JOURNAL = MAX_JOURNAL
Internal.MAX_MANUAL_NOTES = MAX_MANUAL_NOTES
Internal.MAX_MANUAL_LENGTH = MAX_MANUAL_LENGTH

return Knowledge
