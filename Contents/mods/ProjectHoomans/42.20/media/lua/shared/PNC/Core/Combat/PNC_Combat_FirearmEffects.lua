--[[
    PNC Combat Firearm Effects
    Builds one weapon-driven shot event at the authoritative hit frame. Damage
    and ammunition remain server-owned; clients only reproduce the current
    firearm's sound, muzzle light, shell sound, and tracer metadata.
]]

PNC = PNC or {}
PNC.FirearmEffects = PNC.FirearmEffects or {}

local Effects = PNC.FirearmEffects
local Core = PNC.Core
local Firearms = PNC.Firearms
local Diagnostics = PNC.PerformanceScalingDiagnostics

local function nowMs()
    if Core and type(Core.Now) == "function" then
        return tonumber(Core.Now()) or 0
    end
    if getTimeInMillis then return tonumber(getTimeInMillis()) or 0 end
    return 0
end

local function logFirearmAudit(eventName, record, payload, ...)
    local affiliation
    local hostility
    local fields
    local i
    if not Diagnostics
        or Diagnostics.FirearmAuditEnabled ~= true
        or type(Diagnostics.LogFirearmAudit) ~= "function"
    then
        return false
    end
    affiliation = record and record.affiliation or nil
    hostility = record and record.hostility or nil
    fields = {
        "side=authority",
        "shotId=" .. tostring(payload and payload.shotId or ""),
        "npc=" .. tostring(record and record.id or payload and payload.npcId or ""),
        "class=" .. tostring(record and record.tacticalClass
            or payload and payload.tacticalClass or "unknown"),
        "faction=" .. tostring(record and affiliation and affiliation.factionID
            or payload and payload.factionID or ""),
        "hostility=" .. tostring(record and hostility and hostility.mode
            or payload and payload.hostilityMode or ""),
        "t=" .. tostring(nowMs()),
    }
    for i = 1, select("#", ...) do
        fields[#fields + 1] = tostring(select(i, ...))
    end
    return Diagnostics.LogFirearmAudit(eventName, fields)
end

local function readMethod(target, methodName, ...)
    local method
    if not target then return nil end
    method = target[methodName]
    if type(method) ~= "function" then return nil end
    return method(target, ...)
end

local function noiseMultiplier()
    local options
    local option
    local value
    if not getSandboxOptions then return 1 end
    options = getSandboxOptions()
    option = options and readMethod(options, "getOptionByName", "FirearmNoiseMultiplier") or nil
    value = option and tonumber(readMethod(option, "getValue")) or nil
    return value and math.max(0, value) or 1
end

local function publishWorldSound(shooter, descriptor)
    local radius = math.max(0, math.floor(tonumber(descriptor and descriptor.soundRadius) or 0))
    local volume = math.max(0, math.floor(tonumber(descriptor and descriptor.soundVolume) or 0))
    local outside
    local ok
    if radius <= 0 or volume <= 0 or not shooter then
        return false
    end
    radius = math.floor(radius * noiseMultiplier())
    if radius <= 0 then return false end
    outside = readMethod(shooter, "isOutside")
    if outside == false then
        radius = math.max(1, math.floor(radius * 0.5))
    end
    if shooter.addWorldSoundUnlessInvisible then
        ok = pcall(shooter.addWorldSoundUnlessInvisible, shooter, radius, volume, true)
        if ok then return true end
    end
    if addSound then
        ok = pcall(
            addSound,
            shooter,
            math.floor(tonumber(readMethod(shooter, "getX")) or 0),
            math.floor(tonumber(readMethod(shooter, "getY")) or 0),
            math.floor(tonumber(readMethod(shooter, "getZ")) or 0),
            radius,
            volume
        )
        return ok
    end
    return false
end

local function targetCoordinates(target)
    local object
    if not target then return nil, nil, nil end
    object = target.player or target.worldObject
    if not object and target.kind == "npc" and PNC.Registry and PNC.Registry.GetLiveZombie then
        object = PNC.Registry.GetLiveZombie(target.id)
    end
    return tonumber(object and readMethod(object, "getX") or target.x),
        tonumber(object and readMethod(object, "getY") or target.y),
        tonumber(object and readMethod(object, "getZ") or target.z)
end

function Effects.BuildShotPayload(record, shooter, target, weaponItem)
    local descriptor
    local runtime
    local tx
    local ty
    local tz
    local payload
    local startedAt = nowMs()
    logFirearmAudit("payload_build_start", record, nil,
        "weapon=" .. tostring(weaponItem and readMethod(weaponItem, "getFullType") or ""))
    if not record then
        logFirearmAudit("payload_build_rejected", record, nil,
            "reason=record_missing", "elapsedMs=" .. tostring(nowMs() - startedAt))
        return nil
    end
    descriptor = Firearms and Firearms.Describe
        and Firearms.Describe(record, weaponItem, shooter)
        or nil
    if not descriptor then
        logFirearmAudit("payload_build_rejected", record, nil,
            "reason=weapon_profile_unavailable",
            "elapsedMs=" .. tostring(nowMs() - startedAt))
        return nil
    end
    runtime = record.runtime or {}
    record.runtime = runtime
    runtime.firearmShotSequence = (tonumber(runtime.firearmShotSequence) or 0) + 1
    tx, ty, tz = targetCoordinates(target)
    payload = {
        shotId = table.concat({
            tostring(record.id),
            tostring(runtime.bodyLease or "body"),
            tostring(runtime.firearmShotSequence),
            tostring(math.floor(tonumber(Core and Core.Now and Core.Now()) or 0)),
        }, ":"),
        npcId = tostring(record.id),
        shooterOnlineID = PNC.Network and PNC.Network.GetZombieOnlineID
            and PNC.Network.GetZombieOnlineID(shooter)
            or nil,
        sx = tonumber(shooter and readMethod(shooter, "getX")) or tonumber(record.x) or 0,
        sy = tonumber(shooter and readMethod(shooter, "getY")) or tonumber(record.y) or 0,
        sz = tonumber(shooter and readMethod(shooter, "getZ")) or tonumber(record.z) or 0,
        tx = tx,
        ty = ty,
        tz = tz,
        targetKind = target and tostring(target.kind or "") or nil,
        tacticalClass = record.tacticalClass,
        factionID = record.affiliation and record.affiliation.factionID or nil,
        hostilityMode = record.hostility and record.hostility.mode or nil,
        weaponFullType = descriptor.fullType,
        ammoType = descriptor.ammoType,
        ammoPerShot = descriptor.ammoPerShot,
        shotSound = descriptor.shotSound and tostring(descriptor.shotSound) or nil,
        soundRadius = descriptor.soundRadius,
        soundVolume = descriptor.soundVolume,
        soundGain = descriptor.soundGain,
        projectileCount = descriptor.projectileCount,
        projectileSpread = descriptor.projectileSpread,
        maxRange = descriptor.maxRange,
        piercing = descriptor.piercing == true,
        impactSound = descriptor.impactSound and tostring(descriptor.impactSound) or nil,
        shellFallSound = descriptor.ejectsShell == true
            and descriptor.shellFallSound and tostring(descriptor.shellFallSound)
            or nil,
        rackAfterShoot = descriptor.rackAfterShoot == true,
    }
    logFirearmAudit("payload_built", record, payload,
        "weapon=" .. tostring(payload.weaponFullType or ""),
        "targetKind=" .. tostring(payload.targetKind or ""),
        "target=" .. tostring(payload.tx or "") .. ","
            .. tostring(payload.ty or "") .. "," .. tostring(payload.tz or ""),
        "projectiles=" .. tostring(payload.projectileCount or 1),
        "elapsedMs=" .. tostring(nowMs() - startedAt))
    return payload, descriptor
end

function Effects.Emit(record, shooter, target, weaponItem)
    local payload
    local descriptor
    local startedAt = nowMs()
    local soundPublished
    local dispatched
    local route
    logFirearmAudit("emit_start", record, nil,
        "targetKind=" .. tostring(target and target.kind or ""))
    if not Core or not Core.IsAuthority or not Core.IsAuthority() then
        logFirearmAudit("emit_rejected", record, nil,
            "reason=not_authority", "elapsedMs=" .. tostring(nowMs() - startedAt))
        return false, "not_authority"
    end
    payload, descriptor = Effects.BuildShotPayload(record, shooter, target, weaponItem)
    if not payload then
        logFirearmAudit("emit_rejected", record, nil,
            "reason=payload_unavailable", "elapsedMs=" .. tostring(nowMs() - startedAt))
        return false, "weapon_profile_unavailable"
    end
    soundPublished = publishWorldSound(shooter, descriptor)
    logFirearmAudit("world_sound_complete", record, payload,
        "result=" .. tostring(soundPublished),
        "radius=" .. tostring(payload.soundRadius or 0),
        "volume=" .. tostring(payload.soundVolume or 0))
    if PNC.Network and PNC.Network.BroadcastFirearmShot then
        route = "network_broadcast"
        dispatched = PNC.Network.BroadcastFirearmShot(payload)
    elseif (not isServer or not isServer()) and triggerEvent and PNC.Const then
        route = "local_server_command"
        triggerEvent("OnServerCommand", PNC.Const.MODULE, PNC.Const.CMD_FIREARM_SHOT, payload)
        dispatched = true
    else
        route = "none"
        dispatched = false
    end
    logFirearmAudit("emit_complete", record, payload,
        "route=" .. tostring(route),
        "dispatched=" .. tostring(dispatched),
        "elapsedMs=" .. tostring(nowMs() - startedAt))
    return true, payload
end

return Effects
