local SERVER = "Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/"

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. " expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local saveHook
local globalSaves = 0
local calls = {}

Events = {
    OnSave = {
        Add = function(callback)
            equal(saveHook, nil, "one coordinated save hook")
            saveHook = callback
        end,
    },
}
GlobalModData = {
    save = function() globalSaves = globalSaves + 1 end,
}

local function service(name)
    return {
        Dirty = true,
        Save = function(flushGlobal)
            equal(flushGlobal, false, name .. " defers global flush")
            calls[name] = (calls[name] or 0) + 1
            PNC[name].Dirty = false
            return true, "saved"
        end,
    }
end

PNC = {
    Core = {
        DeepCopy = function(value) return value end,
        Now = function() return 1000 end,
        LogWarn = function(message) error(message) end,
    },
    PlayerCharacterTypes = {
        NormalizeRegistry = function(registry) return registry end,
    },
    Registry = {
        DirtyByID = { npc_one = true },
        DirtyDomains = { npc_one = { test = true } },
        DirectoryDirty = true,
        FlushDirty = function()
            calls.Registry = (calls.Registry or 0) + 1
            return 1
        end,
    },
}
PNC.PlayerCharacters = service("PlayerCharacters")
PNC.PlayerCharacters.Registry = { byUUID = {}, uuidAliases = {} }
PNC.NPCKnowledge = service("NPCKnowledge")
PNC.Factions = service("Factions")
PNC.Communities = service("Communities")
PNC.AbstractWorldStore = service("AbstractWorldStore")
PNC.WorldDiscovery = service("WorldDiscovery")
PNC.Conversation = { History = service("ConversationHistory") }
-- The generic mock looks services up directly on PNC.
PNC.ConversationHistory = PNC.Conversation.History

dofile(SERVER .. "PNC_PersistenceCoordinator.lua")
equal(type(saveHook), "function", "coordinator registers world-save hook")

saveHook()

for _, name in ipairs({
    "PlayerCharacters", "NPCKnowledge", "Factions", "Communities",
    "AbstractWorldStore", "WorldDiscovery", "ConversationHistory",
    "Registry",
}) do
    equal(calls[name], 1, name .. " saved once")
end
equal(globalSaves, 1, "all services share one GlobalModData flush")

print("pnc_world_save_coordinator_smoke: ok")
