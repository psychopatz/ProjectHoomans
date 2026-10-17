local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = {}
PNC = {}

local Semantic = T.load(
    "PsychopatzCore",
    "common",
    "PsychopatzCore/Semantics/PsychopatzSemantic.lua"
)
local Context = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueContextState.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticCatalog.lua"
)
local Registry = require
    "PNC/Semantics/PNC_SemanticDialogueFlowRegistry"
local Policy = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialoguePolicy.lua"
)
local Router = Semantic.DialogueRouter

local function contextFor(contextState, npcID)
    return {
        llmEnabled = false,
        semanticContextState = contextState,
        characterUUID = "player-one",
        npcID = npcID,
    }
end

local valid, reason = Registry.Validate({
    id = "invalid_unreachable",
    version = 1,
    triggers = { { intent = "QUESTION" } },
    initial = "start",
    nodes = {
        start = { terminal = true },
        orphan = { terminal = true },
    },
})
T.falsy(valid, "registry rejects unreachable flow nodes")
T.equal(reason, "unreachable_node:orphan",
    "registry reports the unreachable node")

local unsupported, unsupportedReason = Registry.Validate({
    id = "invalid_frame",
    version = 1,
    triggers = { { unsupported = true } },
    initial = "start",
    nodes = { start = { terminal = true } },
})
T.falsy(unsupported, "registry rejects unsupported trigger fields")
T.equal(unsupportedReason, "flow_trigger_unsupported_field:unsupported",
    "registry explains unsupported trigger fields")

local duplicateFrame, duplicateFrameReason = Registry.Validate({
    id = "invalid_duplicate_frame",
    version = 1,
    triggers = { { intent = "QUESTION" } },
    initial = "start",
    nodes = {
        start = {
            accepts = { { intent = "INFORM" }, { intent = "INFORM" } },
            onMatch = "done",
        },
        done = { terminal = true },
    },
})
T.falsy(duplicateFrame, "registry rejects duplicate node frames")
T.equal(duplicateFrameReason, "duplicate_node_transition:start",
    "registry explains duplicate node frames")

local conflictingOwner = Registry.Validate({
    id = "invalid_slot_owner",
    version = 1,
    triggers = { { intent = "QUESTION" } },
    initial = "start",
    nodes = {
        start = {
            accepts = { { intent = "INFORM" } },
            slots = { value = { type = "string", owner = "one" } },
            onMatch = "done",
        },
        done = {
            terminal = true,
            slots = { value = { type = "string", owner = "two" } },
        },
    },
})
T.falsy(conflictingOwner, "registry rejects conflicting slot owners")

local duplicateRegistered, duplicateReason = Registry.Register(require
    "PNC/Semantics/PNC_SemanticDialogueFlow_Identity")
T.falsy(duplicateRegistered, "registry rejects duplicate flow IDs")
T.equal(duplicateReason, "duplicate_flow_id:identity",
    "registry explains duplicate flow IDs")

local contextState = Context.New({ maxFlows = 4, maxFlowStack = 2 })
local state = Semantic.DialogueState.New({ maxEvents = 8 })
local context = contextFor(contextState, "npc-a")
local router = Router.New({
    policy = Policy,
    state = state,
    context = context,
})

local preview = router:Preview("who are you", context, { timestamp = 1 })
T.truthy(preview.accepted, "flow question previews")
T.equal(preview.decision.flow.transition, "start",
    "preview identifies the identity flow start")
T.equal(#contextState:FlowSnapshot(), 0,
    "preview does not create a flow session")
T.equal(state.sequence, 0, "preview does not record a semantic event")

local first = router:Process("who are you", context, { timestamp = 2 })
T.equal(first.flow.status, "started", "identity flow commits once")
T.equal(first.flow.active.flowId, "identity",
    "identity flow owns the committed session")
T.equal(#contextState:FlowSnapshot(), 1,
    "committed flow is visible in bounded context")

local beforeRepeat = contextState:FlowSnapshot()[1]
local beforeSequence = state.sequence
local repeatOne = router:Preview("are you okay", context, { timestamp = 3 })
local repeatTwo = router:Preview("are you okay", context, { timestamp = 3 })
T.equal(repeatOne.decision.flow.transition, "interrupt_start",
    "preview identifies a bounded interruption")
T.equal(repeatTwo.decision.flow.transition, "interrupt_start",
    "repeated preview remains deterministic")
T.equal(state.sequence, beforeSequence,
    "repeated preview does not record state")
T.equal(contextState:FlowSnapshot()[1].active.flowId,
    beforeRepeat.active.flowId,
    "repeated preview preserves the active flow")
T.equal(#contextState:FlowSnapshot()[1].suspended, 0,
    "repeated preview does not push a suspended flow")

local interruption = router:Process("are you okay", context, { timestamp = 4 })
T.equal(interruption.flow.transition, "interrupt_start",
    "wellbeing question commits as an interruption")
T.equal(interruption.flow.active.flowId, "wellbeing",
    "wellbeing becomes active")
T.equal(interruption.flow.suspended[1].flowId, "identity",
    "identity is suspended per addressee")

local wellbeing = router:Process("im fine thanks", context, { timestamp = 5 })
T.equal(wellbeing.flow.transition, "match",
    "wellbeing answer matches its active node")
T.equal(wellbeing.flow.active.flowId, "identity",
    "identity resumes after wellbeing completes")
T.equal(#wellbeing.flow.suspended, 0,
    "completed wellbeing is removed from the stack")

local identity = router:Process("My name is Patrick", context, { timestamp = 6 })
T.equal(identity.flow.transition, "match",
    "identity claim matches its resumed node")
T.equal(identity.flow.status, "retired",
    "completed identity flow retires its session")
T.equal(#contextState:FlowSnapshot(), 0,
    "completed flow leaves no stale session")

local refusalContextState = Context.New()
local refusalRouter = Router.New({
    policy = Policy,
    state = Semantic.DialogueState.New(),
    context = contextFor(refusalContextState, "npc-refusal"),
})
refusalRouter:Process(
    "are you okay",
    refusalRouter.context,
    { timestamp = 7 }
)
local refusal = refusalRouter:Process(
    "no",
    refusalRouter.context,
    { timestamp = 8 }
)
T.equal(refusal.flow.transition, "cancel",
    "wellbeing refusal is owned by the wellbeing flow module")
T.equal(refusal.flow.status, "retired",
    "refused wellbeing flow retires without a central policy branch")
T.equal(#refusalContextState:FlowSnapshot(), 0,
    "refused wellbeing leaves no flow session")

local sharedContext = Context.New({ maxFlows = 4 })
local routerA = Router.New({
    policy = Policy,
    state = Semantic.DialogueState.New(),
    context = contextFor(sharedContext, "npc-a"),
})
local routerB = Router.New({
    policy = Policy,
    state = Semantic.DialogueState.New(),
    context = contextFor(sharedContext, "npc-b"),
})
routerA:Process("who are you", routerA.context, { timestamp = 7 })
routerB:Process("who are you", routerB.context, { timestamp = 7 })
local sessions = sharedContext:FlowSnapshot()
T.equal(#sessions, 2, "flow sessions are isolated by addressee")
T.equal(sessions[1].key, "player-one|npc-a",
    "first addressee keeps its own flow key")
T.equal(sessions[2].key, "player-one|npc-b",
    "second addressee keeps its own flow key")

T.finish("pnc_semantic_dialogue_flow_smoke")
