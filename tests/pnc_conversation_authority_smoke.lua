local T = require "tests/support/test"

local SHARED = T.path("ProjectHoomans", "shared", "")
local SERVER = T.path("ProjectHoomans", "server", "")
local COMMON = T.path("ProjectHoomans", "common_lua", "")
T.addPackagePaths()

local globalData = {}
local sent = {}
local relationshipEffects = 0
local recruitmentCalls = 0
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
        T.path(tostring(modID), "common_mod", path),
        T.path(tostring(modID), "mod", path),
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
    tacticalClass = "neutral",
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

T.load(SHARED .. "PNC/Core/Base/PNC_Constants.lua")
T.load(SHARED .. "PNC/Conversation/Blocks/PNC_ConversationRegistry.lua")
T.load(SHARED .. "PNC/Conversation/Blocks/PNC_ConversationRules.lua")
T.load(SHARED .. "PNC/Conversation/Blocks/PNC_ConversationSelector.lua")
T.load(COMMON .. "PNC/Conversation/Definitions/00_PNC_ConversationDefinitions.lua")
T.load(SERVER .. "PNC/Conversation/PNC_ConversationHistory.lua")
T.load(SERVER .. "PNC/Conversation/PNC_ConversationAuthority.lua")

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
T.equal(pair.useCount, 1, "pair use count")
T.equal(pair.lastOutcomeID, "outcome-a", "pair outcome")
T.equal(History.Check("subject", {
    scope = "pair", cooldownHours = 5,
}, { characterUUID = "character-1", npcID = "npc-1", worldAgeHours = 12 }),
    false, "cooldown blocks early reuse")
T.truthy(History.Check("subject", {
    scope = "pair", cooldownHours = 5,
}, { characterUUID = "character-1", npcID = "npc-1", worldAgeHours = 15 }),
    "cooldown expires")
local scopes = {
    pair = History.BuildKey("pair", "c", "n", "s"),
    character = History.BuildKey("character", "c", "n", "s"),
    npc = History.BuildKey("npc", "c", "n", "s"),
    world = History.BuildKey("world", "c", "n", "s"),
}
T.truthy(scopes.pair ~= scopes.character and scopes.character ~= scopes.npc
    and scopes.npc ~= scopes.world, "history scopes have distinct keys")
T.truthy(History.Save(false), "history persists through ModData")
T.equal(globalData.PNC_ConversationHistory.version, 1, "history schema version")

local fingerprint = Registry.GetFingerprint()
T.truthy(Authority.HandleCategory(player, {
    requestID = "category-1",
    npcID = record.id,
    token = "lease-token",
    categoryID = "projecthoomans:whats_up",
    registryFingerprint = fingerprint,
}), "authoritative category accepted")
local categoryResult = sent[#sent]
T.equal(categoryResult.command, PNC.Const.CMD_CONVERSATION_BLOCK,
    "block response command")
T.equal(categoryResult.payload.success, true, "block response success")
T.truthy(string.find(categoryResult.payload.blockID,
    "projecthoomans:whats_up_", 1, true) == 1,
    "eligible randomized neutral topic selected")
T.truthy(string.sub(categoryResult.payload.blockID, -8) == "_neutral",
    "selected daily topic matches the neutral audience")

T.truthy(Authority.HandleChoice(player, {
    requestID = "choice-1",
    npcID = record.id,
    token = "lease-token",
    blockID = categoryResult.payload.blockID,
    nodeID = "opening",
    choiceID = "detail",
    registryFingerprint = fingerprint,
}), "authoritative choice accepted")
local outcome = sent[#sent]
T.equal(outcome.command, PNC.Const.CMD_CONVERSATION_OUTCOME,
    "outcome response command")
T.equal(outcome.payload.success, true, "outcome success")
T.truthy(outcome.payload.outcomeID == "open"
    or outcome.payload.outcomeID == "guarded",
    "deterministic weighted outcome")
T.equal(outcome.payload.nextNodeID, "details",
    "daily topic enters its authored detail branch")
T.equal(outcome.payload.close, false,
    "built-in subtopic does not close the conversation")
T.equal(outcome.payload.closeReason, nil,
    "non-terminal outcome has no close reason")
T.equal(relationshipEffects, 1, "effect applied exactly once")
local categoryHistory = History.Get(
    "category:projecthoomans:whats_up",
    { scope = "pair" },
    Authority.BuildContext(player, record, "lease-token")
)
T.equal(categoryHistory.useCount, 1, "category use slot advances after commit")

PNC.Recruitment = {
    TryConversation = function(_, _, relationship)
        recruitmentCalls = recruitmentCalls + 1
        T.equal(relationship.approval, 25,
            "recruitment receives current approval")
        return false, "relationship_threshold", {
            eligible = false,
            score = 35,
            threshold = 70,
        }
    end,
}
local recruitFingerprint = Registry.GetFingerprint()
local recruitAccepted, recruitReason = Authority.HandleRecruit(player, {
    requestID = "recruit-1",
    npcID = record.id,
    token = "lease-token",
    registryFingerprint = recruitFingerprint,
})
T.equal(recruitAccepted, false, "insufficient recruit relationship rejected")
T.equal(recruitReason, "relationship_threshold",
    "recruitment reports relationship threshold")
T.equal(recruitmentCalls, 1, "first recruit attempt reaches evaluator")
T.equal(relationshipEffects, 2,
    "rejected recruitment applies its relationship penalty")
T.equal(sent[#sent].payload.relationshipDelta.approval, -2,
    "rejected recruitment lowers approval")
T.equal(sent[#sent].payload.relationshipDelta.respect, -1,
    "rejected recruitment lowers respect")
T.equal(sent[#sent].payload.npcReaction, "declined",
    "genuine recruitment refusal carries an NPC decline reaction")
T.truthy(sent[#sent].payload.responseKey,
    "genuine recruitment refusal carries authored dialogue")
local repeatedRecruit, repeatedRecruitReason = Authority.HandleRecruit(player, {
    requestID = "recruit-2",
    npcID = record.id,
    token = "lease-token",
    registryFingerprint = recruitFingerprint,
})
T.equal(repeatedRecruit, false,
    "repeated insufficient recruit relationship remains rejected")
T.equal(repeatedRecruitReason, "relationship_threshold",
    "repeated recruitment is evaluated instead of cooldown-gated")
T.equal(recruitmentCalls, 2,
    "repeated recruitment reaches evaluator without a time gate")
T.equal(relationshipEffects, 3,
    "each rejected recruitment attempt applies its annoyance penalty")
T.equal(sent[#sent].payload.relationshipDelta.approval, -2,
    "repeated rejection still lowers approval")
T.equal(sent[#sent].payload.relationshipDelta.respect, -1,
    "repeated rejection still lowers respect")
T.equal(sent[#sent].payload.npcReaction, "declined",
    "repeated genuine refusal carries an NPC decline reaction")

local invalidRecruit, invalidRecruitReason = Authority.HandleRecruit(player, {
    requestID = "recruit-invalid-lease",
    npcID = record.id,
    token = "wrong-token",
    registryFingerprint = recruitFingerprint,
})
T.equal(invalidRecruit, false, "invalid recruit lease rejected")
T.equal(invalidRecruitReason, "invalid_lease",
    "invalid recruit lease reports its transport failure")
T.equal(sent[#sent].payload.npcReaction, nil,
    "invalid recruit lease has no NPC decline reaction")
T.equal(sent[#sent].payload.responseKey, nil,
    "invalid recruit lease has no authored NPC refusal")

T.truthy(Authority.HandleChoice(player, {
    requestID = "choice-2",
    npcID = record.id,
    token = "lease-token",
    blockID = categoryResult.payload.blockID,
    nodeID = "details",
    choiceID = "offer_help",
    registryFingerprint = fingerprint,
}), "authoritative branch choice accepted")
local branchOutcome = sent[#sent]
T.equal(branchOutcome.payload.nextNodeID, "followup",
    "daily topic can continue through multiple nodes")
T.equal(relationshipEffects, 4,
    "each committed branch applies its relationship outcome once")

local replayed, replayReason = Authority.HandleChoice(player, {
    requestID = "choice-1",
    npcID = record.id,
    token = "lease-token",
    blockID = categoryResult.payload.blockID,
    nodeID = "opening",
    choiceID = "detail",
    registryFingerprint = fingerprint,
})
T.equal(replayed, false, "replay rejected")
T.equal(replayReason, "replayed_request", "replay rejection reason")
T.equal(relationshipEffects, 4, "replay does not duplicate effect")
T.equal(sent[#sent].payload.success, false, "replay response rejected")

T.truthy(History.Save(false), "daily conversation history saves")
History.Load()
local repeatedDaily, repeatedDailyReason = Authority.HandleCategory(player, {
    requestID = "category-same-day",
    npcID = record.id,
    token = "lease-token",
    categoryID = "projecthoomans:whats_up",
    registryFingerprint = fingerprint,
})
T.equal(repeatedDaily, false,
    "What's Up cannot be triggered twice after save-history reload")
T.equal(repeatedDailyReason, "once_per_day_used",
    "same-day category rejection explains the daily policy")
worldHours = 124
T.truthy(Authority.HandleCategory(player, {
    requestID = "category-next-day",
    npcID = record.id,
    token = "lease-token",
    categoryID = "projecthoomans:whats_up",
    registryFingerprint = fingerprint,
}), "What's Up becomes available after the world day changes")
worldHours = 100

local accepted, reason = Authority.HandleCategory(player, {
    requestID = "category-forged",
    npcID = record.id,
    token = "wrong-token",
    categoryID = "projecthoomans:whats_up",
    registryFingerprint = fingerprint,
})
T.equal(accepted, false, "forged lease rejected")
T.equal(reason, "invalid_lease", "forged lease reason")
T.equal(sent[#sent].payload.npcID, record.id,
    "rejection identifies the conversation for client recovery")

accepted, reason = Authority.HandleCategory(player, {
    requestID = "category-mismatch",
    npcID = record.id,
    token = "lease-token",
    categoryID = "projecthoomans:whats_up",
    registryFingerprint = "wrong",
})
T.equal(accepted, false, "registry mismatch rejected")
T.equal(reason, "registry_mismatch", "registry mismatch reason")
T.equal(sent[#sent].payload.npcID, record.id,
    "registry rejection identifies the active conversation")

record.runtime.conversationLease.conversationState = nil
local missingState, missingStateReason = Authority.HandleChoice(player, {
    requestID = "choice-missing-state",
    npcID = record.id,
    token = "lease-token",
    blockID = categoryResult.payload.blockID,
    nodeID = "opening",
    choiceID = "detail",
    registryFingerprint = fingerprint,
})
T.equal(missingState, false,
    "choice without server conversation state was not rejected")
T.equal(missingStateReason, "conversation_state_missing",
    "missing conversation state reported the wrong reason")
T.equal(sent[#sent].payload.success, false,
    "missing conversation state did not return a client outcome")

T.finish("pnc_conversation_authority_smoke")

T.finish("pnc_conversation_authority_smoke")
