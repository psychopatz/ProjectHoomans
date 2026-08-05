local SHARED = "Contents/mods/ProjectHoomans/42.20/media/lua/shared/"
local SERVER = "Contents/mods/ProjectHoomans/42.20/media/lua/server/"
local COMMON = "Contents/mods/ProjectHoomans/common/media/lua/shared/"
package.path = SHARED .. "?.lua;" .. SERVER .. "?.lua;"
    .. COMMON .. "?.lua;" .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual), 2)
    end
end
local function truth(value, label) if not value then error(label, 2) end end

local globalData = {}
local sent = {}
local relationshipEffects = 0
local worldHours = 100
Events = {
    OnInitGlobalModData = { Add = function() end },
    OnSave = { Add = function() end },
}
ModData = {
    getOrCreate = function(key)
        globalData[key] = globalData[key] or {}
        return globalData[key]
    end,
}
GlobalModData = { save = function() end }
getGameTime = function()
    return { getWorldAgeHours = function() return worldHours end }
end
getWorld = function() return "authority-world" end
getModFileReader = function(modID, path)
    local candidates = {
        "Contents/mods/" .. tostring(modID) .. "/common/" .. path,
        "Contents/mods/" .. tostring(modID) .. "/42.20/" .. path,
    }
    local file
    for _, candidate in ipairs(candidates) do
        file = io.open(candidate, "r")
        if file then break end
    end
    if not file then return nil end
    return {
        readLine = function() return file:read("*l") end,
        close = function() file:close() end,
    }
end

local player = {
    getUsername = function() return "Tester" end,
    getOnlineID = function() return 7 end,
}
local record = {
    id = "npc-authority",
    faction = "neutral",
    hostility = { attackPlayers = false },
    runtime = {
        conversationLease = {
            token = "lease-token",
            maximumDistance = 6,
            dangerRadius = 8,
        },
    },
    social = { morale = 5 },
}

PNC = {
    Network = {
        Internal = {
            SendToPlayer = function(_, command, payload)
                sent[#sent + 1] = { command = command, payload = payload }
                return true
            end,
        },
    },
    Registry = {
        Get = function(id) return id == record.id and record or nil end,
        GetLiveZombie = function() return {} end,
    },
    PlayerCharacters = {
        GetEntityKey = function() return "player:account:character-1" end,
    },
    EntityRef = {
        Parse = function()
            return { kind = "player", characterUUID = "character-1" }
        end,
    },
    Relationships = {
        Get = function()
            return {
                exists = true,
                approval = 25,
                respect = 20,
                familiarity = 20,
                state = "admire",
            }
        end,
        ApplyConversationEffect = function(_, _, effect)
            relationshipEffects = relationshipEffects + 1
            return true, "applied", effect
        end,
    },
    ConversationScene = {
        Begin = function(_, _, _, token)
            if token ~= "lease-token" then return false, "invalid_lease" end
            return true, record.runtime.conversationLease
        end,
    },
}

dofile(SHARED .. "PNC/Core/Base/PNC_Constants.lua")
dofile(SHARED .. "PNC/Conversation/Blocks/PNC_ConversationRegistry.lua")
dofile(SHARED .. "PNC/Conversation/Blocks/PNC_ConversationRules.lua")
dofile(SHARED .. "PNC/Conversation/Blocks/PNC_ConversationSelector.lua")
dofile(COMMON .. "PNC/Conversation/Definitions/00_PNC_ConversationDefinitions.lua")
dofile(SERVER .. "PNC/Conversation/PNC_ConversationHistory.lua")
dofile(SERVER .. "PNC/Conversation/PNC_ConversationAuthority.lua")

local Registry = PNC.Conversation.Registry
local History = PNC.Conversation.History
local Authority = PNC.Conversation.Authority

History.Load()
local pairContext = {
    characterUUID = "character-1",
    npcID = "npc-1",
    worldAgeHours = 10,
}
History.Commit("subject", { scope = "pair" }, pairContext, "outcome-a")
local pair = History.Get("subject", { scope = "pair" }, pairContext)
equal(pair.useCount, 1, "pair use count")
equal(pair.lastOutcomeID, "outcome-a", "pair outcome")
equal(History.Check("subject", {
    scope = "pair", cooldownHours = 5,
}, { characterUUID = "character-1", npcID = "npc-1", worldAgeHours = 12 }),
    false, "cooldown blocks early reuse")
truth(History.Check("subject", {
    scope = "pair", cooldownHours = 5,
}, { characterUUID = "character-1", npcID = "npc-1", worldAgeHours = 15 }),
    "cooldown expires")
local scopes = {
    pair = History.BuildKey("pair", "c", "n", "s"),
    character = History.BuildKey("character", "c", "n", "s"),
    npc = History.BuildKey("npc", "c", "n", "s"),
    world = History.BuildKey("world", "c", "n", "s"),
}
truth(scopes.pair ~= scopes.character and scopes.character ~= scopes.npc
    and scopes.npc ~= scopes.world, "history scopes have distinct keys")
truth(History.Save(false), "history persists through ModData")
equal(globalData.PNC_ConversationHistory.version, 1, "history schema version")

local fingerprint = Registry.GetFingerprint()
truth(Authority.HandleCategory(player, {
    requestID = "category-1",
    npcID = record.id,
    token = "lease-token",
    categoryID = "projecthoomans:whats_up",
    registryFingerprint = fingerprint,
}), "authoritative category accepted")
local categoryResult = sent[#sent]
equal(categoryResult.command, PNC.Const.CMD_CONVERSATION_BLOCK,
    "block response command")
equal(categoryResult.payload.success, true, "block response success")
equal(categoryResult.payload.blockID,
    "projecthoomans:whats_up_basic_neutral", "eligible neutral block")

truth(Authority.HandleChoice(player, {
    requestID = "choice-1",
    npcID = record.id,
    token = "lease-token",
    blockID = categoryResult.payload.blockID,
    nodeID = "opening",
    choiceID = "situation",
    registryFingerprint = fingerprint,
}), "authoritative choice accepted")
local outcome = sent[#sent]
equal(outcome.command, PNC.Const.CMD_CONVERSATION_OUTCOME,
    "outcome response command")
equal(outcome.payload.success, true, "outcome success")
equal(outcome.payload.outcomeID, "reply", "deterministic outcome")
equal(outcome.payload.nextNodeID, "$root",
    "built-in subtopic returns to the conversation menu")
equal(outcome.payload.close, false,
    "built-in subtopic does not close the conversation")
equal(outcome.payload.closeReason, nil,
    "non-terminal outcome has no close reason")
equal(relationshipEffects, 1, "effect applied exactly once")
local categoryHistory = History.Get(
    "category:projecthoomans:whats_up",
    { scope = "pair" },
    Authority.BuildContext(player, record, "lease-token")
)
equal(categoryHistory.useCount, 1, "category use slot advances after commit")

local replayed, replayReason = Authority.HandleChoice(player, {
    requestID = "choice-1",
    npcID = record.id,
    token = "lease-token",
    blockID = categoryResult.payload.blockID,
    nodeID = "opening",
    choiceID = "situation",
    registryFingerprint = fingerprint,
})
equal(replayed, false, "replay rejected")
equal(replayReason, "replayed_request", "replay rejection reason")
equal(relationshipEffects, 1, "replay does not duplicate effect")
equal(sent[#sent].payload.success, false, "replay response rejected")

local accepted, reason = Authority.HandleCategory(player, {
    requestID = "category-forged",
    npcID = record.id,
    token = "wrong-token",
    categoryID = "projecthoomans:whats_up",
    registryFingerprint = fingerprint,
})
equal(accepted, false, "forged lease rejected")
equal(reason, "invalid_lease", "forged lease reason")
equal(sent[#sent].payload.npcID, record.id,
    "rejection identifies the conversation for client recovery")

accepted, reason = Authority.HandleCategory(player, {
    requestID = "category-mismatch",
    npcID = record.id,
    token = "lease-token",
    categoryID = "projecthoomans:whats_up",
    registryFingerprint = "wrong",
})
equal(accepted, false, "registry mismatch rejected")
equal(reason, "registry_mismatch", "registry mismatch reason")
equal(sent[#sent].payload.npcID, record.id,
    "registry rejection identifies the active conversation")

print("pnc_conversation_authority_smoke: ok")
