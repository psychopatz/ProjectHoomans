-- Companion Dogs compatibility: shared identity, gates, and safe access.

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}
local Bridge = PNC.Compatibility.CompanionDogs or {}
local Internal = Bridge.Internal or {}
Bridge.Internal = Internal
PNC.Compatibility.CompanionDogs = Bridge

local MAX_INSTALL_ATTEMPTS = 120

Bridge.INTERACTION_INTERVAL_MS = Bridge.INTERACTION_INTERVAL_MS or 10000
Bridge.INTERACTION_RETRY_INTERVAL_MS =
    Bridge.INTERACTION_RETRY_INTERVAL_MS or 5000
Bridge.INTERACTION_COOLDOWN_MS = Bridge.INTERACTION_COOLDOWN_MS or 120000
Bridge.INTERACTION_RADIUS = Bridge.INTERACTION_RADIUS or 8
Bridge.PRESENTATION_RADIUS = Bridge.PRESENTATION_RADIUS or 30
Bridge.NPC_HUNGER_SAFE_THRESHOLD =
    Bridge.NPC_HUNGER_SAFE_THRESHOLD or 0.15
Bridge.FEED_CHANCE_PERCENT = Bridge.FEED_CHANCE_PERCENT or 20
Bridge.MAX_INTERACTIONS_PER_PUMP = Bridge.MAX_INTERACTIONS_PER_PUMP or 1
Bridge.MAX_NPCS_PER_PUMP = Bridge.MAX_NPCS_PER_PUMP or 4
Bridge.DOG_CACHE_INTERVAL_MS = Bridge.DOG_CACHE_INTERVAL_MS or 5000
Bridge._lastInteractionAt = Bridge._lastInteractionAt or {}
Bridge._nextInteractionAt = Bridge._nextInteractionAt or 0
Bridge._nextRuntimeProbeAt = Bridge._nextRuntimeProbeAt or 0
Bridge._eventSerial = Bridge._eventSerial or 0

function Internal.SafeCall(callback, ...)
    if type(callback) ~= "function" then return false, nil end
    return pcall(callback, ...)
end

function Internal.Now()
    local core = PNC.Core
    if core and type(core.Now) == "function" then
        return tonumber(core.Now()) or 0
    end
    if type(getTimestampMs) == "function" then
        return tonumber(getTimestampMs()) or 0
    end
    return 0
end

function Internal.IsAuthority()
    local core = PNC.Core
    if core and type(core.IsAuthority) == "function" then
        return core.IsAuthority() == true
    end
    return type(isServer) == "function" and isServer() == true
end

function Internal.CompanionDogs()
    return type(CompanionDogs) == "table" and CompanionDogs or nil
end

function Bridge.IsInstalled()
    return type(CompanionDogs) == "table"
        and Bridge._wrappedTable == CompanionDogs
        and CompanionDogs.isFriendlyNPC == Bridge._wrappedPredicate
end

local function isHoomansBody(body)
    local core = PNC.Core
    local ok
    local managed
    if not core or type(core.IsManagedNPCBody) ~= "function" then
        return false
    end
    ok, managed = Internal.SafeCall(core.IsManagedNPCBody, body)
    return ok and managed == true
end

function Bridge.TryInstall()
    local original
    local wrapped
    if Bridge.IsInstalled() then return true end
    if type(CompanionDogs) ~= "table"
        or type(CompanionDogs.isFriendlyNPC) ~= "function"
    then
        return false
    end
    original = CompanionDogs.isFriendlyNPC
    wrapped = function(body)
        if isHoomansBody(body) then return true end
        return original(body)
    end
    CompanionDogs.isFriendlyNPC = wrapped
    Bridge._wrappedTable = CompanionDogs
    Bridge._wrappedPredicate = wrapped
    return true
end

function Bridge.GetDogSex(dog)
    local cd = Internal.CompanionDogs()
    local ok
    local sex
    if not cd or type(cd.animalSex) ~= "function" then return nil end
    ok, sex = Internal.SafeCall(cd.animalSex, dog)
    if not ok then return nil end
    if sex == "male" or sex == "female" then return sex end
    return nil
end

function Bridge.GetDogKey(dog)
    local cd = Internal.CompanionDogs()
    local ok
    local key
    local onlineID
    if not dog then return nil end
    if cd and type(cd.ensureUid) == "function" then
        ok, key = Internal.SafeCall(cd.ensureUid, dog)
        if ok and key and tostring(key) ~= "" then
            return tostring(key)
        end
    end
    if type(dog.getOnlineID) == "function" then
        onlineID = tonumber(dog:getOnlineID())
        if onlineID and onlineID >= 0 then return tostring(onlineID) end
    end
    if type(dog.getAnimalID) == "function" then
        key = dog:getAnimalID()
        if key ~= nil then return tostring(key) end
    end
    return nil
end

function Bridge.GetFlavorID(dog, fed)
    local sex = Bridge.GetDogSex(dog)
    if fed then
        if sex == "male" then return "companion_dogs_feed_boy" end
        if sex == "female" then return "companion_dogs_feed_girl" end
        return "companion_dogs_feed_dog"
    end
    if sex == "male" then return "companion_dogs_good_boy" end
    if sex == "female" then return "companion_dogs_good_girl" end
    return "companion_dogs_good_dog"
end

function Bridge.IsDogEligible(dog)
    local cd = Internal.CompanionDogs()
    local ok
    local isDog
    local companion
    local dead
    if not cd or not dog or type(cd.isDog) ~= "function" then
        return false
    end
    ok, isDog = Internal.SafeCall(cd.isDog, dog)
    if not ok or isDog ~= true then return false end
    if type(cd.isCompanion) == "function" then
        ok, companion = Internal.SafeCall(cd.isCompanion, dog)
        if not ok or companion ~= true then return false end
    end
    if type(dog.isDead) == "function" then
        ok, dead = Internal.SafeCall(dog.isDead, dog)
        if ok and dead == true then return false end
    end
    return true
end

function Bridge.IsDogHungry(dog)
    local cd = Internal.CompanionDogs()
    local hunger
    local threshold
    if not Bridge.IsDogEligible(dog)
        or type(dog.getHunger) ~= "function"
    then
        return false
    end
    hunger = tonumber(dog:getHunger())
    threshold = cd and tonumber(cd.HUNGER_WARN) or nil
    threshold = threshold or 0.6
    return hunger ~= nil and hunger >= threshold
end

function Bridge.IsNPCNotHungry(record)
    local needs = PNC.IndividualNeeds
    local ok
    local hunger
    if not needs or type(needs.Get) ~= "function" then return false end
    ok, hunger = Internal.SafeCall(needs.Get, record, "hunger")
    return ok and hunger ~= nil
        and tonumber(hunger) < Bridge.NPC_HUNGER_SAFE_THRESHOLD
end

function Internal.PairKey(npcID, dogKey)
    return tostring(npcID or "") .. ":" .. tostring(dogKey or "")
end

function Internal.Near(left, right, radius)
    local lx = left and type(left.getX) == "function" and left:getX()
    local ly = left and type(left.getY) == "function" and left:getY()
    local lz = left and type(left.getZ) == "function" and left:getZ()
    local rx = right and type(right.getX) == "function" and right:getX()
    local ry = right and type(right.getY) == "function" and right:getY()
    local rz = right and type(right.getZ) == "function" and right:getZ()
    local dx
    local dy
    if lx == nil or ly == nil or lz == nil
        or rx == nil or ry == nil or rz == nil
    then
        return false
    end
    if math.floor(lz) ~= math.floor(rz) then return false end
    dx = lx - rx
    dy = ly - ry
    return dx * dx + dy * dy <= radius * radius
end

function Internal.VisibleToNPC(record, dog)
    local perception = PNC.Perception
    local ok
    local visible
    if not perception or type(perception.CanSeeWorldObject) ~= "function" then
        return true
    end
    ok, visible = Internal.SafeCall(perception.CanSeeWorldObject, record, dog)
    return ok and visible == true
end

function Internal.NPCIsBusy(record)
    local runtime = record and record.runtime
    local combat = record and record.combat
    local current
    if not record or record.alive == false then return true end
    if runtime and (runtime.attackAction or runtime.combatTarget
        or runtime.target or runtime.inCombat or runtime.combatAction)
    then
        return true
    end
    if combat and (combat.target or combat.active or combat.inCombat) then
        return true
    end
    current = Internal.Now()
    if runtime and current < (tonumber(runtime.inCombatUntil) or 0) then
        return true
    end
    if record.travel and record.travel.state == "active" then return true end
    if record.activeJob then return true end
    return false
end

function Bridge.RollFeedChance()
    if type(ZombRand) == "function" then
        return ZombRand(0, 100) < Bridge.FEED_CHANCE_PERCENT
    end
    return math.random(0, 99) < Bridge.FEED_CHANCE_PERCENT
end

Internal.MAX_INSTALL_ATTEMPTS = MAX_INSTALL_ATTEMPTS

return Bridge
