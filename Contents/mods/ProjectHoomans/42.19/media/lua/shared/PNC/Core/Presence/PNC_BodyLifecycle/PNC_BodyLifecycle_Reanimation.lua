-- Authority-owned handoff from a managed infected corpse to one ordinary
-- engine zombie. Once spawned, PNC removes every control tag and safeguard and
-- permanently releases the zombie to vanilla AI and multiplayer replication.

PNC = PNC or {}
PNC.BodyLifecycle = PNC.BodyLifecycle or {}
PNC.BodyLifecycle.Internal = PNC.BodyLifecycle.Internal or {}

local Lifecycle = PNC.BodyLifecycle
local Internal = Lifecycle.Internal
local Core = PNC.Core
local Const = PNC.Const

local CONTROL_MODDATA_KEYS = {
    "PNC_NPC", "PNC_UUID", "PNC_BodyKind", "PNC_BodyLease",
    "PNC_CorpseToken", "PNC_TagVersion", "PNC_PersistedShell",
    "PNC_ShellVersion", "PNC_BaseOutfit", "PNC_LiveBodyInstanceID",
    "PNC_LiveBodyOnlineID", "PNC_AggroNPCId", "PNC_AggroNPCUntil",
    "PNC_AggroPathAt", "PNC_AggroPathX", "PNC_AggroPathY",
    "PNC_BumpReleaseAt", "PNC_BumpReleasePending", "PNC_CombatReaction",
    "PNC_LastAttackAt", "PNC_ZombieID", "PNC_ClientAttackKey",
    "PNC_ClientHandsKey", "PNC_ClientHumanVisualAt", "PNC_ClientMotionKey",
    "PNC_ClientSpecialKey", "PNC_ClientTreatmentSoundKey",
    "PNC_ClientVisualKey", "PNC_DebugAnimCycleKey",
    "PNC_DebugAnimCycleStartAt", "PNC_DeathMarkerID", "PNC_DeathName",
}

local CONTROL_VARIABLES = {
    "PNCLive", "PNCActor", "PNCAnim", "PNCMoveAnim", "PNCWalkType",
    "PNCPrimary", "PNCSecondary", "PNCPrimaryType", "PNCImmediateAnim",
    "PNCAnimSpeed", "PNCEngineWalkType", "PNCMoving", "PNCIsRunning",
    "PNCIsCrawling", "NoLungeTarget", "NoLungeAttack",
}

local function setBoolean(zombie, methodName, value)
    local method = zombie and zombie[methodName] or nil
    if method then pcall(method, zombie, value) end
end

local function clearManagedState(record, zombie)
    local modData = zombie and zombie.getModData and zombie:getModData() or nil
    local i
    if modData then
        for i = 1, #CONTROL_MODDATA_KEYS do
            modData[CONTROL_MODDATA_KEYS[i]] = nil
        end
        modData.PNC_ReanimatedFrom = tostring(record.id)
    end
    for i = 1, #CONTROL_VARIABLES do
        if zombie.clearVariable then
            pcall(zombie.clearVariable, zombie, CONTROL_VARIABLES[i])
        elseif zombie.setVariable then
            pcall(zombie.setVariable, zombie, CONTROL_VARIABLES[i], false)
        end
    end
end

function Lifecycle.IsReanimationDue(record)
    local markerRuntime
    if record and record.infected ~= nil then
        markerRuntime = PNC.Registry and PNC.Registry.GetDeathMarkerRuntime
            and PNC.Registry.GetDeathMarkerRuntime(record.id) or nil
        return record.infected == true
            and markerRuntime
            and Core.Now() >= (tonumber(markerRuntime.reanimateAt) or 0)
            or false
    end
    local infection = record and record.health and record.health.body
        and record.health.body.infection or nil
    local reanimateAt = tonumber(infection and infection.reanimateAtWorldHour)
    return record and record.alive == false
        and infection and infection.fatal == true
        and reanimateAt and reanimateAt > 0
        and Internal.worldHour() >= reanimateAt or false
end

function Lifecycle.ReleaseReanimatedNPC(record, zombie)
    if not record or not zombie or not Core.IsAuthority() then return false end
    clearManagedState(record, zombie)

    -- Restore only the safeguards used to make the managed IsoZombie harmless.
    -- Do not normalize its posture, reanimation state, health, speed, target,
    -- or animation variables: corpse:reanimate() owns those vanilla states.
    setBoolean(zombie, "setUseless", false)
    setBoolean(zombie, "setNoTeeth", false)
    setBoolean(zombie, "setZombiesDontAttack", false)
    setBoolean(zombie, "setInvincible", false)
    if PNC.Registry and PNC.Registry.GetDeathMarker
        and PNC.Registry.GetDeathMarker(record.id)
        and PNC.Registry.RemoveDeathMarker
    then
        PNC.Registry.RemoveDeathMarker(record.id)
    elseif record.health and PNC.Registry then
        if PNC.Network and PNC.Network.BroadcastRemoval then
            PNC.Network.BroadcastRemoval(record.id, "zombified")
        end
        if PNC.Registry.RemoveRecord then PNC.Registry.RemoveRecord(record.id) end
    end
    return true
end

function Lifecycle.SpawnReanimatedZombie(record, corpse)
    local state
    local now
    local retryAt
    local x
    local y
    local z
    local outfit
    local femaleChance
    local ok
    local zombieList
    local zombie
    local usedCorpseReanimation = false
    if not record or not corpse or not Core.IsAuthority() then
        return false, "not_authority_or_missing"
    end
    if not Lifecycle.IsReanimationDue(record) then return false, "not_due" end

    state = PNC.Registry and PNC.Registry.GetDeathMarkerRuntime
        and PNC.Registry.GetDeathMarkerRuntime(record.id)
        or Internal.ensureRuntime(record)
    now = Core.Now()
    retryAt = tonumber(state.nextReanimationSpawnAt) or 0
    if state.reanimationSpawned == true then return false, "already_spawned" end
    if state.reanimationSpawnInProgress == true then return false, "spawn_in_progress" end
    if now < retryAt then return false, "retry_cooldown" end
    state.reanimationSpawnInProgress = true

    -- This is the normal path. The engine transfers the corpse visual,
    -- inventory, worn items, and modData, allocates the server zombie ID,
    -- inserts it into the cell, and removes the corpse.
    if corpse.reanimate then
        ok, zombie = pcall(corpse.reanimate, corpse)
        usedCorpseReanimation = ok and zombie ~= nil
    end

    -- Keep a narrow fallback for unusual corpses/builds where the engine
    -- method is unavailable or rejects the corpse. This remains authority-only.
    if not usedCorpseReanimation and addZombiesInOutfit then
        x = corpse.getX and corpse:getX() or tonumber(record.x) or 0
        y = corpse.getY and corpse:getY() or tonumber(record.y) or 0
        z = corpse.getZ and corpse:getZ() or tonumber(record.z) or 0
        outfit = PNC.VisualProfiles and PNC.VisualProfiles.ResolveSpawnOutfit
            and PNC.VisualProfiles.ResolveSpawnOutfit(record) or nil
        femaleChance = record.isFemale == true and 100 or 0
        ok, zombieList = pcall(
            addZombiesInOutfit,
            x, y, z, 1, outfit, femaleChance,
            false, -- crawler
            false, -- fall on front
            false, -- fake dead
            false, -- knocked down
            false, -- invulnerable
            false, -- sitting
            1      -- health
        )
        zombie = ok and zombieList and zombieList.size
            and zombieList:size() > 0 and zombieList:get(0) or nil
    end
    state.reanimationSpawnInProgress = false
    if not zombie then
        state.reanimationSpawnAttempts =
            (tonumber(state.reanimationSpawnAttempts) or 0) + 1
        state.nextReanimationSpawnAt =
            now + (tonumber(Const.CORPSE_REANIMATE_RETRY_MS) or 2000)
        state.corpseState = "reanimation_retry"
        if record.runtime then
            Internal.mark(
                record,
                "corpse",
                "reanimation_retry",
                "reanimation_spawn_failed",
                ok and "reanimation_returned_no_zombie"
                    or tostring(zombieList or "engine_reanimation_failed")
            )
        end
        if state.reanimationSpawnAttempts == 1
            or state.reanimationSpawnAttempts % 10 == 0
        then
            Core.LogWarn("Failed to spawn reanimated NPC zombie npc="
                .. tostring(record.id)
                .. " attempts=" .. tostring(state.reanimationSpawnAttempts))
        end
        return false, "spawn_failed"
    end

    state.reanimationSpawned = true
    state.corpseState = "reanimated"
    if not usedCorpseReanimation then
        if zombie.DoZombieStats then pcall(zombie.DoZombieStats, zombie) end
        Internal.removeCorpse(corpse)
    end
    if not Lifecycle.ReleaseReanimatedNPC(record, zombie) then
        return false, "release_failed"
    end
    return true, zombie
end

return Lifecycle
