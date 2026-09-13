-- Native Project Zomboid firearm presentation bridge.
--
-- This module intentionally knows nothing about pistol/rifle families or PNC
-- weapon IDs. Any standard HandWeapon that reports itself as an aimed firearm
-- and supplies the normal engine metadata can use this path.

PNC = PNC or {}
PNC.ClientNativeFirearmEffects = PNC.ClientNativeFirearmEffects or {}

local Native = PNC.ClientNativeFirearmEffects

Native.Failures = Native.Failures or {}
Native.EffectsManager = Native.EffectsManager
Native.BulletTracerEffects = Native.BulletTracerEffects

local function readMethod(target, methodName, ...)
    local method
    if not target then return nil end
    method = target[methodName]
    if type(method) ~= "function" then return nil end
    return method(target, ...)
end

-- Native state/effect calls remain protected because they cross into mutable
-- Java engine state and must degrade to the existing fallback on failure.
local function callNative(target, methodName, ...)
    local method
    if not target then return false, nil end
    method = target[methodName]
    if type(method) ~= "function" then return false, nil end
    return pcall(method, target, ...)
end

-- A tracer burst can contain many projectiles. Protect the whole native
-- emission batch once instead of wrapping every addEffect call separately.
local function callNativeBatch(callback)
    return pcall(callback)
end

local function recordFailure(reason)
    reason = tostring(reason or "unknown")
    if Native.Failures[reason] then return end
    Native.Failures[reason] = true
    if PNC.Core and PNC.Core.Log then
        PNC.Core.Log("WARN", "native_firearm_effect_fallback reason=" .. reason)
    elseif print then
        print("[ProjectHoomans] native_firearm_effect_fallback reason=" .. reason)
    end
end

Native.RecordFailure = recordFailure

local function nativeClass(className)
    local root = zombie
    local iso = root and root.iso or nil
    local objects = iso and iso.objects or nil
    if className == "EffectsManager" then
        return root and root.EffectsManager or EffectsManager
    end
    return objects and objects.IsoBulletTracerEffects or IsoBulletTracerEffects
end

local function nativeSingleton(classObject)
    local getter
    local ok
    local instance
    if not classObject then return nil end
    getter = classObject.getInstance
    if type(getter) ~= "function" then return nil end
    -- This is an optional Java singleton, not a normal Lua API. Some builds
    -- expose the class name but do not expose a callable getInstance bridge;
    -- contain that one boundary failure so the Bandits-compatible fallback
    -- can still run.
    ok, instance = pcall(getter)
    return ok and instance or nil
end

local function getEffectsManager()
    local classObject
    if Native.EffectsManager then return Native.EffectsManager end
    classObject = nativeClass("EffectsManager")
    if not classObject then
        recordFailure("effects_manager_class_unavailable")
        return nil
    end
    Native.EffectsManager = nativeSingleton(classObject)
    if not Native.EffectsManager then
        recordFailure("effects_manager_instance_unavailable")
    end
    return Native.EffectsManager
end

local function getBulletTracerEffects()
    local classObject
    if Native.BulletTracerEffects then return Native.BulletTracerEffects end
    classObject = nativeClass("IsoBulletTracerEffects")
    if not classObject then
        recordFailure("bullet_tracer_class_unavailable")
        return nil
    end
    Native.BulletTracerEffects = nativeSingleton(classObject)
    if not Native.BulletTracerEffects then
        recordFailure("bullet_tracer_instance_unavailable")
    end
    return Native.BulletTracerEffects
end

local function isNativeFirearm(weapon)
    return weapon and readMethod(weapon, "isAimedFirearm") == true
end

local function distanceBetween(x1, y1, z1, x2, y2, z2)
    local dx = (tonumber(x2) or 0) - (tonumber(x1) or 0)
    local dy = (tonumber(y2) or 0) - (tonumber(y1) or 0)
    local dz = (tonumber(z2) or 0) - (tonumber(z1) or 0)
    return math.sqrt((dx * dx) + (dy * dy) + (dz * dz))
end

local function resolveRange(body, weapon, payload)
    local range = tonumber(readMethod(weapon, "getMaxRange", body))
    local sx = tonumber(body and readMethod(body, "getX"))
        or tonumber(payload and payload.sx)
    local sy = tonumber(body and readMethod(body, "getY"))
        or tonumber(payload and payload.sy)
    local sz = tonumber(body and readMethod(body, "getZ"))
        or tonumber(payload and payload.sz)
    local tx = tonumber(payload and payload.tx)
    local ty = tonumber(payload and payload.ty)
    local tz = tonumber(payload and payload.tz) or sz
    range = range or tonumber(payload and payload.maxRange)
    if (not range or range <= 0) and sx and sy and sz and tx and ty and tz then
        range = distanceBetween(sx, sy, sz, tx, ty, tz)
    end
    return math.max(1, range or 30)
end

local function resolveEndpoint(body, payload, projectileIndex, projectileCount, spread)
    local sx = tonumber(body and readMethod(body, "getX"))
        or tonumber(payload and payload.sx)
    local sy = tonumber(body and readMethod(body, "getY"))
        or tonumber(payload and payload.sy)
    local sz = tonumber(body and readMethod(body, "getZ"))
        or tonumber(payload and payload.sz)
    local tx = tonumber(payload and payload.tx)
    local ty = tonumber(payload and payload.ty)
    local tz = tonumber(payload and payload.tz)
    local dx
    local dy
    local length
    local centered
    local normalized
    local spreadAngle
    local lateralOffset
    if not sx or not sy or not sz or not tx or not ty or not tz then
        return nil, nil, nil
    end
    if projectileCount <= 1 or (tonumber(spread) or 0) <= 0 then
        return tx, ty, tz
    end
    dx = tx - sx
    dy = ty - sy
    length = math.sqrt((dx * dx) + (dy * dy))
    if length <= 0.0001 then return tx, ty, tz end
    centered = projectileIndex - ((projectileCount + 1) * 0.5)
    normalized = centered / math.max(1, (projectileCount - 1) * 0.5)
    spreadAngle = math.max(0, math.min(89, tonumber(spread) or 0))
    lateralOffset = math.tan(spreadAngle * math.pi / 180) * length * normalized
    return tx - ((dy / length) * lateralOffset),
        ty + ((dx / length) * lateralOffset), tz
end

local function projectileCount(body, weapon, payload)
    local count = tonumber(readMethod(weapon, "getProjectileCount"))
        or tonumber(payload and payload.projectileCount)
        or 1
    return math.max(1, math.min(32, math.floor(count)))
end

local function withNativeWeapon(body, weapon, callback)
    local current
    local changed = false
    local callbackOk
    local ok
    local result
    local reason
    if not body or not weapon then return false, "native_weapon_missing" end
    if type(body.getUseHandWeapon) ~= "function"
        or type(body.setUseHandWeapon) ~= "function"
    then
        return false, "native_weapon_state_api_missing"
    end
    current = readMethod(body, "getUseHandWeapon")
    if current ~= weapon then
        ok = callNative(body, "setUseHandWeapon", weapon)
        if not ok then return false, "native_weapon_state_set_failed" end
        changed = true
    end
    -- This is an intentional scoped pcall: it gives the temporary native
    -- weapon override a finally-like restoration path if a future effect
    -- call or modded callback raises.
    callbackOk, result, reason = pcall(callback)
    if changed then callNative(body, "setUseHandWeapon", current) end
    if not callbackOk then return false, "native_effect_exception" end
    return result, reason
end

function Native.PlayMuzzleFlash(body, weapon)
    local primaryWeapon
    local muzzleModel
    local manager
    local ok
    if not body or not isNativeFirearm(weapon) then
        return false, "not_native_firearm"
    end
    primaryWeapon = readMethod(body, "getPrimaryHandItem")
    if primaryWeapon and primaryWeapon ~= weapon then
        return false, "primary_weapon_mismatch"
    end
    muzzleModel = readMethod(weapon, "getMuzzleFlashModelKey")
    if not muzzleModel or tostring(muzzleModel) == "" then
        return false, "muzzle_flash_model_missing"
    end
    manager = getEffectsManager()
    if not manager then return false, "effects_manager_unavailable" end
    ok = callNative(manager, "startMuzzleFlash", body, 1)
    if not ok then return false, "native_muzzle_flash_call_failed" end
    return true, "native_muzzle_flash"
end

function Native.PlayTracer(body, weapon, payload)
    local tracer
    local ammoType
    local range
    local count
    local spread
    local hasEndpoint
    local added = 0
    local controller
    local i
    local x
    local y
    local z
    local ok
    local effect
    local addEffect
    if not body or not isNativeFirearm(weapon) then
        return false, "not_native_firearm"
    end
    ammoType = readMethod(weapon, "getAmmoType")
    if not ammoType then return false, "ammo_type_missing" end
    tracer = getBulletTracerEffects()
    if not tracer then return false, "bullet_tracer_unavailable" end
    addEffect = tracer.addEffect
    if type(addEffect) ~= "function" then
        return false, "native_tracer_method_missing"
    end
    range = resolveRange(body, weapon, payload)
    count = projectileCount(body, weapon, payload)
    spread = tonumber(readMethod(weapon, "getProjectileSpread"))
        or tonumber(payload and payload.projectileSpread)
        or 0
    hasEndpoint = payload
        and tonumber(payload.tx) ~= nil
        and tonumber(payload.ty) ~= nil
        and tonumber(payload.tz) ~= nil

    local function emit()
        controller = readMethod(body, "getBallisticsController")
        if not controller and type(body.updateBallistics) == "function" then
            ok = callNative(body, "updateBallistics")
            if not ok then return false, "ballistics_update_failed" end
            controller = readMethod(body, "getBallisticsController")
        end
        if not controller then return false, "ballistics_controller_missing" end
        if hasEndpoint then
            local function emitEndpointEffects()
                for i = 1, count do
                    x, y, z = resolveEndpoint(body, payload, i, count, spread)
                    effect = addEffect(tracer, body, range, x, y, z)
                    if effect then added = added + 1 end
                end
            end
            ok = callNativeBatch(emitEndpointEffects)
            if not ok and added == 0 then
                return false, "native_tracer_call_failed"
            end
        else
            ok, effect = callNative(tracer, "addEffect", body, range)
            if ok and effect then added = 1 end
        end
        if added <= 0 then return false, "native_tracer_not_created" end
        return true, "native_tracer"
    end

    return withNativeWeapon(body, weapon, emit)
end

function Native.GetCapabilities(body, weapon)
    local muzzleModel = weapon and readMethod(weapon, "getMuzzleFlashModelKey") or nil
    return {
        effectsManager = getEffectsManager() ~= nil,
        bulletTracerEffects = getBulletTracerEffects() ~= nil,
        aimedFirearm = isNativeFirearm(weapon) == true,
        ammoType = weapon and readMethod(weapon, "getAmmoType") ~= nil or false,
        muzzleFlashModel = muzzleModel ~= nil and tostring(muzzleModel) ~= "" or false,
        ballisticsController = body
            and readMethod(body, "getBallisticsController") ~= nil
            or false,
        weaponFullType = weapon and tostring(readMethod(weapon, "getFullType") or "")
            or nil,
    }
end

return Native
