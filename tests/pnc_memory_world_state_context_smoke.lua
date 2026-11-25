local T = require "tests/support/test"

T.addPackagePaths()

local nowMs = 50000
isClient = function() return false end
isServer = function() return true end
getGameTime = function()
    return {
        getWorldAgeDaysSinceBegin = function() return 20 end,
        getWorldAgeHours = function() return 480 end,
        getTimeOfDay = function() return 14 end,
    }
end
getClimateManager = function()
    return {
        isRaining = function() return false end,
        getRainIntensity = function() return 0 end,
        getFogIntensity = function() return 0 end,
        isSnowing = function() return false end,
        getTemperature = function() return 20 end,
    }
end
getSandboxOptions = function()
    return {
        doesPowerGridExist = function() return false end,
        getElecShutModifier = function() return 14 end,
        getWaterShutModifier = function() return 14 end,
    }
end
getWorld = function()
    return { isHydroPowerOn = function() return false end }
end

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.RuntimeRole = { AllowsServerCode = function() return true end }
PsychopatzCore.ScopedWorldEvents = {
    AggregateEffects = function()
        return {
            effects = { foodScarcity = true },
            events = { { eventID = "ev_food_1", type = "food_crisis" } },
        }
    end,
}

PNC = {
    Core = { Now = function() return nowMs end },
    Relationships = {
        Get = function(npcID, targetKey)
            if npcID == "npc_farmer" and targetKey == "player:Pat" then
                return {
                    state = "friendly",
                    approval = 25,
                    trust = 20,
                    identityTrust = "trusted",
                    memories = {
                        { type = "protected_from_attacker" },
                        { type = "treated_wound" },
                    },
                }
            end
            return nil
        end,
    },
}

local BC = require "PNC/Semantics/PNC_SemanticBeatContext"
local Catalog = require "PNC/ConvoEngine/Dialogue/ResponseCatalog"
local Lexicon = require "PNC/ConvoEngine/Lexicon"
require("PNC/ConvoEngine/ConvoDSL/ConvoDSL").EnsureActiveLanguage()

-- 1. Working farmer NPC in a settlement with food crisis, power out, and rescue memory
local farmer = {
    id = "npc_farmer",
    name = "Clara Vance",
    alive = true,
    factionID = "fac_1",
    settlementID = "set_1",
    settlementName = "Riverside Camp",
    currentJob = "farming",
    knowledge = { latestGossipTopic = "raiders_north" },
}
local player = { isPlayer = true, getUsername = function() return "Pat" end }

local ctx = BC.Build(farmer, player, { now = nowMs, partnerKey = "player:Pat", addresseeIsPlayer = true })
local flat = BC.FlattenForSpeech(ctx)

T.equal(flat.memSavedMe, true, "protected_from_attacker memory plumbed")
T.equal(flat.memTreatedMe, true, "treated_wound memory plumbed")
T.equal(flat.memBetrayed, false, "no betrayal memory")
T.equal(flat.worldPowerOff, true, "power shutoff plumbed")
T.equal(flat.worldWaterOff, true, "water shutoff plumbed")
T.equal(flat.worldFoodCrisis, true, "scoped world event food_crisis plumbed")
T.equal(flat.worldHasEvent, true, "worldHasEvent plumbed")
T.equal(flat.knowHasGossip, true, "NPC gossip flag plumbed")
T.equal(flat.placeInSettlement, true, "settlement flag plumbed")
T.equal(flat.stateWorking, true, "working state plumbed")
T.equal(flat.stateJob, "farming", "farming job ID plumbed")
T.equal(ctx.tokens["state.job"], "tending the crops", "human-readable job label token")
T.equal(ctx.tokens["place.name"], "Riverside Camp", "settlement name token")

-- 2. Selecting semantic.question.activity for working farmer produces grounded answer mentioning job + settlement + food crisis!
local sel = Catalog.Select("semantic.question.activity", flat, "s1")
T.truthy(sel ~= nil, "activity variant selected")
local spoken = Lexicon.Expand(sel.fallback, flat, ctx.tokens, { salt = "s1" })
T.truthy(string.find(spoken, "tending the crops", 1, true) ~= nil, "NPC mentions specific job: " .. spoken)
T.truthy(string.find(spoken, "Riverside Camp", 1, true) ~= nil, "NPC mentions settlement: " .. spoken)
T.truthy(string.find(spoken, "food", 1, true) ~= nil or string.find(spoken, "Supplies", 1, true) ~= nil,
    "NPC weaves active food_crisis world event into answer: " .. spoken)

-- 3. Sitting NPC answers specifically that they are sitting down
local sitter = {
    id = "npc_sitter",
    name = "Marcus Hale",
    alive = true,
    posture = "sitting",
}
local ctxSit = BC.Build(sitter, player, { now = nowMs + 100, partnerKey = "player:Pat", addresseeIsPlayer = true })
local flatSit = BC.FlattenForSpeech(ctxSit)
T.equal(flatSit.stateSitting, true, "sitting posture plumbed")
local selSit = Catalog.Select("semantic.question.activity", flatSit, "s2")
local spokenSit = Lexicon.Expand(selSit.fallback, flatSit, ctxSit.tokens, { salt = "s2" })
T.truthy(string.find(string.lower(spokenSit), "sitting", 1, true) ~= nil, "sitting NPC says they are sitting: " .. spokenSit)

print("pnc_memory_world_state_context_smoke: ok")
