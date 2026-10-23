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

local function relationshipID(scenario, entry, player)
    local relationship = PNC.Conversation.Relationship
    if relationship and type(relationship.Resolve) == "function" then
        local ok, value = pcall(relationship.Resolve, entry, player)
        if ok and value then return value end
    end
    local bond = scenario and scenario.npc
        and scenario.npc.relationship
        and scenario.npc.relationship.bond or {}
    if bond.class == "lover" then return "Lover" end
    if bond.class == "friend" or bond.class == "family" then
        return "Member"
    end
    return "FirstMeet"
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
        orderKind = npc.orderKind,
        orderSpec = copy(npc.orderSpec),
        hostility = copy(npc.hostility),
        alive = npc.alive ~= false,
        record = copy(npc),
        snapshot = copy(npc),
    }
    return entry, target
end

function TalkParity.Resolve(scenario, value, player)
    local entry, target, reason = TalkParity.BuildEntry(scenario, value)
    if not entry then return nil, reason end
    local palette = PNC.NPCTypePalette
    if not palette then
        local ok, loaded = pcall(require, "PNC/UI/PNC_NPCTypePalette")
        if ok then palette = loaded end
    end
    local audience = PNC.Conversation.Audience
    if not audience then
        local ok, loaded = pcall(require, "PNC/Conversation/PNC_ConversationAudience")
        if ok then audience = loaded end
    end
    local typeID = palette and type(palette.ResolveType) == "function"
        and palette.ResolveType(entry) or target.id
    local relationID = relationshipID(scenario, entry, player)
    local audienceProjection = audience
        and type(audience.Resolve) == "function"
        and audience.Resolve(entry, relationID)
        or {
            audience = entry.hostility and entry.hostility.attackPlayers
                and "hostile" or "neutral",
            relationshipID = relationID,
            tacticalClass = entry.tacticalClass,
            playerHostile = entry.hostility
                and entry.hostility.attackPlayers == true or false,
        }
    local hostile = audienceProjection.playerHostile == true
    local alive = entry.alive ~= false
    local inlineAvailable = PNC.PBrainZ
        and type(PNC.PBrainZ.OpenInlineForTarget) == "function"
    local route
    if not alive then
        route = "unavailable"
    elseif hostile and inlineAvailable
    then
        route = "hostile_inline"
    elseif hostile then
        route = "hostile_full_conversation"
    else
        route = "full_conversation"
    end
    return {
        id = target.id,
        label = target.label,
        description = target.description,
        diagnostic = target.diagnostic == true,
        entryID = entry.id,
        targetType = typeID,
        tacticalClass = entry.tacticalClass,
        hostile = hostile,
        hostileInlineAvailable = inlineAvailable == true,
        audience = audienceProjection.audience,
        relationshipID = audienceProjection.relationshipID or relationID,
        route = route,
        routeReason = hostile
            and (inlineAvailable and "player_hostile_inline"
                or "player_hostile_inline_unavailable")
            or "native_talk_target",
        entryFacts = {
            colonyOwned = entry.colonyOwned == true,
            recruited = entry.recruited == true,
            orderKind = entry.orderKind,
            alive = alive,
            hostility = copy(entry.hostility),
        },
    }
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
        opening = {
            nodeID = view and view.session and view.session.currentNodeID,
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
        messages = context.Values.copy(turn and turn.messages or {}),
        toolCalls = context.Values.copy(turn and turn.toolCalls or {}),
        accepted = turn and turn.accepted == true or false,
        reason = turn and turn.reason,
        start = context.Values.copy(start),
    }
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
    return {
        schema = TalkParity.SCHEMA,
        type = "talk_start",
        scenario = Values.copy(scenario),
        configured = Values.copy(configured),
        start = start,
        turn = turn,
        observation = compactObservation(context, start, turn, snapshot),
        snapshot = snapshot,
    }
end

function TalkParity.Matrix(context, payload)
    local Runtime = context.Runtime
    local Values = context.Values
    payload = type(payload) == "table" and payload or {}
    local original = Values.copy(Runtime.scenario)
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
