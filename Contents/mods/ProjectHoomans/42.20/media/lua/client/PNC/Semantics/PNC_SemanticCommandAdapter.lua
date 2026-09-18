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

Adapter.RegisterAction("FOLLOW", "follow")
Adapter.RegisterAction("STAY", "stay")
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

    local client = PNC.Client
    if not client or type(client.SendCompanionCommand) ~= "function" then
        return {
            status = "unavailable",
            accepted = false,
            reason = "command_transport_unavailable",
            commandID = commandID,
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
    local accepted, reason, targets, details = client.SendCompanionCommand(
        commandID,
        npcID,
        context.scope or "single",
        commandContext
    )
    local result = {
        status = accepted ~= true and "rejected"
            or (commandID == "camp" and reason == "network_queued"
                and "pending" or "accepted"),
        accepted = accepted == true,
        reason = reason,
        commandID = commandID,
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
