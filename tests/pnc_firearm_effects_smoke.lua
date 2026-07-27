local SHARED_FILE = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/Combat/PNC_Combat_FirearmEffects.lua"
local CLIENT_FILE = "Contents/mods/ProjectHoomans/42.19/media/lua/client/PNC/PNC_ClientFirearmEffects.lua"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local now = 1000
local published
local worldNoise
local ammoKey = {
    getItemKey = function() return "ModdedAmmo.556Tracer" end,
}
local weapon = {
    getFullType = function() return "ModdedGuns.TestRifle" end,
    getAmmoType = function() return ammoKey end,
    getClipSize = function() return 30 end,
    getAmmoPerShoot = function() return 2 end,
    getSwingSound = function() return "ModdedRifleShot" end,
    getSoundRadius = function() return 95 end,
    getSoundVolume = function() return 48 end,
    getSoundGain = function() return 0.8 end,
    getProjectileCount = function() return 3 end,
    getProjectileSpread = function() return 1.5 end,
    getMaxRange = function() return 18 end,
    isPiercingBullets = function() return true end,
    getImpactSound = function() return "ModdedBulletImpact" end,
    getShellFallSound = function() return "ModdedShellFall" end,
    isManuallyRemoveSpentRounds = function() return false end,
    isRackAfterShoot = function() return false end,
}
local shooter = {
    getX = function() return 10 end,
    getY = function() return 20 end,
    getZ = function() return 0 end,
    isOutside = function() return true end,
    addWorldSoundUnlessInvisible = function(_, radius, volume, stress)
        worldNoise = { radius = radius, volume = volume, stress = stress }
    end,
}

getScriptManager = function()
    return {
        getItem = function() return nil end,
    }
end
getSandboxOptions = nil
isServer = function() return true end

PNC = {
    Const = {
        MODULE = "PNC",
        CMD_FIREARM_SHOT = "FirearmShot",
    },
    Core = {
        Now = function() return now end,
        IsAuthority = function() return true end,
    },
    Firearms = {},
    Network = {
        GetZombieOnlineID = function() return 77 end,
        BroadcastFirearmShot = function(payload)
            published = payload
            return true
        end,
    },
}

dofile("Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/Combat/PNC_Combat_Firearms.lua")
dofile(SHARED_FILE)

local record = {
    id = "npc_modded_rifle",
    x = 10,
    y = 20,
    z = 0,
    equipment = { primaryFullType = "ModdedGuns.TestRifle" },
    runtime = {},
}
local emitted, payload = PNC.FirearmEffects.Emit(record, shooter, {
    kind = "zombie",
    x = 16,
    y = 22,
    z = 0,
}, weapon)
assertEqual(emitted, true, "authoritative shot emitted")
assertEqual(payload, published, "published payload identity")
assertEqual(payload.shotId, "npc_modded_rifle:body:1:1000", "shot sequence")
assertEqual(payload.weaponFullType, "ModdedGuns.TestRifle", "modded weapon type")
assertEqual(payload.ammoType, "ModdedAmmo.556Tracer", "ItemKey ammo type")
assertEqual(payload.ammoPerShot, 2, "modded ammo consumption metadata")
assertEqual(payload.shotSound, "ModdedRifleShot", "modded weapon sound")
assertEqual(payload.projectileCount, 3, "modded projectile count")
assertEqual(payload.projectileSpread, 1.5, "modded projectile spread")
assertEqual(payload.shellFallSound, "ModdedShellFall", "modded shell sound")
assertEqual(worldNoise.radius, 95, "weapon-driven world noise radius")
assertEqual(worldNoise.volume, 48, "weapon-driven world noise volume")

local played = {}
local rendered = 0
local muzzleFlash = 0
local removedLights = 0
local impactSound
local freeEmitterSound
local liveWeapon = {
    getFullType = function() return "ModdedGuns.TestRifle" end,
    getSwingSound = function() return "LiveModdedRifleShot" end,
    getShellFallSound = function() return "LiveModdedShellFall" end,
    isTwoHandWeapon = function() return true end,
    getStaticModel = function() return nil end,
}
local emitter = {
    playSound = function(_, sound)
        played[#played + 1] = sound
    end,
}
local body = {
    getX = function() return 10 end,
    getY = function() return 20 end,
    getZ = function() return 0 end,
    getAnimAngleRadians = function() return 0 end,
    getPrimaryHandItem = function() return liveWeapon end,
    getEmitter = function() return emitter end,
    startMuzzleFlash = function() muzzleFlash = muzzleFlash + 1 end,
}
local cell = {
    addLamppost = function() end,
    removeLamppost = function() removedLights = removedLights + 1 end,
    getGridSquare = function()
        return {
            playSound = function(_, sound) impactSound = sound end,
        }
    end,
}

PNC.Network.FindZombieByOnlineID = function() return body end
PNC.ClientPresenceSync = { BodyByID = {} }
getTexture = function() return {} end
getCell = function() return cell end
getCore = function()
    return {
        getZoom = function() return 1 end,
    }
end
getRenderer = function()
    return {
        renderline = function() rendered = rendered + 1 end,
    }
end
getWorld = function()
    return {
        getFreeEmitter = function()
            return {
                playSound = function(_, sound)
                    freeEmitterSound = sound
                    return 91
                end,
                setVolume = function() end,
            }
        end,
    }
end
ISCoordConversion = {
    ToScreen = function(x, y, z)
        return (x * 10) - (y * 10), ((x + y) * 5) - (z * 10)
    end,
}
IsoLightSource = {
    new = function(...) return { args = { ... } } end,
}
Events = {
    OnTick = { Add = function() end },
    OnPreUIDraw = { Add = function() end },
    OnResetLua = { Add = function() end },
}

dofile(CLIENT_FILE)

assertEqual(PNC.ClientFirearmEffects.Play(payload), true, "client shot rendered")
assertEqual(played[1], "LiveModdedRifleShot", "live equipped gun sound preferred")
assertEqual(played[2], "LiveModdedShellFall", "live equipped shell sound preferred")
assertEqual(muzzleFlash, 1, "native muzzle hook attempted")
assertEqual(#PNC.ClientFirearmEffects.ActiveLights, 1, "temporary muzzle light added")
assertEqual(#PNC.ClientFirearmEffects.ActiveTracers, 3, "weapon projectile count rendered")
assertEqual(impactSound, "ModdedBulletImpact", "weapon impact sound")
assertEqual(PNC.ClientFirearmEffects.Play(payload), false, "duplicate shot ignored")
PNC.ClientFirearmEffects.OnPreUIDraw()
assertEqual(rendered, 3, "each projectile tracer drawn")
PNC.ClientFirearmEffects.OnTick()
PNC.ClientFirearmEffects.OnTick()
assertEqual(#PNC.ClientFirearmEffects.ActiveLights, 0, "muzzle light cleaned")
assertEqual(removedLights, 1, "muzzle light removed from cell")

PNC.Network.FindZombieByOnlineID = function() return nil end
local remotePayload = {}
for key, value in pairs(payload) do remotePayload[key] = value end
remotePayload.shotId = "npc_modded_rifle:remote:2:1100"
remotePayload.shellFallSound = nil
assertEqual(PNC.ClientFirearmEffects.Play(remotePayload), true, "unresolved remote shot rendered")
assertEqual(freeEmitterSound, "ModdedRifleShot", "remote positional emitter uses packet weapon sound")

print("pnc_firearm_effects_smoke: ok")
