local Health = PNC.Health
local Core = PNC.Core
local Const = PNC.Const
local Registry = PNC.Registry

function Health.ApplyDamageToPlayer(player, amount)
    local current
    if not player or not player.getHealth or not player.setHealth then
        return false
    end
    current = tonumber(player:getHealth()) or 1
    player:setHealth(
        math.max(0, current - (tonumber(amount) or 0) / 100)
    )
    return true
end

local function releaseOwnedWork(record)
    if PNC.WorkService
        and PNC.WorkService.Commands
        and PNC.WorkService.Commands.ReleaseWorker
    then
        PNC.WorkService.Commands.ReleaseWorker(
            record.id,
            "worker_died"
        )
    end
    if PNC.CompanionVehicle and PNC.CompanionVehicle.Release then
        PNC.CompanionVehicle.Release(record, "npc_death")
    end
end

local function markDeadState(record, health, reason)
    if PNC.NPCWounds and PNC.NPCWounds.SetOverallHealth then
        PNC.NPCWounds.SetOverallHealth(record, 0)
    end
    health.current = 0
    health.state = "dead"
    health.reviveUntil = 0
    health.reviveProtectionUntil = 0
    health.recentDamageUntil =
        Core.Now() + Const.RECENT_DAMAGE_SHOW_MS
    record.alive = false
    record.presenceState = Const.PRESENCE_CORPSE
    record.runtime.forceLive = false
    record.runtime.target = nil
    record.runtime.attackAction = nil
    record.runtime.lastPathX = nil
    record.runtime.lastPathY = nil
    record.deathReason = reason or "unknown"
end

local function notifyDeathSystems(record)
    if PNC.Factions and PNC.Factions.OnNPCDeath then
        PNC.Factions.OnNPCDeath(record.id)
    end
    if not PNC.SocialEventHooks then return end
    if PNC.SocialEventHooks.DiscardRescueContributions then
        PNC.SocialEventHooks.DiscardRescueContributions(record)
    end
    if PNC.SocialEncounterTracker
        and PNC.SocialEncounterTracker.OnParticipantLeft
    then
        PNC.SocialEncounterTracker.OnParticipantLeft(
            PNC.EntityRef.ForNPC(record.id),
            PNC.SocialEventHooks.WorldAgeHours(),
            "death"
        )
    end
end

local function createCorpse(record, zombie, reason)
    local create
    local converted
    local result
    if not zombie then
        if not record.corpse then
            record.corpse = {
                token = nil,
                x = record.x,
                y = record.y,
                z = record.z,
                createdWorldHour = 0,
            }
        end
        return
    end
    if zombie.setHealth then zombie:setHealth(0) end
    create = PNC.BodyLifecycle
        and PNC.BodyLifecycle.CreateVanillaCorpse or nil
    if create then
        converted, result =
            create(record, zombie, reason or "death")
    else
        converted, result = false, "corpse_service_unavailable"
    end
    if converted ~= true and Core and Core.Log then
        Core.Log(
            "ERROR",
            "NPC corpse creation failed npc="
                .. tostring(record.id)
                .. " reason=" .. tostring(result or "unknown")
        )
    end
end

local function retireDeadRecord(record)
    local deathMarker
    local colonyOwned
    local retired = false
    colonyOwned = Registry
        and Registry.IsColonyOwnedNPC
        and Registry.IsColonyOwnedNPC(record)
    if Registry and Registry.AddDeathMarker then
        if colonyOwned ~= false then
            deathMarker = Registry.AddDeathMarker(record)
        end
    end
    if deathMarker and Registry and Registry.RemoveRecord then
        record.runtime.deathRetired = true
        if PNC.Network and PNC.Network.BroadcastRemoval then
            PNC.Network.BroadcastRemoval(record.id, "death")
        end
        Registry.RemoveRecord(record.id)
        retired = true
    elseif colonyOwned == false and Registry then
        -- Unowned world NPCs still need a removal event so clients do not
        -- retain their last roster snapshot, but they do not receive a
        -- persistent map marker or a corpse-audit record.
        record.runtime.deathRetired = true
        if PNC.Network and PNC.Network.BroadcastRemoval then
            PNC.Network.BroadcastRemoval(record.id, "death_untracked")
        end
        if Registry.RemoveRecord then
            Registry.RemoveRecord(record.id)
            retired = true
        elseif Registry.MarkDirty then
            Registry.MarkDirty(record, "health")
        end
    elseif Registry and Registry.MarkDirty then
        Registry.MarkDirty(record, "health")
    end
    return deathMarker, retired
end

function Health.Kill(record, zombie, reason)
    local health = Health.Ensure(record)
    local deathMarker
    local retired
    releaseOwnedWork(record)
    markDeadState(record, health, reason)
    notifyDeathSystems(record)
    createCorpse(record, zombie, reason)
    deathMarker, retired = retireDeadRecord(record)
    return retired == true or deathMarker ~= nil, deathMarker
end
