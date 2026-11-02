-- Smoke test for Project Hoomans additive semantic pack and action provider adoption.
-- Verifies:
-- 1. pack.projecthoomans.social_core registers into PsychopatzCore Semantics.
-- 2. Capability isolation: DT-only actor never receives Hoomans actions (Follow, Camp, Guard, etc.).
-- 3. Hoomans companion actor receives Hoomans actions according to its capabilities.
-- 4. Dialogue block resolution through Core Semantics fallback.

local T = require "tests/support/test"
T.addPackagePaths()

-- Set up minimal Lua environment
local CORE_ROOT = "/home/psychopatz/Zomboid/Workshop/psychopatzCore/Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = CORE_ROOT .. "?.lua;" .. package.path

local DT_ROOT = "/home/psychopatz/Zomboid/Workshop/DynamicTrading/Contents/mods/DTCommon/42.20/media/lua/shared/"
package.path = DT_ROOT .. "?.lua;" .. package.path

local HOOMANS_ROOT = "/home/psychopatz/Zomboid/Workshop/ProjectHoomans/Contents/mods/ProjectHoomans/42.20/media/lua/shared/"
package.path = HOOMANS_ROOT .. "?.lua;" .. package.path

-- Load Core Semantics
require "PsychopatzCore/Actors/PsychopatzSocial"
require "PsychopatzCore/Semantics/PsychopatzSemanticDialogueFlow"
require "PsychopatzCore/Semantics/PsychopatzSemanticPackRegistry"
require "PsychopatzCore/Semantics/PsychopatzSemantic"

-- Load DT Semantic Pack
require "DTCommon/DTCommon_SemanticPack"

-- Load Hoomans Conversation Selector and Pack
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.Registry = {
    SCHEMA_VERSION = 1,
    ListBlocks = function(filter) return {} end,
    GetCategory = function(id) return nil end,
}
PNC.Conversation.Rules = {
    MatchesAudience = function() return true end,
    CheckRepeat = function() return true end,
    EvaluateAll = function() return true end,
}

require "PNC/Conversation/Blocks/PNC_ConversationSelector"
require "PNC/Semantics/PNC_CoreSemanticPack"

local CoreSemantics = PsychopatzCore.Semantics
local HoomansPack = PNC.Semantics.CoreSemanticPack

-- 1. Verify pack registration
T.truthy(HoomansPack, "Hoomans semantic pack module loaded")
local ok, err = HoomansPack.Register(PsychopatzCore)
T.truthy(ok, "Hoomans pack registered: " .. tostring(err))

local pack = CoreSemantics.GetPack("pack.projecthoomans.social_core")
T.truthy(pack, "pack.projecthoomans.social_core retrieved from Core")
T.equal(pack.id, "pack.projecthoomans.social_core", "id matches")

-- 2. Capability Isolation: DT-Only Actor
-- A trader with only dynamictrading capabilities
local dtContext = {
    actorID = "dt_trader_bob",
    capabilities = {
        ["dynamictrading.trade"] = true,
        ["dynamictrading.merchant"] = true,
    },
    traderRole = "merchant",
    isCompanion = false,
    relationship = { approval = 50, familiarity = 40 },
}

local dtActions = CoreSemantics.CollectActions(dtContext)
T.truthy(#dtActions > 0, "DT actor has collected actions")

-- Check that ZERO Hoomans actions leaked into DT actor
for _, action in ipairs(dtActions) do
    T.falsy(string.find(action.id, "hoomans.", 1, true),
        "DT actor must not receive Hoomans action: " .. tostring(action.id))
    T.falsy(action.id == "hoomans.command.follow", "DT cannot follow")
    T.falsy(action.id == "hoomans.command.camp", "DT cannot camp")
    T.falsy(action.id == "hoomans.inventory.inspect", "DT cannot inspect inventory")
end

-- Verify DT trade action is present
local hasTrade = false
for _, action in ipairs(dtActions) do
    if action.id == "dynamictrading.trade" then
        hasTrade = true
        break
    end
end
T.truthy(hasTrade, "DT actor has trade action")

-- 3. Hoomans Companion Actor
local companionContext = {
    actorID = "hoomans_npc_alice",
    capabilities = {
        ["hoomans.companion"] = true,
        ["hoomans.command"] = true,
        ["hoomans.inventory"] = true,
        ["hoomans.social"] = true,
    },
    isCompanion = true,
    relationship = { approval = 60, familiarity = 70 },
}

local companionActions = CoreSemantics.CollectActions(companionContext)
T.truthy(#companionActions > 0, "Companion actor has collected actions")

local hasFollow = false
local hasCamp = false
local hasInspect = false
local hasTradeOnCompanion = false

for _, action in ipairs(companionActions) do
    if action.id == "hoomans.command.follow" then hasFollow = true end
    if action.id == "hoomans.command.camp" then hasCamp = true end
    if action.id == "hoomans.inventory.inspect" then hasInspect = true end
    if string.find(action.id, "dynamictrading.", 1, true) then
        hasTradeOnCompanion = true
    end
end

T.truthy(hasFollow, "Companion has follow action")
T.truthy(hasCamp, "Companion has camp action")
T.truthy(hasInspect, "Companion has inventory inspect action")
T.falsy(hasTradeOnCompanion, "Companion without DT capability does not have trade action")

-- 4. Dialogue Block Selection through Selector fallback to Core
local selectorContext = {
    relationship = { approval = 40 },
}
local selectedBlock, meta = PNC.Conversation.Selector.SelectBlock("WELLBEING", selectorContext)
T.truthy(selectedBlock, "Dialogue block selected for WELLBEING via Core fallback")
T.equal(selectedBlock.id, "hoomans_block_wellbeing_good", "Correct block chosen based on approval >= 20")
T.equal(meta.source, "PsychopatzCore.Semantics", "Source provenance is PsychopatzCore.Semantics")

-- Verify gate enforcement: negative approval cannot select wellbeing_good
local hostileContext = {
    relationship = { approval = -50 },
}
local hostileBlock = PNC.Conversation.Selector.SelectBlock("WELLBEING", hostileContext)
T.falsy(hostileBlock, "Approval -50 is rejected by gates (no block eligible)")

local neutralContext = {
    relationship = { approval = 0 },
}
local neutralBlock = PNC.Conversation.Selector.SelectBlock("WELLBEING", neutralContext)
T.truthy(neutralBlock, "Approval 0 selects wellbeing_neutral")
T.equal(neutralBlock.id, "hoomans_block_wellbeing_neutral")

-- 5. Concept & Parser verification
T.truthy(CoreSemantics.Registry.GetConcept("hoomans.concept.companion"), "Concept companion registered")
T.truthy(CoreSemantics.Registry.GetConcept("hoomans.concept.wellbeing"), "Concept wellbeing registered")

local parseFollow = CoreSemantics.Parse("follow me", { capabilities = { ["hoomans.social"] = true } })
T.truthy(parseFollow, "Parses 'follow me'")
T.equal(parseFollow.intent, "COMMAND", "Follow me intent is COMMAND")

local parseRecruit = CoreSemantics.Parse("join me", { capabilities = { ["hoomans.social"] = true } })
T.truthy(parseRecruit, "Parses 'join me'")
T.equal(parseRecruit.intent, "RECRUIT", "Join me intent is RECRUIT")

local parseCamp = CoreSemantics.Parse("make camp", { capabilities = { ["hoomans.social"] = true } })
T.truthy(parseCamp, "Parses 'make camp'")
T.equal(parseCamp.intent, "CAMP", "Make camp intent is CAMP")

local parseWellbeing = CoreSemantics.Parse("how are you", { capabilities = { ["hoomans.social"] = true } })
T.truthy(parseWellbeing, "Parses 'how are you'")
T.equal(parseWellbeing.intent, "ASK_WELLBEING", "How are you intent is ASK_WELLBEING")

T.finish("pnc_core_semantic_adopter_smoke")
