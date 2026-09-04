-- Command outcome policy for player/NPC interactive exchanges.
--
-- Delivery is delegated to the bounded Core queue adapter.  This module only
-- maps command outcomes to flavor IDs and suppresses duplicate legacy acks.

PNC = PNC or {}
PNC.CompanionCommandPresentation = PNC.CompanionCommandPresentation or {}

require "PNC/Commands/PNC_CompanionCommandInteractionQueue"

local Presentation = PNC.CompanionCommandPresentation
local Registry = PNC.Registry

Presentation.CommandAckSuppressions =
    Presentation.CommandAckSuppressions or {}

local function copyContext(context)
    local output = {}
    local key
    if type(context) ~= "table" then return output end
    for key, value in pairs(context) do output[key] = value end
    return output
end

local function currentTime()
    return PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
end

function Presentation.IsCommandAcknowledgementSuppressed(commandID, npcID)
    local key = tostring(commandID or "") .. ":" .. tostring(npcID or "")
    local expiresAt = tonumber(Presentation.CommandAckSuppressions[key])
    if not expiresAt then return false end
    if currentTime() >= expiresAt then
        Presentation.CommandAckSuppressions[key] = nil
        return false
    end
    return true
end

local function suppressAcknowledgements(commandID, targets)
    local expiresAt = currentTime()
        + (tonumber(PNC.Const and PNC.Const.COMPANION_COMMAND_FEEDBACK_MS)
            or 5000)
    local key
    for _, target in ipairs(targets or {}) do
        key = tostring(commandID or "") .. ":"
            .. tostring(target and (target.id or target.npcID) or "")
        if string.sub(key, -1) ~= ":" then
            Presentation.CommandAckSuppressions[key] = expiresAt
        end
    end
end

local function respondentFor(target, targets)
    if target then return target end
    if type(targets) == "table" then return targets[1] end
    return nil
end

function Presentation.ShowCampInteraction(player, target, targets, outcome,
    context, options)
    context = copyContext(context)
    context.commandID = "camp"
    context.playerActor = player
    context.target = target
    context.targets = targets
    return Presentation.ShowCommandInteraction(
        player, "camp", target, targets, outcome, context, options
    )
end

function Presentation.ShowCommandInteraction(player, commandID, target, targets,
    outcome, context, options)
    local respondent = respondentFor(target, targets)
    local playerContext = copyContext(context)
    local npcContext
    local actor
    local playerFlavorID
    local responseID
    local playerShown
    local npcShown
    local queued
    local currentTarget
    local targetList = {}
    options = type(options) == "table" and options or {}
    commandID = tostring(commandID or "")
    outcome = tostring(outcome or "")
    playerContext.playerActor = player
    playerContext.target = target
    playerContext.targets = targets
    playerContext.commandID = commandID
    if target then targetList[#targetList + 1] = target end
    if type(targets) == "table" then
        for _, value in ipairs(targets) do
            if value ~= target then targetList[#targetList + 1] = value end
        end
    end
    if #targetList == 0 and respondent then targetList[1] = respondent end
    if #targetList == 0 then
        if commandID ~= "camp" then return false end
        playerFlavorID = outcome == "invalid"
            and "camp_rejected" or "camp_no_npc"
        queued = Presentation.EnqueueFlavor(
            playerFlavorID,
            "player",
            player,
            playerContext,
            {
                eventID = type(context) == "table" and context.requestID
                    or nil,
                family = "emote_interaction",
            }
        )
        return queued == true
    end
    if outcome == "none" then
        if commandID ~= "camp" then return false end
        queued = Presentation.EnqueueFlavor(
            "camp_no_npc", "player", player, playerContext, {
                eventID = type(context) == "table" and context.requestID
                    or nil,
                family = "emote_interaction",
            }
        )
        return queued == true
    end
    if outcome ~= "pending" and outcome ~= "valid"
        and outcome ~= "invalid"
    then
        return false
    end
    playerFlavorID = outcome == "invalid" and "camp_rejected" or commandID
    if options.playerAlreadySpoke == true then
        playerShown = true
    else
        playerShown = Presentation.EnqueueFlavor(
            playerFlavorID,
            "player",
            player,
            playerContext,
            {
                eventID = type(context) == "table" and context.requestID
                    or nil,
                family = "emote_interaction",
            }
        )
    end
    if outcome == "pending" then
        suppressAcknowledgements(commandID, targetList)
        return playerShown == true
    end
    responseID = outcome == "invalid" and "camp_rejected" or commandID
    for _, value in ipairs(targetList) do
        currentTarget = value
        actor = Registry and Registry.GetLiveZombie and currentTarget.id
            and Registry.GetLiveZombie(currentTarget.id) or nil
        actor = actor or (currentTarget == target
            and type(context) == "table" and context.liveActor or nil)
        npcContext = copyContext(context)
        npcContext.playerActor = player
        npcContext.commandID = commandID
        npcContext.target = currentTarget
        npcContext.targets = { currentTarget }
        npcContext.npcID = currentTarget.id
        npcContext.seed = npcContext.seed or npcContext.requestID
        queued = Presentation.EnqueueFlavor(
            responseID,
            "npc",
            actor,
            npcContext,
            {
                eventID = tostring(type(context) == "table"
                    and (context.requestID or context.eventID) or commandID)
                    .. ":npc:" .. tostring(currentTarget.id or ""),
                family = "emote_interaction",
            }
        )
        if queued == true then npcShown = true end
    end
    if npcShown == true and outcome ~= "pending" then
        suppressAcknowledgements(commandID, targetList)
    end
    return playerShown == true or npcShown == true
end

return Presentation
