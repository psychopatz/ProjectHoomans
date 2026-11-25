-- Smoke test for PatienceTracker, redundant commands, annoyance escalation,
-- mood resolution, and mood/annoyance-driven .convo pool realization.

local T = require "tests/support/test"
T.addPackagePaths()

isClient = function() return false end
isServer = function() return true end
getGameTime = function()
    return {
        getWorldAgeDaysSinceBegin = function() return 10 end,
        getWorldAgeHours = function() return 240 end,
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
        getElecShutModifier = function() return 30 end,
        getWaterShutModifier = function() return 30 end,
        doesPowerGridExist = function() return true end,
    }
end

require "PNC/ConvoEngine/PatienceTracker"
require "PNC/ConvoEngine/TokenFormatter"
require "PNC/ConvoEngine/Lexicon"
require "PNC/ConvoEngine/OfferRealizer"
require "PNC/ConvoEngine/Dialogue/ResponseCatalog"
require("PNC/ConvoEngine/ConvoDSL/ConvoDSL").EnsureActiveLanguage()
require "PNC/Semantics/PNC_SemanticBeatContext"

local Patience = PNC.ConvoEngine.PatienceTracker
local Catalog = PNC.ConvoEngine.ResponseCatalog
local Lex = PNC.ConvoEngine.Lexicon
local Offers = PNC.ConvoEngine.OfferRealizer
local BC = PNC.Semantics.BeatContext

-- 1. Redundant command detection from live orderKind (independent of previousAction)
T.equal(Patience.IsRedundantCommand("FOLLOW", "follow"), true, "FOLLOW while following is redundant")
T.equal(Patience.IsRedundantCommand("FOLLOW", "stay"), false, "FOLLOW while staying is not redundant")
T.equal(Patience.IsRedundantCommand("STAY", "guard"), true, "STAY while guarding is redundant")
T.equal(Patience.IsRedundantCommand("STAY", "follow"), false, "STAY while following is not redundant")
T.equal(Patience.IsRedundantCommand("CAMP", "camp"), true, "CAMP while camping is redundant")
T.equal(Patience.IsRedundantCommand("STOP", "none"), true, "STOP while idle is redundant")

-- 2. Annoyance escalation, personality scaling, apology cooldown, and time decay
Patience.Reset()
local t0 = 10000

local p1 = Patience.RecordTurn("npc_1", "player:a", {
    now = t0, intentKey = "FOLLOW", redundantCommand = true,
})
T.equal(p1.level, "mild", "1st redundant command reaches mild")
T.equal(p1.repeatCount, 1, "repeatCount is 1")

local p2 = Patience.RecordTurn("npc_1", "player:a", {
    now = t0 + 5000, intentKey = "FOLLOW", redundantCommand = true,
})
T.equal(p2.annoyed, true, "2nd redundant command makes NPC annoyed")
T.equal(p2.repeatCount, 2, "repeatCount is 2")

local p3 = Patience.RecordTurn("npc_1", "player:a", {
    now = t0 + 10000, intentKey = "FOLLOW", redundantCommand = true, playerRude = true,
})
T.equal(p3.fedUp, true, "3rd redundant + rude reaches fed_up")
T.equal(p3.level, "fed_up", "level is fed_up")

local p4 = Patience.RecordTurn("npc_1", "player:a", {
    now = t0 + 12000, intentKey = "APOLOGY", apology = true,
})
T.truthy(p4.score < p3.score, "apology reduces annoyance score")

local p5 = Patience.Inspect("npc_1", "player:a", t0 + 200000)
T.equal(p5.level, "calm", "annoyance decays back to calm over time")

local pf = Patience.RecordTurn("npc_friendly", "player:a", {
    now = t0, intentKey = "FOLLOW", redundantCommand = true, socialStyle = "friendly",
})
local pa = Patience.RecordTurn("npc_aggro", "player:a", {
    now = t0, intentKey = "FOLLOW", redundantCommand = true, socialStyle = "aggressive",
})
T.truthy(pf.score < pa.score, "friendly NPC loses patience slower than aggressive NPC")

-- 3. Mood resolution from conditionStats, needs, moods, and patience
T.equal(Patience.ResolveMood({ conditionStats = { panic = 70 } }).primary, "panicked", "high panic -> panicked")
T.equal(Patience.ResolveMood({ conditionStats = { pain = 60 } }).primary, "in_pain", "high pain -> in_pain")
T.equal(Patience.ResolveMood({ needs = { boredom = 0.75 } }).primary, "bored", "high boredom -> bored")
T.equal(Patience.ResolveMood({ needs = { hunger = 0.80 } }).primary, "hungry", "high hunger -> hungry")
T.equal(Patience.ResolveMood({ socialStyle = "friendly", conditionStats = { stress = 0.05 } }).primary, "cheerful", "friendly + calm -> cheerful")
T.equal(Patience.ResolveMood({}, { level = "fed_up", annoyed = true, fedUp = true, score = 85 }).primary, "fed_up", "fed_up overrides calm mood")

-- 4. .convo pool selection, dynamic offers, BeatContext flattening, and mood lexicon
Patience.Reset()
BC.ResetRuntime()

local vCheer = Catalog.Select("command.follow.redundant", {
    moodCheerful = true, stateAlreadyFollowing = true, npcAnnoyance = "calm",
}, "cheer1")
T.equal(vCheer and vCheer.id, "command.follow.redundant.cheerful", "cheerful redundant follow selected")

local vFed = Catalog.Select("command.follow.redundant", {
    npcFedUp = true, npcAnnoyed = true, npcAnnoyance = "fed_up", stateAlreadyFollowing = true,
}, "fed1")
T.equal(vFed and vFed.id, "command.follow.redundant.fed_up", "fed_up redundant follow selected")

local offers = Offers.BuildForPool("command.follow.redundant", {
    stateAlreadyFollowing = true, npcAnnoyed = true,
})
T.equal(#offers, 2, "offers include switch_stay and sorry_nag when annoyed")

local speaker = {
    id = "npc_follow_ctx",
    orderKind = "follow",
    needs = { boredom = 0.8 },
}
local ctx = BC.Build(speaker, { isPlayer = true, name = "Alex" }, {
    now = 5000, commandAction = "FOLLOW", partnerKey = "player:alex",
})
local flat = BC.FlattenForSpeech(ctx)
T.equal(flat.stateOrderKind, "follow", "BeatContext flattens stateOrderKind")
T.equal(flat.stateAlreadyFollowing, true, "BeatContext flattens stateAlreadyFollowing")
T.equal(flat.commandRedundant, true, "BeatContext flattens commandRedundant")
T.equal(flat.moodPrimary, "bored", "BeatContext flattens moodPrimary")
T.equal(flat.moodBored, true, "BeatContext flattens moodBored")

local vBored = Catalog.Select("semantic.question.activity", flat, "bored1")
T.equal(vBored and vBored.id, "semantic.question.activity.idle_bored", "bored NPC answers activity with bored line")

local expanded = Lex.Expand("{?mood.opener} Right now I'm {state.job}{end}", {
    moodTired = true,
}, { ["state.job"] = "standing guard" }, { salt = "exp1" })
T.truthy(string.find(expanded, "standing guard", 1, true) ~= nil, "expanded line keeps job label: " .. tostring(expanded))

print("pnc_patience_mood_redundant_command_smoke: ok")
