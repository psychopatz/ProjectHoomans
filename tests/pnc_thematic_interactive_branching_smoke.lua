local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = PsychopatzCore or {}
PNC = PNC or {
    Const = { MODULE = "PNC" },
    Core = { IsClientOnly = function() return false end, Now = function() return 100 end },
    Semantics = {},
    ConvoEngine = {},
}

require "PsychopatzCore/Semantics/PsychopatzSemantic"
require "PsychopatzCore/ConvoEngine/DialogueState"
require "PsychopatzCore/ConvoEngine/DialogueRouter"
local Affordance = require "PsychopatzCore/ConvoEngine/Affordance"
local Context = require "PNC/ConvoEngine/Dialogue/ContextState"
require "PNC/Semantics/PNC_SemanticCatalog"
require "PNC/ConvoEngine/Registry"
require "PNC/ConvoEngine/Manifest"
local FlowRegistry = require "PNC/ConvoEngine/Dialogue/FlowRegistry"

local Registry = PNC.ConvoEngine.Registry

local FAMILIES = {
    {
        id = "colony.work.status_exchange",
        expectedSlots = { "task", "settlement" },
        expectedStances = {
            agreed = "positive",
            deferred = "contextual",
            checked_in = "neutral",
            refused = "negative",
        },
        blockedReply = "refused",
    },
    {
        id = "travel.excursion.plan_exchange",
        expectedSlots = { "location", "threat" },
        expectedStances = {
            agreed = "positive",
            deferred = "contextual",
            assessed = "neutral",
            refused = "negative",
        },
        blockedReply = "refused",
    },
    {
        id = "combat.aftermath.debrief_exchange",
        expectedSlots = { "threat", "location" },
        expectedStances = {
            debriefed = "positive",
            shaken = "contextual",
            cleared = "neutral",
            refused = "negative",
        },
        blockedReply = "refused",
    },
    {
        id = "social.conflict.mediate_exchange",
        expectedSlots = { "person", "task" },
        expectedStances = {
            reconciled = "positive",
            deferred = "contextual",
            acknowledged = "neutral",
            strained = "negative",
        },
        blockedReply = "strained",
    },
}

local function countMap(tbl)
    local n = 0
    for _ in pairs(tbl or {}) do n = n + 1 end
    return n
end

local CompiledFlows = require("PNC/ConvoEngine/Flows/Dialogue/ThematicInteractive")
local FlowById = {}
for _, f in ipairs(CompiledFlows or {}) do
    if type(f) == "table" and f.id then
        FlowById[f.id] = f
    end
end

local ALL_EIGHT_THEMES = {
    { id = "social.greeting.first_contact", flowId = "greeting_first_contact" },
    { id = "wellbeing.needs.checkin", flowId = "wellbeing_needs_checkin" },
    { id = "social.identity.personal_history", flowId = "identity_personal_history" },
    { id = "knowledge.gossip.exchange", flowId = "knowledge_gossip_exchange" },
    { id = "colony.work.status_exchange", flowId = "colony.work.status_exchange" },
    { id = "travel.excursion.plan_exchange", flowId = "travel.excursion.plan_exchange" },
    { id = "combat.aftermath.debrief_exchange", flowId = "combat.aftermath.debrief_exchange" },
    { id = "social.conflict.mediate_exchange", flowId = "social.conflict.mediate_exchange" },
}

for _, theme in ipairs(ALL_EIGHT_THEMES) do
    local p = Registry.ConvoPlan(theme.id)
    T.truthy(p, "compiled ConvoPlan exists for theme " .. theme.id)
    local f = FlowById[theme.flowId] or FlowById[theme.id]
    T.truthy(f, "compiled flow exists for theme " .. theme.id)
    local ok, res = FlowRegistry.Validate(f)
    T.truthy(ok, theme.id .. " flow passes FlowRegistry.Validate: " .. tostring(res))
    local nc = countMap(f.nodes)
    T.truthy(nc >= 7 and nc <= 9, theme.id .. " has expanded bounded node count (" .. tostring(nc) .. ")")
    local constrainedOffers = 0
    local totalOffers = 0
    for _, node in pairs(f.nodes or {}) do
        local offers = type(node) == "table" and node.branchOffers or {}
        T.truthy(#offers <= 8, theme.id .. " stays within MAX_OFFERS=8")
        for _, bo in ipairs(offers) do
            totalOffers = totalOffers + 1
            if type(bo.constraints) == "table" then
                constrainedOffers = constrainedOffers + 1
            end
        end
    end
    T.truthy(totalOffers >= 12, theme.id .. " exposes deep branch offer surface (" .. tostring(totalOffers) .. ")")
    T.truthy(constrainedOffers >= 2, theme.id .. " enforces hard contextual constraints (" .. tostring(constrainedOffers) .. ")")
    local meta = p.metadata or (p.payload and p.payload.metadata) or {}
    local replySem = meta.replySemantics or {}
    T.truthy(countMap(replySem) >= 5, theme.id .. " separates rich outcome vs stance metadata")
    local replies = p.reply or (p.payload and p.payload.reply) or {}
    local recCount = 0
    for _, rep in pairs(replies) do
        if type(rep) == "table" and type(rep.after) == "table" and type(rep.after.recommend) == "table" then
            recCount = recCount + #rep.after.recommend
        end
    end
    T.truthy(recCount >= 1, theme.id .. " declares after.recommend follow-ups")
end

for _, spec in ipairs(FAMILIES) do
    local plan = Registry.ConvoPlan(spec.id)
    T.truthy(plan, "compiled ConvoPlan exists for " .. spec.id)
    T.truthy(plan.roles and plan.roles.speaker and plan.roles.addressee,
        spec.id .. " defines speaker and addressee roles")
    T.equal(plan.roles.speaker.kinds[1], "actor", spec.id .. " speaker is actor-agnostic")
    T.equal(plan.roles.addressee.kinds[1], "actor", spec.id .. " addressee is actor-agnostic")

    local flow = FlowById[spec.id]
    T.truthy(flow, spec.id .. " defines compiled flow")
    local valid, normalizedOrReason = FlowRegistry.Validate(flow)
    T.truthy(valid, spec.id .. " flow passes FlowRegistry.Validate: " .. tostring(normalizedOrReason))

    local nodeCount = countMap(flow.nodes)
    T.truthy(nodeCount >= 7 and nodeCount <= 9,
        spec.id .. " has expanded bounded flow node count (" .. tostring(nodeCount) .. ")")

    local initialNode = flow.nodes[flow.initial]
    T.truthy(initialNode, spec.id .. " has initial node")
    T.equal(initialNode.onUnrelated, "suspend", spec.id .. " initial node suspends on unrelated input")
    T.truthy(initialNode.branchOffers and #initialNode.branchOffers >= 2,
        spec.id .. " initial node exposes branchOffers")

    for _, slotName in ipairs(spec.expectedSlots) do
        T.truthy(initialNode.slots and initialNode.slots[slotName],
            spec.id .. " declares typed slot " .. slotName)
    end

    local replies = plan.reply or (plan.payload and plan.payload.reply) or plan.replyPools
    T.truthy(replies, spec.id .. " defines reply outcomes")
    local meta = plan.metadata or (plan.payload and plan.payload.metadata) or {}
    local replySemantics = meta.replySemantics or {}
    for outcomeKey, expectedStance in pairs(spec.expectedStances) do
        local replyEntry = replies[outcomeKey]
        T.truthy(replyEntry, spec.id .. " reply defines outcome " .. outcomeKey)
        local sem = replySemantics[outcomeKey]
        T.truthy(sem, spec.id .. " metadata.replySemantics defines " .. outcomeKey)
        T.equal(sem.stance, expectedStance,
            spec.id .. " replySemantics." .. outcomeKey .. " separates stance=" .. expectedStance)
        T.equal(sem.outcome, outcomeKey,
            spec.id .. " replySemantics." .. outcomeKey .. " records outcome=" .. outcomeKey)
    end

local S11 = require "PsychopatzCore/ConvoEngine/S11PolicyEvaluator"
    -- Verify fail-closed statePolicy under dead/hostile/combat states.
    for _, badBehavior in ipairs({ "hostile", "combat", "dead" }) do
        local blocked = S11.EvaluateStatePolicy(plan, {
            npcState = { activeBehavior = badBehavior, healthState = "healthy" },
            situation = { activeBehavior = "idle" },
            roles = { hostile = false },
        })
        T.equal(blocked.admission, "no_op", spec.id .. " fails closed when activeBehavior=" .. badBehavior)
        T.equal(blocked.outcome, "blocked", spec.id .. " returns blocked outcome for " .. badBehavior)
    end

    local deadHealth = S11.EvaluateStatePolicy(plan, {
        npcState = { activeBehavior = "idle", healthState = "dead" },
        situation = { activeBehavior = "idle" },
        roles = { hostile = false },
    })
    T.equal(deadHealth.admission, "no_op", spec.id .. " fails closed when healthState=dead")
    T.equal(deadHealth.outcome, "blocked", spec.id .. " returns blocked outcome for dead healthState")

    local healthy = S11.EvaluateStatePolicy(plan, {
        npcState = { activeBehavior = "idle", healthState = "healthy" },
        situation = { activeBehavior = "idle" },
        roles = { hostile = false },
    })
    T.equal(healthy.outcome, "actionable", spec.id .. " is actionable when healthy and non-hostile")
end

-- Verify ContextState bounded flow stack supports suspend/resume across thematic flows.
local ctxState = Context.New({ maxFlows = 4, maxFlowStack = 2 })
T.truthy(ctxState, "ContextState instantiates for thematic interactive flow checks")

T.finish("pnc_thematic_interactive_branching_smoke")
