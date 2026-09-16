local T = require "tests/support/test"

local ZOMBIE_FLAVOR_FILE = T.path(
    "ProjectHoomans",
    "client",
    "PNC/Compatibility/Mods/Necroa/PNC_Necroa_ZombieFlavor.lua"
)

local now = 5000
local updateCallback
local sizeCalls = 0
local zombies = {}
local cell = {}

getTimeInMillis = function() return now end
ZombRand = function() return 0 end
instanceof = function(object, className)
    return className == "IsoZombie" and object and object.isZombie == true
end

Events = {
    OnZombieUpdate = {
        Add = function(callback) updateCallback = callback end,
    },
    OnWeaponHitCharacter = {
        Add = function() end,
    },
}

local function makeZombie(x, hooman)
    local data = {}
    local zombie = {
        hooman = hooman,
        isZombie = true,
        lines = 0,
        isAlive = function() return true end,
        getX = function() return x end,
        getY = function() return 0 end,
        getZ = function() return 0 end,
        getCell = function() return cell end,
        getModData = function() return data end,
        addLineChatElement = function(self) self.lines = self.lines + 1 end,
    }
    zombies[#zombies + 1] = zombie
    return zombie
end

cell.getZombieList = function()
    return {
        size = function()
            sizeCalls = sizeCalls + 1
            return #zombies
        end,
        get = function(_, index) return zombies[index + 1] end,
    }
end

local hooman = makeZombie(1, true)
local ordinary = makeZombie(3, false)
makeZombie(100, false)

PNC = {
    Compatibility = {
        Necroa = {
            IsActive = function() return true end,
            IsHoomansOwned = function(zombie)
                return zombie and zombie.hooman == true
            end,
        },
    },
}

T.load(ZOMBIE_FLAVOR_FILE)
T.truthy(updateCallback, "Necroa zombie update callback registered")

updateCallback(ordinary)
T.equal(ordinary.lines, 1, "nearby Hoomans zombie receives native flavor text")
T.equal(sizeCalls, 1, "first update performs one shared cell scan")

now = 5100
updateCallback(ordinary)
T.equal(sizeCalls, 1, "updates inside the probe interval do not rescan the cell")

now = 6000
updateCallback(ordinary)
T.equal(sizeCalls, 2, "one later interval performs one additional cell scan")
T.equal(ordinary.lines, 1, "per-zombie speech cooldown prevents flavor flooding")
T.equal(hooman.lines, 0, "Hoomans-owned zombies do not speak in the Necroa lane")

T.finish("pnc_necroa_zombie_flavor_smoke")
