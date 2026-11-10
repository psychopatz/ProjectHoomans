-- Removable test-only adopter. No production algorithm or memory store.
local Fixture = {}
local Relations = require "PNC/Semantics/PNC_SemanticInteractionRelations"
local Catalog = require "PNC/Semantics/PNC_SemanticInteractionCatalog"
local Providers = require "PNC/Semantics/PNC_SemanticInteractionProviders"
local Director = require "PNC/Semantics/PNC_SemanticInteractionDirector"
local ContextProjection = require "worker/Conversation_Context"

local definitions = {
    FIXTURE_PROMISE = { opens = { "fixture_commitment" } },
    FIXTURE_FULFILL = { resolves = { "fixture_commitment" } },
    FIXTURE_BREACH = { resolves = { "fixture_commitment" }, opens = { "repair", "fixture_explanation" } },
    FIXTURE_EXPLAIN = { addresses = { "fixture_explanation" } },
    FIXTURE_REPAIR = { addresses = { "repair" } },
}

local function register()
    if Relations.GetAct("FIXTURE_PROMISE") then return end
    Relations.RegisterRelation("fixture_commitment", { direction = "same" })
    Relations.RegisterRelation("fixture_explanation", { direction = "same" })
    for act, relations in pairs(definitions) do
        local ok, reason = Relations.RegisterAct(act, { relations = relations,
            classes = { "future_commitment" }, retentionSalience = 240,
            compactEvent = string.lower(act), longTerm = true })
        assert(ok, reason)
        local registered, registrationReason = PNC.Conversation.Memory.Events.RegisterType(
            Relations.GetCompactType(act))
        assert(registered, registrationReason)
    end
    local ok, reason = Catalog.Behaviors.RegisterDraft({
        id = "behavior.fixture_commitment", version = 1, owner = "SemanticLabFixture",
        act = "ACKNOWLEDGE_FUTURE_MECHANIC", mode = "one_shot", baseRelevance = 0.99,
        stimuli = { "NPC_SEMANTIC_ACT" }, requiredCapabilities = { "speech" },
        when = { all = { { path = "pragmatic.contextualAdmission.admitted", op = "truthy" },
            { any = {
                { path = "stimulus.semantic.intent", op = "eq", value = "FIXTURE_FULFILL" },
                { path = "stimulus.semantic.intent", op = "eq", value = "FIXTURE_BREACH" },
                { path = "stimulus.semantic.intent", op = "eq", value = "FIXTURE_EXPLAIN" },
                { path = "stimulus.semantic.intent", op = "eq", value = "FIXTURE_REPAIR" },
            } } } },
        outputs = { speech = { dialogueAct = "ACKNOWLEDGE", contentTemplateID = "semantic.social.acknowledged" } },
    })
    assert(ok, reason)
end

function Fixture.Run(context, payload)
    register()
    payload = type(payload) == "table" and payload or {}
    local Runtime = context.Runtime
    local scene = ContextProjection.buildContext(context)
    local actorID = tostring(scene.playerIdentitySeed or scene.playerID)
    local record = Runtime.hydratedNpcRecord
    if not record then return nil, "hydrated_fixture_required" end
    record = PNC.Registry.Get(record.id) or record
    local target = Runtime.relationshipTargetKey
    local router = Runtime.view.session.semanticDialogueRouter
    local session = router.context.semanticContextState
    local act = payload.recordAct
    if act then
        if not definitions[act] then return nil, "fixture_act_invalid" end
        local spec = Relations.GetCompactType(act)
        if payload.tier == "SESSION" then
            session:RecordTurn({ intent = act, speechAct = act, confidence = 1 },
                { speaker = "player", speakerID = actorID })
        elseif payload.tier == "TODAY" then
            PNC.Conversation.Memory.Events.RecordRelationshipMemory(record, {
                type = spec.id, aboutKey = target,
            }, target)
        elseif payload.tier == "DURABLE" then
            local ok, reason = PNC.Relationships.AddMemory(record.id, target, {
                id = "fixture:" .. act .. ":" .. tostring(payload.serial or 1),
                type = spec.id, aboutKey = target, createdAt = getGameTime():getWorldAgeHours(),
                strength = 1, permanent = true,
            })
            if not ok then return nil, reason end
        else return nil, "fixture_tier_invalid" end
    end
    scene = ContextProjection.buildContext(context)
    local stimulus = { type = "NPC_SEMANTIC_ACT",
        source = { actorID = actorID, kind = "fixture", providerID = "fixture.commitment" },
        targets = { record.id }, semantic = { intent = payload.queryAct or "FIXTURE_FULFILL",
            speechAct = payload.queryAct or "FIXTURE_FULFILL", confidence = 1 } }
    local preview, reason = Director.PreviewStimulus(stimulus,
        Runtime.view.session.semanticDialogueState, scene)
    if not preview then return nil, reason end
    local UtterancePlan = PNC.Semantics.UtterancePlan
    local plan = UtterancePlan.New({ speaker = "npc", target = "recipient",
        dialogueAct = "ACKNOWLEDGE", strategy = "ACKNOWLEDGE", topic = "commitment" })
    local realized = UtterancePlan.Realize(plan)
    return { ok = true, admission = context.Values.copy(preview.pragmatic.contextualAdmission),
        interactionPlan = context.Values.copy(preview.interactionPlan),
        evidence = Providers.QueryEvidence(scene, {}),
        utterancePlanKind = plan.kind, realizedText = realized and realized.text,
        registered = PNC.Conversation.Memory.Events.GetType("fixture_promise").dynamic ~= true }
end

return Fixture
