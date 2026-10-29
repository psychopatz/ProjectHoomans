-- Command resolution and authoritative client dispatch.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

require "PNC/Semantics/PNC_SemanticCommandAdapter_Registry"
local Adapter = PNC.Semantics.CommandAdapter
local Internal = Adapter.Internal
local normalized = Internal.Normalize

local function destinationCategory(actionIntent)
    local destination = actionIntent and actionIntent.destination
    return normalized(destination and (
        destination.category or destination.concept or destination.value
    ))
end

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
    local encounterEpisodeID = actionIntent.modifiers
        and actionIntent.modifiers.encounterEpisodeID or nil
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
        encounterEpisodeID = encounterEpisodeID,
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
