local Effects = PNC and PNC.ClientFirearmEffects
if not Effects then return end

local Internal = Effects.Internal or {}
local Deps = Internal.AudioVisualDeps or {}
local readMethod = Deps.readMethod
local reserveLightSlot = Deps.reserveLightSlot

local function playShotAudio(body, weapon, payload)
    local sound = weapon and readMethod(weapon, "getSwingSound") or payload.shotSound
    local shellSound = payload.shellFallSound and (
        weapon and readMethod(weapon, "getShellFallSound") or payload.shellFallSound
    ) or nil
    local emitter
    local world
    local soundId
    local gain = tonumber(weapon and readMethod(weapon, "getSoundGain"))
        or tonumber(payload.soundGain)
        or 1
    emitter = body and readMethod(body, "getEmitter") or nil
    if not emitter and getWorld then
        world = getWorld()
        emitter = world and readMethod(
            world,
            "getFreeEmitter",
            tonumber(payload.sx) or 0,
            tonumber(payload.sy) or 0,
            tonumber(payload.sz) or 0
        ) or nil
    end
    if not emitter then return false end
    if sound and tostring(sound) ~= "" and emitter and emitter.playSound then
        local ok
        ok, soundId = pcall(emitter.playSound, emitter, tostring(sound))
        if ok and soundId and emitter.setVolume then
            pcall(emitter.setVolume, emitter, soundId, gain)
        end
    end
    if shellSound and tostring(shellSound) ~= "" and emitter and emitter.playSound then
        pcall(emitter.playSound, emitter, tostring(shellSound))
    end
    return sound ~= nil
end

local function resolveLightSquare(body, payload, muzzleX, muzzleY, muzzleZ)
    local cell
    local square
    local squareZ
    if getCell and muzzleX and muzzleY and muzzleZ then
        cell = getCell()
        if cell and type(cell.getGridSquare) == "function" then
            squareZ = tonumber(body and readMethod(body, "getZ"))
                or tonumber(payload and payload.sz)
                or 0
            square = cell:getGridSquare(
                math.floor(tonumber(muzzleX) or 0),
                math.floor(tonumber(muzzleY) or 0),
                math.floor(squareZ)
            )
            if square then return square end
        end
    end
    if body then
        square = readMethod(body, "getSquare")
        if square then return square end
    end
    if not getCell then return nil end
    cell = getCell()
    if not cell or type(cell.getGridSquare) ~= "function" then return nil end
    return cell:getGridSquare(
        math.floor(tonumber(payload.sx) or 0),
        math.floor(tonumber(payload.sy) or 0),
        math.floor(tonumber(payload.sz) or 0)
    )
end

local function spawnLight(body, payload, muzzleX, muzzleY, muzzleZ)
    local cell
    local square
    local lightSource
    local x
    local y
    local z
    if not IsoLightSource or not getCell then return false, "api_unavailable" end
    cell = getCell()
    if not cell or not cell.addLamppost then return false, "cell_unavailable" end
    square = resolveLightSquare(body, payload, muzzleX, muzzleY, muzzleZ)
    if not square then return false, "square_unavailable" end
    x = tonumber(readMethod(square, "getX"))
    y = tonumber(readMethod(square, "getY"))
    z = tonumber(readMethod(square, "getZ"))
    if not x or not y or not z then
        return false, "square_coordinates_unavailable"
    end
    if not reserveLightSlot() then
        return false, "light_budget"
    end
    -- Match Bandits' proven B42 fallback: the final 1 is the light's
    -- one-tick lifetime, which lets the engine own its cleanup. Use a
    -- desaturated warm-white flash. IsoLightSource has RGB and radius,
    -- not an alpha channel, so lower RGB/radius is the transparent-looking
    -- equivalent and avoids an artificial orange pool of light.
    lightSource = IsoLightSource.new(
        x,
        y,
        z,
        0.78,
        0.68,
        0.52,
        9,
        1
    )
    cell:addLamppost(lightSource)
    return true, "created", x, y, z
end

Effects.Internal.AudioVisual = {
    playShotAudio = playShotAudio,
    spawnLight = spawnLight,
}
