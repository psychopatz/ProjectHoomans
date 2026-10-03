-- Client presentation for companion command results.

local Internal = PNC.Client.Internal
local ClientState = PNC.Network.ClientState
local Registry = PNC.Registry

require "PNC/UI/Nameplates/PNC_NameplateToolFeedback"
local ToolFeedback = PNC.NameplateToolFeedback

local function recordCampResult(args)
    local perceptionDebug
    local diagnostics
    args = type(args) == "table" and args or {}
    if tostring(args.commandID or "") ~= "camp" then return end
    perceptionDebug = PNC.PerceptionDebug
    diagnostics = perceptionDebug
        and perceptionDebug.CampDiagnostics or nil
    if not diagnostics or type(diagnostics.RecordServer) ~= "function" then
        pcall(require,
            "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_CampDiagnostics")
        perceptionDebug = PNC.PerceptionDebug
        diagnostics = perceptionDebug
            and perceptionDebug.CampDiagnostics or nil
    end
    if diagnostics and type(diagnostics.RecordServer) == "function" then
        diagnostics.RecordServer(args)
    end
end

local function recordManualActivityResult(args)
    local targets = args.targets
    local handled = false
    if type(targets) == "table" then
        for _, value in ipairs(targets) do
            if PNC.Client and PNC.Client.RecordManualActivityDiagnostic then
                PNC.Client.RecordManualActivityDiagnostic(
                    value,
                    args.commandID,
                    args.accepted == true,
                    args.reason,
                    args.requestID,
                    args.details
                )
                handled = true
            end
        end
    end
    if not handled and args.id and PNC.Client
        and PNC.Client.RecordManualActivityDiagnostic
    then
        PNC.Client.RecordManualActivityDiagnostic(
            args.id,
            args.commandID,
            args.accepted == true,
            args.reason,
            args.requestID,
            args.details
        )
    end
end

local function resolveCompanionTargets(args)
    local targets = {}
    local targetID
    local targetEntry
    for _, value in ipairs(args.targets or {}) do
        targetID = tostring(value or "")
        if targetID ~= "" then
            targetEntry = Registry and Registry.Get
                and Registry.Get(targetID) or nil
            targetEntry = targetEntry or ClientState.snapshots
                and ClientState.snapshots[targetID] or nil
            targets[#targets + 1] = targetEntry
                or { id = targetID }
        end
    end
    targetID = args.dialogueID or args.id
    if #targets == 0 and targetID then
        targetID = tostring(targetID)
        local target = Registry and Registry.Get and Registry.Get(targetID)
            or nil
        target = target or ClientState.snapshots
            and ClientState.snapshots[targetID] or nil
        if target then targets[1] = target end
    end
    return targets
end

local function handleCompanionEmoteResult(args, player)
    local targets = resolveCompanionTargets(args)
    local target = targets[1]
    if not target then return end
    local resultReason = tostring(args.reason or "")
    local outcome = args.accepted == true and "valid"
        or ((string.sub(resultReason, 1, 5) == "camp_"
            or string.sub(resultReason, 1, 9) == "campfire_")
            and "invalid")
        or nil
    if not outcome
        or not PNC.CompanionCommandPresentation
        or not PNC.CompanionCommandPresentation.ShowCommandInteraction
    then
        return
    end
    PNC.CompanionCommandPresentation.ShowCommandInteraction(
        player,
        args.commandID,
        target,
        targets,
        outcome,
        {
            origin = tostring(args.commandSource or ""),
            commandID = args.commandID,
            target = target,
            targets = targets,
            playerActor = player,
            requestID = args.requestID,
            seed = args.requestID,
        },
        { playerAlreadySpoke = true }
    )
end

local function handleCampResult(args, player)
    local targetID = args.dialogueID or args.id
    local actor = Registry and Registry.GetLiveZombie and targetID
        and Registry.GetLiveZombie(targetID) or nil
    local target = Registry and Registry.Get and targetID
        and Registry.Get(targetID) or nil
    target = target or ClientState.snapshots
        and targetID
        and ClientState.snapshots[tostring(targetID)] or nil
    local resultReason = tostring(args.reason or "")
    if (string.sub(resultReason, 1, 5) ~= "camp_"
        and string.sub(resultReason, 1, 9) ~= "campfire_")
        or not PNC.CompanionCommandPresentation
        or not PNC.CompanionCommandPresentation.ShowCommandRejection
    then
        return
    end
    PNC.CompanionCommandPresentation.ShowCommandRejection(
        player,
        actor,
        args.commandID,
        args.reason,
        {
            target = target,
            playerActor = player,
            requestID = args.requestID,
            seed = args.requestID,
        }
    )
end

function Internal.HandleCompanionCommandResult(args)
    args = type(args) == "table" and args or {}
    recordCampResult(args)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local commandSource = tostring(args.commandSource or "")
    if commandSource == "llm_tool"
        and ToolFeedback and ToolFeedback.PushResult
    then
        ToolFeedback.PushResult(args)
    end
    if commandSource == "colonist_activities"
        or string.match(tostring(args.commandID or ""), "^manual_")
            ~= nil
    then
        recordManualActivityResult(args)
        return
    end
    if commandSource == "companion_emote" then
        handleCompanionEmoteResult(args, player)
        return
    end
    if tostring(args.commandID or "") ~= "camp" then
        return
    end
    handleCampResult(args, player)
end

return Internal
