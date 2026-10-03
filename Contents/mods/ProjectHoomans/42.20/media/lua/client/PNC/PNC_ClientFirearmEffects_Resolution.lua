local Effects = PNC and PNC.ClientFirearmEffects
if not Effects then return end

local Internal = Effects.Internal or {}
local Deps = Internal.ResolutionDeps or {}
local NativeEffects = Deps.NativeEffects
local readMethod = Deps.readMethod
local BORE_MUZZLE_TILES = Deps.BORE_MUZZLE_TILES
local BORE_HEIGHT_TILES = Deps.BORE_HEIGHT_TILES
local BORE_SIDE_TILES = Deps.BORE_SIDE_TILES
local BORE_MIN_MODEL_LENGTH = Deps.BORE_MIN_MODEL_LENGTH
local BORE_MAX_MODEL_LENGTH = Deps.BORE_MAX_MODEL_LENGTH

local function sameWeaponType(weapon, fullType)
    local weaponType
    if not weapon then return false end
    if not fullType or tostring(fullType) == "" then return true end
    weaponType = readMethod(weapon, "getFullType")
    return tostring(weaponType or "") == tostring(fullType)
end

local function resolveBody(payload)
    local body
    local key
    if not payload then return nil end
    if payload.body then return payload.body end
    if payload.shooterOnlineID ~= nil and PNC.Network and PNC.Network.FindZombieByOnlineID then
        body = PNC.Network.FindZombieByOnlineID(payload.shooterOnlineID)
    end
    if body then return body end
    key = tostring(payload.npcId or "")
    if key == "" then return nil end
    if PNC.ClientPresenceSync then
        body = PNC.ClientPresenceSync.BodyByID and PNC.ClientPresenceSync.BodyByID[key] or nil
    end
    if not body and PNC.Registry and PNC.Registry.GetLiveZombie then
        body = PNC.Registry.GetLiveZombie(key)
    end
    return body
end

local function resolveWeapon(body, payload)
    local weapon
    if not body then return nil end
    weapon = readMethod(body, "getPrimaryHandItem")
    if sameWeaponType(weapon, payload and payload.weaponFullType) then
        return weapon
    end
    weapon = readMethod(body, "getUseHandWeapon")
    if sameWeaponType(weapon, payload and payload.weaponFullType) then
        return weapon
    end
    weapon = readMethod(body, "getAttackingWeapon")
    if sameWeaponType(weapon, payload and payload.weaponFullType) then
        return weapon
    end
    return nil
end

-- The live shot bearing in world space. The payload already carries the
-- authoritative shooter and aim point, so the bore is never taken from the
-- animation facing first: while aiming, strafing, or blending, the character
-- can face somewhere the barrel is not pointing, and offsetting the muzzle
-- along that facing is what detached the tracer from the gun. Facing stays as
-- the last resort for a shot that carries no aim point at all.
local function resolveBoreDirection(body, payload)
    local bodyX = tonumber(body and readMethod(body, "getX"))
    local bodyY = tonumber(body and readMethod(body, "getY"))
    local originX = bodyX or tonumber(payload and payload.sx)
    local originY = bodyY or tonumber(payload and payload.sy)
    local targetX = tonumber(payload and payload.tx)
    local targetY = tonumber(payload and payload.ty)
    local dx
    local dy
    local length
    local facing
    local forwardX
    local forwardY
    local angle
    if originX and originY and targetX and targetY then
        dx, dy = targetX - originX, targetY - originY
        length = math.sqrt((dx * dx) + (dy * dy))
        if length > 0.001 then return dx / length, dy / length end
    end
    facing = body and readMethod(body, "getForwardDirection") or nil
    forwardX = facing and tonumber(readMethod(facing, "getX")) or nil
    forwardY = facing and tonumber(readMethod(facing, "getY")) or nil
    if forwardX and forwardY
        and math.abs(forwardX) + math.abs(forwardY) > 0.001
    then
        length = math.sqrt((forwardX * forwardX) + (forwardY * forwardY))
        return forwardX / length, forwardY / length
    end
    angle = tonumber(body and readMethod(body, "getAnimAngleRadians"))
    if angle then return math.cos(angle), math.sin(angle) end
    return nil, nil
end

-- Barrel length along the bore, from the weapon model's muzzle attachment when
-- a modded weapon supplies one. Clamped, because a missing or unusual model
-- script must not be able to fling the tracer away from the shooter. The
-- attachment's lateral and vertical terms are deliberately unused: they were
-- previously applied on the wrong axes, which is part of why the muzzle never
-- sat on the barrel line.
local function modelBoreLength(weapon)
    local staticModel = weapon and readMethod(weapon, "getStaticModel") or nil
    local manager
    local model
    local attachment
    local offset
    local length
    if not staticModel or not getScriptManager then return nil end
    manager = getScriptManager()
    model = manager and readMethod(manager, "getModelScript", staticModel) or nil
    attachment = model and readMethod(model, "getAttachmentById", "muzzle") or nil
    offset = attachment and readMethod(attachment, "getOffset") or nil
    length = offset and tonumber(readMethod(offset, "y")) or nil
    if length and length >= BORE_MIN_MODEL_LENGTH
        and length <= BORE_MAX_MODEL_LENGTH
    then
        return length
    end
    return nil
end

-- World-space barrel tip: shooter position advanced along the shot bearing by
-- the barrel length, laterally offset inside the bore frame, and lifted to
-- barrel height instead of the old absolute 1.1 tiles that floated the effect
-- well above the weapon.
local function getMuzzlePosition(body, weapon, payload)
    local x = tonumber(body and readMethod(body, "getX")) or tonumber(payload.sx) or 0
    local y = tonumber(body and readMethod(body, "getY")) or tonumber(payload.sy) or 0
    local squareZ = tonumber(body and readMethod(body, "getZ")) or tonumber(payload.sz) or 0
    local boreX, boreY = resolveBoreDirection(body, payload)
    local forward = modelBoreLength(weapon) or BORE_MUZZLE_TILES
    local rightX
    local rightY
    if not boreX or not boreY then
        -- Nothing to aim along: keep the world axis so the shot still renders.
        boreX, boreY = 1, 0
    end
    rightX, rightY = -boreY, boreX
    return x + (boreX * forward) + (rightX * BORE_SIDE_TILES),
        y + (boreY * forward) + (rightY * BORE_SIDE_TILES),
        squareZ + BORE_HEIGHT_TILES,
        squareZ
end

function Effects.GetNativeCapabilities(body, payload)
    local weapon = resolveWeapon(body, payload or {})
    return NativeEffects.GetCapabilities(body, weapon)
end

Effects.Internal.Resolution = {
    resolveBody = resolveBody,
    resolveWeapon = resolveWeapon,
    getMuzzlePosition = getMuzzlePosition,
}
