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

function Adapter.Resolve(actionIntent)
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
    local commandID, resolveReason = Adapter.Resolve(actionIntent)
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
    }
    local accepted, reason, targets = client.SendCompanionCommand(
        commandID,
        npcID,
        context.scope or "single",
        commandContext
    )
    return {
        status = accepted == true and "accepted" or "rejected",
        accepted = accepted == true,
        reason = reason,
        commandID = commandID,
        targets = targets,
    }
end

return Adapter
