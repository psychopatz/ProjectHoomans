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

local function safeMethod(target, methodName, ...)
    local method
    local ok
    local value
    if not target then return nil end
    method = target[methodName]
    if type(method) ~= "function" then return nil end
    ok, value = pcall(method, target, ...)
    return ok and value or nil
end

local function noiseMultiplier()
    local options
    local option
    local value
    if not getSandboxOptions then return 1 end
    local ok
    ok, options = pcall(getSandboxOptions)
    if not ok then options = nil end
    option = options and safeMethod(options, "getOptionByName", "FirearmNoiseMultiplier") or nil
    value = option and tonumber(safeMethod(option, "getValue")) or nil
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
    outside = safeMethod(shooter, "isOutside")
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
            math.floor(tonumber(safeMethod(shooter, "getX")) or 0),
            math.floor(tonumber(safeMethod(shooter, "getY")) or 0),
            math.floor(tonumber(safeMethod(shooter, "getZ")) or 0),
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
    return tonumber(object and safeMethod(object, "getX") or target.x),
        tonumber(object and safeMethod(object, "getY") or target.y),
        tonumber(object and safeMethod(object, "getZ") or target.z)
end

function Effects.BuildShotPayload(record, shooter, target, weaponItem)
    local descriptor = Firearms and Firearms.Describe
        and Firearms.Describe(record, weaponItem)
        or nil
    local runtime
    local tx
    local ty
    local tz
    if not record or not descriptor then return nil end
    runtime = record.runtime or {}
    record.runtime = runtime
    runtime.firearmShotSequence = (tonumber(runtime.firearmShotSequence) or 0) + 1
    tx, ty, tz = targetCoordinates(target)
    return {
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
        sx = tonumber(shooter and safeMethod(shooter, "getX")) or tonumber(record.x) or 0,
        sy = tonumber(shooter and safeMethod(shooter, "getY")) or tonumber(record.y) or 0,
        sz = tonumber(shooter and safeMethod(shooter, "getZ")) or tonumber(record.z) or 0,
        tx = tx,
        ty = ty,
        tz = tz,
        targetKind = target and tostring(target.kind or "") or nil,
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
    }, descriptor
end

function Effects.Emit(record, shooter, target, weaponItem)
    local payload
    local descriptor
    if not Core or not Core.IsAuthority or not Core.IsAuthority() then
        return false, "not_authority"
    end
    payload, descriptor = Effects.BuildShotPayload(record, shooter, target, weaponItem)
    if not payload then
        return false, "weapon_profile_unavailable"
    end
    publishWorldSound(shooter, descriptor)
    if PNC.Network and PNC.Network.BroadcastFirearmShot then
        PNC.Network.BroadcastFirearmShot(payload)
    elseif (not isServer or not isServer()) and triggerEvent and PNC.Const then
        triggerEvent("OnServerCommand", PNC.Const.MODULE, PNC.Const.CMD_FIREARM_SHOT, payload)
    end
    return true, payload
end

return Effects
