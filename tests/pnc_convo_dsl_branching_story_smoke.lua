local T = require "tests/support/test"

T.addPackagePaths()

local Catalog = require "PNC/ConvoEngine/Dialogue/ResponseCatalog"
local FlowRegistry = require "PNC/ConvoEngine/Dialogue/FlowRegistry"
local ConvoDSL = require "PNC/ConvoEngine/ConvoDSL/ConvoDSL"

local diag = ConvoDSL.Reload("EN")
T.equal(#diag.errors, 0, "zero errors loading EN ConvoBlocks + stories: " .. table.concat(diag.errors, "; "))
T.truthy((diag.storyCount or 0) >= 2, "registered at least 2 pilot .convo stories")

-- 1. Gate-based branching story: convo.weather_context
local weatherFlow = FlowRegistry.Get("convo.weather_context")
T.truthy(weatherFlow ~= nil, "convo.weather_context registered in FlowRegistry")
T.equal(weatherFlow.initial, "weather_gate", "initial node is weather_gate")
local gateNode = weatherFlow.nodes.weather_gate
T.truthy(gateNode and gateNode.gate, "weather_gate has compiled gate")
T.equal(gateNode.gate.type, "pnc:weather", "env.raining compiled to pnc:weather gate")
T.equal(gateNode.gate.field, "raining", "gate field is raining")
T.equal(gateNode.onPass, "raining", "onPass -> raining")
T.equal(gateNode.onFail, "clear", "onFail -> clear")
T.equal(gateNode.onUnknown, "unknown", "onUnknown -> unknown")
T.equal(weatherFlow.nodes.raining.responsePool, "semantic.flow.weather.raining", "explicit pool preserved")

-- 2. Multi-step choice story + multi-line `say` variants: convo.travel_excursion
local excFlow = FlowRegistry.Get("convo.travel_excursion")
T.truthy(excFlow ~= nil, "convo.travel_excursion registered in FlowRegistry")
T.equal(excFlow.initial, "propose_route", "initial node is propose_route")
local propNode = excFlow.nodes.propose_route
T.equal(propNode.responsePool, "story.convo.travel_excursion.propose_route", "node pool auto-registered")
local propPool = Catalog.Get(propNode.responsePool)
T.truthy(propPool and #propPool.variants == 2, "multi-line say block produced 2 variants")
T.equal(#propNode.branchOffers, 3, "3 branchOffers compiled from choices")
T.equal(#propNode.accepts, 3, "3 accepts frames auto-derived from choices")
T.equal(propNode.onMatch, "assess_risk", "onMatch wired to assess_risk")
T.equal(propNode.onClarify, "assess_hazard_intel", "onClarify wired to assess_hazard_intel")
T.equal(propNode.onRefuse, "called_off", "onRefuse wired to called_off")
T.equal(propNode.onUnrelated, "suspend", "onUnrelated wired to suspend")

local meta = ConvoDSL.StoryMetadata["convo.travel_excursion"]
T.truthy(meta ~= nil, "story metadata recorded")
T.equal(meta.guards[1], "safe_to_talk", "guard preset recorded")
T.equal(meta.recommends.assess_risk[1], "combat.aftermath.debrief_exchange", "terminal recommend recorded")

-- 3. `extend story` non-destructively adds a community choice + node
local extScript, extErr = ConvoDSL.ParseText([[
lang EN
namespace hoomans
pack community_weather_hold

extend story convo.travel_excursion
  node propose_route
    choice warn_storm -> postponed:
      label: "Propose weather hold"
      say: "Visibility is zero. Wait until it clears?"
      intent: DEFER
      subject: ROUTE

  node postponed terminal
    say [default]:
      "Good idea, {term.address}. We'll wait out the storm."
      "Better to wait for clear skies, {term.address}."
    recommend wellbeing.needs.checkin
]], "community_weather_hold.convo", "EN")
T.truthy(extScript ~= nil, "extend story parsed cleanly: " .. tostring(extErr))
ConvoDSL.ApplyScripts({ extScript }, "EN")

local updatedFlow = FlowRegistry.Get("convo.travel_excursion")
T.equal(#updatedFlow.nodes.propose_route.branchOffers, 4, "extend story appended 4th choice")
T.truthy(updatedFlow.nodes.postponed and updatedFlow.nodes.postponed.terminal == true, "extend story added terminal node")
local postPool = Catalog.Get("story.convo.travel_excursion.postponed")
T.truthy(postPool and #postPool.variants == 2, "extended node multi-line say registered 2 variants")

-- 4. Nested scripting story: convo.camp_rest_break (`say` -> `choice 1` -> nested `choice 1a`/`1b` + `do`)
local campFlow = FlowRegistry.Get("convo.camp_rest_break")
T.truthy(campFlow ~= nil, "convo.camp_rest_break registered in FlowRegistry")
T.equal(campFlow.initial, "start", "direct say under story auto-created start node")
T.equal(#campFlow.nodes.start.branchOffers, 3, "start node compiled 3 top-level choices")
T.truthy(campFlow.nodes.c1 ~= nil and campFlow.nodes.c1.terminal == false, "choice 1 auto-created non-terminal child node c1")
T.equal(#campFlow.nodes.c1.branchOffers, 2, "nested choice 1a and 1b compiled under c1")
T.truthy(campFlow.nodes.c1_c1a ~= nil and campFlow.nodes.c1_c1a.terminal == true, "nested choice 1a auto-created terminal node c1_c1a")
T.truthy(campFlow.nodes.c1_c1b ~= nil and campFlow.nodes.c1_c1b.terminal == true, "nested choice 1b auto-created terminal node c1_c1b")

local campMeta = ConvoDSL.StoryMetadata["convo.camp_rest_break"]
T.truthy(campMeta and type(campMeta.actions.c1) == "table" and #campMeta.actions.c1 == 2, "do camp + do relationship.trust +1 recorded on c1")
T.equal(campMeta.actions.c1[1].capability, "camp", "first action is camp")
T.equal(campMeta.actions.c1[2].capability, "relationship.trust", "second effect is relationship.trust")
T.equal(campMeta.actions.c1[2].delta, 1, "trust delta parsed as +1")
T.equal(campMeta.actions.c1_c1a[1].capability, "medical.check_wounds", "nested choice 1a recorded medical.check_wounds")

-- 5. Interactive branching gossip stories (media, radio, world) + autonomous NPC choice reuse
local OfferRealizer = require "PNC/ConvoEngine/OfferRealizer"
local mediaFlow = FlowRegistry.Get("convo.gossip.media")
local radioFlow = FlowRegistry.Get("convo.gossip.radio")
local worldFlow = FlowRegistry.Get("convo.gossip.world")
T.truthy(mediaFlow ~= nil and #mediaFlow.nodes.start.branchOffers == 4, "convo.gossip.media has 4 choices (pos/neu/neg/tactical)")
local warmPosReaction = ConvoDSL.ResolveReaction("convo.gossip.media", "cpositive", { socialStyle = "warm" })
T.truthy(warmPosReaction ~= nil and warmPosReaction.followUpOffers ~= nil and #warmPosReaction.followUpOffers == 2,
    "media positive warm reaction nests 2 bonding follow-up choices")
local coldPosReaction = ConvoDSL.ResolveReaction("convo.gossip.media", "cpositive", { speakerStyle = "cold" })
T.truthy(coldPosReaction ~= nil and coldPosReaction.terminal == true,
    "media positive cold reaction stays restrained and terminal")
T.truthy(radioFlow ~= nil and #radioFlow.nodes.start.branchOffers == 5, "convo.gossip.radio has 5 choices (pos/neu/neg/tactical/trader)")
T.truthy(worldFlow ~= nil and #worldFlow.nodes.start.branchOffers == 4, "convo.gossip.world has 4 choices (pos/neu/neg/protective)")

-- 7. Asymmetric personality reactions on the SAME choice (`convo.gossip.media` -> `cnegative`)
local tacReaction = ConvoDSL.ResolveReaction("convo.gossip.media", "cnegative", { speakerStyle = "tactical" })
T.truthy(tacReaction ~= nil and string.find(tacReaction.line, "Power's too precious", 1, true) ~= nil,
    "tactical NPC respects pragmatic pushback")
T.equal(tacReaction.actions[1].capability, "relationship.respect", "tactical NPC gains respect on negative pushback")
T.equal(tacReaction.actions[1].delta, 3, "tactical NPC respect delta is +3")
T.equal(tacReaction.actions[4].capability, "guard_perimeter", "tactical NPC shifts to guard_perimeter")

local warmReaction = ConvoDSL.ResolveReaction("convo.gossip.media", "cnegative", { socialStyle = "warm" })
T.truthy(warmReaction ~= nil and string.find(warmReaction.line, "pretty cold", 1, true) ~= nil,
    "warm NPC feels stung by the exact same negative pushback")
T.equal(warmReaction.actions[1].capability, "relationship.approval", "warm NPC loses approval")
T.equal(warmReaction.actions[1].delta, -3, "warm NPC approval delta is -3")

local stressedAggReaction = ConvoDSL.ResolveReaction("convo.gossip.media", "cnegative", {
    speakerStyle = "aggressive",
    moodStressed = true,
})
T.truthy(stressedAggReaction ~= nil and string.find(stressedAggReaction.line, "Nobody asked", 1, true) ~= nil,
    "stressed aggressive NPC snaps back and opens conflict escalation branch")
T.equal(stressedAggReaction.actions[1].delta, -4, "stressed aggressive NPC approval delta is -4")
T.truthy(stressedAggReaction.followUpOffers ~= nil and #stressedAggReaction.followUpOffers == 2,
    "conflict reaction unlocks 2 follow-up choices (deescalate vs double_down)")

-- 8. NPC<->NPC autonomous conflict vs de-escalation on the exact same follow-up choices
local forgivingPick = OfferRealizer.PickAutonomous(stressedAggReaction.followUpOffers, {
    forgiveness = 0.95, compassion = 0.9, aggression = 0.1, bravery = 0.3,
}, {}, { deterministic = true })
T.equal(forgivingPick.id, "convo.gossip.media.deescalate", "forgiving NPC autonomously de-escalates conflict")

local hotheadPick = OfferRealizer.PickAutonomous(stressedAggReaction.followUpOffers, {
    forgiveness = 0.1, compassion = 0.1, aggression = 0.95, bravery = 0.9,
}, { relationshipState = "rival" }, { deterministic = true })
T.equal(hotheadPick.id, "convo.gossip.media.double_down", "aggressive rival NPC autonomously doubles down into conflict")

-- 9. Banded personality context projection + trader materialism reaction
local traderCtx = ConvoDSL.ProjectPersonalityContext({ materialism = 0.85, sociability = 0.7 }, {})
T.equal(traderCtx.personalityMaterialism, "high", "ProjectPersonalityContext bands 0.85 materialism to high")
local traderReaction = ConvoDSL.ResolveReaction("convo.gossip.radio", "ctrader", traderCtx)
T.truthy(traderReaction ~= nil and string.find(traderReaction.line, "Now you're talking", 1, true) ~= nil,
    "high-materialism listener responds enthusiastically to trader radio angle")
T.equal(traderReaction.actions[3].capability, "trade", "trader reaction triggers trade action")

-- 10. Autonomous NPCs reuse the exact same gossip blueprints & traits!
local tacticalOffers = OfferRealizer.BuildForPool("semantic.gossip.world.opening", { speakerStyle = "tactical" }, {}, { maxOffers = 10 })
local hasTactical = false
for i = 1, #tacticalOffers do
    if tacticalOffers[i].id == "gossip.stance.tactical" then hasTactical = true end
end
T.truthy(hasTactical, "tactical NPC unlocks specialized gossip.stance.tactical choice")

local warmNPC = OfferRealizer.PickAutonomous(tacticalOffers, {
    compassion = 0.95, sociability = 0.9, bravery = 0.2, aggression = 0.1,
}, { socialStyle = "warm", relationshipState = "friend" }, { deterministic = true })
T.equal(warmNPC.id, "gossip.stance.positive", "compassionate friend NPC autonomously picks positive gossip stance")

local aggressiveNPC = OfferRealizer.PickAutonomous(tacticalOffers, {
    compassion = 0.1, sociability = 0.2, bravery = 0.9, aggression = 0.95,
}, { moodStressed = true, relationshipState = "rival" }, { deterministic = true })
T.equal(aggressiveNPC.id, "gossip.stance.negative_dismiss", "stressed aggressive rival NPC autonomously picks negative dismiss stance")

-- Seeded weighted roll (CK3-style) returns a valid eligible offer deterministically for a given seed
local seeded1 = OfferRealizer.PickAutonomous(tacticalOffers, {
    compassion = 0.9, sociability = 0.85, bravery = 0.3, aggression = 0.1,
}, { socialStyle = "warm" }, { seed = "npc_a:npc_b:day3" })
local seeded2 = OfferRealizer.PickAutonomous(tacticalOffers, {
    compassion = 0.9, sociability = 0.85, bravery = 0.3, aggression = 0.1,
}, { socialStyle = "warm" }, { seed = "npc_a:npc_b:day3" })
T.truthy(seeded1 ~= nil and seeded1.id == seeded2.id, "seeded weighted pick is deterministic for the same seed")

T.finish("pnc_convo_dsl_branching_story_smoke")
print("pnc_convo_dsl_branching_story_smoke: ok")
