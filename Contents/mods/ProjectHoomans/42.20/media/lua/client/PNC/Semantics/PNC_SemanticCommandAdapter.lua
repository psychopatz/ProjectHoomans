-- Client adapter from semantic action intents to the existing authoritative
-- companion-command transport. NLU and policy remain side-effect free.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Adapter = PNC.Semantics.CommandAdapter or {}
PNC.Semantics.CommandAdapter = Adapter

Adapter.VERSION = 1
Adapter.Actions = Adapter.Actions or {}

local function normalized(value)
    return string.upper(tostring(value or ""))
end

local function destinationCategory(actionIntent)
    local destination = actionIntent and actionIntent.destination
    return normalized(destination and (
        destination.category or destination.concept or destination.value
    ))
end

function Adapter.RegisterAction(action, definition)
    action = normalized(action)
    if action == "" then return false, "invalid_action" end
    if type(definition) ~= "string" and type(definition) ~= "table" then
        return false, "invalid_action_definition"
    end
    Adapter.Actions[action] = definition
    return true, definition
end

-- This descriptor is the public, typed seam consumed by Semantic Lab. It
-- names the existing command registry and dispatcher; it does not contain a
-- callback or create a second execution path.
Adapter.RegisterAction("FOLLOW", {
    capabilityID = "pnc:companion.follow",
    owner = "PNC.CompanionCommands",
    route = "existing_companion_command",
    workflowKind = "simple_command",
    templateVersion = 1,
    contractVersion = 1,
    commandID = "follow",
    handlerID = "PNC.Client.SendCompanionCommand",
    targetScope = "single_or_group",
    triggerFrames = {
        { intent = "REQUEST", speechAct = "REQUEST", action = "FOLLOW" },
    },
    requiredSlots = {
        npcID = {
            type = "entity",
            owner = "dialogue_context",
            source = "npcID",
        },
    },
    permissionGate = {
        type = "pnc:semantic_context",
        capabilityID = "pnc:companion.follow",
        requiresTarget = true,
        requiresAuthority = true,
    },
    outcomeMapping = {
        queued = "queued",
        accepted = "queued",
        pending = "queued",
        network_queued = "queued",
        rejected = "rejected",
        failed = "failed",
    },
    responsePools = {
        queued = {
            key = "UI_PNC_Conversation_Semantic_GeneratedFollowQueued",
            en = "Okay, I'll follow you.",
            tl = "Sige, susundan kita.",
        },
        rejected = {
            key = "UI_PNC_Conversation_Semantic_GeneratedFollowRejected",
            en = "I can't follow you right now.",
            tl = "Hindi kita masusundan ngayon.",
        },
        failed = {
            key = "UI_PNC_Conversation_Semantic_GeneratedFollowFailed",
            en = "I couldn't start following you.",
            tl = "Hindi ko masimulan ang pagsunod sa iyo.",
        },
    },
    translationOwner = "ProjectHoomans",
    arguments = {
        npcID = "actor_target",
        scope = "single_or_group",
    },
    requires = {
        "conversation_or_companion_authority",
        "resolved_target",
    },
    result = {
        "requested",
        "rejected",
        "queued",
        "accepted",
        "completed",
    },
})
Adapter.RegisterAction("STAY", {
    capabilityID = "pnc:companion.stay",
    owner = "PNC.CompanionCommands",
    route = "existing_companion_command",
    workflowKind = "simple_command",
    templateVersion = 1,
    contractVersion = 1,
    commandID = "stay",
    handlerID = "PNC.Client.SendCompanionCommand",
    targetScope = "single_or_group",
    triggerFrames = {
        { intent = "REQUEST", speechAct = "REQUEST", action = "STAY" },
    },
    requiredSlots = {
        npcID = {
            type = "entity",
            owner = "dialogue_context",
            source = "npcID",
        },
    },
    permissionGate = {
        type = "pnc:semantic_context",
        capabilityID = "pnc:companion.stay",
        requiresTarget = true,
        requiresAuthority = true,
    },
    outcomeMapping = {
        queued = "queued",
        accepted = "queued",
        pending = "queued",
        network_queued = "queued",
        rejected = "rejected",
        failed = "failed",
    },
    responsePools = {
        queued = {
            key = "UI_PNC_Conversation_Semantic_GeneratedStayQueued",
            en = "Okay, I'll stay here.",
            tl = "Sige, mananatili ako rito.",
        },
        rejected = {
            key = "UI_PNC_Conversation_Semantic_GeneratedStayRejected",
            en = "I can't stay here right now.",
            tl = "Hindi ako makapananatili rito ngayon.",
        },
        failed = {
            key = "UI_PNC_Conversation_Semantic_GeneratedStayFailed",
            en = "I couldn't start the stay order.",
            tl = "Hindi ko masimulan ang utos na manatili.",
        },
    },
    translationOwner = "ProjectHoomans",
    arguments = {
        npcID = "actor_target",
        scope = "single_or_group",
    },
    requires = {
        "conversation_or_companion_authority",
        "resolved_target",
    },
    result = {
        "requested",
        "rejected",
        "queued",
        "accepted",
        "completed",
    },
})
-- A direct stop is represented by the existing authoritative stay order. It
-- stops following at the current position without adding a second command
-- implementation.
Adapter.RegisterAction("STOP", {
    capabilityID = "pnc:companion.stop",
    owner = "PNC.CompanionCommands",
    route = "existing_companion_command",
    workflowKind = "simple_command",
    templateVersion = 1,
    contractVersion = 1,
    commandID = "stay",
    handlerID = "PNC.Client.SendCompanionCommand",
    targetScope = "single_or_group",
    triggerFrames = {
        { intent = "REQUEST", speechAct = "REQUEST", action = "STOP" },
    },
    requiredSlots = {
        npcID = {
            type = "entity",
            owner = "dialogue_context",
            source = "npcID",
        },
    },
    permissionGate = {
        type = "pnc:semantic_context",
        capabilityID = "pnc:companion.stop",
        requiresTarget = true,
        requiresAuthority = true,
    },
    outcomeMapping = {
        queued = "queued",
        accepted = "queued",
        pending = "queued",
        network_queued = "queued",
        rejected = "rejected",
        failed = "failed",
    },
    responsePools = {
        queued = {
            key = "UI_PNC_Conversation_Semantic_GeneratedStopQueued",
            en = "Okay, I'll stop following.",
            tl = "Sige, titigil ako sa pagsunod.",
        },
        rejected = {
            key = "UI_PNC_Conversation_Semantic_GeneratedStopRejected",
            en = "I can't stop following right now.",
            tl = "Hindi ako makapaghinto sa pagsunod ngayon.",
        },
        failed = {
            key = "UI_PNC_Conversation_Semantic_GeneratedStopFailed",
            en = "I couldn't stop following.",
            tl = "Hindi ako nakahinto sa pagsunod.",
        },
    },
    translationOwner = "ProjectHoomans",
    arguments = {
        npcID = "actor_target",
        scope = "single_or_group",
    },
    requires = {
        "conversation_or_companion_authority",
        "resolved_target",
    },
    result = {
        "requested", "rejected", "queued", "accepted", "completed",
    },
})
Adapter.RegisterAction("GO", {
    capabilityID = "pnc:companion.go_home",
    owner = "PNC.CompanionCommands",
    route = "existing_companion_command",
    workflowKind = "simple_command",
    templateVersion = 1,
    contractVersion = 1,
    handlerID = "PNC.Client.SendCompanionCommand",
    targetScope = "single_or_group",
    destinations = {
        HOME = "return_home",
    },
    triggerFrames = {
        { intent = "REQUEST", speechAct = "REQUEST", action = "GO" },
    },
    requiredSlots = {
        npcID = {
            type = "entity",
            owner = "dialogue_context",
            source = "npcID",
        },
        destination = {
            type = "location",
            owner = "semantic_ir",
            source = "destination",
        },
    },
    permissionGate = {
        type = "pnc:semantic_context",
        capabilityID = "pnc:companion.go_home",
        requiresTarget = true,
        requiresAuthority = true,
    },
    outcomeMapping = {
        queued = "queued",
        accepted = "queued",
        pending = "queued",
        network_queued = "queued",
        rejected = "rejected",
        failed = "failed",
    },
    responsePools = {
        queued = {
            key = "UI_PNC_Conversation_Semantic_GeneratedGoQueued",
            en = "Okay, I'll head home.",
            tl = "Sige, uuwi ako.",
        },
        rejected = {
            key = "UI_PNC_Conversation_Semantic_GeneratedGoRejected",
            en = "I can't head home right now.",
            tl = "Hindi ako makauuwi ngayon.",
        },
        failed = {
            key = "UI_PNC_Conversation_Semantic_GeneratedGoFailed",
            en = "I couldn't head home.",
            tl = "Hindi ako nakauwi.",
        },
    },
    translationOwner = "ProjectHoomans",
    arguments = {
        npcID = "actor_target",
        destination = "resolved_destination",
        scope = "single_or_group",
    },
    requires = {
        "conversation_or_companion_authority",
        "resolved_destination",
    },
    result = {
        "requested", "rejected", "queued", "accepted", "completed",
    },
})
-- All CAMP scopes use the same authoritative command. Group admission still
-- batches nearby targets in the command registry, while a single recipient
-- receives the same durable camp order instead of entering a second semantic
-- action-plan path that can acknowledge without taking movement ownership.
Adapter.RegisterAction("CAMP", {
    capabilityID = "pnc:companion.camp",
    owner = "PNC.CompanionCommands",
    route = "existing_companion_command",
    workflowKind = "simple_command",
    templateVersion = 1,
    contractVersion = 1,
    commandID = "camp",
    handlerID = "PNC.Client.SendCompanionCommand",
    targetScope = "single_or_group",
    triggerFrames = {
        { intent = "REQUEST", speechAct = "REQUEST", action = "CAMP" },
    },
    requiredSlots = {
        npcID = {
            type = "entity",
            owner = "dialogue_context",
            source = "npcID",
        },
        target = {
            type = "location",
            owner = "semantic_ir",
            source = "target",
        },
    },
    permissionGate = {
        type = "pnc:semantic_context",
        capabilityID = "pnc:companion.camp",
        requiresTarget = true,
        requiresAuthority = true,
    },
    outcomeMapping = {
        queued = "queued",
        accepted = "queued",
        pending = "queued",
        network_queued = "queued",
        rejected = "rejected",
        failed = "failed",
    },
    responsePools = {
        queued = {
            key = "UI_PNC_Conversation_Semantic_GeneratedCampQueued",
            en = "Okay, I'll set up camp there.",
            tl = "Sige, magse-set up ako ng kampo roon.",
        },
        rejected = {
            key = "UI_PNC_Conversation_Semantic_GeneratedCampRejected",
            en = "I can't set up camp there right now.",
            tl = "Hindi ako makapag-set up ng kampo roon ngayon.",
        },
        failed = {
            key = "UI_PNC_Conversation_Semantic_GeneratedCampFailed",
            en = "I couldn't set up camp there.",
            tl = "Hindi ako nakapag-set up ng kampo roon.",
        },
    },
    translationOwner = "ProjectHoomans",
    arguments = {
        npcID = "actor_target",
        target = "resolved_camp_site",
        scope = "single_or_group",
    },
    requires = {
        "conversation_or_companion_authority",
        "resolved_camp_site",
    },
    result = {
        "requested", "rejected", "queued", "accepted", "completed",
    },
})

-- The clinic-supplies quest is an authoritative contract, not a second
-- command implementation. These descriptors let the same generated
-- simple-command template expose its offer, acceptance, status query, and
-- turn-in operations while the server-owned quest service remains the only
-- state mutator.
local QUEST_RESPONSE_POOLS = {
    offer = {
        queued = {
            key = "UI_PNC_Conversation_Semantic_QuestOfferQueued",
            en = "I can help with the clinic supplies.",
            tl = "Matutulungan kita sa mga suplay ng klinika.",
        },
        rejected = {
            key = "UI_PNC_Conversation_Semantic_QuestOfferRejected",
            en = "I can't take that clinic-supplies request right now.",
            tl = "Hindi ko matatanggap ang kahilingan para sa suplay ngayon.",
        },
        failed = {
            key = "UI_PNC_Conversation_Semantic_QuestOfferFailed",
            en = "I couldn't check that clinic-supplies request.",
            tl = "Hindi ko masuri ang kahilingan para sa suplay.",
        },
    },
    accept = {
        queued = {
            key = "UI_PNC_Conversation_Semantic_QuestAcceptedQueued",
            en = "I'll bring the clinic supplies.",
            tl = "Dadalahin ko ang mga suplay ng klinika.",
        },
        rejected = {
            key = "UI_PNC_Conversation_Semantic_QuestAcceptedRejected",
            en = "I can't accept that request right now.",
            tl = "Hindi ko matatanggap ang kahilingang iyon ngayon.",
        },
        failed = {
            key = "UI_PNC_Conversation_Semantic_QuestAcceptedFailed",
            en = "I couldn't accept that request.",
            tl = "Hindi ko matanggap ang kahilingang iyon.",
        },
    },
    status = {
        queued = {
            key = "UI_PNC_Conversation_Semantic_QuestStatusQueued",
            en = "I'll check the clinic-supplies request.",
            tl = "Susuriin ko ang kahilingan para sa suplay ng klinika.",
        },
        rejected = {
            key = "UI_PNC_Conversation_Semantic_QuestStatusRejected",
            en = "I can't check that request right now.",
            tl = "Hindi ko masuri ang kahilingang iyon ngayon.",
        },
        failed = {
            key = "UI_PNC_Conversation_Semantic_QuestStatusFailed",
            en = "I couldn't check that request.",
            tl = "Hindi ko masuri ang kahilingang iyon.",
        },
    },
    turn_in = {
        queued = {
            key = "UI_PNC_Conversation_Semantic_QuestTurnInQueued",
            en = "I'll turn in the clinic supplies.",
            tl = "Ipapasa ko ang mga suplay ng klinika.",
        },
        rejected = {
            key = "UI_PNC_Conversation_Semantic_QuestTurnInRejected",
            en = "I can't turn that in yet.",
            tl = "Hindi ko pa maipapasa iyon.",
        },
        failed = {
            key = "UI_PNC_Conversation_Semantic_QuestTurnInFailed",
            en = "I couldn't turn in the clinic supplies.",
            tl = "Hindi ko maipasa ang mga suplay ng klinika.",
        },
    },
}

local QUEST_OPERATIONS = {
    {
        action = "HELP",
        capabilityID = "pnc:quest.clinic_supplies.offer",
        commandID = "quest:clinic_supplies:offer",
        operation = "offer",
        triggerFrames = {
            { intent = "REQUEST", speechAct = "REQUEST", action = "HELP" },
        },
        responses = QUEST_RESPONSE_POOLS.offer,
    },
    {
        action = "QUEST_ACCEPT",
        capabilityID = "pnc:quest.clinic_supplies.accept",
        commandID = "quest:clinic_supplies:accept",
        operation = "accept",
        triggerFrames = {
            { intent = "ACCEPT", speechAct = "ACCEPT", action = "QUEST_ACCEPT" },
        },
        responses = QUEST_RESPONSE_POOLS.accept,
    },
    {
        action = "QUEST_STATUS",
        capabilityID = "pnc:quest.clinic_supplies.status",
        commandID = "quest:clinic_supplies:status",
        operation = "status",
        triggerFrames = {
            { intent = "QUESTION", speechAct = "QUESTION", action = "QUEST_STATUS" },
        },
        responses = QUEST_RESPONSE_POOLS.status,
    },
    {
        action = "QUEST_TURN_IN",
        capabilityID = "pnc:quest.clinic_supplies.turn_in",
        commandID = "quest:clinic_supplies:turn_in",
        operation = "turn_in",
        triggerFrames = {
            { intent = "REQUEST", speechAct = "REQUEST", action = "QUEST_TURN_IN" },
        },
        responses = QUEST_RESPONSE_POOLS.turn_in,
    },
}

local function registerQuestOperation(operation)
    local capabilityID = operation.capabilityID
    Adapter.RegisterAction(operation.action, {
        capabilityID = capabilityID,
        owner = "PNC.QuestService",
        route = "existing_quest_contract",
        workflowKind = "simple_command",
        templateVersion = 1,
        contractVersion = 1,
        commandID = operation.commandID,
        operation = operation.operation,
        handlerID = "PNC.Client.RequestSemanticQuest",
        targetScope = "single_recipient",
        triggerFrames = operation.triggerFrames,
        requiredSlots = {
            npcID = {
                type = "entity",
                owner = "dialogue_context",
                source = "npcID",
            },
        },
        permissionGate = {
            type = "pnc:semantic_context",
            capabilityID = capabilityID,
            requiresTarget = true,
            requiresAuthority = true,
        },
        outcomeMapping = {
            queued = "queued",
            accepted = "queued",
            pending = "queued",
            network_queued = "queued",
            rejected = "rejected",
            failed = "failed",
        },
        responsePools = operation.responses,
        translationOwner = "ProjectHoomans",
        arguments = {
            npcID = "giver_npc",
            questID = "pnc.quest.clinic_supplies",
            operation = operation.operation,
            expectedRevision = "conversation_quest_revision",
        },
        requires = {
            "conversation_or_quest_authority",
            "resolved_giver",
        },
        result = {
            "requested", "available", "accepted", "active", "ready",
            "rewarded", "rejected", "failed",
        },
    })
end

for _, operation in ipairs(QUEST_OPERATIONS) do
    registerQuestOperation(operation)
end

-- Generated command flows use the shared response catalog selector. These
-- reviewed variants let the same generated template honor the registered
-- relationship/personality snapshot without putting branching or effects in
-- the generator or the command adapter.
local CONTEXTUAL_QUEUED_RESPONSES = {
    FOLLOW = {
        friendly = { en = "Of course, I'll follow you.", tl = "Siyempre, susundan kita." },
        trusted = { en = "I know you. I'll follow.", tl = "Kilala kita. Susunod ako." },
        withdrawn = { en = "I'll follow.", tl = "Susunod ako." },
        repeated = { en = "I'm still following you.", tl = "Sinusundan pa rin kita." },
    },
    STAY = {
        friendly = { en = "Sure, I'll stay here.", tl = "Sige, mananatili ako rito." },
        trusted = { en = "All right, I'll stay.", tl = "Sige, mananatili ako." },
        withdrawn = { en = "Okay, I'll stay.", tl = "Sige, mananatili ako." },
        repeated = { en = "I'm already staying here.", tl = "Nananatili na ako rito." },
    },
    STOP = {
        friendly = { en = "Got it, I'll stop following.", tl = "Nakuha ko, titigil ako sa pagsunod." },
        trusted = { en = "Understood, I'll stop.", tl = "Naiintindihan ko, titigil ako." },
        withdrawn = { en = "Okay, I'll stop.", tl = "Sige, titigil ako." },
        repeated = { en = "I've already stopped following.", tl = "Tumigil na ako sa pagsunod." },
    },
    GO = {
        friendly = { en = "Sure, I'll head home.", tl = "Sige, uuwi ako." },
        trusted = { en = "All right, I'm heading home.", tl = "Sige, pauwi na ako." },
        withdrawn = { en = "I'll head home.", tl = "Uuwi ako." },
        repeated = { en = "I'm still heading home.", tl = "Pauwi pa rin ako." },
    },
    CAMP = {
        friendly = { en = "Sure, I'll set up camp there.", tl = "Sige, magse-set up ako ng kampo roon." },
        trusted = { en = "All right, I'll make camp there.", tl = "Sige, magtatayo ako ng kampo roon." },
        withdrawn = { en = "I'll set up camp there.", tl = "Magtatayo ako ng kampo roon." },
        repeated = { en = "I'm still setting up camp there.", tl = "Nagtatayo pa rin ako ng kampo roon." },
    },
}

local function attachContextualQueuedResponses()
    for action, variants in pairs(CONTEXTUAL_QUEUED_RESPONSES) do
        local definition = Adapter.Actions[action]
        local response = definition and definition.responsePools
            and definition.responsePools.queued
        if response then
            response.variants = {
                {
                    id = "friendly",
                    key = response.key .. "Friendly",
                    en = variants.friendly.en,
                    tl = variants.friendly.tl,
                    when = { socialStyle = "friendly" },
                    priority = 2,
                },
                {
                    id = "trusted",
                    key = response.key .. "Trusted",
                    en = variants.trusted.en,
                    tl = variants.trusted.tl,
                    when = {
                        relationshipState = {
                            "Friend", "Trusted", "Ally", "Member", "Lover",
                        },
                    },
                    priority = 3,
                },
                {
                    id = "withdrawn",
                    key = response.key .. "Withdrawn",
                    en = variants.withdrawn.en,
                    tl = variants.withdrawn.tl,
                    when = { socialStyle = "withdrawn" },
                    priority = 1,
                },
                {
                    id = "repeated",
                    key = response.key .. "Repeated",
                    en = variants.repeated.en,
                    tl = variants.repeated.tl,
                    when = { previousAction = action },
                    priority = 4,
                },
            }
        end
    end
end

attachContextualQueuedResponses()

function Adapter.Resolve(actionIntent, context)
    if type(actionIntent) ~= "table" then
        return nil, "invalid_action_intent"
    end
    if actionIntent.modifiers and actionIntent.modifiers.negated == true then
        return nil, "negated_action"
    end

    local action = normalized(actionIntent.action)
    local definition = Adapter.Actions[action]
    if type(definition) == "string" then return definition end
    if type(definition) == "table"
        and type(definition.commandID) == "string"
    then
        return definition.commandID
    end
    if type(definition) == "table" and type(definition.destinations) == "table" then
        local commandID = definition.destinations[destinationCategory(actionIntent)]
        if commandID then return commandID end
        return nil, "unsupported_destination"
    end
    return nil, "unmapped_action"
end

function Adapter.Dispatch(actionIntent, context)
    context = type(context) == "table" and context or {}
    local commandID, resolveReason = Adapter.Resolve(actionIntent, context)
    if not commandID then
        return {
            status = resolveReason == "negated_action"
                and "skipped" or "unmapped",
            accepted = false,
            reason = resolveReason,
            action = actionIntent and actionIntent.action,
        }
    end

    local definition = Adapter.Actions[normalized(actionIntent.action)]
    local binding = type(definition) == "table" and definition or nil

    -- Resolve the live facade at dispatch time. The headless harness can
    -- install its translation fallback after module load; retaining a stale
    -- table alias would bypass the current client request boundary.
    local client = (_G.PNC and _G.PNC.Client) or PNC.Client
    if binding and binding.route == "existing_quest_contract" then
        if not client or type(client.RequestSemanticQuest) ~= "function" then
            return {
                status = "unavailable",
                accepted = false,
                reason = "quest_transport_unavailable",
                commandID = commandID,
                action = actionIntent.action,
                binding = binding,
                capabilityID = binding.capabilityID,
                handlerID = binding.handlerID,
            }
        end
        local request = {
            commandID = commandID,
            operation = binding.operation,
            questID = context.questID or "pnc.quest.clinic_supplies",
            npcID = context.npcID or context.targetID,
            giverNPCID = context.giverNPCID or context.npcID
                or context.targetID,
            expectedRevision = context.questRevision,
            requestID = context.requestID,
            conversationID = context.conversationID,
            conversationToken = context.conversationToken,
        }
        local accepted, reason, details = client.RequestSemanticQuest(
            request, context)
        local result = type(details) == "table" and details or {}
        local status = tostring(result.status or "")
        if status == "" then
            status = accepted == true and "accepted" or "rejected"
        end
        return {
            status = status,
            accepted = accepted == true,
            reason = result.reason or reason,
            action = actionIntent.action,
            commandID = commandID,
            binding = binding,
            capabilityID = binding.capabilityID,
            handlerID = binding.handlerID,
            request = request,
            result = result,
        }
    end
    if not client or type(client.SendCompanionCommand) ~= "function" then
        return {
            status = "unavailable",
            accepted = false,
            reason = "command_transport_unavailable",
            commandID = commandID,
            action = actionIntent.action,
            binding = binding,
        }
    end

    local npcID = context.npcID or context.targetID
    local commandContext = {
        origin = "semantic_dialogue",
        commandSource = "semantic_dialogue",
        dialogueID = context.dialogueID,
        requestID = context.requestID,
        semanticAction = actionIntent.action,
        targets = context.targets,
        campSiteHint = context.campSiteHint,
        groupID = context.groupID,
        groupTurnID = context.groupTurnID,
    }
    local request = {
        commandID = commandID,
        npcID = npcID,
        scope = context.scope or "single",
        requestID = context.requestID,
        dialogueID = context.dialogueID,
        commandSource = "semantic_dialogue",
        semanticAction = actionIntent.action,
        targets = context.targets,
        groupID = context.groupID,
        groupTurnID = context.groupTurnID,
    }
    local accepted, reason, targets, details = client.SendCompanionCommand(
        commandID,
        npcID,
        context.scope or "single",
        commandContext
    )
    local resultStatus = accepted ~= true and "rejected"
        or (commandID == "camp" and reason == "network_queued"
            and "pending" or "accepted")
    if accepted ~= true and type(details) == "table"
        and tostring(details.status or "") == "failed"
    then
        resultStatus = "failed"
    end
    local result = {
        status = resultStatus,
        accepted = accepted == true,
        reason = reason,
        commandID = commandID,
        action = actionIntent.action,
        binding = binding,
        capabilityID = binding and binding.capabilityID or nil,
        handlerID = binding and binding.handlerID or nil,
        request = request,
        targets = targets,
        details = details,
    }
    if commandID == "camp" and type(context.campSiteHint) == "table" then
        local hint = context.campSiteHint
        result.siteLabel = hint.label
        result.siteScope = hint.siteScope or hint.scope
        result.siteID = hint.siteID or hint.campfireID
        result.siteRoomType = hint.roomType
        result.siteRisk = hint.risk
    end
    return result
end

return Adapter
