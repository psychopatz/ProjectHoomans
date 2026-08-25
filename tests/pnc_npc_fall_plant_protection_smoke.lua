local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local function list(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
    }
end

local function square(x, y, hasPlant)
    return {
        getX = function() return x end,
        getY = function() return y end,
        getZ = function() return 0 end,
        hasFarmingPlant = function() return hasPlant == true end,
    }
end

local scriptItem = {
    chanceToFall = 17,
    getChanceToFall = function(self) return self.chanceToFall end,
    DoParam = function(self, name, value)
        if name == "ChanceToFall" then
            self.chanceToFall = tonumber(value)
        end
    end,
}

local visual = {
    getItemType = function() return "Base.Hat_Test" end,
    getScriptItem = function() return scriptItem end,
}

local safeSquare = square(10, 10, false)
local plantSquare = square(11, 10, true)
local currentSquare = plantSquare
local currentX = 11.5
local currentY = 10.5
local currentZ = 0
local cell = {
    getGridSquare = function(_, x, y)
        if x == 10 and y == 10 then return safeSquare end
        return nil
    end,
}
local zombie = {
    getModData = function() return { PNC_NPC = true } end,
    getItemVisuals = function() return list({ visual }) end,
    getSquare = function() return currentSquare end,
    getCell = function() return cell end,
    getX = function() return currentX end,
    getY = function() return currentY end,
    getZ = function() return currentZ end,
    setX = function(_, value) currentX = value end,
    setY = function(_, value) currentY = value end,
    setZ = function(_, value) currentZ = value end,
    setCurrent = function(_, value) currentSquare = value end,
}

PNC = {
    Core = {},
    LiveBodyControl = {
        EnforceManagedSafety = function() return true end,
        IsMultiplayer = function() return false end,
    },
}

local zombieUpdateHandler
local tickHandler
local weaponHitHandler
Events = {
    OnZombieUpdate = {
        Remove = function() end,
        Add = function(handler) zombieUpdateHandler = handler end,
    },
    OnTick = {
        Remove = function() end,
        Add = function(handler) tickHandler = handler end,
    },
    OnWeaponHitCharacter = {
        Remove = function() end,
        Add = function(handler) weaponHitHandler = handler end,
    },
    OnGameStart = { Remove = function() end, Add = function() end },
    OnServerStarted = { Remove = function() end, Add = function() end },
}

T.load("ProjectHoomans", "shared", "PNC/Core/Base/PNC_Core.lua")
T.load("ProjectHoomans", "shared",
    "PNC/Core/Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_Events.lua")

zombieUpdateHandler(zombie)
T.equal(scriptItem.chanceToFall, 0,
    "managed NPC visual clothing is protected during zombie update")
T.equal(currentSquare, safeSquare,
    "managed NPC is moved off a crop square before vanilla trampling")

tickHandler()
T.equal(scriptItem.chanceToFall, 17,
    "visual clothing ChanceToFall is restored after the engine update")

weaponHitHandler({}, zombie)
T.equal(scriptItem.chanceToFall, 0,
    "weapon-hit knockdowns protect visual clothing before damage resolves")
tickHandler()
T.equal(scriptItem.chanceToFall, 17,
    "weapon-hit visual protection is restored after the tick")

T.finish("pnc_npc_fall_plant_protection_smoke")
