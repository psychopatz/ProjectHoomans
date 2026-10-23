-- Shared target projection for native Talk and the Semantic Lab.
--
-- The Lab must exercise the same target facts that native Talk consumes.  The
-- catalog below is intentionally small and truthful: tactical class and
-- ownership are production facts, while the labels are only Lab-facing
-- diagnostics.  This module does not own relationship state or create a
-- second NPC store; it builds a bounded entry projection for the worker.

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local TalkParity = PNC.Conversation.TalkParity or {}
PNC.Conversation.TalkParity = TalkParity
local TalkStart = PNC.Conversation.TalkStart
    or require "PNC/Conversation/PNC_ConversationTalkStart"

TalkParity.VERSION = 1
TalkParity.SCHEMA = "semantic.talk.parity.v1"

local TARGETS = {
    {
        id = "current",
        label = "Current target",
        description = "Use the currently configured NPC entry.",
        diagnostic = true,
    },
    {
        id = "colonist",
        label = "Colonist",
        description = "Colony-owned NPC without a follow order.",
        tacticalClass = "colonist",
        colonyOwned = true,
        recruited = true,
        companion = true,
        ownedByPlayer = true,
        actorAuthority = { eligible = true, companion = true, owned = true },
        hostility = { attackPlayers = false },
        followState = { mode = "idle" },
        role = "colonist",
    },
    {
        id = "follower",
        label = "Follower",
        description = "Colony-owned NPC with the production follow order.",
        tacticalClass = "colonist",
        colonyOwned = true,
        recruited = true,
        companion = true,
        ownedByPlayer = true,
        actorAuthority = { eligible = true, companion = true, owned = true },
        hostility = { attackPlayers = false },
        followState = { mode = "following" },
        orderKind = "follow",
        orderSpec = { kind = "follow" },
        role = "follower",
    },
    {
        id = "neutral",
        label = "Neutral",
        description = "Non-owned NPC with the production neutral tactical class.",
        tacticalClass = "neutral",
        colonyOwned = false,
        recruited = false,
        companion = false,
        ownedByPlayer = false,
        actorAuthority = { eligible = false, companion = false, owned = false },
        hostility = { attackPlayers = false },
        followState = { mode = "idle" },
    },
    {
        id = "hostile",
        label = "Hostile / Enemy",
        description = "NPC with the production hostile tactical class and player hostility.",
        tacticalClass = "hostile",
        colonyOwned = false,
        recruited = false,
        companion = false,
        ownedByPlayer = false,
        actorAuthority = { eligible = false, companion = false, owned = false },
        hostility = { attackPlayers = true },
        followState = { mode = "idle" },
        activeBehavior = "attack",
    },
}

local ALIASES = {
    enemy = "hostile",
    hostile_enemy = "hostile",
}

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do
        result[key] = copy(item)
    end
    return result
end

local function canonicalID(value)
    local id = string.lower(tostring(value or "current"))
    return ALIASES[id] or id
end

local function targetByID(value)
    local id = canonicalID(value)
    for _, target in ipairs(TARGETS) do
        if target.id == id then return target end
    end
    return nil
end

local function applyOverrides(npc, target)
    if not target or target.id == "current" then return npc end
    local fields = {
        "tacticalClass", "colonyOwned", "recruited", "companion",
        "ownedByPlayer", "actorAuthority", "hostility", "followState",
        "orderKind", "orderSpec", "role", "activeBehavior",
    }
    for _, key in ipairs(fields) do
        npc[key] = copy(target[key])
    end
    return npc
end

function TalkParity.CanonicalID(value)
    return canonicalID(value)
end

function TalkParity.GetTarget(value)
    local target = targetByID(value)
    return target and copy(target) or nil
end

function TalkParity.GetCatalog()
    local catalog = {}
    for _, target in ipairs(TARGETS) do
        local row = {
            id = target.id,
            label = target.label,
            description = target.description,
            diagnostic = target.diagnostic == true,
        }
        if target.tacticalClass then
            row.tacticalClass = target.tacticalClass
        end
        catalog[#catalog + 1] = row
    end
    return catalog
end

function TalkParity.ApplyTarget(scenario, value)
    local target = targetByID(value)
    if not target then return nil, "unknown_talk_target" end
    local result = copy(scenario or {})
    result.npc = copy(result.npc or {})
    applyOverrides(result.npc, target)
    result.runtime = copy(result.runtime or {})
    result.runtime.semanticLabTalkTarget = target.id
    return result, target.id
end

function TalkParity.BuildEntry(scenario, value)
    local target = targetByID(value)
    if not target then return nil, nil, "unknown_talk_target" end
    local npc = copy(scenario and scenario.npc or {})
    applyOverrides(npc, target)
    local id = tostring(npc.npcID or npc.id or "harness-npc")
    local entry = {
        id = id,
        tacticalClass = npc.tacticalClass,
        colonyOwned = npc.colonyOwned == true,
        recruited = npc.recruited == true,
        companion = npc.companion == true,
        ownedByPlayer = npc.ownedByPlayer == true,
        orderKind = npc.orderKind,
        orderSpec = copy(npc.orderSpec),
        followState = copy(npc.followState),
        activeBehavior = npc.activeBehavior,
        role = npc.role,
        hostility = copy(npc.hostility),
        alive = npc.alive ~= false,
        available = npc.available,
        availabilityReason = npc.availabilityReason,
        record = copy(npc),
        snapshot = copy(npc),
    }
    return entry, target
end

function TalkParity.Resolve(scenario, value, player)
    local entry, target, reason = TalkParity.BuildEntry(scenario, value)
    if not entry then return nil, reason end
    local projection, projectionReason = TalkStart.Project(
        entry,
        player,
        { source = "semantic_lab" }
    )
    if not projection then return nil, projectionReason end
    projection.id = target.id
    projection.label = target.label
    projection.description = target.description
    projection.diagnostic = target.diagnostic == true
    projection.entryFacts = {
        colonyOwned = projection.ownership.colonyOwned,
        recruited = projection.ownership.recruited,
        ownedByPlayer = projection.ownership.ownedByPlayer,
        orderKind = projection.ownership.orderKind,
        alive = entry.alive ~= false,
        hostility = copy(entry.hostility),
    }
    return projection
end

local function resolvedText(value)
    if type(value) == "string" then return value end
    if type(value) ~= "table" then return tostring(value or "") end
    return tostring(value.text or value.fallback or value.key or "")
end

local function choicesFor(view)
    local session = view and view.session
    local source = session and session.choices
        or session and session.currentNode and session.currentNode.choices
        or {}
    local choices = {}
    for _, choice in ipairs(source) do
        if type(choice) == "table" then
            choices[#choices + 1] = {
                id = choice.id,
                text = resolvedText(choice.text),
                textKey = choice.textKey,
                enabled = choice.enabled ~= false,
                frame = copy(
                    choice.source and choice.source.semanticFrame
                ),
                action = choice.actionID
                    or choice.semantic and choice.semantic.actionID,
                route = choice.semantic and choice.semantic.route,
            }
        end
    end
    return choices
end

function TalkParity.StartProjection(context, value, view)
    local Runtime = context.Runtime
    local scenario = Runtime.scenario or {}
    local resolved, reason = TalkParity.Resolve(
        scenario, value, context.player
    )
    if not resolved then return nil, reason end
    local runtime = scenario.runtime or {}
    local npc = scenario.npc or {}
    local dynamicTradingLoad = Runtime.dynamicTradingLoad or {
        requested = runtime.availableMods
            and runtime.availableMods.DTHoomans == true or false,
        loaded = false,
        reason = "disabled",
    }
    local traderOverlay = tostring(npc.role or "") == "trader"
    local integration = {
        pbrainz = {
            inlineAvailable = resolved.hostileInlineAvailable == true,
            reason = resolved.hostileInlineReason,
        },
        dynamicTrading = context.Values.copy(dynamicTradingLoad),
        traderOverlay = {
            enabled = traderOverlay,
            providerID = traderOverlay and "dynamictrading.trader" or nil,
            targetType = resolved.targetType,
            tacticalClass = resolved.tacticalClass,
        },
    }
    local graph = context.Conversation
        and type(context.Conversation.graphProjection) == "function"
        and context.Conversation.graphProjection(view) or nil
    return {
        schema = TalkParity.SCHEMA,
        target = resolved,
        route = resolved.route,
        targetType = resolved.targetType,
        audience = resolved.audience,
        hostile = resolved.hostile,
        integration = integration,
        opening = {
            nodeID = view and view.session and view.session.currentNodeID,
            messages = context.Values.copy(Runtime.transcript or {}),
            choices = choicesFor(view),
            suggestions = context.Values.copy(
                view and view.semanticSuggestions
            ),
            graph = context.Values.copy(graph),
        },
    }
end

local function messageText(message)
    if type(message) ~= "table" then return "" end
    local payload = message.payload or message.value
    return resolvedText(payload)
end

local function compactMessages(messages)
    local result = {}
    for _, message in ipairs(messages or {}) do
        if type(message) == "table" then
            result[#result + 1] = {
                id = message.id or message.messageID,
                speaker = message.speaker,
                text = messageText(message),
                kind = message.kind,
            }
        end
    end
    return result
end

local function compactTurn(context, turn)
    local Values = context.Values
    local result = type(turn) == "table" and turn.result or nil
    local ir = type(result) == "table" and result.ir or nil
    return {
        ok = turn and turn.ok == true or false,
        type = turn and turn.type,
        input = turn and turn.input,
        accepted = turn and turn.accepted == true or false,
        reason = turn and turn.reason,
        result = type(result) == "table" and {
            accepted = result.accepted == true,
            reason = result.reason,
            sequence = result.sequence,
            ir = type(ir) == "table" and {
                intent = ir.intent,
                speechAct = ir.speechAct,
                action = ir.action,
                subject = ir.subject,
                confidence = ir.confidence,
                normalizedText = ir.normalizedText,
            } or nil,
            actionResult = Values.copy(result.actionResult),
        } or nil,
        messages = compactMessages(turn and turn.messages or {}),
        toolCalls = Values.copy(turn and turn.toolCalls or {}),
        relationshipBefore = Values.copy(
            turn and turn.relationshipBefore or {}
        ),
        relationshipAfter = Values.copy(
            turn and turn.relationshipAfter or {}
        ),
    }
end

local function compactObservation(context, start, turn, snapshot)
    local observation = turn and turn.observation or {}
    local response = observation and observation.response or {}
    local contextSnapshot = snapshot and snapshot.context or {}
    local actor = contextSnapshot.actorConversationContext or {}
    local relationship = actor.relationship or {}
    local graph = observation.conversationGraph
        or turn and turn.conversationGraph
        or snapshot and snapshot.conversationGraph
    local suggestions = observation.suggestions or {}
    local choices = {}
    for _, candidate in ipairs(suggestions.candidates or {}) do
        if type(candidate) == "table" then
            choices[#choices + 1] = {
                id = candidate.id,
                action = candidate.action,
                label = candidate.display and candidate.display.label
                    or candidate.labelFallback,
                status = candidate.status,
            }
        end
    end
    local responseText = response.text
    if not responseText and turn and turn.messages then
        for index = #turn.messages, 1, -1 do
            local message = turn.messages[index]
            if message and message.speaker == "npc" then
                responseText = messageText(message)
                break
            end
        end
    end
    return {
        npcResponse = responseText,
        semanticHubChoices = choices,
        speechStyleContext = contextSnapshot.speechStyleContext
            or response.speechStyleContext or {},
        relationship = {
            standing = relationship.state or relationship.standing or "unknown",
            bond = context.Values.copy(
                relationship.bond
                or snapshot.simulationProjection
                    and snapshot.simulationProjection.npc
                    and snapshot.simulationProjection.npc.bond
                or {}
            ),
            approval = relationship.approval,
            respect = relationship.respect,
            familiarity = relationship.familiarity,
        },
        runtimeGraphPath = {
            kind = graph and graph.graphKind or "none",
            graph = context.Values.copy(graph),
        },
        suggestions = context.Values.copy(suggestions),
        choices = choicesFor(context.Runtime.view),
        messages = compactMessages(turn and turn.messages or {}),
        toolCalls = context.Values.copy(turn and turn.toolCalls or {}),
        accepted = turn and turn.accepted == true or false,
        reason = turn and turn.reason,
        start = context.Values.copy(start),
    }
end

local function compactRelationshipRecord(value, Values)
    local result = Values.copy(value)
    if type(result) ~= "table" then return result end
    for _, key in ipairs({
        "memories", "saturation", "cooldowns", "interactionJournal",
        "events", "history", "recentEvents",
    }) do
        result[key] = nil
    end
    return result
end

local function compactScenario(value, Values)
    local result = Values.copy(value)
    if type(result) == "table" and type(result.npc) == "table" then
        result.npc.social = nil
        if type(result.npc.relationship) == "table" then
            result.npc.relationship = compactRelationshipRecord(
                result.npc.relationship, Values
            )
        end
    end
    return result
end

local function compactWorkingWorld(value, Values)
    local result = Values.copy(value)
    if type(result) ~= "table" then return result end
    for _, key in ipairs({ "effective", "baseline" }) do
        if type(result[key]) == "table"
            and type(result[key].npc) == "table"
        then
            result[key] = compactScenario(result[key], Values)
        end
    end
    return result
end

local function compactContext(value, Values)
    local result = Values.copy(value)
    if type(result) ~= "table" then return result end
    for _, key in ipairs({
        "knowledge", "dossier", "dialogue", "state", "engineFacts",
        "engineEvents", "categoryDiagnostics", "conversationRoot",
        "conversationBlock",
    }) do
        result[key] = nil
    end
    local actor = result.actorConversationContext
    if type(actor) == "table" and type(actor.relationship) == "table" then
        actor.relationship = compactRelationshipRecord(actor.relationship, Values)
    end
    return result
end

local function compactSnapshot(value, Values)
    local result = Values.copy(value)
    if type(result) ~= "table" then return result end
    result.scenario = compactScenario(result.scenario, Values)
    result.workingWorld = compactWorkingWorld(result.workingWorld, Values)
    result.context = compactContext(result.context, Values)
    local simulation = result.simulationProjection
    local relationship = type(simulation) == "table"
        and simulation.relationship or nil
    if type(relationship) == "table" then
        relationship.record = compactRelationshipRecord(
            relationship.record, Values
        )
    end
    return result
end

function TalkParity.Start(context, value, utterance)
    local Runtime = context.Runtime
    local Values = context.Values
    local scenario, targetOrReason = TalkParity.ApplyTarget(
        Values.copy(Runtime.scenario), value
    )
    if not scenario then return nil, targetOrReason end
    local configured = context.ScenarioSession.reset(context, scenario)
    local start, reason = TalkParity.StartProjection(
        context, targetOrReason, Runtime.view
    )
    if not start then return nil, reason end
    local turn = context.Conversation.turn(
        context, tostring(utterance or "hello")
    )
    local snapshot = context.ScenarioSession.snapshot(context)
    -- A saved actor may carry a large raw provider payload (for example a
    -- native inventory blob). Talk parity needs the effective scenario and
    -- conversation projection, not a second copy of the complete source
    -- snapshot on every turn. The full immutable source remains available
    -- through SNAPSHOT/import responses.
    if type(snapshot.sourceSnapshot) == "table" then
        snapshot.sourceSnapshot.data = nil
        snapshot.sourceSnapshot.providerPayloads = nil
    end
    if type(snapshot.workingWorld) == "table" then
        snapshot.workingWorld.baseline = nil
    end
    local compactScenarioValue = compactScenario(scenario, Values)
    local compactConfigured = compactSnapshot(configured, Values)
    if type(compactConfigured.sourceSnapshot) == "table" then
        compactConfigured.sourceSnapshot.data = nil
        compactConfigured.sourceSnapshot.providerPayloads = nil
    end
    compactConfigured.workingWorld = compactWorkingWorld(
        compactConfigured.workingWorld, Values
    )
    snapshot = compactSnapshot(snapshot, Values)
    return {
        schema = TalkParity.SCHEMA,
        type = "talk_start",
        scenario = compactScenarioValue,
        configured = compactConfigured,
        start = start,
        turn = compactTurn(context, turn),
        observation = compactObservation(context, start, turn, snapshot),
        snapshot = snapshot,
    }
end

function TalkParity.Matrix(context, payload)
    local Runtime = context.Runtime
    local Values = context.Values
    payload = type(payload) == "table" and payload or {}
    local original = Values.copy(Runtime.scenario)
    local originalDynamicTradingLoaded = Runtime.dynamicTradingLoaded
    local base = Values.copy(original)
    local targetIDs = payload.targetIDs
    if type(targetIDs) ~= "table" or #targetIDs == 0 then
        targetIDs = { "colonist", "follower", "neutral", "hostile" }
    end
    local maximum = math.max(1, math.min(8, tonumber(payload.maximum) or 8))
    local utterance = tostring(payload.utterance or "hello")
    local rows = {}
    for index = 1, math.min(#targetIDs, maximum) do
        local targetID = targetIDs[index]
        local scenario, canonicalOrReason = TalkParity.ApplyTarget(base, targetID)
        if scenario then
            Runtime.dynamicTradingLoaded = originalDynamicTradingLoaded
            context.ScenarioSession.reset(context, scenario)
            local start, startReason = TalkParity.StartProjection(
                context, canonicalOrReason, Runtime.view
            )
            if start then
                local turn = context.Conversation.turn(context, utterance)
                local snapshot = context.ScenarioSession.snapshot(context)
                local row = compactObservation(context, start, turn, snapshot)
                row.index = index - 1
                row.label = start.target.label
                row.target = start.target
                row.integration = Values.copy(start.integration)
                rows[#rows + 1] = row
            else
                rows[#rows + 1] = {
                    index = index - 1,
                    label = tostring(targetID),
                    error = startReason,
                }
            end
        else
            rows[#rows + 1] = {
                index = index - 1,
                label = tostring(targetID),
                error = canonicalOrReason,
            }
        end
    end
    Runtime.dynamicTradingLoaded = originalDynamicTradingLoaded
    context.ScenarioSession.reset(context, original)
    return {
        ok = true,
        schema = "semantic.talk.parity.matrix.v1",
        utterance = utterance,
        targets = TalkParity.GetCatalog(),
        rows = rows,
        restoredScenario = true,
    }
end

return TalkParity
