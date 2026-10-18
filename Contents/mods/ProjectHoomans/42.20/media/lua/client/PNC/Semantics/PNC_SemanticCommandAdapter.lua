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
Adapter.RegisterAction("STOP", "stay")
Adapter.RegisterAction("GO", {
    destinations = {
        HOME = "return_home",
    },
})
-- All CAMP scopes use the same authoritative command. Group admission still
-- batches nearby targets in the command registry, while a single recipient
-- receives the same durable camp order instead of entering a second semantic
-- action-plan path that can acknowledge without taking movement ownership.
Adapter.RegisterAction("CAMP", "camp")

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

    local client = PNC.Client
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
