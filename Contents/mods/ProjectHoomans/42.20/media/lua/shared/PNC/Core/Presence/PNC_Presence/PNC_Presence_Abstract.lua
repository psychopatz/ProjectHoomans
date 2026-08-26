local Presence = PNC.Presence
local Internal = Presence.Internal
local Core = PNC.Core
local Const = PNC.Const
local Registry = PNC.Registry
local PathService = PNC.PathService
local ZombieAggro = PNC.ZombieAggro

local function worldAgeHours()
    return getGameTime and getGameTime()
        and getGameTime().getWorldAgeHours
        and getGameTime():getWorldAgeHours() or 0
end

local function notifyAbstraction(record, reason)
    local entityRef = PNC.EntityRef
        and PNC.EntityRef.ForNPC(record.id) or nil
    if PNC.FactionIncidentService
        and PNC.FactionIncidentService.CleanupEntity
        and entityRef
    then
        PNC.FactionIncidentService.CleanupEntity(
            entityRef,
            worldAgeHours(),
            reason or "target_abstracted"
        )
    end
    if PNC.FactionTelemetry then
        PNC.FactionTelemetry.RecordCallback({
            operation = "npc_abstraction",
            worldAgeHours = worldAgeHours(),
            actorKey = entityRef,
            sourceFactionID = PNC.Factions
                and PNC.Factions.GetFactionID
                and PNC.Factions.GetFactionID(record)
                or nil,
            result = "accepted",
            reason = reason or "abstract",
        })
    end
    if PNC.SocialEncounterTracker
        and PNC.SocialEncounterTracker.OnParticipantLeft
        and PNC.SocialEventHooks
    then
        PNC.SocialEncounterTracker.OnParticipantLeft(
            entityRef,
            PNC.SocialEventHooks.WorldAgeHours(),
            reason or "abstract"
        )
    end
end

local function clearLiveRuntime(record)
    record.runtime.target = nil
    record.runtime.lastPathX = nil
    record.runtime.lastPathY = nil
    record.runtime.roaming = nil
    record.runtime.roamGoalX = nil
    record.runtime.roamGoalY = nil
    record.runtime.roamGoalZ = nil
end

local function captureInventory(record, zombie)
    local inventoryOk
    local inventoryReason
    if not PNC.Inventory or not PNC.Inventory.CaptureLooseInventory then
        return
    end
    inventoryOk, inventoryReason =
        PNC.Inventory.CaptureLooseInventory(record, zombie)
    if not inventoryOk then
        Core.LogWarn(
            "PNC inventory abstraction failed npc=" .. tostring(record.id)
                .. " reason=" .. tostring(inventoryReason)
        )
    end
end

local function removeLiveBody(record, zombie, reason)
    captureInventory(record, zombie)
    if PNC.Travel and PNC.Travel.Service then
        PNC.Travel.Service.OnAbstracted(record, zombie)
    end
    record.x = zombie:getX()
    record.y = zombie:getY()
    record.z = zombie:getZ()
    if PathService.Commands and PathService.Commands.Reset then
        PathService.Commands.Reset(record, zombie, reason or "abstract")
    else
        PathService.Reset(zombie, record)
    end
    if ZombieAggro and ZombieAggro.ClearForNPCBody then
        ZombieAggro.ClearForNPCBody(zombie)
    end
    PNC.BodyLifecycle.RemoveLiveBody(record, zombie, reason or "abstract")
end

function Presence.Abstract(record, reason)
    local zombie = Registry.GetLiveZombie(record.id)
    local net = Internal.ResolveNetwork()
    if not Core.IsAuthority()
        or record.presenceState ~= Const.PRESENCE_LIVE
    then
        return false
    end
    notifyAbstraction(record, reason)
    clearLiveRuntime(record)
    if zombie then
        removeLiveBody(record, zombie, reason)
    else
        if PNC.Travel and PNC.Travel.Service then
            PNC.Travel.Service.OnAbstracted(record, nil)
        end
        PNC.BodyLifecycle.RemoveLiveBody(
            record,
            nil,
            reason or "abstract_missing"
        )
    end
    record.presenceState = Const.PRESENCE_ABSTRACT
    if net and net.BroadcastRemoval then
        net.BroadcastRemoval(record.id, reason or "abstract")
    end
    return true
end
