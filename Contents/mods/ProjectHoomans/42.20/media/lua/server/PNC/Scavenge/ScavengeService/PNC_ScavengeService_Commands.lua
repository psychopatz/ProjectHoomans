if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local WorldLoot = require "PsychopatzCore/WorldLoot/PsychopatzWorldLoot"
local Service = PNC.ScavengeService
local Internal = Service.Internal
local Policy = PNC.ScavengePolicy
local TERMINAL_STATES = Internal.TERMINAL_STATES
local copy = Internal.Copy
local touch = Internal.Touch
local activity = Internal.Activity
local ownerMatches = Internal.OwnerMatches
local authorizeNPC = Internal.AuthorizeNPC
local sessionForNPC = Internal.SessionForNPC
local releaseReservations = Internal.ReleaseReservations
local removeSession = Internal.RemoveSession

function Service.SetAutoGrab(player, arguments)
    arguments = type(arguments) == "table" and arguments or {}
    local ok, result = Policy.SetAutoGrab(player, arguments.fullType,
        arguments.enabled == true)
    if not ok then return false, result end
    local session = Service.GetSession(arguments.sessionId)
    if session and ownerMatches(session, player) then
        for _, entry in ipairs(session.manifest) do
            if entry.fullType == arguments.fullType then
                entry.autoGrab = arguments.enabled == true
            end
        end
        touch(session, "AutoGrabChanged", {
            fullType = arguments.fullType,
            enabled = arguments.enabled == true,
        }, "immediate")
    end
    return true, "auto_grab_updated", result
end

function Service.RemoveAutoGrab(player, arguments)
    arguments = copy(arguments or {})
    arguments.enabled = false
    return Service.SetAutoGrab(player, arguments)
end

function Service.SetSearchPreferences(player, arguments)
    local ok, result = Policy.SetPreferences(player,
        arguments and arguments.sourcePolicy)
    return ok, ok and "preferences_updated" or result, result
end

function Service.RequestPolicy(player, arguments)
    local record, reason = authorizeNPC(player, arguments and arguments.npcId)
    if not record then return false, reason end
    return true, "policy_snapshot", {
        policyOnly = true,
        npcId = tostring(record.id),
        npcName = tostring(record.name or record.id),
        sourcePolicy = Policy.GetPreferences(player),
        policy = Policy.Snapshot(player),
        revision = 0,
    }
end

function Service.RequestSnapshot(player, arguments)
    local session = Service.GetSession(arguments and arguments.sessionId)
        or sessionForNPC(arguments and arguments.npcId)
    if not session then return false, "session_not_found" end
    if not ownerMatches(session, player) then return false, "session_not_owned" end
    Service.SendSnapshot(session, player)
    return true, "snapshot_sent", Service.BuildSnapshot(session)
end

function Service.BringBack(record, player)
    local session = record and sessionForNPC(record.id) or nil
    if session then
        releaseReservations(session, "bring_back")
        if not TERMINAL_STATES[session.state] then
            session.state = "CANCELLED"
            session.phase = "CANCELLED"
            activity(session, "BRING_BACK", nil, "return_home")
            WorldLoot.ReleaseSession(session.worldLootSessionId)
            session.worldLootReleased = true
            touch(session, "CollectionCancelled", {
                reason = "bring_back",
            }, "immediate")
        end
        if PNC.TaskLeaseService and PNC.TaskLeaseService.ForNPC(record.id) then
            PNC.Tasking.Commands.CancelForNPC(record.id, "SCAVENGE_BRING_BACK")
        end
    end
    if PNC.ColonyStorageService
        and PNC.ColonyStorageService.RequestNPCCourierDeposit
    then
        local ok = PNC.ColonyStorageService.RequestNPCCourierDeposit(player, {
            npcId = record.id,
            requestId = PNC.Core.GenerateID("scavenge_bring_back"),
        })
        if ok == true then return true end
    end
    return false
end

function Service.ReleaseTerminal(sessionId)
    local session = Service.GetSession(sessionId)
    if not session or not TERMINAL_STATES[session.state] then return false end
    return removeSession(session, "terminal_release")
end

return Service
