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

T.finish("pnc_convo_dsl_branching_story_smoke")
print("pnc_convo_dsl_branching_story_smoke: ok")
