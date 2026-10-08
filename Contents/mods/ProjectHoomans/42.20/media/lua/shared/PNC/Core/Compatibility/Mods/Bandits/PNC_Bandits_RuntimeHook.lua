-- Runtime hooks for Bandits public combat entry points.

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}
PNC.Compatibility.Bandits = PNC.Compatibility.Bandits or {}
local Bridge = PNC.Compatibility.Bandits.IncomingBridge
    or require "PNC/Core/Compatibility/Mods/Bandits/PNC_Bandits_IncomingBridge"
local Context = Bridge.IncomingContext
    or require "PNC/Core/Compatibility/Mods/Bandits/PNC_Bandits_IncomingContext"

local function rangedHitLanded(shooter, item, victim)
    local dx
    local dy
    local distance
    local brain
    local accuracyMap
    local accuracyLevel
    local sightGeneral
    local sightCharacter
    local sightScope
    local scope
    local threshold
    local randomValue
    if not Context.IsRanged(item, Context.FullType(item), nil, nil) then
        return true
    end
    if not BanditRandom or type(BanditRandom.Get) ~= "function" then
        return true
    end
    dx = (Context.Coordinate(victim, "getX") or 0)
        - (Context.Coordinate(shooter, "getX") or 0)
    dy = (Context.Coordinate(victim, "getY") or 0)
        - (Context.Coordinate(shooter, "getY") or 0)
    distance = math.sqrt((dx * dx) + (dy * dy))
    brain = BanditBrain and type(BanditBrain.Get) == "function"
        and BanditBrain.Get(shooter) or nil
    accuracyMap = { -8, -4, 0, 4, 8 }
    accuracyLevel = SandboxVars and SandboxVars.Bandits
        and SandboxVars.Bandits.General_OverallAccuracy or 0
    sightGeneral = accuracyMap[accuracyLevel] or 0
    sightCharacter = tonumber(brain and brain.accuracyBoost) or 0
    sightScope = 0
    scope = Context.SafeMethod(item, "getWeaponPart", "Scope")
    if scope and BanditCompatibility
        and type(BanditCompatibility.GetScopeRange) == "function"
    then
        local ok, value = pcall(BanditCompatibility.GetScopeRange, scope)
        if ok then sightScope = tonumber(value) or 0 end
    end
    threshold = 1200 + (9000 - 1200)
        / (1 + math.exp(0.13 * (distance
            - (16 + sightGeneral + sightCharacter + sightScope))))
    randomValue = BanditRandom.Get()
    return tonumber(randomValue) ~= nil
        and tonumber(randomValue) < threshold
end

local function installHitBridge()
    local utils = BanditUtils
    local original
    local wrapper
    if not utils or type(utils.Hit) ~= "function" then return false end
    if Bridge.banditUtils == utils and utils.Hit == Bridge.hitWrapper then
        return true
    end
    original = utils.Hit
    wrapper = function(shooter, item, victim, damageSplit)
        if not Context.IsHoomansBody(victim) then
            return original(shooter, item, victim, damageSplit)
        end
        if not Context.HasAuthority()
            and (type(isClient) ~= "function" or not isClient())
        then
            return false
        end
        if not rangedHitLanded(shooter, item, victim) then return true end
        local applied = Bridge.ApplyHit(shooter, item, victim, {})
        return applied == true
    end
    utils.Hit = wrapper
    Bridge.banditUtils = utils
    Bridge.originalHit = original
    Bridge.hitWrapper = wrapper
    return true
end

local function installCompatibilityBridge()
    local compatibility = BanditHoomansCompatibility
    local original
    local wrapper
    if not compatibility
        or type(compatibility.ApplyBanditHit) ~= "function"
    then
        return false
    end
    if Bridge.compatibility == compatibility
        and compatibility.ApplyBanditHit == Bridge.compatibilityWrapper
    then
        return true
    end
    original = compatibility.ApplyBanditHit
    wrapper = function(shooter, item, victim, amount)
        if not Context.IsHoomansBody(victim) then
            return original(shooter, item, victim, amount)
        end
        return Bridge.ApplyHit(shooter, item, victim, {
            amount = amount,
            type = "bandits_compatibility_damage",
        })
    end
    compatibility.ApplyBanditHit = wrapper
    Bridge.compatibility = compatibility
    Bridge.originalCompatibilityHit = original
    Bridge.compatibilityWrapper = wrapper
    return true
end

local function installMeleeBridge()
    local actions = ZombieActions
    local smack = actions and actions.Smack
    local original
    local wrapper
    if not smack or type(smack.onWorking) ~= "function" then return false end
    if Bridge.smack == smack and smack.onWorking == Bridge.smackWrapper then
        return true
    end
    original = smack.onWorking
    wrapper = function(bandit, task)
        local enemy
        local item
        local brain
        local amount
        local actionState
        local updated
        if not task or task.hit then return original(bandit, task) end
        enemy = BanditZombie and BanditZombie.Cache
            and BanditZombie.Cache[task.eid] or nil
        if not enemy or not Context.IsHoomansBody(enemy)
            or (tonumber(task.time) or 0) > (tonumber(task.attackTime) or 0)
        then
            return original(bandit, task)
        end
        actionState = Context.SafeMethod(bandit, "getActionStateName")
        if actionState == "getup"
            or actionState == "getup-fromonback"
            or actionState == "getup-fromonfront"
            or actionState == "getup-fromsitting"
            or actionState == "staggerback"
            or actionState == "staggerback-knockeddown"
        then
            return original(bandit, task)
        end
        task.hit = true
        if Bandit and type(Bandit.UpdateTask) == "function" then
            pcall(Bandit.UpdateTask, bandit, task)
        end
        if not BanditCompatibility
            or type(BanditCompatibility.InstanceItem) ~= "function"
        then
            return false
        end
        updated, item = pcall(
            BanditCompatibility.InstanceItem,
            task.weapon
        )
        if not updated or not item then return false end
        brain = BanditBrain and type(BanditBrain.Get) == "function"
            and BanditBrain.Get(bandit) or nil
        amount = Context.MaxDamage(item)
            * (tonumber(brain and brain.strengthBoost) or 1)
            * 2.60
        Bridge.ApplyHit(bandit, item, enemy, {
            amount = amount,
            attackType = "melee",
            attackKind = "bandits_melee",
            damageClass = "melee",
            woundType = "laceration",
            type = "bandits_melee_damage",
        })
        return false
    end
    smack.onWorking = wrapper
    Bridge.smack = smack
    Bridge.originalSmack = original
    Bridge.smackWrapper = wrapper
    return true
end

local function removeRetry()
    if Bridge.retry and Events and Events.OnTick
        and Events.OnTick.Remove
    then
        Events.OnTick.Remove(Bridge.retry)
    end
end

local function retryInstall()
    Bridge.installAttempts = Bridge.installAttempts + 1
    local hitInstalled = installHitBridge()
    local compatibilityInstalled = installCompatibilityBridge()
    local meleeInstalled = installMeleeBridge()
    local optionalMelee = ZombieActions and ZombieActions.Smack
    local optionalCompatibility = BanditHoomansCompatibility
    if (hitInstalled
            and (not optionalCompatibility or compatibilityInstalled)
            and (not optionalMelee or meleeInstalled))
        or Bridge.installAttempts >= 120
    then
        removeRetry()
    end
end

local installedHit = installHitBridge()
local installedCompatibility = installCompatibilityBridge()
local installedMelee = installMeleeBridge()
local optionalMelee = ZombieActions and ZombieActions.Smack
local optionalCompatibility = BanditHoomansCompatibility
local installed = installedHit
    and (not optionalCompatibility or installedCompatibility)
    and (not optionalMelee or installedMelee)

if not installed and Events and Events.OnTick and Events.OnTick.Add then
    Bridge.retry = retryInstall
    Events.OnTick.Add(retryInstall)
end

return Bridge
