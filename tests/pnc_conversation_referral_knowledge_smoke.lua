local T = require "tests/support/test"

local SHARED = T.path("ProjectHoomans", "shared", "PNC/Core/")
local SERVER = T.path("ProjectHoomans", "server", "PNC/")

PNC = {
    Core = {
        GenerateID = (function()
            local id = 0
            return function(prefix)
                id = id + 1
                return tostring(prefix) .. ":" .. tostring(id)
            end
        end)(),
        DeepCopy = function(value)
            if type(value) ~= "table" then return value end
            local output = {}
            for key, item in pairs(value) do
                output[key] = PNC.Core.DeepCopy(item)
            end
            return output
        end,
    },
}
ModData = {
    store = {},
    getOrCreate = function(key)
        ModData.store[key] = ModData.store[key] or {}
        return ModData.store[key]
    end,
}

T.load(SHARED .. "Relationships/PNC_EntityRef.lua")
T.load(SHARED .. "Knowledge/PNC_KnowledgeRegistry.lua")
T.load(SHARED .. "Knowledge/PNC_KnowledgeBuiltins.lua")

local npc = {
    id = "npc_referral_target",
    name = "Rocco Patz",
}
PNC.Registry = {
    Get = function(id)
        return tostring(id) == npc.id and npc or nil
    end,
}
PNC.Identity = {
    GetCharacterSummary = function(record)
        return { displayName = record and record.name }
    end,
}
PNC.PlayerCharacters = {
    GetRegistryRecord = function(uuid)
        return uuid == "char_referral"
            and { accountKey = "smoke", accountIdentity = "smoke" }
            or nil
    end,
    GetCharacterUUID = function() return "char_referral" end,
    EnsureIdentity = function() return "char_referral", "existing_identity" end,
    Save = function() return true end,
}
PNC.PlayerContext = {
    Resolve = function()
        return {
            accountKey = "smoke",
            characterUUID = "char_referral",
            entityKey = "player:smoke:char_referral",
            bindingRevision = 1,
        }
    end,
}
PNC.Relationships = {
    Get = function() return { familiarity = 0, approval = 0 } end,
}

T.load(SERVER .. "Knowledge/PNC_NPCKnowledgeService.lua")
local Knowledge = PNC.NPCKnowledge
local source = PNC.KnowledgeEvidenceSources.Get("conversation_referral")
T.truthy(source, "conversation referral source is registered")
T.equal(source.mayConfirm, true, "referral source can confirm identity")
T.equal(source.bypassDiscovery, true,
    "validated referral bypasses prior identity discovery")

local result, reason = Knowledge.RecordEvidence({
    characterUUID = "char_referral",
    npcID = npc.id,
    descriptorID = "identity.name",
    sourceType = "conversation_referral",
    payload = { observedValue = npc.name },
    worldAgeHours = 100,
})
T.truthy(result, "validated referral evidence is accepted")
T.equal(reason, nil, "accepted referral has no rejection reason")
T.equal(result.evidence.sourceType, "conversation_referral",
    "accepted evidence preserves referral authority")
T.equal(result.discovered.value, npc.name,
    "referral records the authoritative merchant name")
T.equal(result.discovered.status, "confirmed",
    "referral identity is confirmed")

T.finish("pnc_conversation_referral_knowledge_smoke")
