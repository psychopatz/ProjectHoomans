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

local function callMethod(target, methodName, ...)
    local method
    if not target then return false, nil end
    method = target[methodName]
    if type(method) ~= "function" then return false, nil end
    return pcall(method, target, ...)
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
    ok, instance = pcall(getter)
    if ok and instance then return instance end
    ok, instance = pcall(getter, classObject)
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
    return weapon and safeMethod(weapon, "isAimedFirearm") == true
end

local function isAnimationReady(body)
    local animationPlayer
    if not body or type(body.getAnimationPlayer) ~= "function" then
        return false
    end
    animationPlayer = safeMethod(body, "getAnimationPlayer")
    return animationPlayer
        and safeMethod(animationPlayer, "isReady") == true
        or false
end

local function distanceBetween(x1, y1, z1, x2, y2, z2)
    local dx = (tonumber(x2) or 0) - (tonumber(x1) or 0)
    local dy = (tonumber(y2) or 0) - (tonumber(y1) or 0)
    local dz = (tonumber(z2) or 0) - (tonumber(z1) or 0)
    return math.sqrt((dx * dx) + (dy * dy) + (dz * dz))
end

local function resolveRange(body, weapon, payload)
    local range = tonumber(safeMethod(weapon, "getMaxRange", body))
    local sx = tonumber(body and safeMethod(body, "getX"))
        or tonumber(payload and payload.sx)
    local sy = tonumber(body and safeMethod(body, "getY"))
        or tonumber(payload and payload.sy)
    local sz = tonumber(body and safeMethod(body, "getZ"))
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
    local sx = tonumber(body and safeMethod(body, "getX"))
        or tonumber(payload and payload.sx)
    local sy = tonumber(body and safeMethod(body, "getY"))
        or tonumber(payload and payload.sy)
    local sz = tonumber(body and safeMethod(body, "getZ"))
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
    local count = tonumber(safeMethod(weapon, "getProjectileCount"))
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
    current = safeMethod(body, "getUseHandWeapon")
    if current ~= weapon then
        ok = callMethod(body, "setUseHandWeapon", weapon)
        if not ok then return false, "native_weapon_state_set_failed" end
        changed = true
    end
    callbackOk, result, reason = pcall(callback)
    if changed then callMethod(body, "setUseHandWeapon", current) end
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
    if not isAnimationReady(body) then
        return false, "animation_player_not_ready"
    end
    primaryWeapon = safeMethod(body, "getPrimaryHandItem")
    if primaryWeapon and primaryWeapon ~= weapon then
        return false, "primary_weapon_mismatch"
    end
    muzzleModel = safeMethod(weapon, "getMuzzleFlashModelKey")
    if not muzzleModel or tostring(muzzleModel) == "" then
        return false, "muzzle_flash_model_missing"
    end
    manager = getEffectsManager()
    if not manager then return false, "effects_manager_unavailable" end
    ok = callMethod(manager, "startMuzzleFlash", body, 1)
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
    if not body or not isNativeFirearm(weapon) then
        return false, "not_native_firearm"
    end
    if not isAnimationReady(body) then
        return false, "animation_player_not_ready"
    end
    ammoType = safeMethod(weapon, "getAmmoType")
    if not ammoType then return false, "ammo_type_missing" end
    tracer = getBulletTracerEffects()
    if not tracer then return false, "bullet_tracer_unavailable" end
    range = resolveRange(body, weapon, payload)
    count = projectileCount(body, weapon, payload)
    spread = tonumber(safeMethod(weapon, "getProjectileSpread"))
        or tonumber(payload and payload.projectileSpread)
        or 0
    hasEndpoint = payload
        and tonumber(payload.tx) ~= nil
        and tonumber(payload.ty) ~= nil
        and tonumber(payload.tz) ~= nil

    local function emit()
        controller = safeMethod(body, "getBallisticsController")
        if not controller and type(body.updateBallistics) == "function" then
            ok = callMethod(body, "updateBallistics")
            if not ok then return false, "ballistics_update_failed" end
            controller = safeMethod(body, "getBallisticsController")
        end
        if not controller then return false, "ballistics_controller_missing" end
        if hasEndpoint then
            for i = 1, count do
                x, y, z = resolveEndpoint(body, payload, i, count, spread)
                ok, effect = callMethod(tracer, "addEffect", body, range, x, y, z)
                if not ok then
                    if added == 0 then return false, "native_tracer_call_failed" end
                    break
                end
                if effect then added = added + 1 end
            end
        else
            ok, effect = callMethod(tracer, "addEffect", body, range)
            if ok and effect then added = 1 end
        end
        if added <= 0 then return false, "native_tracer_not_created" end
        return true, "native_tracer"
    end

    return withNativeWeapon(body, weapon, emit)
end

function Native.GetCapabilities(body, weapon)
    local animationPlayer = body and safeMethod(body, "getAnimationPlayer") or nil
    local muzzleModel = weapon and safeMethod(weapon, "getMuzzleFlashModelKey") or nil
    return {
        effectsManager = getEffectsManager() ~= nil,
        bulletTracerEffects = getBulletTracerEffects() ~= nil,
        aimedFirearm = isNativeFirearm(weapon) == true,
        ammoType = weapon and safeMethod(weapon, "getAmmoType") ~= nil or false,
        muzzleFlashModel = muzzleModel ~= nil and tostring(muzzleModel) ~= "" or false,
        animationReady = animationPlayer
            and safeMethod(animationPlayer, "isReady") == true
            or false,
        ballisticsController = body
            and safeMethod(body, "getBallisticsController") ~= nil
            or false,
        weaponFullType = weapon and tostring(safeMethod(weapon, "getFullType") or "")
            or nil,
    }
end

return Native
