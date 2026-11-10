-- Disposable production-worker fixtures and storage measurements. No save IO.
local Handler = {}

function Handler.handle(context, command, payload)
    if command == "TEST_EVIDENCE_STRESS" then
        local Fixture = require "worker/EvidenceStressFixture"
        return Fixture.Run(context, payload)
    end
    if command == "TEST_FUTURE_EVIDENCE" then
        local Fixture = require "worker/FutureEvidenceFixture"
        return Fixture.Run(context, payload)
    end
    if command == "TEST_EVIDENCE_METADATA" then
        local rows = {}
        local Events = PNC.Conversation.Memory.Events
        for id, definition in pairs(PNC.SocialEventDefinitions) do
            local metadata = definition.semantic
            local entry = Events.GetType(definition.targetMemory.type)
            local actorMemory = definition.actorMemory
            local actorEntry = actorMemory and Events.GetType(actorMemory.type)
            rows[#rows + 1] = { id = id, described = type(metadata) == "table",
                retained = metadata and metadata.retain,
                code = entry and entry.code, dynamic = entry and entry.dynamic == true,
                retentionSalience = entry and entry.salience,
                canonical = entry and metadata
                    and entry.salience == metadata.retentionSalience
                    and entry.longTerm == (metadata.longTerm == true),
                actorPolicyRequired = actorMemory ~= nil,
                actorCanonical = actorMemory and actorEntry and actorMemory.semantic
                    and actorEntry.salience == actorMemory.semantic.retentionSalience or false }
        end
        table.sort(rows, function(a, b) return a.id < b.id end)
        local fallback = Events.Internal.ResolveEventType("addon_evidence_fixture")
        return { ok = true, rows = rows, fallbackDynamic = fallback and fallback.dynamic }
    end
    if command == "TEST_EVIDENCE_PROVIDERS" then
        local Providers = require "PNC/Semantics/PNC_SemanticInteractionProviders"
        for _, tier in ipairs({ "SESSION", "TODAY", "DURABLE" }) do
            local sourceTier = tier
            Providers.RegisterEvidenceAdapter({ id = "fixture." .. tier,
                sourceTier = tier, Query = function()
                    return {{ sourceRef = sourceTier .. ":fixture", actorID = "player:a",
                        targetID = "npc:b", relations = { opens = { "test" } },
                        retentionSalience = 220, confidence = 0.8,
                        effectiveStrength = 0.5, ageHours = 1,
                        rawText = "excluded" }}
                end })
        end
        return { ok = true, evidence = Providers.QueryEvidence({}, {
            relation = "test", targetID = "npc:b" }) }
    end
    if command ~= "TEST_EVIDENCE_STORAGE" then return false end
    local Runtime = context.Runtime
    local record = Runtime.hydratedNpcRecord
    if type(record) ~= "table" then return nil, "hydrated_fixture_required" end
    record = PNC.Registry.Get(record.id) or record
    payload = type(payload) == "table" and payload or {}
    local target = PNC.PlayerCharacters.GetEntityKey(getPlayer(), {
        create = true,
    }) or Runtime.relationshipTargetKey
    if payload.emitHelp then
        local time = getGameTime()
        local accepted, reason = PNC.SocialEvents.Emit({
            id = "social:fixture:help:" .. tostring(payload.emitHelp), type = "treated_wound",
            actorKey = "npc:" .. record.id, targetKey = target,
            occurredAt = time:getWorldAgeHours(), sourceSystem = "health", context = {},
        })
        if not accepted or type(accepted) == "table" and accepted.ok ~= true then
            return nil, "help_event_rejected:" .. tostring(type(accepted) == "table" and accepted.reason or reason)
        end
        record = PNC.Registry.Get(record.id) or record
    end
    if payload.openResponse then
        local view = Runtime.view
        local router = view and view.session and view.session.semanticDialogueRouter
        local state = router and router.context and router.context.semanticContextState
        if not state then return nil, "session_context_unavailable" end
        state:RecordNPCResponse({ intent = payload.openResponse, speechAct = payload.openResponse,
            confidence = 1 }, { speakerID = record.id })
        state:SetPendingFollowUp({ id = "fixture:pending", kind = payload.openResponse,
            topic = "supplies", openedTurn = state.sequence })
    end
    if payload.clearSession then
        local router = Runtime.view.session.semanticDialogueRouter
        if router and router.context.semanticContextState then router.context.semanticContextState:Reset() end
    end
    if payload.advanceDays then
        Runtime.scenario.world.worldAgeHours =
            (tonumber(Runtime.scenario.world.worldAgeHours) or 0)
            + math.min(30, math.max(0, tonumber(payload.advanceDays) or 0)) * 24
        record.memory = PNC.Conversation.Memory.Events.Normalize(record.memory)
    end
    if payload.saturate == true then
        local relationship = PNC.RelationshipTypes.NewRelationship(target)
        for index = 1, PNC.RelationshipConstants.MEMORY_LIMIT do
            relationship.memories[index] = PNC.RelationshipTypes.NewMemory({
                id = "e0:permanent:" .. tostring(index), type = "insulted",
                aboutKey = target, createdAt = 0, strength = 1,
                permanent = true, approvalEffect = -1,
            })
        end
        record.social.relationships[target] = relationship
    end
    if payload.project then
        PNC.Conversation.Memory.Events.RecordRelationshipMemory(record, {
            type = payload.project, aboutKey = target,
            permanent = payload.permanent == true,
        }, target)
    end
    if payload.addMemory then
        PNC.Relationships.AddMemory(record.id, target, {
            id = "fixture:durable:" .. payload.addMemory,
            type = payload.addMemory, aboutKey = target,
            strength = 1, permanent = true, createdAt = 0,
        })
        record = PNC.Registry.Get(record.id) or record
    end
    if payload.fillUnrelated then
        for index = 1, math.min(18, tonumber(payload.fillUnrelated) or 0) do
            PNC.Relationships.AddMemory(record.id, target, {
                id = "z_unrelated:" .. tostring(index), type = "provided_treated_wound",
                aboutKey = target, createdAt = getGameTime():getWorldAgeHours(), strength = 0.5,
            })
        end
        record = PNC.Registry.Get(record.id) or record
    end
    local relationship = PNC.Relationships.Get(record.id, target) or {}
    local raw = PNC.Persistence.SerializeRecord(record)
    local ContextProjection = require "worker/Conversation_Context"
    local dialogueContext = ContextProjection.buildContext(context)
    local roots = {}
    local presentation = payload.presentation and PNC.RelationshipPresentation
        and PNC.RelationshipPresentation.BuildForConversation(getPlayer(), record.id)
    local conduct = PNC.Conduct.GetForEntity(target) or {}
    local conductRows = {}
    for index = 1, math.min(#(conduct.evidence or {}), 4) do
        local row = conduct.evidence[index]
        conductRows[#conductRows + 1] = { eventType = row.eventType,
            actorKey = row.actorKey, subjectKey = row.subjectKey, strength = row.strength }
    end
    for key in pairs(Runtime.modData or {}) do roots[#roots + 1] = key end
    table.sort(roots)
    return {
        ok = true, memory = context.Values.copy(record.memory),
        relationship = context.Values.copy(relationship),
        serializedRecord = context.Values.copy(raw), roots = roots,
        presentationEvidence = presentation and presentation.semanticEvidence,
        conduct = { count = #(conduct.evidence or {}), sample = conductRows },
        identity = { adapterTarget = Runtime.relationshipTargetKey, target = target,
            targetKind = dialogueContext.relationship and dialogueContext.relationship.targetKind,
            targetID = dialogueContext.relationship and dialogueContext.relationship.targetID },
        evidence = PNC.Semantics.InteractionProviders.QueryEvidence(dialogueContext, {}),
        limits = { today = 8, compactDurable = 6,
            relationship = PNC.RelationshipConstants.MEMORY_LIMIT,
            conduct = PNC.ConductConstants.EVIDENCE_LIMIT },
    }
end

return Handler
